-- ============================================
-- DATA VALIDATION QUERIES
-- ============================================
-- Investigate unusual transaction volumes

-- ============================================
-- 1. CHECK TRANSACTION TYPES
-- ============================================
-- What types of transactions are being counted?
SELECT TOP 20
    pt.PartTransaction,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    AVG(CAST(COUNT(*) as FLOAT)) OVER (PARTITION BY pt.PartTransaction) as AvgPerType
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
GROUP BY pt.PartTransaction, pt.Username
ORDER BY TransactionCount DESC;

-- ============================================
-- 2. DETAILED LOOK AT TOP PERFORMER
-- ============================================
-- What exactly is oskar.smoczynski doing?
SELECT TOP 100
    pt.CreateDate,
    pt.PartTransaction,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty,
    pt.Location,
    DATEDIFF(SECOND, LAG(pt.CreateDate) OVER (ORDER BY pt.CreateDate), pt.CreateDate) as SecondsBetweenTransactions
FROM pls.vPartTransaction pt
WHERE pt.Username = 'oskar.smoczynski'
  AND pt.CreateDate >= CAST(GETDATE() as DATE)
ORDER BY pt.CreateDate;

-- ============================================
-- 3. TIME PATTERN ANALYSIS
-- ============================================
-- Are these transactions happening too fast to be manual?
SELECT 
    pt.Username,
    COUNT(*) as TotalTransactions,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(SECOND, MIN(pt.CreateDate), MAX(pt.CreateDate)) as TotalSeconds,
    CASE 
        WHEN DATEDIFF(SECOND, MIN(pt.CreateDate), MAX(pt.CreateDate)) > 0 
        THEN CAST(COUNT(*) as FLOAT) / DATEDIFF(SECOND, MIN(pt.CreateDate), MAX(pt.CreateDate))
        ELSE 0 
    END as TransactionsPerSecond
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
GROUP BY pt.Username
HAVING COUNT(*) > 500  -- Focus on high-volume operators
ORDER BY TransactionsPerSecond DESC;

-- ============================================
-- 4. CHECK FOR BULK/BATCH OPERATIONS
-- ============================================
-- Look for patterns indicating bulk operations
SELECT TOP 50
    pt.Username,
    pt.PartNo,
    pt.Location,
    COUNT(*) as SamePartLocationCount,
    MIN(pt.CreateDate) as FirstTime,
    MAX(pt.CreateDate) as LastTime,
    DATEDIFF(SECOND, MIN(pt.CreateDate), MAX(pt.CreateDate)) as TimeSpanSeconds
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, pt.PartNo, pt.LocationNo
HAVING COUNT(*) > 50  -- Large batches of same part/location
ORDER BY SamePartLocationCount DESC;
