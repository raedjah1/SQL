-- =====================================================
-- PART NUMBER ATTRIBUTES FOR GD00Z-8-ADT
-- =====================================================
-- Get all attributes for part number GD00Z-8-ADT from PartNoAttribute table

-- SIMPLE VERSION: Get all attributes with attribute names
SELECT 
    pna.PartNo,
    pna.AttributeID,
    ca.AttributeName,
    pna.Value as AttributeValue,
    pna.ProgramID,
    pna.CreateDate as AttributeCreatedDate,
    pna.LastActivityDate as AttributeLastUpdated
FROM Plus.pls.PartNoAttribute pna
    LEFT JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
WHERE pna.PartNo = 'GD00Z-8-ADT'
ORDER BY ca.AttributeName;

-- ALTERNATIVE: If you need to see all programs or just want the raw data
SELECT 
    pna.PartNo,
    pna.AttributeID,
    ca.AttributeName,
    pna.Value as AttributeValue,
    pna.ProgramID,
    pna.CreateDate as AttributeCreatedDate,
    pna.LastActivityDate as AttributeLastUpdated
FROM Plus.pls.PartNoAttribute pna
    LEFT JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
WHERE pna.PartNo = 'GD00Z-8-ADT'
ORDER BY pna.ProgramID, ca.AttributeName;

