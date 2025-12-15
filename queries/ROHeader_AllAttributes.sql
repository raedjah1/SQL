-- Show all ROHeader attributes for Program 10068
-- This query shows all base columns plus all attribute values

SELECT 
    -- Base ROHeader columns
    rh.ID,
    rh.CustomerReference,
    rh.ThirdPartyReference,
    rh.ProgramID,
    rh.StatusID,
    cs.Description AS StatusDescription,
    rh.BizTalkID,
    rh.OrderTypeID,
    rh.AddressID,
    rh.UserID,
    u.Username AS CreatedByUser,
    rh.CreateDate,
    rh.LastActivityDate,
    
    -- All ROHeader attributes (pivoted)
    MAX(CASE WHEN ca.AttributeName = 'SHIPFROMORG' THEN roa.Value END) AS SHIPFROMORG,
    MAX(CASE WHEN ca.AttributeName = 'BRANCHES' THEN roa.Value END) AS BRANCHES,
    -- Add more attributes as needed - this will show all available attributes
    
    -- Show all attribute names and values as a comma-separated list
    STRING_AGG(ca.AttributeName + '=' + roa.Value, ', ') AS AllAttributes

FROM Plus.pls.ROHeader rh
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = rh.StatusID
LEFT JOIN Plus.pls.[User] u ON u.ID = rh.UserID
LEFT JOIN Plus.pls.ROHeaderAttribute roa ON roa.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.CodeAttribute ca ON ca.ID = roa.AttributeID
WHERE rh.ProgramID = 10068
GROUP BY 
    rh.ID,
    rh.CustomerReference,
    rh.ThirdPartyReference,
    rh.ProgramID,
    rh.StatusID,
    cs.Description,
    rh.BizTalkID,
    rh.OrderTypeID,
    rh.AddressID,
    rh.UserID,
    u.Username,
    rh.CreateDate,
    rh.LastActivityDate
ORDER BY rh.CreateDate DESC;



