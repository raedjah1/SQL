-- ============================================
-- ADT DAILY FWD INVENTORY ADJUSTMENTS REPORT
-- ============================================
-- Daily report showing all manual inventory adjustments made during the shift
-- for ADT Program (10068) tracking and audit purposes

-- ============================================
-- 1. FIND INVENTORY ADJUSTMENT TRANSACTIONS FOR ADT PROGRAM
-- ============================================
-- Look for manual inventory adjustment transactions in Program 10068
SELECT 
    'ADT INVENTORY ADJUSTMENTS' as ReportType,
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
    pt.Source,
    pt.Condition,
    pt.Configuration,
    pt.LotNo,
    pt.PalletBoxNo,
    pt.ToPalletBoxNo,
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
    'FWD' as Program,
    pt.ProgramID
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= CAST(GETDATE() as DATE)  -- Today only
  AND pt.PartTransaction IN (
    'WH-ADDPART',           -- Manual add parts
    'WH-REMOVEPART',        -- Manual remove parts  
    'ERP-ADDPART',          -- ERP add parts
    'ERP-REMOVEPART',       -- ERP remove parts
    'WO-SCRAP',             -- Scrap adjustments
    'WH-DISCREPANCYRECEIVE' -- Discrepancy adjustments
  )
ORDER BY pt.CreateDate DESC;

-- ============================================
-- 2. FIND PRE/POST ADJUSTMENT QUANTITIES
-- ============================================
-- This query attempts to find quantity before/after adjustments
-- Note: This may require additional tables or historical data
SELECT 
    'ADT ADJUSTMENT WITH QUANTITIES' as ReportType,
    pt.ID as TransactionID,
    pt.PartTransaction as TransactionType,
    pt.PartNo as SKU,
    pt.Location as Locator,
    pt.Qty as QuantityAffected,
    pt.Username as Operator,
    pt.CreateDate as TransactionTime,
    pt.Reason as Notes,
    -- Try to get current quantity from PartLocation
    pl.QtyOnHand as CurrentQuantity,
    -- Calculate pre-adjustment quantity
    CASE 
        WHEN pt.PartTransaction IN ('WH-ADDPART', 'ERP-ADDPART') 
        THEN pl.QtyOnHand - pt.Qty
        WHEN pt.PartTransaction IN ('WH-REMOVEPART', 'ERP-REMOVEPART') 
        THEN pl.QtyOnHand + pt.Qty
        ELSE pl.QtyOnHand
    END as PreAdjustmentQty,
    pl.QtyOnHand as PostAdjustmentQty,
    pt.ProgramID
FROM pls.vPartTransaction pt
LEFT JOIN pls.vPartLocation pl ON pt.PartNo = pl.PartNo 
    AND pt.Location = pl.LocationNo 
    AND pt.ProgramID = pl.ProgramID
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= CAST(GETDATE() as DATE)  -- Today only
  AND pt.PartTransaction IN (
    'WH-ADDPART', 'WH-REMOVEPART', 'ERP-ADDPART', 'ERP-REMOVEPART'
  )
ORDER BY pt.CreateDate DESC;

-- ============================================
-- 3. FIND ALL ADT TRANSACTION TYPES FOR REFERENCE
-- ============================================
-- Discover what transaction types exist for ADT program
SELECT 
    'ADT TRANSACTION TYPES' as ReportType,
    pt.PartTransaction as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    MIN(pt.CreateDate) as EarliestTransaction,
    MAX(pt.CreateDate) as LatestTransaction,
    -- Categorize transaction types
    CASE 
        WHEN pt.PartTransaction LIKE '%ADDPART%' THEN 'Inventory Adjustment - Add'
        WHEN pt.PartTransaction LIKE '%REMOVEPART%' THEN 'Inventory Adjustment - Remove'
        WHEN pt.PartTransaction LIKE '%SCRAP%' THEN 'Inventory Adjustment - Scrap'
        WHEN pt.PartTransaction LIKE '%DISCREPANCY%' THEN 'Inventory Adjustment - Discrepancy'
        WHEN pt.PartTransaction LIKE '%RECEIVE%' THEN 'Receiving Transaction'
        WHEN pt.PartTransaction LIKE '%MOVE%' THEN 'Movement Transaction'
        WHEN pt.PartTransaction LIKE '%CONSUME%' THEN 'Consumption Transaction'
        WHEN pt.PartTransaction LIKE '%ISSUE%' THEN 'Issue Transaction'
        ELSE 'Other Transaction'
    END as TransactionCategory
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
GROUP BY pt.PartTransaction
ORDER BY TransactionCount DESC;

