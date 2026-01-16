-- Simple query to get all PartNo attributes for 5800PIR-RES (ADT program)
-- Shows attribute name, value, and username who created/modified it

SELECT 
    pna.PartNo,
    pna.ProgramID,
    ca.AttributeName,
    pna.Value AS AttributeValue,
    u.Username AS CreatedBy,
    pna.CreateDate AS AttributeCreateDate,
    u_mod.Username AS LastModifiedBy,
    pna.LastActivityDate AS AttributeLastActivityDate
FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    LEFT JOIN Plus.pls.[User] u ON u.ID = pna.UserID
    LEFT JOIN Plus.pls.[User] u_mod ON u_mod.ID = pna.LastActivityUserID
WHERE pna.PartNo = '5800PIR-RES'
    AND pna.ProgramID IN (10068, 10072)  -- ADT program IDs
ORDER BY ca.AttributeName, pna.CreateDate DESC;



