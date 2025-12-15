-- ================================================
-- DELL OBA REVIEW SUMMARY BY OPERATOR AND DATE
-- ================================================
-- Summary showing how many OBA reviews each operator did each day
-- ================================================

WITH FicoreMemphis AS (
    SELECT
        fic2.SerialNumber,
        fic2.Result,
        fic2.StartTime,
        ROW_NUMBER() OVER (
            PARTITION BY fic2.SerialNumber
            ORDER BY fic2.StartTime DESC
        ) AS rn
    FROM redw.tia.DataWipeResult AS fic2
    WHERE fic2.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
      AND fic2.TestArea = 'MEMPHIS' COLLATE Latin1_General_100_CI_AS
      AND fic2.MachineName = 'FICORE' COLLATE Latin1_General_100_CI_AS
      AND fic2.StartTime >= '2025-10-20 00:00:00.000000'
      AND fic2.StartTime < '2025-10-25 00:00:00.000000'
),
FicoreFICORE AS (
    SELECT
        fic.SerialNumber,
        fic.Result,
        fic.StartTime,
        ROW_NUMBER() OVER (
            PARTITION BY fic.SerialNumber
            ORDER BY fic.StartTime DESC
        ) AS rn
    FROM redw.tia.DataWipeResult AS fic
    WHERE fic.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
      AND fic.TestArea = 'FICORE' COLLATE Latin1_General_100_CI_AS
      AND fic.StartTime >= '2025-10-20 00:00:00.000000'
      AND fic.StartTime < '2025-10-25 00:00:00.000000'
),
Spectrum AS (
    SELECT
        spc.SerialNumber,
        spc.Result,
        spc.StartTime,
        ROW_NUMBER() OVER (
            PARTITION BY spc.SerialNumber
            ORDER BY spc.StartTime DESC
        ) AS rn
    FROM redw.tia.DataWipeResult AS spc
    WHERE spc.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
      AND spc.TestArea = 'Memphis' COLLATE Latin1_General_100_CI_AS
      AND spc.MachineName = 'SPECTRUMX' COLLATE Latin1_General_100_CI_AS
      AND spc.StartTime >= '2025-10-20 00:00:00.000000'
      AND spc.StartTime < '2025-10-25 00:00:00.000000'
),
BaseData AS (
    SELECT
        ps.ProgramID,
        ps.PartNo,
        ps.SerialNo,
        rcv.ReceivedDate,
        prt.Description,
        CAST(NULL AS varchar(20))     AS [Warranty Status],
        COALESCE(ficMem.Result, ficCore.Result) AS [Ficore Results],
        spc.Result                    AS [Spectrum Results],
        u.Username                    AS [Auditor Name],
        oba.CreateDate                AS [OBA Date],
        CASE WHEN oba.Value = 'PASS' THEN 'Pass' ELSE 'Fail' END AS [OBA Results],
        CASE WHEN oba.Value = 'PASS' THEN NULL ELSE oba.Value END AS [If Fail, Reason]
    FROM Plus.pls.PartSerial AS ps
    JOIN Plus.pls.CodeStatus AS st
      ON st.ID = ps.StatusID
    JOIN Plus.pls.PartNo AS prt
      ON prt.PartNo = ps.PartNo
    JOIN Plus.pls.PartSerialAttribute AS oba
      ON oba.PartSerialID = ps.ID
     AND oba.AttributeID  = 1394
    JOIN Plus.pls.[User] AS u
      ON u.ID = oba.UserID
    LEFT JOIN FicoreMemphis AS ficMem
      ON ficMem.SerialNumber = ps.SerialNo
     AND ficMem.rn = 1
    LEFT JOIN FicoreFICORE AS ficCore
      ON ficCore.SerialNumber = ps.SerialNo
     AND ficCore.rn = 1
    LEFT JOIN Spectrum AS spc
      ON spc.SerialNumber = ps.SerialNo
     AND spc.rn = 1
    OUTER APPLY (
        SELECT MIN(rec.CreateDate) AS ReceivedDate
        FROM Plus.pls.PartTransaction AS rec
        WHERE rec.ProgramID         = ps.ProgramID
          AND rec.PartNo            = ps.PartNo
          AND rec.SerialNo          = ps.SerialNo
          AND rec.PartTransactionID = 1
          AND rec.OrderHeaderID     = ps.ROHeaderID
          AND rec.CreateDate >= '2025-10-20 00:00:00.000000'
          AND rec.CreateDate < '2025-10-25 00:00:00.000000'
    ) AS rcv
    WHERE ps.ProgramID = 10053
      AND oba.CreateDate >= '2025-10-20 00:00:00.000000'
      AND oba.CreateDate < '2025-10-25 00:00:00.000000'
)
SELECT
    [Auditor Name] AS Operator,
    CAST([OBA Date] AS DATE) AS ReviewDate,
    COUNT(*) AS TotalReviews,
    SUM(CASE WHEN [OBA Results] = 'Pass' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN [OBA Results] = 'Fail' THEN 1 ELSE 0 END) AS FailCount,
    CAST(SUM(CASE WHEN [OBA Results] = 'Pass' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS PassRate
FROM BaseData
WHERE [Auditor Name] IS NOT NULL
GROUP BY [Auditor Name], CAST([OBA Date] AS DATE)
ORDER BY [Auditor Name], ReviewDate;

-- ================================================
-- SIMPLER VERSION WITHOUT TEST DATA (FASTER)
-- ================================================

WITH BaseData AS (
    SELECT
        u.Username AS AuditorName,
        oba.CreateDate AS OBADate,
        CASE WHEN oba.Value = 'PASS' THEN 'Pass' ELSE 'Fail' END AS OBAResult,
        CASE WHEN oba.Value = 'PASS' THEN NULL ELSE oba.Value END AS FailReason
    FROM Plus.pls.PartSerial AS ps
    JOIN Plus.pls.PartSerialAttribute AS oba
      ON oba.PartSerialID = ps.ID
     AND oba.AttributeID  = 1394
    JOIN Plus.pls.[User] AS u
      ON u.ID = oba.UserID
    WHERE ps.ProgramID = 10053
      AND oba.CreateDate >= '2025-10-20 00:00:00.000000'
      AND oba.CreateDate < '2025-10-25 00:00:00.000000'
)
SELECT
    AuditorName AS Operator,
    CAST(OBADate AS DATE) AS ReviewDate,
    COUNT(*) AS TotalReviews,
    SUM(CASE WHEN OBAResult = 'Pass' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN OBAResult = 'Fail' THEN 1 ELSE 0 END) AS FailCount,
    CAST(SUM(CASE WHEN OBAResult = 'Pass' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS PassRate
FROM BaseData
WHERE AuditorName IS NOT NULL
GROUP BY AuditorName, CAST(OBADate AS DATE)
ORDER BY AuditorName, ReviewDate;
