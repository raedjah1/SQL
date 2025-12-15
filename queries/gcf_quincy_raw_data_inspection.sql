-- ============================================================================
-- RAW DATA INSPECTION - See actual error messages and comparisons
-- ============================================================================
-- This shows the raw data so you can see what's happening with error comparisons
-- Focus on 2025-11-18 to match your Excel comparison

SELECT 
    r.serialNo,
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    r.createDate AS [CreateDateTime],
    r.isSuccess,
    r.initialErrorDate,
    -- Initial Error (full or preview)
    CASE 
        WHEN LEN(r.initialError) > 200 THEN LEFT(r.initialError, 200) + '...'
        ELSE r.initialError
    END AS [InitialError_Raw],
    -- Extract initial error message (after "Failed :" if XML)
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
        WHEN r.initialError IS NOT NULL AND r.initialError NOT LIKE '%<%' THEN
            -- Plain text error
            LTRIM(RTRIM(LEFT(r.initialError, 200)))
        ELSE NULL
    END AS [InitialError_Extracted],
    -- Check if there's ANY new error in BizTalk (not just XML)
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Biztalk.dbo.Outmessage_hdr obm
            WHERE obm.Source = 'Plus'
              AND obm.Contract = '10053'
              AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
              AND obm.Processed = 'F'
              AND obm.Customer_order_No = r.serialNo
              AND obm.Insert_Date > r.initialErrorDate
        ) THEN 'YES'
        ELSE 'NO'
    END AS [HasNewErrorInBizTalk],
    -- Latest error from BizTalk (if exists)
    latestError.LatestErrorDate AS [LatestErrorDate],
    latestError.LatestErrorMessage AS [LatestError_Extracted],
    CASE 
        WHEN latestError.LatestErrorRaw IS NOT NULL AND LEN(latestError.LatestErrorRaw) > 200 
        THEN LEFT(latestError.LatestErrorRaw, 200) + '...'
        ELSE latestError.LatestErrorRaw
    END AS [LatestError_Raw],
    -- Current ErrorStatus calculation
    CASE 
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
        WHEN r.initialErrorDate IS NULL THEN 'Cannot Determine'
        WHEN latestError.LatestErrorMessage IS NOT NULL THEN
            CASE 
                WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
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
        ELSE 'Resolved'
    END AS [CurrentErrorStatus],
    -- Comparison details
    CASE 
        WHEN latestError.LatestErrorMessage IS NOT NULL 
             AND r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' THEN
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
                )) = latestError.LatestErrorMessage THEN 'MATCH'
                ELSE 'NO MATCH - Different'
            END
        WHEN latestError.LatestErrorMessage IS NOT NULL 
             AND r.initialError IS NOT NULL 
             AND r.initialError NOT LIKE '%<%' THEN
            'Plain Text - Cannot Compare'
        ELSE 'N/A'
    END AS [ComparisonResult]
FROM ClarityWarehouse.agentlogs.repair r
OUTER APPLY (
    -- Get latest error from BizTalk (try XML first, then any error)
    SELECT TOP 1
        obm.Insert_Date AS LatestErrorDate,
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
        )) AS LatestErrorMessage,
        obm.Message AS LatestErrorRaw
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
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-18'
    AND r.isSuccess = 1  -- Only resolution attempts
ORDER BY 
    CASE 
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 1
        WHEN r.initialErrorDate IS NULL THEN 2
        WHEN latestError.LatestErrorMessage IS NOT NULL THEN
            CASE 
                WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
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
                        )) = latestError.LatestErrorMessage THEN 3  -- Same Error
                        ELSE 4  -- Encountered New Error
                    END
                ELSE 4  -- Encountered New Error (plain text)
            END
        ELSE 5  -- Resolved
    END,
    r.serialNo;

