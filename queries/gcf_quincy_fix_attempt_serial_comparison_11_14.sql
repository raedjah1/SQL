-- ============================================================================
-- SERIAL NUMBER COMPARISON: Excel vs Query for "Resolved by Quincy" on 11/14/2025
-- ============================================================================
-- This will help identify which serial numbers are in Excel but not in Query,
-- and vice versa
-- ============================================================================

-- Excel list (from user input)
WITH ExcelSerials AS (
    SELECT serialNo
    FROM (VALUES
        ('DF0J0D4'), ('1CPWFF4'), ('589TMD4'), ('8VYXSB4'), ('94RV3D4'), ('34RV3D4'),
        ('J43HXB4'), ('439HD74'), ('J43HXB4'), ('45NBGC4'), ('DZTTJC4'), ('G4MBVC4'),
        ('6LX01D4'), ('66W9V74'), ('88TCZF4'), ('2GN5PC4'), ('GK021D4'), ('GYWT2C4'),
        ('BZR4N94'), ('1MFX5F4'), ('3TW61D4'), ('CYWT2C4'), ('DWWT2C4'), ('2MT58F4'),
        ('BZR4N94'), ('JCB9MD4'), ('5G121D4'), ('BZZ1MD4'), ('37RGSB4'), ('CVVQDC4'),
        ('GK31KD4'), ('311L6F4'), ('9215WF4'), ('77NTLD4'), ('77NTLD4'), ('77NTLD4'),
        ('77NTLD4'), ('77NTLD4'), ('589TMD4'), ('24RV3D4'), ('24RV3D4'), ('57VV3D4'),
        ('17VV3D4'), ('24RV3D4'), ('15RV3D4'), ('57VV3D4'), ('17VV3D4'), ('24RV3D4'),
        ('8VYXSB4'), ('57VV3D4'), ('17VV3D4'), ('24RV3D4'), ('65RV3D4'), ('57VV3D4'),
        ('C6VV3D4'), ('17VV3D4'), ('G6VV3D4'), ('24RV3D4'), ('C6VV3D4'), ('57VV3D4'),
        ('17VV3D4'), ('H6VV3D4'), ('C6VV3D4'), ('D4RV3D4'), ('17VV3D4'), ('57VV3D4'),
        ('54RV3D4'), ('44RV3D4'), ('C6VV3D4'), ('54RV3D4'), ('55RV3D4'), ('44RV3D4'),
        ('84RV3D4'), ('54RV3D4'), ('44RV3D4'), ('84RV3D4'), ('54RV3D4'), ('44RV3D4'),
        ('84RV3D4'), ('54RV3D4'), ('44RV3D4'), ('46VV3D4'), ('84RV3D4'), ('1HN3284'),
        ('4NGYSB4'), ('JTTJPD4'), ('74RV3D4'), ('D3RV3D4'), ('37VV3D4'), ('DF121D4'),
        ('44RV3D4'), ('54RV3D4'), ('84RV3D4'), ('56VV3D4'), ('B4RV3D4'), ('84RV3D4'),
        ('47VV3D4'), ('H0JTW54'), ('BNTVSF4'), ('93RV3D4'), ('1K9N3D4'), ('83RV3D4'),
        ('4HHSMC4'), ('45NBGC4'), ('6LX01D4'), ('66W9V74'), ('99RQBB4'), ('DN1X3D4'),
        ('2N7H3D4'), ('88TCZF4'), ('GK021D4'), ('2GN5PC4'), ('GYWT2C4'), ('JPH2ND4'),
        ('4TMWJD4'), ('3TW61D4'), ('CYWT2C4'), ('2MT58F4'), ('JCB9MD4'), ('CVVQDC4'),
        ('DWWT2C4'), ('5G121D4'), ('37RGSB4'), ('2KYP3D4'), ('BZZ1MD4'), ('8XMSPD4'),
        ('94RV3D4'), ('94RV3D4'), ('34RV3D4'), ('94RV3D4'), ('34RV3D4'), ('G2L9724'),
        ('94RV3D4'), ('34RV3D4'), ('G2L9724'), ('94RV3D4'), ('34RV3D4'), ('G2L9724'),
        ('34RV3D4'), ('J43HXB4'), ('J43HXB4'), ('J43HXB4'), ('GYWT2C4'), ('508YSB4'),
        ('27VV3D4'), ('4STXSB4'), ('6Z8YSB4'), ('GVKXSB4'), ('G18YSB4'), ('FL98MD4'),
        ('H2HTKB4'), ('D0LXSB4'), ('F6VV3D4'), ('32J5XB4'), ('JWFXXC4'), ('6KVYSB4'),
        ('G4PVMD4'), ('J9TYSB4'), ('CKHXSB4'), ('7SMXSB4'), ('C1VXSB4'), ('GQHXSB4'),
        ('7MZ11D4'), ('98BYSB4'), ('CB74FY3'), ('5NCYSB4'), ('GDM7CD4'), ('H5NBGC4'),
        ('7WQM564'), ('GJJRMD4'), ('H98BGD4'), ('7YZ35D4'), ('JNZ11D4'), ('8FQ0PC4'),
        ('2HN3284'), ('J2FWLC4'), ('1NB15D4'), ('GQN75C4'), ('BQY1CB4'), ('DG84WF4'),
        ('CSPZ4D4'), ('JXWT2C4'), ('7WWT2C4'), ('83D1Y84'), ('14758F4'), ('1YWT2C4'),
        ('9YWT2C4'), ('2WWT2C4'), ('BXWT2C4'), ('1L1C094'), ('7GXRFD4'), ('FYWT2C4')
    ) AS ExcelData(serialNo)
),
QuerySerials AS (
    -- Get serial numbers from our query for "Resolved by Quincy" on 11/14/2025
    -- Using the EXACT same logic as gcf_quincy_fix_attempt_summary.sql
    SELECT r.serialNo
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
    WHERE r.ErrorStatus = 'Resolved'  -- Only "Resolved by Quincy"
)

