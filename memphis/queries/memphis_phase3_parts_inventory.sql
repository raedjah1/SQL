-- ===============================================
-- MEMPHIS SITE INTELLIGENCE - PHASE 3
-- PARTS & INVENTORY INTELLIGENCE
-- ===============================================

-- Query 7: Parts Processed at Memphis
SELECT 
    pt.ID as PartID,
    pt.PartNumber,
    pt.Description as PartDescription,
    pt.Category,
    pt.Manufacturer,
    pt.Model,
    COUNT(*) as TimesProcessed,
    COUNT(DISTINCT wo.ID) as UniqueWorkOrders,
    p.Name as ProgramName,
    p.CustomerID,
    MIN(wo.CreateDate) as FirstProcessed,
    MAX(wo.LastActivityDate) as LastProcessed,
    AVG(DATEDIFF(day, wo.CreateDate, COALESCE(wo.CompleteDate, GETDATE()))) as AvgProcessingTime
FROM PLUS.pls.WorkOrder wo
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
LEFT JOIN PLUS.pls.Part pt ON wo.PartID = pt.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY pt.ID, pt.PartNumber, pt.Description, pt.Category, pt.Manufacturer, pt.Model, p.Name, p.CustomerID
ORDER BY TimesProcessed DESC;

-- Query 8: Serial Number Tracking and Inventory
SELECT 
    sn.ID as SerialNumberID,
    sn.SerialNumber,
    sn.Status as SerialStatus,
    sn.Location,
    sn.CreateDate as SerialCreateDate,
    sn.LastModified as SerialLastModified,
    pt.PartNumber,
    pt.Description as PartDescription,
    wo.ID as WorkOrderID,
    wo.StatusID as WorkOrderStatus,
    p.Name as ProgramName,
    p.CustomerID
FROM PLUS.pls.SerialNumber sn
INNER JOIN PLUS.pls.WorkOrder wo ON sn.WorkOrderID = wo.ID
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
LEFT JOIN PLUS.pls.Part pt ON wo.PartID = pt.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY sn.CreateDate DESC;

-- Query 9: Inventory Status and Location Tracking
SELECT 
    inv.ID as InventoryID,
    inv.PartID,
    pt.PartNumber,
    pt.Description as PartDescription,
    inv.Location,
    inv.Quantity,
    inv.ReservedQuantity,
    inv.AvailableQuantity,
    inv.Status as InventoryStatus,
    inv.LastCountDate,
    inv.CreateDate as InventoryCreateDate,
    p.Name as ProgramName
FROM PLUS.pls.Inventory inv
LEFT JOIN PLUS.pls.Part pt ON inv.PartID = pt.ID
LEFT JOIN PLUS.pls.Location loc ON inv.LocationID = loc.ID
LEFT JOIN PLUS.pls.Program p ON loc.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS' OR inv.Location LIKE '%MEMPHIS%'
ORDER BY inv.Quantity DESC;
