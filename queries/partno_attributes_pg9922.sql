-- =====================================================
-- PART NUMBER ATTRIBUTES FOR PG9922
-- =====================================================
-- Get all attributes for part number PG9922 from PartNoAttribute table

-- FIRST: Check what columns exist in CodeAttribute
SELECT TOP 5 * 
FROM Plus.pls.CodeAttribute
ORDER BY ID;

-- SIMPLE VERSION: Just get the attributes for PG9922
SELECT 
    pna.PartNo,
    pna.AttributeID,
    ca.AttributeName,
    pna.Value as AttributeValue,
    pna.CreateDate as AttributeCreatedDate,
    pna.LastActivityDate as AttributeLastUpdated
FROM Plus.pls.PartNoAttribute pna
    LEFT JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
WHERE pna.PartNo = 'PG9922'
ORDER BY ca.AttributeName;

-- ALTERNATIVE: If CodeAttribute doesn't have AttributeName, use just the ID
SELECT 
    pna.PartNo,
    pna.AttributeID,
    pna.Value as AttributeValue,
    pna.CreateDate as AttributeCreatedDate,
    pna.LastActivityDate as AttributeLastUpdated
FROM Plus.pls.PartNoAttribute pna
WHERE pna.PartNo = 'PG9922'
ORDER BY pna.AttributeID;