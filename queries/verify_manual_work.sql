-- ============================================
-- VERIFY MANUAL WORK - VALIDATION QUERIES
-- ============================================
-- Let's confirm we've found the right manual work transactions

-- ============================================
-- 1. TRANSACTION TYPE BREAKDOWN - VERIFICATION
-- ============================================
-- Show which transaction types we're including and their volumes
SELECT 
    pt.PartTransaction,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    AVG(CAST(COUNT(*) as FLOAT)) OVER (PARTITION BY pt.PartTransaction) as AvgPerOperator,
    MIN(pt.CreateDate) as EarliestTransaction,
    MAX(pt.CreateDate) as LatestTransaction
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)  -- Today only
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN (
    'WO-REPAIR',            -- Repair work (manual) - MOST COMMON
    'RO-CLOSE',             -- Closing repair orders (manual)
    'SO-CSCLOSE',           -- Closing sales orders (manual)
    'WO-SCRAP',             -- Scrapping work orders (manual)
    'WO-HARVEST',           -- Harvesting completed work (manual)
    'WO-RTS',               -- Return to stock (manual)
    'WO-CANCEL',            -- Canceling work orders (manual)
    'WO-REOPEN',            -- Reopening work orders (manual)
    'RO-CANCEL',            -- Canceling repair orders (manual)
    'RO-CTSRECEIVE',        -- CTS receiving (manual)
    'WH-ADDPART',           -- Adding parts to warehouse (manual)
    'WH-REMOVEPART',        -- Removing parts from warehouse (manual)
    'WH-DISCREPANCYRECEIVE' -- Receiving with discrepancies (manual)
  )
GROUP BY pt.PartTransaction
ORDER BY TransactionCount DESC;

-- ============================================
-- 2. REALISTIC TRANSACTION RATES - VERIFICATION
-- ============================================
-- Check that transaction rates look realistic for manual work
SELECT TOP 20
    pt.Username as Operator,
    pt.PartTransaction,
    COUNT(*) as TransactionCount,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as TotalMinutes,
    CASE 
        WHEN DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) > 0 
        THEN CAST(COUNT(*) as FLOAT) / DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate))
        ELSE 0 
    END as TransactionsPerMinute,
    CASE 
        WHEN DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) > 0 
        THEN CAST(COUNT(*) as FLOAT) / DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) * 60
        ELSE 0 
    END as TransactionsPerHour
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)  -- Today only
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN (
    'WO-REPAIR', 'RO-CLOSE', 'SO-CSCLOSE', 'WO-SCRAP', 'WO-HARVEST', 'WO-RTS', 
    'WO-CANCEL', 'WO-REOPEN', 'RO-CANCEL', 'RO-CTSRECEIVE', 'WH-ADDPART', 
    'WH-REMOVEPART', 'WH-DISCREPANCYRECEIVE'
  )
GROUP BY pt.Username, pt.PartTransaction
HAVING COUNT(*) >= 5  -- Minimum activity
ORDER BY TransactionsPerHour DESC;

-- ============================================
-- 3. SAMPLE MANUAL WORK RECORDS - VERIFICATION
-- ============================================
-- Look at actual records to confirm they look like manual work
SELECT TOP 20
    pt.CreateDate,
    pt.PartTransaction,
    pt.Username,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty,
    pt.Program,
    pt.ProgramID,
    DATEDIFF(SECOND, LAG(pt.CreateDate) OVER (ORDER BY pt.CreateDate), pt.CreateDate) as SecondsBetweenTransactions
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)  -- Today only
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN (
    'WO-REPAIR', 'RO-CLOSE', 'SO-CSCLOSE', 'WO-SCRAP', 'WO-HARVEST', 'WO-RTS', 
    'WO-CANCEL', 'WO-REOPEN', 'RO-CANCEL', 'RO-CTSRECEIVE', 'WH-ADDPART', 
    'WH-REMOVEPART', 'WH-DISCREPANCYRECEIVE'
  )
ORDER BY pt.CreateDate DESC;

-- ============================================
-- 4. COMPARISON WITH BULK OPERATIONS - VERIFICATION
-- ============================================
-- Show the difference between our manual work and bulk operations
SELECT 
    'MANUAL WORK (Our Filter)' as WorkType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    AVG(CAST(COUNT(*) as FLOAT)) OVER () as AvgPerOperator
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN (
    'WO-REPAIR', 'RO-CLOSE', 'SO-CSCLOSE', 'WO-SCRAP', 'WO-HARVEST', 'WO-RTS', 
    'WO-CANCEL', 'WO-REOPEN', 'RO-CANCEL', 'RO-CTSRECEIVE', 'WH-ADDPART', 
    'WH-REMOVEPART', 'WH-DISCREPANCYRECEIVE'
  )

UNION ALL

SELECT 
    'BULK OPERATIONS (Excluded)' as WorkType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    AVG(CAST(COUNT(*) as FLOAT)) OVER () as AvgPerOperator
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN (
    'SO-RESERVE', 'SO-SHIP', 'WO-CONSUMECOMPONENTS', 'WO-ISSUEPART', 
    'ERP-ADDPART', 'WO-CONSUME', 'WH-MOVEPART', 'RO-RECEIVE'
  );
