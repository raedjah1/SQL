-- ============================================
-- DEEP DATA INVESTIGATION - FIND THE REAL ISSUE
-- ============================================
-- Let's dig deeper into these high-volume operators

-- ============================================
-- 1. WHAT IS PEGAH.ESLAMIEH ACTUALLY DOING?
-- ============================================
-- 815 transactions in 1 hour = 13.6 per minute = not realistic for manual work
SELECT TOP 50
    pt.CreateDate,
    pt.PartTransaction,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty,
    pt.Program,
    pt.ProgramID,
    DATEDIFF(SECOND, LAG(pt.CreateDate) OVER (ORDER BY pt.CreateDate), pt.CreateDate) as SecondsBetweenTransactions
FROM pls.vPartTransaction pt
WHERE pt.Username = 'pegah.eslamieh'
  AND pt.CreateDate >= CAST(GETDATE() as DATE)
  AND (
    pt.PartTransaction LIKE 'RO-%' OR      -- FSR work (Repair Orders)
    pt.PartTransaction = 'WO-WIP' OR       -- ECR work (Work in Progress)
    pt.PartTransaction LIKE 'SO-%'         -- B2B work (Sales Orders)
  )
ORDER BY pt.CreateDate;

-- ============================================
-- 2. WHAT IS OSKAR.SMOCZYNSKI DOING?
-- ============================================
-- Let's see his filtered transactions
SELECT TOP 50
    pt.CreateDate,
    pt.PartTransaction,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty,
    pt.Program,
    pt.ProgramID,
    DATEDIFF(SECOND, LAG(pt.CreateDate) OVER (ORDER BY pt.CreateDate), pt.CreateDate) as SecondsBetweenTransactions
FROM pls.vPartTransaction pt
WHERE pt.Username = 'oskar.smoczynski'
  AND pt.CreateDate >= CAST(GETDATE() as DATE)
  AND (
    pt.PartTransaction LIKE 'RO-%' OR      -- FSR work (Repair Orders)
    pt.PartTransaction = 'WO-WIP' OR       -- ECR work (Work in Progress)
    pt.PartTransaction LIKE 'SO-%'         -- B2B work (Sales Orders)
  )
ORDER BY pt.CreateDate;

-- ============================================
-- 3. BREAKDOWN BY SPECIFIC TRANSACTION TYPE
-- ============================================
-- Which specific RO/SO/WO-WIP transactions are causing high volumes?
SELECT 
    pt.PartTransaction,
    pt.Username,
    COUNT(*) as TransactionCount,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(SECOND, MIN(pt.CreateDate), MAX(pt.CreateDate)) as TimeSpanSeconds,
    CASE 
        WHEN DATEDIFF(SECOND, MIN(pt.CreateDate), MAX(pt.CreateDate)) > 0 
        THEN CAST(COUNT(*) as FLOAT) / DATEDIFF(SECOND, MIN(pt.CreateDate), MAX(pt.CreateDate))
        ELSE 0 
    END as TransactionsPerSecond
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND (
    pt.PartTransaction LIKE 'RO-%' OR      -- FSR work (Repair Orders)
    pt.PartTransaction = 'WO-WIP' OR       -- ECR work (Work in Progress)
    pt.PartTransaction LIKE 'SO-%'         -- B2B work (Sales Orders)
  )
GROUP BY pt.PartTransaction, pt.Username
HAVING COUNT(*) > 100  -- Focus on high volume
ORDER BY TransactionsPerSecond DESC;

-- ============================================
-- 4. CHECK FOR BULK PATTERNS IN FILTERED DATA
-- ============================================
-- Are there bulk operations even in RO/SO/WO-WIP?
SELECT TOP 30
    pt.Username,
    pt.PartTransaction,
    pt.PartNo,
    COUNT(*) as SamePartCount,
    MIN(pt.CreateDate) as FirstTime,
    MAX(pt.CreateDate) as LastTime,
    DATEDIFF(SECOND, MIN(pt.CreateDate), MAX(pt.CreateDate)) as TimeSpanSeconds
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND (
    pt.PartTransaction LIKE 'RO-%' OR      -- FSR work (Repair Orders)
    pt.PartTransaction = 'WO-WIP' OR       -- ECR work (Work in Progress)
    pt.PartTransaction LIKE 'SO-%'         -- B2B work (Sales Orders)
  )
GROUP BY pt.Username, pt.PartTransaction, pt.PartNo
HAVING COUNT(*) > 50  -- Large batches of same part
ORDER BY SamePartCount DESC;

-- ============================================
-- 5. REALISTIC OPERATORS ONLY
-- ============================================
-- Show operators with realistic transaction rates (under 2 per minute)
SELECT TOP 50
    pt.Username as Operator,
    COUNT(*) as TotalTransactions,
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
  AND (
    pt.PartTransaction LIKE 'RO-%' OR      -- FSR work (Repair Orders)
    pt.PartTransaction = 'WO-WIP' OR       -- ECR work (Work in Progress)
    pt.PartTransaction LIKE 'SO-%'         -- B2B work (Sales Orders)
  )
GROUP BY pt.Username
HAVING COUNT(*) >= 10  -- Minimum activity
  AND CASE 
    WHEN DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) > 0 
    THEN CAST(COUNT(*) as FLOAT) / DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate))
    ELSE 0 
  END <= 2  -- Max 2 transactions per minute (realistic for manual work)
ORDER BY TransactionsPerMinute DESC;
