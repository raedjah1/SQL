-- ============================================================================
-- GCF QUINCY SUMMARY - FIRST ERROR AFTER INTERACTION
-- ============================================================================
-- Gets the FIRST error after Quincy interaction (createDate) instead of latest
-- ============================================================================

SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    COUNT(*) AS [TotalQuincyInteractions],
    
    -- Count columns (matching Excel breakdown)
    SUM(CASE WHEN r.isSuccess = 1 THEN 1 ELSE 0 END) AS [QuincyResolutionAttempts],
    SUM(CASE WHEN r.isSuccess = 1 AND r.ErrorStatus = 'Encountered New Error' THEN 1 ELSE 0 END) AS [EncounteredNewError],
    SUM(CASE WHEN r.isSuccess = 1 AND r.ErrorStatus = 'Resolved' THEN 1 ELSE 0 END) AS [ResolvedByQuincy],
    SUM(CASE WHEN r.isSuccess = 1 AND r.ErrorStatus = 'Same Error' THEN 1 ELSE 0 END) AS [SameError],
    SUM(CASE WHEN r.isSuccess = 1 AND r.ErrorStatus = 'Cannot Determine' THEN 1 ELSE 0 END) AS [GCFRequestTriggerFailure],
    
    -- Percentage columns (as decimals 0.0 to 1.0, not multiplied by 100)
    -- Resolution Attempt % = Resolution Attempts / Total Interactions
    CAST(ROUND(CAST(SUM(CASE WHEN r.isSuccess = 1 THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [ResolutionAttemptPercent],
    
    -- Resolved but New Error % (Based on resolution attempts) = Encountered New Error / Resolution Attempts
    -- Only count resolution attempts where we can determine the status (not "Cannot Determine")
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.isSuccess = 1 
             AND r.ErrorStatus = 'Encountered New Error' THEN 1 
        ELSE 0
    END) AS FLOAT) / NULLIF(SUM(CASE WHEN r.isSuccess = 1 AND r.ErrorStatus != 'Cannot Determine' THEN 1 ELSE 0 END), 0), 4) AS DECIMAL(5,4)) AS [ResolvedButNewErrorPercent],
    
    -- Full Resolutions (Msg Sent Ok) - Based on resolution attempts = Resolved / Resolution Attempts
    -- Only count resolution attempts where we can determine the status
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.isSuccess = 1 
             AND r.ErrorStatus = 'Resolved' THEN 1 
        ELSE 0
    END) AS FLOAT) / NULLIF(SUM(CASE WHEN r.isSuccess = 1 AND r.ErrorStatus != 'Cannot Determine' THEN 1 ELSE 0 END), 0), 4) AS DECIMAL(5,4)) AS [FullResolutionsPercent],
    
    -- Total Resolution % (Based on resolution attempts) = Resolved but New Error % + Full Resolutions %
    -- Only count resolution attempts where we can determine the status
    CAST(ROUND(CAST((
        SUM(CASE WHEN r.isSuccess = 1 AND r.ErrorStatus = 'Encountered New Error' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN r.isSuccess = 1 AND r.ErrorStatus = 'Resolved' THEN 1 ELSE 0 END)
    ) AS FLOAT) / NULLIF(SUM(CASE WHEN r.isSuccess = 1 AND r.ErrorStatus != 'Cannot Determine' THEN 1 ELSE 0 END), 0), 4) AS DECIMAL(5,4)) AS [TotalResolutionPercent]

