-- ============================================================================
-- Total Quincy Interactions by Date
-- Matches Excel: Uses CST date filtering and counts ALL records (not distinct)
-- Power BI will handle showing 0s for missing dates if you use a date table
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
        -- Get latest error message from BizTalk (if exists)
        latestError.LatestErrorMessage,
        -- Determine error status: "Encountered New Error", "Same Error", or "Resolved"
        -- This matches Excel's logic by comparing actual error messages
        -- First check if ANY new error exists (not just XML), then compare
        CASE 
            -- If no initial error, can't determine
            WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
            WHEN r.initialErrorDate IS NULL THEN 'Cannot Determine'
            
            -- Check if there's ANY new error in BizTalk (not just XML)
            WHEN EXISTS (
                SELECT 1
                FROM Biztalk.dbo.Outmessage_hdr obm
                WHERE obm.Source = 'Plus'
                  AND obm.Contract = '10053'
                  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
                  AND obm.Processed = 'F'
                  AND obm.Customer_order_No = r.serialNo
                  AND obm.Insert_Date > r.initialErrorDate
            ) THEN
                -- There's a new error - try to extract and compare
                CASE 
                    -- If we successfully extracted both initial and latest error messages, compare them
                    WHEN latestError.LatestErrorMessage IS NOT NULL 
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
                            )) = latestError.LatestErrorMessage THEN 'Same Error'
                            ELSE 'Encountered New Error'
                        END
                    -- If initial error is plain text OR we can't extract latest error, any new error = "Encountered New Error"
                    ELSE 'Encountered New Error'
                END
            -- No new error = "Resolved"
            ELSE 'Resolved'
        END AS [ErrorStatus]
    FROM ClarityWarehouse.agentlogs.repair r
    OUTER APPLY (
        -- Get latest error message from BizTalk (extracted after "Failed :")
        SELECT TOP 1
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
            )) AS LatestErrorMessage
        FROM Biztalk.dbo.Outmessage_hdr obm
        WHERE obm.Source = 'Plus'
          AND obm.Contract = '10053'
          AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
          AND obm.Processed = 'F'
          AND obm.Customer_order_No = r.serialNo
          AND obm.Insert_Date > r.initialErrorDate
          AND obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%'
          AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
          AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14
        ORDER BY obm.Insert_Date DESC
    ) AS latestError
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
) AS r
GROUP BY CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
ORDER BY [Date] DESC;

