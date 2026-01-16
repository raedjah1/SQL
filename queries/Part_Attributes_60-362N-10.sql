-- Get all attributes for part number 60-362N-10
SELECT 
    pna.PartNo,
    ca.AttributeName,
    pna.Value AS AttributeValue,
    pna.ProgramID,
    pna.CreateDate,
    pna.LastActivityDate,
    u.Username AS CreatedBy
FROM Plus.pls.PartNoAttribute pna
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
LEFT JOIN Plus.pls.[User] u ON u.ID = pna.UserID
WHERE pna.PartNo = '60-362N-10'
ORDER BY ca.AttributeName;