FROM (
    SELECT 
        r.*,
        CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [CSTDate],
        
        -- Get FIRST message from BizTalk after Quincy interaction (could be error OR "Msg Sent Ok")
        firstMessage.FirstErrorMessage,
        firstMessage.Processed AS FirstMessageProcessed,
        firstMessage.MessageRaw AS FirstMessageRaw,
        
        -- Determine error status: "Encountered New Error", "Same Error", or "Resolved"
        CASE 
            -- If no initial error, can't determine
            WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
            WHEN r.initialErrorDate IS NULL THEN 'Cannot Determine'
            
            -- Check if there's a FIRST message from BizTalk after Quincy interaction
            WHEN firstMessage.MessageRaw IS NOT NULL THEN
                -- There's a message - check if it's "Msg Sent Ok" or an error
                CASE 
                    -- If first message is "Msg Sent Ok" (Processed = 'T' OR message contains "msg sent ok")
                    WHEN firstMessage.Processed = 'T' 
                         OR LOWER(firstMessage.MessageRaw) LIKE '%msg sent ok%' THEN
                        'Resolved'
                    -- If first message is an error (Processed = 'F' and not "Msg Sent Ok")
                    WHEN firstMessage.Processed = 'F' 
                         AND LOWER(firstMessage.MessageRaw) NOT LIKE '%msg sent ok%' THEN
                        -- There's a new error - try to extract and compare
                        CASE 
                            -- If we successfully extracted both initial and first error messages, compare them
                            WHEN firstMessage.FirstErrorMessage IS NOT NULL
                         AND r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                         AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
                         AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14 THEN
                        -- Both are XML - extract and compare error messages (after "Failed :")
                        CASE 
                            WHEN LTRIM(SUBSTRING(
                                SUBSTRING(r.initialError, 
                                    CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                                    CASE 
                                        WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                        THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                        ELSE 1
                                    END
                                ),
                                CASE 
                                    WHEN CHARINDEX('Failed :', 
                                        SUBSTRING(r.initialError, 
                                            CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                                            CASE 
                                                WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                                THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                                ELSE 1
                                            END
                                        )) > 0 
                                    THEN CHARINDEX('Failed :', 
                                        SUBSTRING(r.initialError, 
                                            CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                                            CASE 
                                                WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                                THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                                ELSE 1
                                            END
                                        )) + 9
                                    ELSE 1 
                                END,
                                200
                            )) = firstMessage.FirstErrorMessage THEN 'Same Error'
                            ELSE 'Encountered New Error'
                        END
                    -- If initial error is plain text OR we can't extract first error, any new error = "Encountered New Error"
                    ELSE 'Encountered New Error'
                END
                    -- Unknown message type
                    ELSE 'Cannot Determine'
                END
            -- No message from BizTalk at all → "GCF Request Trigger Failure"
            ELSE 'Cannot Determine'
        END AS [ErrorStatus]
        
    FROM ClarityWarehouse.agentlogs.repair r
    
    OUTER APPLY (
        -- Get FIRST message from BizTalk after Quincy interaction (matching view logic)
        -- Could be error OR "Msg Sent Ok" - we'll check in categorization
        SELECT TOP 1
            obm.Message AS MessageRaw,
            obm.Processed,
            -- Extract error message (only if it has STATUSREASON XML structure)
            CASE 
                WHEN obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%'
                     AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
                     AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14 THEN
                    LTRIM(SUBSTRING(
                        SUBSTRING(obm.Message, 
                            CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                            CASE 
                                WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                ELSE 1
                            END
                        ),
                        CASE 
                            WHEN CHARINDEX('Failed :', 
                                SUBSTRING(obm.Message, 
                                    CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                    CASE 
                                        WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                        THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                        ELSE 1
                                    END
                                )) > 0 
                            THEN CHARINDEX('Failed :', 
                                SUBSTRING(obm.Message, 
                                    CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                    CASE 
                                        WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                        THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                        ELSE 1
                                    END
                                )) + 9
                            ELSE 1 
                        END,
                        200
                    ))
                ELSE NULL
            END AS FirstErrorMessage
        FROM Biztalk.dbo.Outmessage_hdr obm
        WHERE obm.Source = 'Plus'
          AND obm.Contract = '10053'
          AND obm.Message_Type IN ('DellARB-GCF_V2', 'DellARB-GCF_V3', 'DellARB-GCF_V4', 'DellARB-GCF_V5')  -- All message types
          AND obm.Customer_order_No = r.serialNo
          AND obm.Insert_Date > r.createDate  -- After Quincy interaction
          AND r.isSuccess = 1  -- Only get message for resolution attempts (matching view)
        ORDER BY obm.Insert_Date ASC  -- FIRST message (matching view)
    ) AS firstMessage
    
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
) AS r
GROUP BY CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
ORDER BY [Date] DESC;

