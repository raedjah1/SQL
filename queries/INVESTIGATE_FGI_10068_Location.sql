-- Simple query to see all parts in location FGI.10068.0.0.0
SELECT 
    pq.PartNo,
    pq.AvailableQty,
    pq.ConfigurationID,
    cc.Description AS ConfigurationDescription,
    pq.PalletBoxNo,
    pq.LotNo,
    loc.LocationNo,
    loc.Warehouse,
    loc.Bay,
    loc.StatusID,
    cs.Description AS LocationStatus,
    pq.CreateDate AS PartQtyCreateDate,
    pq.LastActivityDate AS PartQtyLastActivity
FROM Plus.pls.PartQty pq
INNER JOIN Plus.pls.PartLocation loc ON loc.ID = pq.LocationID
LEFT JOIN Plus.pls.CodeConfiguration cc ON cc.ID = pq.ConfigurationID
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = loc.StatusID
WHERE loc.LocationNo = 'FGI.10068.0.0.0'
  AND pq.ProgramID = 10068
ORDER BY pq.AvailableQty DESC, pq.PartNo;








