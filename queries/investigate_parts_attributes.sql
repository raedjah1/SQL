-- Investigative Query: All PartNo Attributes and PartSerial Attributes
-- For all PartNos and SerialNos from the parts_from_trowndown query

-- Get base PartNos and SerialNos from the transaction query
WITH BaseParts AS (
    SELECT DISTINCT
        pt.PartNo,
        pt.SerialNo,
        pt.ProgramID
    FROM Plus.pls.PartTransaction pt
    WHERE UPPER(pt.Location) LIKE '%TORNDOWN%'
        AND UPPER(pt.ToLocation) = 'RESERVE.10053.0.0.0'
        AND pt.CustomerReference LIKE 'SCR%'
),
PartSerialIDs AS (
    SELECT DISTINCT
        bp.PartNo,
        bp.SerialNo,
        ps.ID AS PartSerialID
    FROM BaseParts bp
    LEFT JOIN Plus.pls.PartSerial ps ON ps.SerialNo = bp.SerialNo 
        AND ps.ProgramID = bp.ProgramID
)
-- Part 1: All PartNo Attributes
SELECT 
    'PartNoAttribute' AS AttributeType,
    bp.PartNo,
    NULL AS SerialNo,
    ca.AttributeName,
    pna.Value AS AttributeValue,
    pna.CreateDate AS AttributeCreateDate,
    pna.LastActivityDate AS AttributeLastActivityDate,
    u.Username AS AttributeUser
FROM BaseParts bp
INNER JOIN Plus.pls.PartNoAttribute pna ON pna.PartNo = bp.PartNo
    AND pna.ProgramID = bp.ProgramID
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
LEFT JOIN Plus.pls.[User] u ON u.ID = pna.UserID

UNION ALL

-- Part 2: All PartSerial Attributes
SELECT 
    'PartSerialAttribute' AS AttributeType,
    bp.PartNo,
    bp.SerialNo,
    ca.AttributeName,
    psa.Value AS AttributeValue,
    psa.CreateDate AS AttributeCreateDate,
    psa.LastActivityDate AS AttributeLastActivityDate,
    u.Username AS AttributeUser
FROM BaseParts bp
INNER JOIN PartSerialIDs psi ON psi.PartNo = bp.PartNo 
    AND psi.SerialNo = bp.SerialNo
INNER JOIN Plus.pls.PartSerialAttribute psa ON psa.PartSerialID = psi.PartSerialID
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
LEFT JOIN Plus.pls.[User] u ON u.ID = psa.UserID

ORDER BY AttributeType, PartNo, SerialNo, AttributeName;

