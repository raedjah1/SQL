-- ============================================================================
-- INVESTIGATION: Why Excel shows "Resolved by Quincy" but Query shows "Encountered New Error"
-- ============================================================================
-- For the 31 serials that Excel has as "Resolved" but Query has as "Encountered New Error"
-- Check if they have "Msg Sent Ok" messages that might explain Excel's logic
-- ============================================================================

WITH ExcelResolvedSerials AS (
    SELECT DISTINCT serialNo
    FROM (VALUES
        ('14758F4'), ('1CPWFF4'), ('1MFX5F4'), ('27VV3D4'), ('2HN3284'), ('2WWT2C4'),
        ('4STXSB4'), ('508YSB4'), ('5NCYSB4'), ('6KVYSB4'), ('6Z8YSB4'), ('77NTLD4'),
        ('7SMXSB4'), ('7WQM564'), ('83D1Y84'), ('98BYSB4'), ('BQY1CB4'), ('CB74FY3'),
        ('CKHXSB4'), ('D0LXSB4'), ('DG84WF4'), ('FL98MD4'), ('G18YSB4'), ('G2L9724'),
        ('G4PVMD4'), ('GQHXSB4'), ('GVKXSB4'), ('H2HTKB4'), ('J9TYSB4'), ('JWFXXC4'),
        ('JXWT2C4')
    ) AS ExcelData(serialNo)
)

SELECT 
    e.serialNo,
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
    -- Get "Msg Sent Ok" timestamp
    (SELECT TOP 1 obm.Insert_Date 
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Customer_order_No = r.serialNo
       AND obm.Insert_Date > r.createDate
       AND LOWER(obm.Message) LIKE '%msg sent ok%'
     ORDER BY obm.Insert_Date ASC) AS [MsgSentOkTime],
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
    END AS [WhichCameFirst]
FROM ExcelResolvedSerials e
INNER JOIN ClarityWarehouse.agentlogs.repair r
    ON r.serialNo = e.serialNo
    AND r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 1
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
ORDER BY e.serialNo, r.createDate;

