-- ============================================
-- FIND FWD DATA IN PROGRAM 10068 (ADT)
-- ============================================
-- Comprehensive search for FWD (Excess Centralization) data
-- within ADT Program (10068) across all relevant tables

-- ============================================
-- 1. SEARCH FWD IN PART TRANSACTIONS
-- ============================================
SELECT 
    'FWD IN PART TRANSACTIONS' as DataSource,
    pt.ID as TransactionID,
    pt.PartTransaction,
    pt.PartNo as SKU,
    pt.SerialNo,
    pt.Qty,
    pt.Location,
    pt.ToLocation,
    pt.Username as Operator,
    pt.CreateDate as TransactionTime,
    pt.Reason as Notes,
    pt.CustomerReference,
    pt.ProgramID
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND (
    pt.PartNo LIKE '%FWD%' OR
    pt.SerialNo LIKE '%FWD%' OR
    pt.CustomerReference LIKE '%FWD%' OR
    pt.Reason LIKE '%FWD%' OR
    pt.Location LIKE '%FWD%' OR
    pt.ToLocation LIKE '%FWD%'
  )
ORDER BY pt.CreateDate DESC;

-- ============================================
-- 2. SEARCH FWD IN WORK ORDERS
-- ============================================
SELECT 
    'FWD IN WORK ORDERS' as DataSource,
    wo.ID as WorkOrderID,
    wo.CustomerReference,
    wo.PartNo,
    wo.SerialNo,
    wo.RepairTypeDescription,
    wo.StatusDescription,
    wo.Username,
    wo.CreateDate,
    wo.LastActivityDate,
    wo.ProgramID
FROM pls.vWOHeader wo
WHERE wo.ProgramID = 10068  -- ADT Program
  AND (
    wo.CustomerReference LIKE '%FWD%' OR
    wo.PartNo LIKE '%FWD%' OR
    wo.SerialNo LIKE '%FWD%' OR
    wo.RepairTypeDescription LIKE '%FWD%'
  )
ORDER BY wo.CreateDate DESC;

-- ============================================
-- 3. SEARCH FWD IN REPAIR ORDERS
-- ============================================
SELECT 
    'FWD IN REPAIR ORDERS' as DataSource,
    ro.ID as RepairOrderID,
    ro.RepairOrderNo,
    ro.CustomerReference,
    ro.PartNo,
    ro.SerialNo,
    ro.StatusDescription,
    ro.Username,
    ro.CreateDate,
    ro.LastActivityDate,
    ro.ProgramID
FROM pls.vROUnit ro
WHERE ro.ProgramID = 10068  -- ADT Program
  AND (
    ro.CustomerReference LIKE '%FWD%' OR
    ro.PartNo LIKE '%FWD%' OR
    ro.SerialNo LIKE '%FWD%' OR
    ro.RepairOrderNo LIKE '%FWD%'
  )
ORDER BY ro.CreateDate DESC;

-- ============================================
-- 4. SEARCH FWD IN PART LOCATIONS
-- ============================================
SELECT 
    'FWD IN PART LOCATIONS' as DataSource,
    pl.PartNo,
    pl.SerialNo,
    pl.Location,
    pl.QtyOnHand,
    pl.Username,
    pl.LastActivityDate,
    pl.ProgramID
FROM pls.vPartLocation pl
WHERE pl.ProgramID = 10068  -- ADT Program
  AND (
    pl.PartNo LIKE '%FWD%' OR
    pl.SerialNo LIKE '%FWD%' OR
    pl.Location LIKE '%FWD%'
  )
ORDER BY pl.LastActivityDate DESC;

-- ============================================
-- 5. SEARCH FWD IN PART SERIALS
-- ============================================
SELECT 
    'FWD IN PART SERIALS' as DataSource,
    ps.PartNo,
    ps.SerialNo,
    ps.Username,
    ps.CreateDate,
    ps.LastActivityDate,
    ps.ProgramID
FROM pls.vPartSerial ps
WHERE ps.ProgramID = 10068  -- ADT Program
  AND (
    ps.PartNo LIKE '%FWD%' OR
    ps.SerialNo LIKE '%FWD%'
  )
ORDER BY ps.CreateDate DESC;

-- ============================================
-- 6. SEARCH FWD IN DOCK LOG
-- ============================================
SELECT 
    'FWD IN DOCK LOG' as DataSource,
    dl.ID as DockLogID,
    dl.CustomerReference,
    dl.PartNo,
    dl.SerialNo,
    dl.Username,
    dl.CreateDate,
    dl.LastActivityDate,
    dl.ProgramID
