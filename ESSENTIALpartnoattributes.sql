-- ESSENTIAL: All PartNo Attributes for a given PartNo (ADT)
-- Usage: set @PartNo (required). Program defaults to ADT (10068).

DECLARE @ProgramID INT = 10068;      -- ADT
DECLARE @PartNo    VARCHAR(50) = ''; -- <-- set this (e.g., '2W-B')

SELECT
    pna.ProgramID,
    pna.PartNo,
    ca.AttributeName,
    pna.Value AS AttributeValue,
    pna.CreateDate,
    pna.LastActivityDate,
    pna.ID AS PartNoAttributeID
FROM Plus.pls.PartNoAttribute AS pna
INNER JOIN Plus.pls.CodeAttribute AS ca
    ON ca.ID = pna.AttributeID
WHERE pna.ProgramID = @ProgramID
  AND pna.PartNo = @PartNo
ORDER BY
    ca.AttributeName,
    pna.LastActivityDate DESC,
    pna.ID DESC;


