-- ============================================
-- SIMPLE FWD SEARCH IN PROGRAM 10068
-- ============================================
-- Quick search for FWD data anywhere in ADT Program (10068)

-- Search all relevant columns for FWD
SELECT 
    'FWD FOUND' as Status,
    'PartTransaction' as TableName,
    pt.ID as RecordID,
    pt.PartNo as SKU,
    pt.SerialNo,
    pt.CustomerReference,
    pt.Location,
    pt.ToLocation,
    pt.Username as Operator,
    pt.CreateDate as TransactionTime,
    pt.PartTransaction as TransactionType,
    pt.Qty as Quantity,
    pt.Reason as Notes
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068
  AND (
    pt.PartNo LIKE '%FWD%' OR
    pt.SerialNo LIKE '%FWD%' OR
    pt.CustomerReference LIKE '%FWD%' OR
    pt.Reason LIKE '%FWD%' OR
    pt.Location LIKE '%FWD%' OR
    pt.ToLocation LIKE '%FWD%'
  )

UNION ALL

SELECT 
    'FWD FOUND' as Status,
    'WorkOrder' as TableName,
    wo.ID as RecordID,
    wo.PartNo as SKU,
    wo.SerialNo,
    wo.CustomerReference,
    wo.WorkstationDescription as Location,
    NULL as ToLocation,
    wo.Username as Operator,
    wo.CreateDate as TransactionTime,
    wo.RepairTypeDescription as TransactionType,
    NULL as Quantity,
    NULL as Notes
FROM pls.vWOHeader wo
WHERE wo.ProgramID = 10068
  AND (
    wo.CustomerReference LIKE '%FWD%' OR
    wo.PartNo LIKE '%FWD%' OR
    wo.SerialNo LIKE '%FWD%' OR
    wo.RepairTypeDescription LIKE '%FWD%'
  )

UNION ALL

SELECT 
    'FWD FOUND' as Status,
    'RepairOrder' as TableName,
    ro.ID as RecordID,
    ro.PartNo as SKU,
    ro.SerialNo,
    ro.CustomerReference,
    NULL as Location,
    NULL as ToLocation,
    ro.Username as Operator,
    ro.CreateDate as TransactionTime,
    ro.StatusDescription as TransactionType,
    NULL as Quantity,
    NULL as Notes
FROM pls.vROUnit ro
WHERE ro.ProgramID = 10068
  AND (
    ro.CustomerReference LIKE '%FWD%' OR
    ro.PartNo LIKE '%FWD%' OR
    ro.SerialNo LIKE '%FWD%' OR
    ro.RepairOrderNo LIKE '%FWD%'
  )

ORDER BY TransactionTime DESC;


