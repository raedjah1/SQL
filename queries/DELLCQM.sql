SELECT
    b.ProgramID                              AS [ProgramID],
    b.PartNo                                 AS [Part No.],
    b.SerialNo                               AS [Serial No. (Service Tag)],
    rcv.ReceivedDate                         AS [Received Date],  
    b.Description,
    CAST(NULL AS varchar(20))                AS [Warranty Status],
    COALESCE(ficMem.Result, ficCore.Result)  AS [Ficore Results],
    spc.Result                               AS [Spectrum Results],
    b.AuditorName                            AS [Auditor Name],
    b.CQMDate                                AS [CQM Date],
    b.CQMResult                              AS [CQM Results],
    b.FailReason                             AS [If Fail, Reason],
    b.DispositionCode                        AS [Disposition Code],
    b.ConditionCode                          AS [Condition Code],
    b.LOB                                    AS [LOB],
    -- R2REC_Cosmetic: Map based on Condition Code and DISPOSITION
    CASE 
        WHEN b.ConditionCode = 'FO' THEN 'C9'  -- Sell As New-FGA (Condition Code FO)
        WHEN b.DispositionCode = 'Sell As New-FGA' THEN 'C9'  -- Sell As New-FGA (DISPOSITION)
        WHEN b.DispositionCode IN ('Like New', 'Telesales') THEN 'C6'
        WHEN b.DispositionCode = 'Scratch and Dent' THEN 'C5'
        WHEN b.DispositionCode LIKE '%Mexico%' OR b.DispositionCode LIKE '%Repair%' THEN 'C0'  -- Damaged/Mexico repair (keep as C0 for now per requirements)
        WHEN b.DispositionCode IS NULL THEN 'C0'  -- SNP or no disposition
        ELSE 'C0'  -- Default for unknown dispositions
    END AS [R2REC_Cosmetic],
    -- R2REC_Functionality: Map based on Condition Code and DISPOSITION
    CASE 
        WHEN b.ConditionCode = 'FO' THEN 'F6'  -- Sell As New-FGA (Condition Code FO)
        WHEN b.DispositionCode = 'Sell As New-FGA' THEN 'F6'  -- Sell As New-FGA (DISPOSITION)
        WHEN b.DispositionCode IN ('Like New', 'Telesales') THEN 'F5'
        WHEN b.DispositionCode = 'Scratch and Dent' THEN 'F4'
        WHEN b.DispositionCode LIKE '%Mexico%' OR b.DispositionCode LIKE '%Repair%' THEN 'N/A'  -- Damaged/Mexico repair (keep as N/A for now per requirements)
        WHEN b.DispositionCode IS NULL THEN NULL  -- SNP or no disposition (NULL, not N/A)
        ELSE 'N/A'  -- Default for unknown dispositions
    END AS [R2REC_Functionality]
FROM (
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
        disposition.Value AS DispositionCode,
        condition_code.Value AS ConditionCode,
        psa_lob.Value AS LOB,
        ps.ProgramID
    FROM Plus.pls.PartSerial          AS ps
    JOIN Plus.pls.PartNo              AS prt ON prt.PartNo       = ps.PartNo
    JOIN Plus.pls.PartSerialAttribute AS oba ON oba.PartSerialID  = ps.ID
                                            AND oba.AttributeID   = 1395   -- swap if your CQM attribute is 1394
    JOIN Plus.pls.[User]              AS u   ON u.ID             = oba.UserID
    LEFT JOIN Plus.pls.PartSerialAttribute AS disposition
      ON disposition.PartSerialID = ps.ID
     AND disposition.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'DISPOSITION')
    LEFT JOIN Plus.pls.PartSerialAttribute AS condition_code
      ON condition_code.PartSerialID = ps.ID
     AND condition_code.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'ConditionCode')
    LEFT JOIN Plus.pls.PartSerialAttribute AS psa_lob
      ON psa_lob.PartSerialID = ps.ID
     AND psa_lob.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB')
    WHERE ps.ProgramID = 10053
) AS b
LEFT JOIN (
    SELECT
        SerialNumber,
        Result,
        ROW_NUMBER() OVER (
            PARTITION BY SerialNumber
            ORDER BY EndTime DESC, ID DESC
        ) AS RowNum
    FROM redw.tia.DataWipeResult AS d
    WHERE d.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
      AND d.TestArea = 'MEMPHIS' COLLATE Latin1_General_100_CI_AS
      AND d.MachineName = 'FICORE' COLLATE Latin1_General_100_CI_AS
      AND EXISTS (
          SELECT 1
          FROM Plus.pls.PartSerial ps
          JOIN Plus.pls.PartSerialAttribute oba ON oba.PartSerialID = ps.ID
              AND oba.AttributeID = 1395
          WHERE ps.SerialNo = d.SerialNumber
            AND ps.ProgramID = 10053
      )
) AS ficMem
  ON ficMem.SerialNumber = b.SerialNo
 AND ficMem.RowNum = 1
LEFT JOIN (
    SELECT
        SerialNumber,
        Result,
        ROW_NUMBER() OVER (
            PARTITION BY SerialNumber
            ORDER BY EndTime DESC, ID DESC
        ) AS RowNum
    FROM redw.tia.DataWipeResult AS d
    WHERE d.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
      AND d.TestArea = 'FICORE' COLLATE Latin1_General_100_CI_AS
      AND EXISTS (
          SELECT 1
          FROM Plus.pls.PartSerial ps
          JOIN Plus.pls.PartSerialAttribute oba ON oba.PartSerialID = ps.ID
              AND oba.AttributeID = 1395
          WHERE ps.SerialNo = d.SerialNumber
            AND ps.ProgramID = 10053
      )
) AS ficCore
  ON ficCore.SerialNumber = b.SerialNo
 AND ficCore.RowNum = 1
LEFT JOIN (
    SELECT
        SerialNumber,
        Result,
        ROW_NUMBER() OVER (
            PARTITION BY SerialNumber
            ORDER BY EndTime DESC, ID DESC
        ) AS RowNum
    FROM redw.tia.DataWipeResult AS d
    WHERE d.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
      AND d.TestArea = 'Memphis' COLLATE Latin1_General_100_CI_AS
      AND d.MachineName = 'SPECTRUMX' COLLATE Latin1_General_100_CI_AS
      AND EXISTS (
          SELECT 1
          FROM Plus.pls.PartSerial ps
          JOIN Plus.pls.PartSerialAttribute oba ON oba.PartSerialID = ps.ID
              AND oba.AttributeID = 1395
          WHERE ps.SerialNo = d.SerialNumber
            AND ps.ProgramID = 10053
      )
) AS spc
  ON spc.SerialNumber = b.SerialNo
 AND spc.RowNum = 1
OUTER APPLY (
    SELECT MIN(rec.CreateDate) AS ReceivedDate
    FROM Plus.pls.PartTransaction AS rec
    WHERE rec.ProgramID          = 10053
      AND rec.PartNo             = b.PartNo
      AND rec.SerialNo           = b.SerialNo
      AND rec.PartTransactionID IN (1, 47)
      AND rec.OrderHeaderID      = b.ROHeaderID
) AS rcv;