FROM pls.vRODockLog dl
WHERE dl.ProgramID = 10068  -- ADT Program
  AND (
    dl.CustomerReference LIKE '%FWD%' OR
    dl.PartNo LIKE '%FWD%' OR
    dl.SerialNo LIKE '%FWD%'
  )
ORDER BY dl.CreateDate DESC;

-- ============================================
-- 7. SUMMARY OF FWD DATA FOUND
-- ============================================
SELECT 
    'FWD DATA SUMMARY' as SummaryType,
    'Part Transactions' as TableName,
    COUNT(*) as RecordCount,
    COUNT(DISTINCT pt.PartNo) as UniqueParts,
    COUNT(DISTINCT pt.SerialNo) as UniqueSerials,
    MIN(pt.CreateDate) as EarliestRecord,
    MAX(pt.CreateDate) as LatestRecord
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
    'FWD DATA SUMMARY' as SummaryType,
    'Work Orders' as TableName,
    COUNT(*) as RecordCount,
    COUNT(DISTINCT wo.PartNo) as UniqueParts,
    COUNT(DISTINCT wo.SerialNo) as UniqueSerials,
    MIN(wo.CreateDate) as EarliestRecord,
    MAX(wo.CreateDate) as LatestRecord
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
    'FWD DATA SUMMARY' as SummaryType,
    'Repair Orders' as TableName,
    COUNT(*) as RecordCount,
    COUNT(DISTINCT ro.PartNo) as UniqueParts,
    COUNT(DISTINCT ro.SerialNo) as UniqueSerials,
    MIN(ro.CreateDate) as EarliestRecord,
    MAX(ro.CreateDate) as LatestRecord
FROM pls.vROUnit ro
WHERE ro.ProgramID = 10068
  AND (
    ro.CustomerReference LIKE '%FWD%' OR
    ro.PartNo LIKE '%FWD%' OR
    ro.SerialNo LIKE '%FWD%' OR
    ro.RepairOrderNo LIKE '%FWD%'
  )

ORDER BY TableName;

-- ============================================
-- 8. FIND FWD INVENTORY ADJUSTMENTS SPECIFICALLY
-- ============================================
-- This focuses on manual inventory adjustments for FWD
SELECT 
    'FWD INVENTORY ADJUSTMENTS' as ReportType,
    pt.ID as TransactionID,
    pt.PartTransaction as TransactionType,
    pt.PartNo as SKU,
    pt.SerialNo,
    pt.Location as Locator,
    pt.ToLocation as ToLocator,
    pt.Qty as QuantityAffected,
    pt.Username as Operator,
    pt.CreateDate as TransactionTime,
    pt.Reason as Notes,
    pt.CustomerReference,
    -- Determine adjustment type
    CASE 
        WHEN pt.PartTransaction = 'WH-ADDPART' THEN 'Up Adjust'
        WHEN pt.PartTransaction = 'WH-REMOVEPART' THEN 'Down Adjust'
        WHEN pt.PartTransaction = 'ERP-ADDPART' THEN 'Up Adjust (ERP)'
        WHEN pt.PartTransaction = 'ERP-REMOVEPART' THEN 'Down Adjust (ERP)'
        WHEN pt.PartTransaction = 'WO-SCRAP' THEN 'Inbound Scrap'
        WHEN pt.PartTransaction = 'WH-DISCREPANCYRECEIVE' THEN 'Discrepancy Adjust'
        ELSE pt.PartTransaction
    END as AdjustmentType,
    -- Client and Program info
    'ADT, LLC' as ClientName,
    'FWD' as Program
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.PartTransaction IN (
    'WH-ADDPART', 'WH-REMOVEPART', 'ERP-ADDPART', 'ERP-REMOVEPART',
    'WO-SCRAP', 'WH-DISCREPANCYRECEIVE'
  )
  AND (
    pt.PartNo LIKE '%FWD%' OR
    pt.SerialNo LIKE '%FWD%' OR
    pt.CustomerReference LIKE '%FWD%' OR
    pt.Reason LIKE '%FWD%' OR
    pt.Location LIKE '%FWD%' OR
    pt.ToLocation LIKE '%FWD%'
  )
ORDER BY pt.CreateDate DESC;
