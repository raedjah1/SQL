-- Inventory Query for ProgramID 10053 using base tables (not views)
-- Combines PartQty (non-serialized) and PartSerial (serialized) inventory
-- Base tables used:
--   - Plus.pls.PartQty (quantities)
--   - Plus.pls.PartSerial (serialized units)
--   - Plus.pls.PartLocation (location details)
--   - Plus.pls.CodeStatus (status descriptions)
--   - Plus.pls.CodeLocationGroup (location group descriptions)
--   - Plus.pls.CodeConfiguration (configuration descriptions)
--   - Plus.pls.PartNo (part descriptions)
--   - Plus.pls.PartNoAttribute (commodity attributes)
--   - Plus.pls.CodeAttribute (attribute definitions)
--   - Plus.pls.[User] (usernames)

-- PartQty records (non-serialized inventory)
SELECT 
    pq.PartNo,
    pq.AvailableQty,
    pl.LocationNo AS Location,
    NULL AS SerialNumber,  -- PartQty doesn't have serial numbers
    cc.Description AS Configuration,
    pna_primary.Value AS PrimaryCommodity,
    pna_secondary.Value AS SecondaryCommodity,
    pn.Description,
    clg.Description AS LocationGroup,
    pl.ID AS LocationID,
    pl.Warehouse,
    pl.Bin,
    u.Username,
    pq.LastActivityDate,
    pq.CreateDate,
    DATEDIFF(DAY, pq.CreateDate, GETDATE()) AS Aging
FROM Plus.pls.PartQty pq
INNER JOIN Plus.pls.PartLocation pl ON pl.ID = pq.LocationID
INNER JOIN Plus.pls.CodeStatus cs ON cs.ID = pl.StatusID
INNER JOIN Plus.pls.CodeLocationGroup clg ON clg.ID = pl.LocationGroupID
LEFT JOIN Plus.pls.CodeConfiguration cc ON cc.ID = pq.ConfigurationID
LEFT JOIN Plus.pls.PartNo pn ON pn.PartNo = pq.PartNo
LEFT JOIN Plus.pls.[User] u ON u.ID = pq.UserID
-- PrimaryCommodity attribute
LEFT JOIN Plus.pls.PartNoAttribute pna_primary ON pna_primary.PartNo = pq.PartNo
    AND pna_primary.ProgramID = 10053
    AND pna_primary.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'PrimaryCommodity')
-- SecondaryCommodity attribute
LEFT JOIN Plus.pls.PartNoAttribute pna_secondary ON pna_secondary.PartNo = pq.PartNo
    AND pna_secondary.ProgramID = 10053
    AND pna_secondary.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'SecondaryCommodity')
WHERE pq.ProgramID = 10053
  AND pq.AvailableQty > 0

UNION ALL

-- PartSerial records (serialized inventory)
SELECT 
    ps.PartNo,
    1 AS AvailableQty,  -- Each serial is 1 unit
    pl.LocationNo AS Location,
    ps.SerialNo AS SerialNumber,
    cc.Description AS Configuration,
    pna_primary.Value AS PrimaryCommodity,
    pna_secondary.Value AS SecondaryCommodity,
    pn.Description,
    clg.Description AS LocationGroup,
    pl.ID AS LocationID,
    pl.Warehouse,
    pl.Bin,
    u.Username,
    ps.LastActivityDate,
    ps.CreateDate,
    DATEDIFF(DAY, ps.CreateDate, GETDATE()) AS Aging
FROM Plus.pls.PartSerial ps
INNER JOIN Plus.pls.PartLocation pl ON pl.ID = ps.LocationID
INNER JOIN Plus.pls.CodeStatus cs ON cs.ID = ps.StatusID
INNER JOIN Plus.pls.CodeLocationGroup clg ON clg.ID = pl.LocationGroupID
LEFT JOIN Plus.pls.CodeConfiguration cc ON cc.ID = ps.ConfigurationID
LEFT JOIN Plus.pls.PartNo pn ON pn.PartNo = ps.PartNo
LEFT JOIN Plus.pls.[User] u ON u.ID = ps.UserID
-- PrimaryCommodity attribute
LEFT JOIN Plus.pls.PartNoAttribute pna_primary ON pna_primary.PartNo = ps.PartNo
    AND pna_primary.ProgramID = 10053
    AND pna_primary.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'PrimaryCommodity')
-- SecondaryCommodity attribute
LEFT JOIN Plus.pls.PartNoAttribute pna_secondary ON pna_secondary.PartNo = ps.PartNo
    AND pna_secondary.ProgramID = 10053
    AND pna_secondary.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'SecondaryCommodity')
WHERE ps.ProgramID = 10053

ORDER BY PartNo, Location, SerialNumber;

