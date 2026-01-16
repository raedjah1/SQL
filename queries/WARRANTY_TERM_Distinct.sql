-- All distinct WARRANTY_TERM attribute values for ADT (ProgramID 10068)

SELECT DISTINCT
    pna.Value AS WarrantyTerm
FROM Plus.pls.PartNoAttribute AS pna
INNER JOIN Plus.pls.CodeAttribute AS ca
    ON ca.ID = pna.AttributeID
WHERE pna.ProgramID = 10068
  AND ca.AttributeName = 'WARRANTY_TERM'
  AND pna.Value IS NOT NULL
ORDER BY pna.Value;

