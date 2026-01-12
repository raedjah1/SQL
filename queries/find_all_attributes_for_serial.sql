-- Find ALL attributes for serial number 1Y64D44
-- This will show where R2REC_Cosmetic and R2REC_Functionality might be

-- PartSerialAttribute
SELECT 
    'PartSerialAttribute' AS SourceTable,
    ps.SerialNo,
    ps.PartNo,
    ca.AttributeName,
    psa.Value,
    psa.CreateDate,
    psa.LastActivityDate
FROM Plus.pls.PartSerial ps
JOIN Plus.pls.PartSerialAttribute psa ON psa.PartSerialID = ps.ID
JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
WHERE ps.SerialNo = '1Y64D44'
  AND ps.ProgramID = 10053

UNION ALL

-- PartNoAttribute (for the part number of this serial)
SELECT 
    'PartNoAttribute' AS SourceTable,
    ps.SerialNo,
    pna.PartNo,
    ca.AttributeName,
    pna.Value,
    pna.CreateDate,
    pna.LastActivityDate
FROM Plus.pls.PartSerial ps
JOIN Plus.pls.PartNoAttribute pna ON pna.PartNo = ps.PartNo
JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
WHERE ps.SerialNo = '1Y64D44'
  AND ps.ProgramID = 10053
  AND pna.ProgramID = 10053

UNION ALL

-- ROUnitAttribute
SELECT 
    'ROUnitAttribute' AS SourceTable,
    ru.SerialNo,
    rl.PartNo,
    ca.AttributeName,
    rua.Value,
    rua.CreateDate,
    rua.LastActivityDate
FROM Plus.pls.ROUnit ru
JOIN Plus.pls.ROLine rl ON rl.ID = ru.ROLineID
JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID
JOIN Plus.pls.CodeAttribute ca ON ca.ID = rua.AttributeID
WHERE ru.SerialNo = '1Y64D44'

UNION ALL

-- ROHeaderAttribute (for the RO that contains this serial)
SELECT 
    'ROHeaderAttribute' AS SourceTable,
    ru.SerialNo,
    rl.PartNo,
    ca.AttributeName,
    roa.Value,
    roa.CreateDate,
    roa.LastActivityDate
FROM Plus.pls.ROUnit ru
JOIN Plus.pls.ROLine rl ON rl.ID = ru.ROLineID
JOIN Plus.pls.ROHeader rh ON rh.ID = rl.ROHeaderID
JOIN Plus.pls.ROHeaderAttribute roa ON roa.ROHeaderID = rh.ID
JOIN Plus.pls.CodeAttribute ca ON ca.ID = roa.AttributeID
WHERE ru.SerialNo = '1Y64D44'

ORDER BY SourceTable, AttributeName;

