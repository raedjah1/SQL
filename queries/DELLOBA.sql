
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
    CASE WHEN oba.Value = 'PASS' THEN NULL ELSE oba.Value END AS [If Fail, Reason],
    disposition.Value AS [Disposition Code],
    condition_code.Value AS [Condition Code],
    psa_lob.Value AS [LOB],
    -- R2REC_Cosmetic: Map based on Condition Code and DISPOSITION
    CASE 
        WHEN condition_code.Value = 'FO' THEN 'C9'  -- Sell As New-FGA (Condition Code FO)
        WHEN disposition.Value = 'Sell As New-FGA' THEN 'C9'  -- Sell As New-FGA (DISPOSITION)
        WHEN disposition.Value IN ('Like New', 'Telesales') THEN 'C6'
        WHEN disposition.Value = 'Scratch and Dent' THEN 'C5'
        WHEN disposition.Value LIKE '%Mexico%' OR disposition.Value LIKE '%Repair%' THEN 'C0'  -- Damaged/Mexico repair (keep as C0 for now per requirements)
        WHEN disposition.Value IS NULL THEN 'C0'  -- SNP or no disposition
        ELSE 'C0'  -- Default for unknown dispositions
    END AS [R2REC_Cosmetic],
    -- R2REC_Functionality: Map based on Condition Code and DISPOSITION
    CASE 
        WHEN condition_code.Value = 'FO' THEN 'F6'  -- Sell As New-FGA (Condition Code FO)
        WHEN disposition.Value = 'Sell As New-FGA' THEN 'F6'  -- Sell As New-FGA (DISPOSITION)
        WHEN disposition.Value IN ('Like New', 'Telesales') THEN 'F5'
        WHEN disposition.Value = 'Scratch and Dent' THEN 'F4'
        WHEN disposition.Value LIKE '%Mexico%' OR disposition.Value LIKE '%Repair%' THEN 'N/A'  -- Damaged/Mexico repair (keep as N/A for now per requirements)
        WHEN disposition.Value IS NULL THEN NULL  -- SNP or no disposition (NULL, not N/A)
        ELSE 'N/A'  -- Default for unknown dispositions
    END AS [R2REC_Functionality]
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
LEFT JOIN Plus.pls.PartSerialAttribute AS disposition
  ON disposition.PartSerialID = ps.ID
 AND disposition.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'DISPOSITION')
LEFT JOIN Plus.pls.PartSerialAttribute AS condition_code
  ON condition_code.PartSerialID = ps.ID
 AND condition_code.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'ConditionCode')
LEFT JOIN Plus.pls.PartSerialAttribute AS psa_lob
  ON psa_lob.PartSerialID = ps.ID
 AND psa_lob.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB')
LEFT JOIN (
    SELECT
        fic2.SerialNumber,
        fic2.Result,
        ROW_NUMBER() OVER (
            PARTITION BY fic2.SerialNumber
            ORDER BY fic2.EndTime DESC, fic2.ID DESC
        ) AS rn
    FROM redw.tia.DataWipeResult AS fic2
    WHERE fic2.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
      AND fic2.TestArea = 'MEMPHIS' COLLATE Latin1_General_100_CI_AS
      AND fic2.MachineName = 'FICORE' COLLATE Latin1_General_100_CI_AS
) AS ficMem
  ON ficMem.SerialNumber = ps.SerialNo
 AND ficMem.rn = 1
LEFT JOIN (
    SELECT
        fic.SerialNumber,
        fic.Result,
        ROW_NUMBER() OVER (
            PARTITION BY fic.SerialNumber
            ORDER BY fic.EndTime DESC, fic.ID DESC
        ) AS rn
    FROM redw.tia.DataWipeResult AS fic
    WHERE fic.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
      AND fic.TestArea = 'FICORE' COLLATE Latin1_General_100_CI_AS
) AS ficCore
  ON ficCore.SerialNumber = ps.SerialNo
 AND ficCore.rn = 1
LEFT JOIN (
    SELECT
        spc.SerialNumber,
        spc.Result,
        ROW_NUMBER() OVER (
            PARTITION BY spc.SerialNumber
            ORDER BY spc.EndTime DESC, spc.ID DESC
        ) AS rn
    FROM redw.tia.DataWipeResult AS spc
    WHERE spc.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
      AND spc.TestArea = 'Memphis' COLLATE Latin1_General_100_CI_AS
      AND spc.MachineName = 'SPECTRUMX' COLLATE Latin1_General_100_CI_AS
) AS spc
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
) AS rcv
WHERE ps.ProgramID = 10053
