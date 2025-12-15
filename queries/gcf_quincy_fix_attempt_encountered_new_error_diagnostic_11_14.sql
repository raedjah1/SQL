-- ============================================================================
-- DIAGNOSTIC: "Encountered New Error" records for 11/14/2025
-- ============================================================================
-- This query verifies we get exactly 31 records categorized as "Encountered New Error"
-- and shows all details to compare with Power BI
-- ============================================================================

-- Summary: Count by category
SELECT 
    'Total Fix Attempts (isSuccess = 1)' AS [Metric],
    COUNT(*) AS [Count]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 1
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'

UNION ALL

SELECT 
    'Encountered New Error (from our query)' AS [Metric],
    COUNT(*) AS [Count]
FROM (
    SELECT 
        r.serialNo,
        r.createDate,
        -- Determine error status (matching gcf_quincy_fix_attempt_summary.sql logic)
        CASE 
            WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
            WHEN r.initialErrorDate IS NULL THEN 'Cannot Determine'
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
            ELSE 'Resolved'
        END AS [ErrorStatus]
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
WHERE categorized.ErrorStatus = 'Encountered New Error';

-- Detail: All "Encountered New Error" records with full details
SELECT 
    categorized.serialNo,
    categorized.woHeaderID,
    categorized.partNo,
    categorized.[Quincy Resolution Date Attempt],
    categorized.QuincyAttemptTime,
    categorized.[Initial ErrorDate],
    categorized.isSuccess,
    categorized.InitialErrorMessage,
    categorized.LatestErrorMessage,
    categorized.LatestMessageLookup,
    categorized.ComparisonResult,
    categorized.ErrorStatus
FROM (
    SELECT 
        r.serialNo,
        r.woHeaderID,
        r.partNo,
        CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Quincy Resolution Date Attempt],
        r.createDate AS QuincyAttemptTime,
        r.initialErrorDate AS [Initial ErrorDate],
        r.isSuccess,
        -- Extract initial error message (after "Failed :")
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
        END AS InitialErrorMessage,
        -- Latest error message from BizTalk
        latestError.LatestErrorMessage,
        -- Latest error categorization (using GCF error categorization logic)
        CASE 
            WHEN latestError.LatestErrorMessage IS NULL THEN 'No Latest Error'
            WHEN LOWER(latestError.LatestErrorMessage) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%root element is missing%' THEN 'Root Element Missing'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag - Flip Win8Upgrade Attribute'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error. Check for corrupt/bad Mods'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator error. Check for duplicate/corrupt Mods'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%could not find an os part number for the order%' THEN 'Could not find an OS Part Number for the Order'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined, Check for SSDR Mod with correct INFO part'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%error, internal hd(s) have not been placed%' THEN 'Error, Internal HD(s) have not been placed - Check BASE and SMOD.'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD when a notebook Base is in the order'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%validation error in process: could not find the family%' THEN 'Missing Family: Check Base Mod'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found!(0) - Needs Memory MOD'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%error while processing for the memory container%' THEN 'Incorrect or Corrupt Memory Mod'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%os part number%'
             AND LOWER(latestError.LatestErrorMessage) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts in Order'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts in the Order'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(latestError.LatestErrorMessage) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed - Check DPK Part'
        ELSE 'Other/Unknown'
    END AS [LatestMessageLookup],
    -- Comparison result
    CASE 
        WHEN latestError.LatestErrorMessage IS NULL THEN 'No Latest Error to Compare'
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
                )) = latestError.LatestErrorMessage THEN 'MATCH - Same Error'
                ELSE 'DIFFERENT - New Error'
            END
        ELSE 'Cannot Compare - Initial Error Not XML'
    END AS [ComparisonResult],
    -- Error status from our query
    CASE 
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
        WHEN r.initialErrorDate IS NULL THEN 'Cannot Determine'
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
        ELSE 'Resolved'
    END AS [ErrorStatus]
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
WHERE categorized.ErrorStatus = 'Encountered New Error'
ORDER BY categorized.serialNo, categorized.QuincyAttemptTime;

