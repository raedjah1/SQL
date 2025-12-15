-- ============================================================================
-- FIX ATTEMPT SUMMARY
-- ============================================================================
-- Matches Excel pivot: "Fix Attempt Summary"
-- Shows resolution attempts (isSuccess = 1) grouped by error status
-- ============================================================================
-- Categories:
--   - "Encountered New Error" (ErrorStatus = 'Encountered New Error')
--   - "Resolved by Quincy" (ErrorStatus = 'Resolved')
--   - "Same Error" (ErrorStatus = 'Same Error')
--   - "GCF Request Trigger Failure" (ErrorStatus = 'Cannot Determine')
-- ============================================================================

SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Quincy Resolution Date Attempt],
    -- Map ErrorStatus to Excel labels
    CASE 
        WHEN r.ErrorStatus = 'Encountered New Error' THEN 'Encountered New Error'
        WHEN r.ErrorStatus = 'Resolved' THEN 'Resolved by Quincy'
        WHEN r.ErrorStatus = 'Same Error' THEN 'Same Error'
        WHEN r.ErrorStatus = 'Cannot Determine' THEN 'GCF Request Trigger Failure'
        ELSE 'Other'
    END AS [Same Error, Different Error or Resolved],
    -- Count total records (matching Excel - Excel uses COUNT(*), not COUNT(DISTINCT))
    COUNT(*) AS [Count of serialNo],
    -- Calculate percentage (as decimal, multiply by 100 in Power BI if needed)
    CAST(ROUND(CAST(COUNT(*) AS FLOAT) / NULLIF(SUM(COUNT(*)) OVER (), 0), 4) AS DECIMAL(5,4)) AS [Percentage]
FROM (
    SELECT 
        r.*,
        CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [CSTDate],
        -- Get latest error message from BizTalk (if exists)
        latestError.LatestErrorMessage,
        -- Determine error status: "Encountered New Error", "Same Error", or "Resolved"
        -- Excel logic: Check "Latest Message Lookup" first - "Msg Sent Ok" = Resolved, "Not Found" = GCF Request Trigger Failure
        CASE 
            -- If no initial error, can't determine → "GCF Request Trigger Failure"
            WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
            WHEN r.initialErrorDate IS NULL THEN 'Cannot Determine'
            
            -- FIRST check: Is there ANY new error in BizTalk (excluding "Msg Sent Ok")?
            -- Errors take precedence over "Msg Sent Ok" - if there's a new error, categorize it
            -- Check for messages AFTER the Quincy attempt time (r.createDate), not just after initial error
            WHEN EXISTS (
                SELECT 1
                FROM Biztalk.dbo.Outmessage_hdr obm
                WHERE obm.Source = 'Plus'
                  AND obm.Contract = '10053'
                  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
                  AND obm.Processed = 'F'
                  AND obm.Customer_order_No = r.serialNo
                  AND obm.Insert_Date > r.createDate  -- After Quincy attempt time
                  AND LOWER(obm.Message) NOT LIKE '%msg sent ok%'  -- Exclude "Msg Sent Ok" from error check
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
            -- No new error at all (but we have initial error) → "Resolved" (not "GCF Request Trigger Failure")
            -- This means Quincy attempted a fix and no new errors appeared = resolved
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
          AND obm.Insert_Date > r.createDate  -- After Quincy attempt time
          AND LOWER(obm.Message) NOT LIKE '%msg sent ok%'  -- Exclude "Msg Sent Ok" from error extraction
          AND obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%'
          AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
          AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14
        ORDER BY obm.Insert_Date DESC
    ) AS latestError
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND r.isSuccess = 1  -- Only resolution attempts (Fix Attempt)
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
) AS r
GROUP BY 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE),
    CASE 
        WHEN r.ErrorStatus = 'Encountered New Error' THEN 'Encountered New Error'
        WHEN r.ErrorStatus = 'Resolved' THEN 'Resolved by Quincy'
        WHEN r.ErrorStatus = 'Same Error' THEN 'Same Error'
        WHEN r.ErrorStatus = 'Cannot Determine' THEN 'GCF Request Trigger Failure'
        ELSE 'Other'
    END
ORDER BY 
    [Quincy Resolution Date Attempt] DESC,
    [Count of serialNo] DESC;

