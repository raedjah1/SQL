-- Show all unique Warranty Status values in the database
-- Simple list of what values actually exist

SELECT DISTINCT
    pna.Value AS WarrantyStatus,
    'PartNoAttribute' AS Source,
    COUNT(*) AS Count
FROM Plus.pls.PartNoAttribute pna
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
WHERE ca.AttributeName = 'WARRANTY_STATUS'
  AND pna.ProgramID IN (10068, 10072)
GROUP BY pna.Value

UNION ALL

SELECT DISTINCT
    psa.Value AS WarrantyStatus,
    'PartSerialAttribute' AS Source,
    COUNT(*) AS Count
FROM Plus.pls.PartSerialAttribute psa
INNER JOIN Plus.pls.PartSerial ps ON ps.ID = psa.PartSerialID
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
WHERE ca.AttributeName = 'WARRANTY_STATUS'
  AND ps.ProgramID IN (10068, 10072)
GROUP BY psa.Value

ORDER BY Source, WarrantyStatus;



