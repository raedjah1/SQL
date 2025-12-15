-- ================================================
-- DELL OBA REVIEW WITH OCTOBER 20-24, 2025 FILTER
-- ================================================

CREATE OR ALTER VIEW [rpt].[DellOBAReview] AS
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
)
SELECT
    ps.ProgramID,
    ps.PartNo  AS [Part No],
    ps.SerialNo AS [Serial No (Service Tag)],
    rcv.ReceivedDate              AS [Received Date],
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
  AND oba.CreateDate < '2025-10-25 00:00:00.000000';


















