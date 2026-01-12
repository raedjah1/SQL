-- Find where R2REC_Cosmetic and R2REC_Functionality are stored
-- Search all attribute tables for these attribute names or C0 values

-- 1. Check CodeAttribute table for R2REC attribute names
SELECT 
    'CodeAttribute' AS TableName,
    ca.ID AS AttributeID,
    ca.AttributeName,
    NULL AS Value,
    NULL AS SerialNo
FROM Plus.pls.CodeAttribute ca
WHERE ca.AttributeName LIKE '%R2REC%'
   OR ca.AttributeName LIKE '%Cosmetic%'
   OR ca.AttributeName LIKE '%Functionality%'

UNION ALL

-- 2. Check PartSerialAttribute for R2REC attributes
SELECT 
    'PartSerialAttribute' AS TableName,
    psa.AttributeID,
    ca.AttributeName,
    psa.Value,
    ps.SerialNo
FROM Plus.pls.PartSerialAttribute psa
JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
JOIN Plus.pls.PartSerial ps ON ps.ID = psa.PartSerialID
WHERE (ca.AttributeName LIKE '%R2REC%'
   OR ca.AttributeName LIKE '%Cosmetic%'
   OR ca.AttributeName LIKE '%Functionality%'
   OR psa.Value = 'C0')
  AND ps.ProgramID = 10053
  AND ps.SerialNo = '1Y64D44'  -- Test with known serial

UNION ALL

-- 3. Check ROUnitAttribute for R2REC attributes
SELECT 
    'ROUnitAttribute' AS TableName,
    rua.AttributeID,
    ca.AttributeName,
    rua.Value,
    ru.SerialNo
FROM Plus.pls.ROUnitAttribute rua
JOIN Plus.pls.CodeAttribute ca ON ca.ID = rua.AttributeID
JOIN Plus.pls.ROUnit ru ON ru.ID = rua.ROUnitID
WHERE (ca.AttributeName LIKE '%R2REC%'
   OR ca.AttributeName LIKE '%Cosmetic%'
   OR ca.AttributeName LIKE '%Functionality%'
   OR rua.Value = 'C0')
  AND ru.SerialNo = '1Y64D44'  -- Test with known serial

UNION ALL

-- 4. Check ROHeaderAttribute for R2REC attributes
SELECT 
    'ROHeaderAttribute' AS TableName,
    roa.AttributeID,
    ca.AttributeName,
    roa.Value,
    NULL AS SerialNo
FROM Plus.pls.ROHeaderAttribute roa
JOIN Plus.pls.CodeAttribute ca ON ca.ID = roa.AttributeID
JOIN Plus.pls.ROHeader rh ON rh.ID = roa.ROHeaderID
WHERE (ca.AttributeName LIKE '%R2REC%'
   OR ca.AttributeName LIKE '%Cosmetic%'
   OR ca.AttributeName LIKE '%Functionality%'
   OR roa.Value = 'C0')
  AND rh.ProgramID = 10053
  AND EXISTS (
      SELECT 1 
      FROM Plus.pls.ROUnit ru 
      JOIN Plus.pls.ROLine rl ON rl.ID = ru.ROLineID
      WHERE rl.ROHeaderID = rh.ID 
        AND ru.SerialNo = '1Y64D44'
  )

ORDER BY TableName, AttributeName;

