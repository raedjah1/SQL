-- =====================================================
-- ALL PART NUMBERS WITH WARRANTY_IDENTIFIER = "Serial Number"
-- =====================================================
-- Find all part numbers that have "Serial Number" as their WARRANTY_IDENTIFIER

SELECT 
    pna.PartNo,
    pna.AttributeID,
    ca.AttributeName,
    pna.Value as AttributeValue,
    pna.ProgramID,
    pna.CreateDate as AttributeCreatedDate,
    pna.LastActivityDate as AttributeLastUpdated
FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
WHERE ca.AttributeName = 'WARRANTY_IDENTIFIER'
    AND pna.Value = 'Serial Number'
ORDER BY pna.PartNo, pna.ProgramID;

