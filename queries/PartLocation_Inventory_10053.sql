-- Inventory Query for ProgramID 10053 using base tables (not views)
-- Uses PartQty as base (like partinventory.sql) and LEFT JOINs PartSerial to get serial numbers
-- Base tables used:
--   - Plus.pls.PartQty (quantities)
--   - Plus.pls.PartSerial (serialized units - for serial numbers only)
--   - Plus.pls.PartLocation (location details)
--   - Plus.pls.CodeStatus (status descriptions)
--   - Plus.pls.CodeLocationGroup (location group descriptions)
--   - Plus.pls.CodeConfiguration (configuration descriptions)
--   - Plus.pls.PartNo (part descriptions)
--   - Plus.pls.CodeCommodity (commodity descriptions)
--   - Plus.pls.[User] (usernames)

SELECT 
    pq.PartNo,
    pq.AvailableQty,
    pl.LocationNo AS Location,
    ps.SerialNo AS SerialNumber,  -- Get one serial number from PartSerial if it exists
    cc.Description AS Configuration,
    pcc.Description AS PrimaryCommodity,
    scc.Description AS SecondaryCommodity,
    pn.Description,
    CASE WHEN pn.SerialFlag = 0 THEN 'N' ELSE 'Y' END AS SerialFlag,
    clg.Description AS LocationGroup,
    pl.ID AS LocationID,
    pl.Warehouse,
    pl.Bin,
    u.Username,
    pq.LastActivityDate,
    pq.CreateDate,
    DATEDIFF(DAY, pq.LastActivityDate, GETDATE()) AS Aging
FROM Plus.pls.PartQty pq
INNER JOIN Plus.pls.PartLocation pl ON pl.ID = pq.LocationID
INNER JOIN Plus.pls.CodeStatus cs ON cs.ID = pl.StatusID
INNER JOIN Plus.pls.CodeLocationGroup clg ON clg.ID = pl.LocationGroupID
LEFT JOIN Plus.pls.CodeConfiguration cc ON cc.ID = pq.ConfigurationID
INNER JOIN Plus.pls.PartNo pn ON pn.PartNo = pq.PartNo
LEFT JOIN Plus.pls.[User] u ON u.ID = pq.UserID
LEFT JOIN Plus.pls.CodeCommodity pcc ON pcc.ID = pn.PrimaryCommodityID
LEFT JOIN Plus.pls.CodeCommodity scc ON scc.ID = pn.SecondaryCommodityID
-- Get one serial number from PartSerial if it exists (using OUTER APPLY to avoid row multiplication)
OUTER APPLY (
    SELECT TOP 1 ps.SerialNo
    FROM Plus.pls.PartSerial ps
    WHERE ps.PartNo = pq.PartNo 
        AND ps.LocationID = pq.LocationID 
        AND ps.ProgramID = 10053
    ORDER BY ps.SerialNo
) ps
WHERE pq.ProgramID = 10053
  AND pq.AvailableQty > 0

ORDER BY PartNo, Location, SerialNumber;

