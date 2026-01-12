-- Simple query to see all parts moved from TAGTORNDOWN to another location
SELECT 
    pt.ID,
    pt.ProgramID,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty,
    cpt.Description AS TransactionType,
    pt.Location AS FromLocation,
    pl_from.Warehouse AS FromWarehouse,
    pt.ToLocation,
    pl_to.Warehouse AS ToWarehouse,
    pt.CreateDate,
    u.Username
FROM Plus.pls.PartTransaction pt
    LEFT JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    LEFT JOIN Plus.pls.User u ON u.ID = pt.UserID
    -- Get source warehouse
    LEFT JOIN Plus.pls.PartLocation pl_from ON pl_from.LocationNo = pt.Location
    -- Get destination warehouse
    LEFT JOIN Plus.pls.PartLocation pl_to ON pl_to.LocationNo = pt.ToLocation
WHERE pt.ProgramID = 10053
    AND UPPER(LTRIM(RTRIM(pl_from.Warehouse))) = 'TAGTORNDOWN'
    AND pt.ToLocation IS NOT NULL
    AND pt.ToLocation != pt.Location
ORDER BY pt.CreateDate DESC

