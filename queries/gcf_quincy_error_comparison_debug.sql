-- ============================================================================
-- DEBUG: Error Comparison Logic for 2025-11-18
-- ============================================================================
-- This query shows how we're categorizing errors to find the discrepancy

SELECT 
    r.serialNo,
    r.createDate,
    r.isSuccess,
    -- Initial error preview
    CASE 
        WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' THEN
            SUBSTRING(r.initialError, 
                CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                CASE 
                    WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                    THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                    ELSE 100
                END
            )
        ELSE LEFT(r.initialError, 100)
    END AS [InitialErrorPreview],
    -- Latest error from BizTalk
    latestError.LatestErrorMessage AS [LatestErrorFromBizTalk],
    -- Extracted initial error message (after "Failed :")
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
        ELSE NULL
    END AS [ExtractedInitialErrorMessage],
    -- Current ErrorStatus
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
    END AS [ErrorStatus],
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
                ELSE 'NO MATCH'
            END
        ELSE 'N/A'
    END AS [ComparisonResult]
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
      AND obm.Insert_Date > r.initialErrorDate
      AND obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%'
      AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
      AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14
    ORDER BY obm.Insert_Date DESC
) AS latestError
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-18'
    AND r.isSuccess = 1
ORDER BY 
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
    END, 
    r.serialNo;

