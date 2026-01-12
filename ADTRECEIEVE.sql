-- Simplified: Only returns SKU (PartNo), CR (ASN), SN (SerialNo), Qty, Program for all time
-- Filtered by PartNo attribute DISPOSITION = 'CR Program' (case insensitive)
WITH Rectransactions AS ( 
     SELECT 
     rec.CustomerReference AS ASN,
     rec.PartNo,
     rec.SerialNo,
     rec.Qty,
     rec.ProgramID

     FROM Plus.pls.PartTransaction AS rec
     JOIN Plus.pls.CodePartTransaction AS rcd ON rcd.ID = rec.PartTransactionID AND rcd.Description = 'RO-RECEIVE'
     JOIN Plus.pls.RODockLog AS dl ON dl.ID = rec.RODockLogID

     WHERE rec.ProgramID IN (10068, 10072) 
      AND rec.PartTransactionID = 1
     )

SELECT 
    rec.PartNo AS SKU,
    rec.ASN AS CR,
    rec.SerialNo AS SN,
    rec.Qty,
    rec.ProgramID AS Program,
    ca.AttributeName AS Disposition,
    pna.Value AS AttributeValue
FROM Rectransactions rec
INNER JOIN Plus.pls.PartNoAttribute pna ON pna.PartNo = rec.PartNo AND pna.ProgramID = rec.ProgramID
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID 
    AND UPPER(LTRIM(RTRIM(ca.AttributeName))) = 'DISPOSITION'
    AND UPPER(LTRIM(RTRIM(pna.Value))) = 'CR PROGRAM'  -- Case insensitive filter
ORDER BY rec.ASN, rec.PartNo, rec.SerialNo;