-- Serial numbers in Excel but NOT in Query
SELECT 
    'In Excel but NOT in Query' AS [Category],
    e.serialNo,
    COUNT(*) AS [OccurrencesInExcel]
FROM ExcelSerials e
LEFT JOIN QuerySerials q ON e.serialNo = q.serialNo
WHERE q.serialNo IS NULL
GROUP BY e.serialNo

UNION ALL

-- Serial numbers in Query but NOT in Excel
SELECT 
    'In Query but NOT in Excel' AS [Category],
    q.serialNo,
    COUNT(*) AS [OccurrencesInQuery]
FROM QuerySerials q
LEFT JOIN ExcelSerials e ON q.serialNo = e.serialNo
WHERE e.serialNo IS NULL
GROUP BY q.serialNo

ORDER BY [Category], serialNo;

-- ============================================================================
-- Summary counts (separate query - CTEs redefined)
-- ============================================================================
WITH ExcelSerials AS (
    SELECT serialNo
    FROM (VALUES
        ('DF0J0D4'), ('1CPWFF4'), ('589TMD4'), ('8VYXSB4'), ('94RV3D4'), ('34RV3D4'),
        ('J43HXB4'), ('439HD74'), ('J43HXB4'), ('45NBGC4'), ('DZTTJC4'), ('G4MBVC4'),
        ('6LX01D4'), ('66W9V74'), ('88TCZF4'), ('2GN5PC4'), ('GK021D4'), ('GYWT2C4'),
        ('BZR4N94'), ('1MFX5F4'), ('3TW61D4'), ('CYWT2C4'), ('DWWT2C4'), ('2MT58F4'),
        ('BZR4N94'), ('JCB9MD4'), ('5G121D4'), ('BZZ1MD4'), ('37RGSB4'), ('CVVQDC4'),
        ('GK31KD4'), ('311L6F4'), ('9215WF4'), ('77NTLD4'), ('77NTLD4'), ('77NTLD4'),
        ('77NTLD4'), ('77NTLD4'), ('589TMD4'), ('24RV3D4'), ('24RV3D4'), ('57VV3D4'),
        ('17VV3D4'), ('24RV3D4'), ('15RV3D4'), ('57VV3D4'), ('17VV3D4'), ('24RV3D4'),
        ('8VYXSB4'), ('57VV3D4'), ('17VV3D4'), ('24RV3D4'), ('65RV3D4'), ('57VV3D4'),
        ('C6VV3D4'), ('17VV3D4'), ('G6VV3D4'), ('24RV3D4'), ('C6VV3D4'), ('57VV3D4'),
        ('17VV3D4'), ('H6VV3D4'), ('C6VV3D4'), ('D4RV3D4'), ('17VV3D4'), ('57VV3D4'),
        ('54RV3D4'), ('44RV3D4'), ('C6VV3D4'), ('54RV3D4'), ('55RV3D4'), ('44RV3D4'),
        ('84RV3D4'), ('54RV3D4'), ('44RV3D4'), ('84RV3D4'), ('54RV3D4'), ('44RV3D4'),
        ('84RV3D4'), ('54RV3D4'), ('44RV3D4'), ('46VV3D4'), ('84RV3D4'), ('1HN3284'),
        ('4NGYSB4'), ('JTTJPD4'), ('74RV3D4'), ('D3RV3D4'), ('37VV3D4'), ('DF121D4'),
        ('44RV3D4'), ('54RV3D4'), ('84RV3D4'), ('56VV3D4'), ('B4RV3D4'), ('84RV3D4'),
        ('47VV3D4'), ('H0JTW54'), ('BNTVSF4'), ('93RV3D4'), ('1K9N3D4'), ('83RV3D4'),
        ('4HHSMC4'), ('45NBGC4'), ('6LX01D4'), ('66W9V74'), ('99RQBB4'), ('DN1X3D4'),
        ('2N7H3D4'), ('88TCZF4'), ('GK021D4'), ('2GN5PC4'), ('GYWT2C4'), ('JPH2ND4'),
        ('4TMWJD4'), ('3TW61D4'), ('CYWT2C4'), ('2MT58F4'), ('JCB9MD4'), ('CVVQDC4'),
        ('DWWT2C4'), ('5G121D4'), ('37RGSB4'), ('2KYP3D4'), ('BZZ1MD4'), ('8XMSPD4'),
        ('94RV3D4'), ('94RV3D4'), ('34RV3D4'), ('94RV3D4'), ('34RV3D4'), ('G2L9724'),
        ('94RV3D4'), ('34RV3D4'), ('G2L9724'), ('94RV3D4'), ('34RV3D4'), ('G2L9724'),
        ('34RV3D4'), ('J43HXB4'), ('J43HXB4'), ('J43HXB4'), ('GYWT2C4'), ('508YSB4'),
        ('27VV3D4'), ('4STXSB4'), ('6Z8YSB4'), ('GVKXSB4'), ('G18YSB4'), ('FL98MD4'),
        ('H2HTKB4'), ('D0LXSB4'), ('F6VV3D4'), ('32J5XB4'), ('JWFXXC4'), ('6KVYSB4'),
        ('G4PVMD4'), ('J9TYSB4'), ('CKHXSB4'), ('7SMXSB4'), ('C1VXSB4'), ('GQHXSB4'),
        ('7MZ11D4'), ('98BYSB4'), ('CB74FY3'), ('5NCYSB4'), ('GDM7CD4'), ('H5NBGC4'),
        ('7WQM564'), ('GJJRMD4'), ('H98BGD4'), ('7YZ35D4'), ('JNZ11D4'), ('8FQ0PC4'),
        ('2HN3284'), ('J2FWLC4'), ('1NB15D4'), ('GQN75C4'), ('BQY1CB4'), ('DG84WF4'),
        ('CSPZ4D4'), ('JXWT2C4'), ('7WWT2C4'), ('83D1Y84'), ('14758F4'), ('1YWT2C4'),
        ('9YWT2C4'), ('2WWT2C4'), ('BXWT2C4'), ('1L1C094'), ('7GXRFD4'), ('FYWT2C4')
    ) AS ExcelData(serialNo)
),
QuerySerials AS (
    -- Get serial numbers from our query for "Resolved by Quincy" on 11/14/2025
    -- Using the EXACT same logic as gcf_quincy_fix_attempt_summary.sql
    SELECT r.serialNo
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
    WHERE r.ErrorStatus = 'Resolved'  -- Only "Resolved by Quincy"
)
SELECT 
    'Excel Total (with duplicates)' AS [Metric],
    COUNT(*) AS [Count]
FROM ExcelSerials

UNION ALL

SELECT 
    'Excel Unique Serial Numbers' AS [Metric],
    COUNT(DISTINCT serialNo) AS [Count]
FROM ExcelSerials

UNION ALL

SELECT 
    'Query Total (with duplicates)' AS [Metric],
    COUNT(*) AS [Count]
FROM QuerySerials

UNION ALL

SELECT 
    'Query Unique Serial Numbers' AS [Metric],
    COUNT(DISTINCT serialNo) AS [Count]
FROM QuerySerials

UNION ALL

SELECT 
    'In Excel but NOT in Query (Unique)' AS [Metric],
    COUNT(DISTINCT e.serialNo) AS [Count]
FROM ExcelSerials e
LEFT JOIN QuerySerials q ON e.serialNo = q.serialNo
WHERE q.serialNo IS NULL

UNION ALL

SELECT 
    'In Query but NOT in Excel (Unique)' AS [Metric],
    COUNT(DISTINCT q.serialNo) AS [Count]
FROM QuerySerials q
LEFT JOIN ExcelSerials e ON q.serialNo = e.serialNo
WHERE e.serialNo IS NULL;

