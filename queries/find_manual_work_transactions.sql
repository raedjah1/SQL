-- ============================================
-- FIND MANUAL WORK TRANSACTIONS
-- ============================================
-- Look for transaction types that could realistically be 80/hour manual work

-- ============================================
-- 1. LOW-VOLUME TRANSACTION TYPES
-- ============================================
-- Find transaction types with reasonable volumes (not bulk operations)
SELECT 
    pt.PartTransaction,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    AVG(CAST(COUNT(*) as FLOAT)) OVER (PARTITION BY pt.PartTransaction) as AvgPerOperator,
    MIN(pt.CreateDate) as EarliestTransaction,
    MAX(pt.CreateDate) as LatestTransaction
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
GROUP BY pt.PartTransaction
HAVING COUNT(*) < 1000  -- Exclude bulk operations
  AND COUNT(DISTINCT pt.Username) > 1  -- Multiple operators doing this work
ORDER BY TransactionCount DESC;

-- ============================================
-- 2. MANUAL-LIKE TRANSACTION PATTERNS
-- ============================================
-- Look for transactions that seem like individual manual work
SELECT 
    pt.PartTransaction,
    pt.Username,
    COUNT(*) as TransactionCount,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as TotalMinutes,
    CASE 
        WHEN DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) > 0 
        THEN CAST(COUNT(*) as FLOAT) / DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate))
        ELSE 0 
    END as TransactionsPerMinute
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN (
    'RO-CLOSE', 'RO-CANCEL', 'RO-CTSRECEIVE',
    'WO-REPAIR', 'WO-SCRAP', 'WO-HARVEST', 'WO-RTS', 'WO-UNREPAIR', 'WO-CANCEL', 'WO-REOPEN',
    'SO-CSCLOSE', 'SO-UNRESERVE', 'SO-REOPEN', 'SO-CANCEL'
  )
GROUP BY pt.PartTransaction, pt.Username
HAVING COUNT(*) >= 5  -- Minimum activity
ORDER BY TransactionsPerMinute DESC;

-- ============================================
-- 3. REALISTIC OPERATOR PERFORMANCE
-- ============================================
-- Find operators with realistic transaction rates (1-3 per minute max)
SELECT TOP 50
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
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, pt.PartTransaction
HAVING COUNT(*) >= 10  -- Minimum activity
  AND CASE 
    WHEN DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) > 0 
    THEN CAST(COUNT(*) as FLOAT) / DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate))
    ELSE 0 
  END <= 3  -- Max 3 transactions per minute (realistic for manual work)
ORDER BY TransactionsPerHour DESC;

-- ============================================
-- 4. QUESTION FOR YOU
-- ============================================
-- Based on your manufacturing process, which of these represent manual operator work?
SELECT DISTINCT
    pt.PartTransaction,
    'QUESTION: Is this manual operator work?' as Question
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN (
    'RO-CLOSE', 'RO-CANCEL', 'RO-CTSRECEIVE', 'RO-RECEIVE',
    'WO-REPAIR', 'WO-SCRAP', 'WO-HARVEST', 'WO-RTS', 'WO-UNREPAIR', 'WO-CANCEL', 'WO-REOPEN', 'WO-WIP',
    'SO-CSCLOSE', 'SO-UNRESERVE', 'SO-REOPEN', 'SO-CANCEL', 'SO-SHIP', 'SO-RESERVE'
  )
ORDER BY pt.PartTransaction;
