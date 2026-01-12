-- Find all distinct DISPOSITION values for all OBA records
-- Uses same base query logic as DELLOBA.sql

SELECT DISTINCT
    psa_disposition.Value AS DISPOSITION,
    COUNT(*) AS Count
FROM Plus.pls.PartSerial AS ps
JOIN Plus.pls.CodeStatus AS st
  ON st.ID = ps.StatusID
JOIN Plus.pls.PartNo AS prt
  ON prt.PartNo = ps.PartNo
JOIN Plus.pls.PartSerialAttribute AS oba
  ON oba.PartSerialID = ps.ID
 AND oba.AttributeID  = 1394  -- OBA attribute
LEFT JOIN Plus.pls.PartSerialAttribute AS psa_disposition
  ON psa_disposition.PartSerialID = ps.ID
 AND psa_disposition.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'DISPOSITION')
WHERE ps.ProgramID = 10053
  AND psa_disposition.Value IS NOT NULL
GROUP BY psa_disposition.Value
ORDER BY psa_disposition.Value;

