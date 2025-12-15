-- ================================================
-- CQM REVIEW SUMMARY BY OPERATOR AND DATE
-- ================================================
-- Summary showing how many reviews each operator did each day
-- ================================================

WITH BaseData AS (
    SELECT
        ps.ID,
        ps.PartNo,
        ps.SerialNo,
        ps.ROHeaderID,
        prt.Description,
        u.Username           AS AuditorName,
        oba.CreateDate       AS CQMDate,
        CASE WHEN oba.Value = 'PASS' THEN 'Pass' ELSE 'Fail' END AS CQMResult,
        CASE WHEN oba.Value = 'PASS' THEN NULL ELSE oba.Value END AS FailReason,
        ps.ProgramID
    FROM Plus.pls.PartSerial          AS ps
    JOIN Plus.pls.PartNo              AS prt ON prt.PartNo       = ps.PartNo
    JOIN Plus.pls.PartSerialAttribute AS oba ON oba.PartSerialID  = ps.ID
                                            AND oba.AttributeID   = 1395
    JOIN Plus.pls.[User]              AS u   ON u.ID             = oba.UserID
    WHERE ps.ProgramID = 10053
      AND oba.CreateDate >= '2025-10-20 00:00:00.000000'
      AND oba.CreateDate < '2025-10-25 00:00:00.000000'
),
AllTestResults AS (
    SELECT
        d.SerialNumber,
        d.Program,
        d.TestArea,
        d.MachineName,
        d.Result,
        d.StartTime,
        d.ID
    FROM redw.tia.DataWipeResult AS d
    JOIN BaseData                 AS b ON b.SerialNo = d.SerialNumber
    WHERE d.Program = 'DELL_MEM'
      AND d.StartTime >= '2025-10-20 00:00:00.000000'
      AND d.StartTime < '2025-10-25 00:00:00.000000'
),
RankedResults AS (
    SELECT
        SerialNumber,
        Result,
        TestArea,
        MachineName,
        ROW_NUMBER() OVER (
            PARTITION BY SerialNumber, TestArea, MachineName
            ORDER BY StartTime DESC, ID DESC
        ) AS RowNum
    FROM AllTestResults
),
FullResults AS (
    SELECT
        b.ProgramID,
        b.PartNo,
        b.SerialNo,
        rcv.ReceivedDate,
        b.Description,
        CAST(NULL AS varchar(20))                AS [Warranty Status],
        COALESCE(ficMem.Result, ficCore.Result)  AS [Ficore Results],
        spc.Result,
        b.AuditorName                            AS [Auditor Name],
        b.CQMDate                                AS [CQM Date],
        b.CQMResult                              AS [CQM Results],
        b.FailReason                             AS [If Fail, Reason]
    FROM BaseData AS b
    LEFT JOIN RankedResults AS ficMem
      ON ficMem.SerialNumber = b.SerialNo
     AND ficMem.TestArea     = 'MEMPHIS' COLLATE Latin1_General_100_CI_AS
     AND ficMem.MachineName  = 'FICORE' COLLATE Latin1_General_100_CI_AS
     AND ficMem.RowNum       = 1
    LEFT JOIN RankedResults AS ficCore
      ON ficCore.SerialNumber = b.SerialNo
     AND ficCore.TestArea     = 'FICORE' COLLATE Latin1_General_100_CI_AS
     AND ficCore.RowNum       = 1
    LEFT JOIN RankedResults AS spc
      ON spc.SerialNumber = b.SerialNo
     AND spc.TestArea     = 'MEMPHIS' COLLATE Latin1_General_100_CI_AS
     AND spc.MachineName  = 'SPECTRUMX' COLLATE Latin1_General_100_CI_AS
     AND spc.RowNum       = 1
    OUTER APPLY (
        SELECT MIN(rec.CreateDate) AS ReceivedDate
        FROM Plus.pls.PartTransaction AS rec
        WHERE rec.ProgramID          = 10053
          AND rec.PartNo             = b.PartNo
          AND rec.SerialNo           = b.SerialNo
          AND rec.PartTransactionID IN (1, 47)
          AND rec.OrderHeaderID      = b.ROHeaderID
          AND rec.CreateDate >= '2025-10-20 00:00:00.000000'
          AND rec.CreateDate < '2025-10-25 00:00:00.000000'
    ) AS rcv
)
SELECT
    [Auditor Name] AS Operator,
    CAST([CQM Date] AS DATE) AS ReviewDate,
    COUNT(*) AS TotalReviews,
    SUM(CASE WHEN [CQM Results] = 'Pass' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN [CQM Results] = 'Fail' THEN 1 ELSE 0 END) AS FailCount,
    CAST(SUM(CASE WHEN [CQM Results] = 'Pass' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS PassRate
FROM FullResults
WHERE [Auditor Name] IS NOT NULL
GROUP BY [Auditor Name], CAST([CQM Date] AS DATE)
ORDER BY [Auditor Name], ReviewDate;

-- ================================================
-- ALTERNATIVE: SIMPLE TOTAL SUMMARY
-- ================================================

WITH BaseData AS (
    SELECT
        ps.ID,
        ps.PartNo,
        ps.SerialNo,
        ps.ROHeaderID,
        prt.Description,
        u.Username           AS AuditorName,
        oba.CreateDate       AS CQMDate,
        CASE WHEN oba.Value = 'PASS' THEN 'Pass' ELSE 'Fail' END AS CQMResult,
        CASE WHEN oba.Value = 'PASS' THEN NULL ELSE oba.Value END AS FailReason,
        ps.ProgramID
    FROM Plus.pls.PartSerial          AS ps
    JOIN Plus.pls.PartNo              AS prt ON prt.PartNo       = ps.PartNo
    JOIN Plus.pls.PartSerialAttribute AS oba ON oba.PartSerialID  = ps.ID
                                            AND oba.AttributeID   = 1395
    JOIN Plus.pls.[User]              AS u   ON u.ID             = oba.UserID
    WHERE ps.ProgramID = 10053
      AND oba.CreateDate >= '2025-10-20 00:00:00.000000'
      AND oba.CreateDate < '2025-10-25 00:00:00.000000'
)
SELECT
    AuditorName AS Operator,
    CAST(CQMDate AS DATE) AS ReviewDate,
    COUNT(*) AS TotalReviews,
    SUM(CASE WHEN CQMResult = 'Pass' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN CQMResult = 'Fail' THEN 1 ELSE 0 END) AS FailCount,
    CAST(SUM(CASE WHEN CQMResult = 'Pass' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS PassRate
FROM BaseData
WHERE AuditorName IS NOT NULL
GROUP BY AuditorName, CAST(CQMDate AS DATE)
ORDER BY AuditorName, ReviewDate;


















