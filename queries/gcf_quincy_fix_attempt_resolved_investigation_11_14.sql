-- ============================================================================
-- INVESTIGATION: All "Resolved by Quincy" records for 11/14/2025
-- ============================================================================
-- Shows all 192 records categorized as "Resolved by Quincy" with timing analysis
-- This helps understand why they're categorized as "Resolved" vs other categories
-- ============================================================================

SELECT 
    r.serialNo,
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [QuincyResolutionDate],
    r.createDate AS [QuincyAttemptTime],
    r.initialErrorDate,
    -- Check for "Msg Sent Ok"
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
    -- Get FIRST "Msg Sent Ok" timestamp (earliest one)
    (SELECT TOP 1 obm.Insert_Date 
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Customer_order_No = r.serialNo
       AND obm.Insert_Date > r.createDate
       AND LOWER(obm.Message) LIKE '%msg sent ok%'
     ORDER BY obm.Insert_Date ASC) AS [FirstMsgSentOkTime],
    -- Hours from Quincy attempt to first "Msg Sent Ok"
    DATEDIFF(HOUR, r.createDate, 
        (SELECT TOP 1 obm.Insert_Date 
         FROM Biztalk.dbo.Outmessage_hdr obm
         WHERE obm.Source = 'Plus'
           AND obm.Contract = '10053'
           AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
           AND obm.Customer_order_No = r.serialNo
           AND obm.Insert_Date > r.createDate
           AND LOWER(obm.Message) LIKE '%msg sent ok%'
         ORDER BY obm.Insert_Date ASC)
    ) AS [HoursToFirstMsgSentOk],
    -- Check for new errors (excluding "Msg Sent Ok")
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
    -- Get first new error timestamp
    (SELECT TOP 1 obm.Insert_Date 
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Processed = 'F'
       AND obm.Customer_order_No = r.serialNo
       AND obm.Insert_Date > r.createDate
       AND LOWER(obm.Message) NOT LIKE '%msg sent ok%'
     ORDER BY obm.Insert_Date ASC) AS [FirstNewErrorTime],
    -- Determine which came first: "Msg Sent Ok" or new error?
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
        ) AND EXISTS (
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
                WHEN (SELECT TOP 1 obm.Insert_Date 
                      FROM Biztalk.dbo.Outmessage_hdr obm
                      WHERE obm.Source = 'Plus'
                        AND obm.Contract = '10053'
                        AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
                        AND obm.Customer_order_No = r.serialNo
                        AND obm.Insert_Date > r.createDate
                        AND LOWER(obm.Message) LIKE '%msg sent ok%'
                      ORDER BY obm.Insert_Date ASC) < 
                     (SELECT TOP 1 obm.Insert_Date 
                      FROM Biztalk.dbo.Outmessage_hdr obm
                      WHERE obm.Source = 'Plus'
                        AND obm.Contract = '10053'
                        AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
                        AND obm.Processed = 'F'
                        AND obm.Customer_order_No = r.serialNo
                        AND obm.Insert_Date > r.createDate
                        AND LOWER(obm.Message) NOT LIKE '%msg sent ok%'
                      ORDER BY obm.Insert_Date ASC)
                THEN 'Msg Sent Ok came FIRST'
                ELSE 'New Error came FIRST'
            END
        ELSE 'N/A'
    END AS [WhichCameFirst],
    -- Show current categorization from our query (using ErrorStatus from subquery)
    CASE 
        WHEN r.ErrorStatus = 'Resolved' THEN 'Resolved by Quincy'
        WHEN r.ErrorStatus = 'Same Error' THEN 'Same Error'
        WHEN r.ErrorStatus = 'Encountered New Error' THEN 'Encountered New Error'
        WHEN r.ErrorStatus = 'Cannot Determine' THEN 'GCF Request Trigger Failure'
        ELSE r.ErrorStatus
    END AS [CurrentCategory],
    -- Also show the extracted error messages for comparison
    r.LatestErrorMessage,
    -- Extract initial error message for comparison
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
    END AS [InitialErrorMessage]
FROM (
    SELECT 
        r.*,
        CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [CSTDate],
        latestError.LatestErrorMessage,
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
) AS r
WHERE r.ErrorStatus = 'Resolved'  -- Only "Resolved by Quincy" records
ORDER BY r.serialNo, r.createDate;