-- ============================================
-- 4. FIND ADT LOCATION PATTERNS
-- ============================================
-- Discover what locations are used for ADT operations
SELECT 
    'ADT LOCATIONS' as ReportType,
    pt.Location as Locator,
    pt.ToLocation as ToLocator,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as UniqueParts,
    COUNT(DISTINCT pt.Username) as UniqueOperators,
    MIN(pt.CreateDate) as EarliestTransaction,
    MAX(pt.CreateDate) as LatestTransaction
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND (pt.Location IS NOT NULL OR pt.ToLocation IS NOT NULL)
GROUP BY pt.Location, pt.ToLocation
ORDER BY TransactionCount DESC;

-- ============================================
-- 5. FIND ADT PARTS WITH ADJUSTMENT ACTIVITY
-- ============================================
-- Discover which parts have adjustment activity
SELECT 
    'ADT PARTS WITH ADJUSTMENTS' as ReportType,
    pt.PartNo as SKU,
    COUNT(*) as AdjustmentCount,
    COUNT(DISTINCT pt.PartTransaction) as AdjustmentTypes,
    COUNT(DISTINCT pt.Username) as UniqueOperators,
    SUM(CASE WHEN pt.PartTransaction LIKE '%ADDPART%' THEN pt.Qty ELSE 0 END) as TotalAdded,
    SUM(CASE WHEN pt.PartTransaction LIKE '%REMOVEPART%' THEN pt.Qty ELSE 0 END) as TotalRemoved,
    MIN(pt.CreateDate) as EarliestAdjustment,
    MAX(pt.CreateDate) as LatestAdjustment
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.PartTransaction IN (
    'WH-ADDPART', 'WH-REMOVEPART', 'ERP-ADDPART', 'ERP-REMOVEPART',
    'WO-SCRAP', 'WH-DISCREPANCYRECEIVE'
  )
GROUP BY pt.PartNo
ORDER BY AdjustmentCount DESC;

-- ============================================
-- 6. FIND ADT OPERATORS MAKING ADJUSTMENTS
-- ============================================
-- Discover which operators are making inventory adjustments
SELECT 
    'ADT ADJUSTMENT OPERATORS' as ReportType,
    pt.Username as Operator,
    COUNT(*) as AdjustmentCount,
    COUNT(DISTINCT pt.PartTransaction) as AdjustmentTypes,
    COUNT(DISTINCT pt.PartNo) as UniqueParts,
    MIN(pt.CreateDate) as EarliestAdjustment,
    MAX(pt.CreateDate) as LatestAdjustment,
    -- Adjustment breakdown by type
    SUM(CASE WHEN pt.PartTransaction LIKE '%ADDPART%' THEN 1 ELSE 0 END) as AddAdjustments,
    SUM(CASE WHEN pt.PartTransaction LIKE '%REMOVEPART%' THEN 1 ELSE 0 END) as RemoveAdjustments,
    SUM(CASE WHEN pt.PartTransaction LIKE '%SCRAP%' THEN 1 ELSE 0 END) as ScrapAdjustments
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.PartTransaction IN (
    'WH-ADDPART', 'WH-REMOVEPART', 'ERP-ADDPART', 'ERP-REMOVEPART',
    'WO-SCRAP', 'WH-DISCREPANCYRECEIVE'
  )
GROUP BY pt.Username
ORDER BY AdjustmentCount DESC;
