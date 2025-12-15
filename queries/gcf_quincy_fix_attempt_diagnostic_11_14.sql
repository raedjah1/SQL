-- ============================================================================
-- DIAGNOSTIC: Fix Attempt Categorization for 11/14/2025
-- ============================================================================
-- This will show WHY each record is being categorized the way it is
-- ============================================================================

SELECT 
    r.serialNo,
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [QuincyResolutionDate],
    r.createDate AS [QuincyAttemptTime],
    r.initialErrorDate AS [InitialErrorDate],
    
    -- Check 1: Has initial error?
    CASE 
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'NO'
        WHEN r.initialErrorDate IS NULL THEN 'NO'
        ELSE 'YES'
    END AS [HasInitialError],
    
    -- Check 2: Has "Msg Sent Ok"?
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Biztalk.dbo.Outmessage_hdr obm
            WHERE obm.Source = 'Plus'
              AND obm.Contract = '10053'
              AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
              AND obm.Customer_order_No = r.serialNo
              AND obm.Insert_Date > r.createDate
              AND LOWER(obm.Message) LIKE '%msg sent ok%'
        ) THEN 'YES'
        ELSE 'NO'
    END AS [HasMsgSentOk],
    
    -- Check 3: Has new error (excluding Msg Sent Ok)?
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
        ) THEN 'YES'
        ELSE 'NO'
    END AS [HasNewError],
    
    -- Latest error message (if exists)
    latestError.LatestErrorMessage AS [LatestErrorMessage],
    
    -- Initial error message (extracted)
    CASE 
        WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
             AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
             AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14 THEN
            LTRIM(SUBSTRING(
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
            ))
        WHEN r.initialError = 'Root element is missing.' THEN 'Root element is missing.'
        ELSE LEFT(r.initialError, 100)
    END AS [InitialErrorMessage],
    
    -- Comparison result
    CASE 
        WHEN latestError.LatestErrorMessage IS NOT NULL 
             AND r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
             AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
             AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14 THEN
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
                )) = latestError.LatestErrorMessage THEN 'MATCH - Same Error'
                ELSE 'DIFFERENT - New Error'
            END
        ELSE 'CANNOT COMPARE'
    END AS [ComparisonResult],
    
    -- Current categorization
    CASE 
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'GCF Request Trigger Failure'
        WHEN r.initialErrorDate IS NULL THEN 'GCF Request Trigger Failure'
        WHEN EXISTS (
            SELECT 1
            FROM Biztalk.dbo.Outmessage_hdr obm
            WHERE obm.Source = 'Plus'
              AND obm.Contract = '10053'
              AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
              AND obm.Customer_order_No = r.serialNo
              AND obm.Insert_Date > r.createDate
              AND LOWER(obm.Message) LIKE '%msg sent ok%'
        ) THEN 'Resolved by Quincy'
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
        ) THEN
            CASE 
                WHEN latestError.LatestErrorMessage IS NOT NULL 
                     AND r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                     AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
                     AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14 THEN
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
                ELSE 'Encountered New Error'
            END
        ELSE 'Resolved by Quincy'
    END AS [CurrentCategory]
FROM ClarityWarehouse.agentlogs.repair r
OUTER APPLY (
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
      AND obm.Insert_Date > r.createDate
      AND LOWER(obm.Message) NOT LIKE '%msg sent ok%'
      AND obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%'
      AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
      AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14
    ORDER BY obm.Insert_Date DESC
) AS latestError
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 1
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
ORDER BY [CurrentCategory], r.serialNo;

-- Summary by category
SELECT 
    [CurrentCategory],
    COUNT(*) AS [Count]
FROM (
    -- Same logic as above, just the category
    SELECT 
        CASE 
            WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'GCF Request Trigger Failure'
            WHEN r.initialErrorDate IS NULL THEN 'GCF Request Trigger Failure'
            WHEN EXISTS (
                SELECT 1
                FROM Biztalk.dbo.Outmessage_hdr obm
                WHERE obm.Source = 'Plus'
                  AND obm.Contract = '10053'
                  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
                  AND obm.Customer_order_No = r.serialNo
                  AND obm.Insert_Date > r.createDate
                  AND LOWER(obm.Message) LIKE '%msg sent ok%'
            ) THEN 'Resolved by Quincy'
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
            ) THEN
                CASE 
                    WHEN latestError.LatestErrorMessage IS NOT NULL 
                         AND r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                         AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
                         AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14 THEN
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
                    ELSE 'Encountered New Error'
                END
            ELSE 'Resolved by Quincy'
        END AS [CurrentCategory]
    FROM ClarityWarehouse.agentlogs.repair r
    OUTER APPLY (
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
          AND obm.Insert_Date > r.createDate
          AND LOWER(obm.Message) NOT LIKE '%msg sent ok%'
          AND obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%'
          AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
          AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14
        ORDER BY obm.Insert_Date DESC
    ) AS latestError
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND r.isSuccess = 1
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
) AS categorized
GROUP BY [CurrentCategory]
ORDER BY [Count] DESC;

