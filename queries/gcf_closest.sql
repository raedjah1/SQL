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
        -- Get previous attempt's initial error message (for same serial number, same date)
        prevAttempt.PreviousInitialErrorMessage,
        -- Determine error status: "Encountered New Error", "Same Error", or "Resolved"
        -- Power BI logic: Check if initial error changed between attempts, OR if new error in BizTalk
        CASE 
            -- If no initial error, can't determine → "GCF Request Trigger Failure"
            WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
            WHEN r.initialErrorDate IS NULL THEN 'Cannot Determine'
            
            -- NEW LOGIC: Check if initial error changed from previous attempt (same serial, same date)
            -- This is what Power BI appears to be checking
            WHEN prevAttempt.PreviousInitialErrorMessage IS NOT NULL THEN
                    -- Compare current and previous initial errors
                    CASE 
                        WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                             AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
                             AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14
                             AND prevAttempt.PreviousInitialError LIKE '%<STATUSREASON>%</STATUSREASON>%'
                             AND CHARINDEX('<STATUSREASON>', prevAttempt.PreviousInitialError) > 0
                             AND CHARINDEX('</STATUSREASON>', prevAttempt.PreviousInitialError) > CHARINDEX('<STATUSREASON>', prevAttempt.PreviousInitialError) + 14 THEN
                            -- Both are XML - extract and compare
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
                                )) = prevAttempt.PreviousInitialErrorMessage THEN 'Same Error'
                                ELSE 'Encountered New Error'
                            END
                        ELSE 'Encountered New Error'  -- Can't compare or different format = new error
                    END
                ELSE NULL  -- No previous attempt
            END AS ErrorStatusFromPreviousAttempt,
            -- Determine error status: "Encountered New Error", "Same Error", or "Resolved"
            -- Power BI logic: First check if initial error changed between attempts, then check BizTalk
            CASE 
                -- If no initial error, can't determine → "GCF Request Trigger Failure"
                WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
                WHEN r.initialErrorDate IS NULL THEN 'Cannot Determine'
                
                -- FIRST: Check if initial error changed from previous attempt (same serial, same date)
                -- This is what Power BI appears to be checking
                WHEN prevAttempt.PreviousInitialErrorMessage IS NOT NULL THEN
                    -- Compare current and previous initial errors
                    CASE 
                        WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                             AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
                             AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14
                             AND prevAttempt.PreviousInitialError LIKE '%<STATUSREASON>%</STATUSREASON>%'
                             AND CHARINDEX('<STATUSREASON>', prevAttempt.PreviousInitialError) > 0
                             AND CHARINDEX('</STATUSREASON>', prevAttempt.PreviousInitialError) > CHARINDEX('<STATUSREASON>', prevAttempt.PreviousInitialError) + 14 THEN
                            -- Both are XML - extract and compare
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
                                )) = prevAttempt.PreviousInitialErrorMessage THEN 'Same Error'
                                ELSE 'Encountered New Error'
                            END
                        ELSE 'Encountered New Error'  -- Can't compare or different format = new error
                    END
                
                -- SECOND: Check if there's a new error in BizTalk (excluding "Msg Sent Ok")
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
                -- Check if the error is a DPK/infrastructure error (not a real GCF validation error)
                -- These should be "GCF Request Trigger Failure" not "Encountered New Error"
                CASE 
                    WHEN EXISTS (
                        SELECT 1
                        FROM Biztalk.dbo.Outmessage_hdr obm
                        WHERE obm.Source = 'Plus'
                          AND obm.Contract = '10053'
                          AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
                          AND obm.Processed = 'F'
                          AND obm.Customer_order_No = r.serialNo
                          AND obm.Insert_Date > r.createDate
                          AND LOWER(obm.Message) NOT LIKE '%msg sent ok%'
                          -- Check for DPK/infrastructure error patterns (not extractable XML GCF errors)
                          AND (
                              LOWER(obm.Message) LIKE '%dpk request%'
                              OR LOWER(obm.Message) LIKE '%lkm thrown exception%'
                              OR (LOWER(obm.Message) LIKE '%service tag is invalid%' AND LOWER(obm.Message) LIKE '%dpk%')
                              OR (LOWER(obm.Message) LIKE '%available quantity less than the required quantity%' AND LOWER(obm.Message) LIKE '%dpk%')
                              OR (LOWER(obm.Message) NOT LIKE '%<statusreason>%</statusreason>%' AND LOWER(obm.Message) LIKE '%instance: arc_tn message:%')
                          )
                    ) THEN 'Cannot Determine'  -- DPK/infrastructure error = GCF Request Trigger Failure
                    -- There's a new error - try to extract and compare
                    ELSE
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
    OUTER APPLY (
        -- Get previous attempt's initial error message (for same serial number, same date)
        SELECT TOP 1
            r2.initialError AS PreviousInitialError,
            CASE 
                WHEN r2.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                     AND CHARINDEX('<STATUSREASON>', r2.initialError) > 0
                     AND CHARINDEX('</STATUSREASON>', r2.initialError) > CHARINDEX('<STATUSREASON>', r2.initialError) + 14 THEN
                    LTRIM(SUBSTRING(
                        SUBSTRING(r2.initialError, 
                            CHARINDEX('<STATUSREASON>', r2.initialError) + 14, 
                            CASE 
                                WHEN CHARINDEX('</STATUSREASON>', r2.initialError) - CHARINDEX('<STATUSREASON>', r2.initialError) - 14 > 0 
                                THEN CHARINDEX('</STATUSREASON>', r2.initialError) - CHARINDEX('<STATUSREASON>', r2.initialError) - 14
                                ELSE 1
                            END
                        ),
                        CASE 
                            WHEN CHARINDEX('Failed :', 
                                SUBSTRING(r2.initialError, 
                                    CHARINDEX('<STATUSREASON>', r2.initialError) + 14, 
                                    CASE 
                                        WHEN CHARINDEX('</STATUSREASON>', r2.initialError) - CHARINDEX('<STATUSREASON>', r2.initialError) - 14 > 0 
                                        THEN CHARINDEX('</STATUSREASON>', r2.initialError) - CHARINDEX('<STATUSREASON>', r2.initialError) - 14
                                        ELSE 1
                                    END
                                )) > 0 
                            THEN CHARINDEX('Failed :', 
                                SUBSTRING(r2.initialError, 
                                    CHARINDEX('<STATUSREASON>', r2.initialError) + 14, 
                                    CASE 
                                        WHEN CHARINDEX('</STATUSREASON>', r2.initialError) - CHARINDEX('<STATUSREASON>', r2.initialError) - 14 > 0 
                                        THEN CHARINDEX('</STATUSREASON>', r2.initialError) - CHARINDEX('<STATUSREASON>', r2.initialError) - 14
                                        ELSE 1
                                    END
                                )) + 9
                            ELSE 1 
                        END,
                        200
                    ))
                ELSE LEFT(r2.initialError, 200)
            END AS PreviousInitialErrorMessage
        FROM ClarityWarehouse.agentlogs.repair r2
        WHERE r2.programID = 10053
          AND r2.agentName = 'quincy'
          AND r2.isSuccess = 1
          AND r2.serialNo = r.serialNo
          AND CAST(DATEADD(HOUR, -6, r2.createDate) AS DATE) = CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)  -- Same date
          AND r2.createDate < r.createDate  -- Previous attempt (earlier time)
        ORDER BY r2.createDate DESC  -- Most recent previous attempt
    ) AS prevAttempt
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

