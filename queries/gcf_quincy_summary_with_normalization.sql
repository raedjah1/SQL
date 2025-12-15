-- ============================================================================
-- GCF QUINCY SUMMARY - WITH NORMALIZED ERROR LOGIC
-- ============================================================================
-- Combines the best of both: view's normalization + categorization + percentages
-- Uses robust error normalization (handles ErrorReason DATAITEM, STATUSREASON, etc.)
-- ============================================================================

SELECT 
    arl.CSTDate AS [Date],
    COUNT(*) AS [TotalQuincyInteractions],
    
    -- Count columns (matching Excel breakdown)
    SUM(CASE WHEN arl.isSuccess = 1 THEN 1 ELSE 0 END) AS [QuincyResolutionAttempts],
    SUM(CASE WHEN arl.isSuccess = 1 AND arl.ErrorStatus = 'Encountered New Error' THEN 1 ELSE 0 END) AS [EncounteredNewError],
    SUM(CASE WHEN arl.isSuccess = 1 AND arl.ErrorStatus = 'Resolved' THEN 1 ELSE 0 END) AS [ResolvedByQuincy],
    SUM(CASE WHEN arl.isSuccess = 1 AND arl.ErrorStatus = 'Same Error' THEN 1 ELSE 0 END) AS [SameError],
    SUM(CASE WHEN arl.isSuccess = 1 AND arl.ErrorStatus = 'Cannot Determine' THEN 1 ELSE 0 END) AS [GCFRequestTriggerFailure],
    
    -- Percentage columns (as decimals 0.0 to 1.0, not multiplied by 100)
    -- Resolution Attempt % = Resolution Attempts / Total Interactions
    CAST(ROUND(CAST(SUM(CASE WHEN arl.isSuccess = 1 THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [ResolutionAttemptPercent],
    
    -- Resolved but New Error % (Based on resolution attempts) = Encountered New Error / Resolution Attempts
    -- Only count resolution attempts where we can determine the status (not "Cannot Determine")
    CAST(ROUND(CAST(SUM(CASE 
        WHEN arl.isSuccess = 1 
             AND arl.ErrorStatus = 'Encountered New Error' THEN 1 
        ELSE 0
    END) AS FLOAT) / NULLIF(SUM(CASE WHEN arl.isSuccess = 1 AND arl.ErrorStatus != 'Cannot Determine' THEN 1 ELSE 0 END), 0), 4) AS DECIMAL(5,4)) AS [ResolvedButNewErrorPercent],
    
    -- Full Resolutions (Msg Sent Ok) - Based on resolution attempts = Resolved / Resolution Attempts
    -- Only count resolution attempts where we can determine the status
    CAST(ROUND(CAST(SUM(CASE 
        WHEN arl.isSuccess = 1 
             AND arl.ErrorStatus = 'Resolved' THEN 1 
        ELSE 0
    END) AS FLOAT) / NULLIF(SUM(CASE WHEN arl.isSuccess = 1 AND arl.ErrorStatus != 'Cannot Determine' THEN 1 ELSE 0 END), 0), 4) AS DECIMAL(5,4)) AS [FullResolutionsPercent],
    
    -- Total Resolution % (Based on resolution attempts) = Resolved but New Error % + Full Resolutions %
    -- Only count resolution attempts where we can determine the status
    CAST(ROUND(CAST((
        SUM(CASE WHEN arl.isSuccess = 1 AND arl.ErrorStatus = 'Encountered New Error' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN arl.isSuccess = 1 AND arl.ErrorStatus = 'Resolved' THEN 1 ELSE 0 END)
    ) AS FLOAT) / NULLIF(SUM(CASE WHEN arl.isSuccess = 1 AND arl.ErrorStatus != 'Cannot Determine' THEN 1 ELSE 0 END), 0), 4) AS DECIMAL(5,4)) AS [TotalResolutionPercent]

FROM (
    SELECT 
        r.*,
        CAST(CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATETIME2) AS DATE) AS [CSTDate],
        
        -- Use normalized errors from view logic
        ie.InitialErrorNorm,
        ne.NewErrorNorm AS FirstMessageNorm,
        firstMessageRaw.Processed AS FirstMessageProcessed,
        firstMessageRaw.Message AS FirstMessageRaw,
        
        -- Determine error status using normalized errors (matching view's logic)
        -- The view gets the FIRST message after createDate, then we check if it's "Msg Sent Ok" or an error
        CASE 
            -- If no initial error, can't determine
            WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
            WHEN r.initialErrorDate IS NULL THEN 'Cannot Determine'
            
            -- Check if there's a FIRST message from BizTalk (matching view's OUTER APPLY)
            WHEN firstMessageRaw.Message IS NOT NULL THEN
                -- There's a message from BizTalk - check if it's "Msg Sent Ok" or an error
                CASE 
                    -- If first message is "Msg Sent Ok" (Processed = 'T' OR message contains "msg sent ok")
                    WHEN firstMessageRaw.Processed = 'T' 
                         OR LOWER(firstMessageRaw.Message) LIKE '%msg sent ok%' THEN
                        'Resolved'
                    -- If first message is an error (Processed = 'F' and not "Msg Sent Ok")
                    WHEN firstMessageRaw.Processed = 'F' 
                         AND LOWER(firstMessageRaw.Message) NOT LIKE '%msg sent ok%' THEN
                        -- There's a new error - compare normalized errors
                        CASE 
                            -- If we have both normalized errors, compare them
                            WHEN ie.InitialErrorNorm IS NOT NULL 
                                 AND ne.NewErrorNorm IS NOT NULL THEN
                                CASE 
                                    WHEN ie.InitialErrorNorm = ne.NewErrorNorm THEN 'Same Error'
                                    ELSE 'Encountered New Error'
                                END
                            -- If we can't normalize, any new error = "Encountered New Error"
                            ELSE 'Encountered New Error'
                        END
                    -- Unknown message type
                    ELSE 'Cannot Determine'
                END
            -- No message from BizTalk at all → "GCF Request Trigger Failure"
            ELSE 'Cannot Determine'
        END AS [ErrorStatus]
        
    FROM ClarityWarehouse.agentlogs.repair r
    
    -- ========================================================================
    -- Inline normalization for initialError (from view logic)
    -- ========================================================================
    CROSS APPLY (
        SELECT MsgTrim = LTRIM(RTRIM(ISNULL(r.initialError, '')))
    ) ie0
    CROSS APPLY (
        SELECT
            BaseReason =
                CASE
                    -- XML + ErrorReason DATAITEM
                    WHEN ie0.MsgTrim LIKE '%<?xml%'
                         AND CHARINDEX('name="ErrorReason"', ie0.MsgTrim) > 0
                         AND CHARINDEX('value="', ie0.MsgTrim, CHARINDEX('name="ErrorReason"', ie0.MsgTrim) + 1) > 0
                         AND CHARINDEX('"', ie0.MsgTrim, 
                             CHARINDEX('value="', ie0.MsgTrim, CHARINDEX('name="ErrorReason"', ie0.MsgTrim) + 1) + LEN('value="')) > 0
                    THEN
                        SUBSTRING(
                            ie0.MsgTrim,
                            CHARINDEX('value="', ie0.MsgTrim, CHARINDEX('name="ErrorReason"', ie0.MsgTrim) + 1) + LEN('value="'),
                            CHARINDEX('"', ie0.MsgTrim, 
                                CHARINDEX('value="', ie0.MsgTrim, CHARINDEX('name="ErrorReason"', ie0.MsgTrim) + 1) + LEN('value="')) - 
                            (CHARINDEX('value="', ie0.MsgTrim, CHARINDEX('name="ErrorReason"', ie0.MsgTrim) + 1) + LEN('value="'))
                        )
                    -- XML + <STATUSREASON>...</STATUSREASON>
                    WHEN ie0.MsgTrim LIKE '%<?xml%'
                         AND CHARINDEX('<STATUSREASON>', ie0.MsgTrim) > 0
                         AND CHARINDEX('</STATUSREASON>', ie0.MsgTrim) > CHARINDEX('<STATUSREASON>', ie0.MsgTrim)
                    THEN
                        SUBSTRING(
                            ie0.MsgTrim,
                            CHARINDEX('<STATUSREASON>', ie0.MsgTrim) + LEN('<STATUSREASON>'),
                            CHARINDEX('</STATUSREASON>', ie0.MsgTrim) - (CHARINDEX('<STATUSREASON>', ie0.MsgTrim) + LEN('<STATUSREASON>'))
                        )
                    -- no XML / no markers → full message
                    ELSE ie0.MsgTrim
                END
    ) ie1
    CROSS APPLY (
        SELECT
            ReasonWithFailed =
                CASE
                    WHEN CHARINDEX('Failed :', ie1.BaseReason) > 0
                    THEN SUBSTRING(ie1.BaseReason, CHARINDEX('Failed :', ie1.BaseReason), LEN(ie1.BaseReason))
                    ELSE ie1.BaseReason
                END
    ) ie2
    CROSS APPLY (
        SELECT
            InitialErrorNorm =
                LTRIM(RTRIM(
                    CASE
                        WHEN CHARINDEX(' - ', ie2.ReasonWithFailed) > 0
                             AND CHARINDEX(' - ', ie2.ReasonWithFailed) < 25
                        THEN SUBSTRING(ie2.ReasonWithFailed, CHARINDEX(' - ', ie2.ReasonWithFailed) + 3, LEN(ie2.ReasonWithFailed))
                        ELSE ie2.ReasonWithFailed
                    END
                ))
    ) ie
    
    -- ========================================================================
    -- Get FIRST message from BizTalk after repair attempt (matching view logic)
    -- ========================================================================
    OUTER APPLY (
        SELECT TOP 1
            obm.Message,
            obm.Processed
        FROM Biztalk.dbo.Outmessage_hdr obm
        WHERE obm.Source = 'Plus'
          AND obm.Contract = '10053'
          AND obm.Message_Type IN ('DellARB-GCF_V2', 'DellARB-GCF_V3', 'DellARB-GCF_V4', 'DellARB-GCF_V5')
          AND obm.Customer_order_No = r.serialNo
          AND (obm.Insert_Date AT TIME ZONE 'Central Standard Time' AT TIME ZONE 'UTC') > (r.createDate AT TIME ZONE 'UTC')
          AND r.isSuccess = 1  -- Only get message for resolution attempts (matching view)
        ORDER BY obm.Insert_Date ASC  -- FIRST message (matching view)
    ) firstMessageRaw
    
    -- ========================================================================
    -- Inline normalization for firstMessage (from view logic)
    -- ========================================================================
    CROSS APPLY (
        SELECT MsgTrim = LTRIM(RTRIM(ISNULL(firstMessageRaw.Message, '')))
    ) ne0
    CROSS APPLY (
        SELECT
            BaseReason =
                CASE
                    WHEN ne0.MsgTrim LIKE '%<?xml%'
                         AND CHARINDEX('name="ErrorReason"', ne0.MsgTrim) > 0
                         AND CHARINDEX('value="', ne0.MsgTrim, CHARINDEX('name="ErrorReason"', ne0.MsgTrim) + 1) > 0
                         AND CHARINDEX('"', ne0.MsgTrim, 
                             CHARINDEX('value="', ne0.MsgTrim, CHARINDEX('name="ErrorReason"', ne0.MsgTrim) + 1) + LEN('value="')) > 0
                    THEN
                        SUBSTRING(
                            ne0.MsgTrim,
                            CHARINDEX('value="', ne0.MsgTrim, CHARINDEX('name="ErrorReason"', ne0.MsgTrim) + 1) + LEN('value="'),
                            CHARINDEX('"', ne0.MsgTrim, 
                                CHARINDEX('value="', ne0.MsgTrim, CHARINDEX('name="ErrorReason"', ne0.MsgTrim) + 1) + LEN('value="')) - 
                            (CHARINDEX('value="', ne0.MsgTrim, CHARINDEX('name="ErrorReason"', ne0.MsgTrim) + 1) + LEN('value="'))
                        )
                    WHEN ne0.MsgTrim LIKE '%<?xml%'
                         AND CHARINDEX('<STATUSREASON>', ne0.MsgTrim) > 0
                         AND CHARINDEX('</STATUSREASON>', ne0.MsgTrim) > CHARINDEX('<STATUSREASON>', ne0.MsgTrim)
                    THEN
                        SUBSTRING(
                            ne0.MsgTrim,
                            CHARINDEX('<STATUSREASON>', ne0.MsgTrim) + LEN('<STATUSREASON>'),
                            CHARINDEX('</STATUSREASON>', ne0.MsgTrim) - (CHARINDEX('<STATUSREASON>', ne0.MsgTrim) + LEN('<STATUSREASON>'))
                        )
                    ELSE ne0.MsgTrim
                END
    ) ne1
    CROSS APPLY (
        SELECT
            ReasonWithFailed =
                CASE
                    WHEN CHARINDEX('Failed :', ne1.BaseReason) > 0
                    THEN SUBSTRING(ne1.BaseReason, CHARINDEX('Failed :', ne1.BaseReason), LEN(ne1.BaseReason))
                    ELSE ne1.BaseReason
                END
    ) ne2
    CROSS APPLY (
        SELECT
            NewErrorNorm =
                LTRIM(RTRIM(
                    CASE
                        WHEN CHARINDEX(' - ', ne2.ReasonWithFailed) > 0
                             AND CHARINDEX(' - ', ne2.ReasonWithFailed) < 25
                        THEN SUBSTRING(ne2.ReasonWithFailed, CHARINDEX(' - ', ne2.ReasonWithFailed) + 3, LEN(ne2.ReasonWithFailed))
                        ELSE ne2.ReasonWithFailed
                    END
                ))
    ) ne
    
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND r.debug = 0  -- Match view's filter
        AND CAST(CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATETIME2) AS DATE) >= '2025-11-08'
) AS arl
GROUP BY arl.CSTDate
ORDER BY [Date] DESC;

