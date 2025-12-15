-- ============================================
-- CHECK ACTUAL TRANSACTION TYPE VALUES
-- ============================================
-- Let's see what the actual PartTransaction values look like

-- ============================================
-- 1. ALL TRANSACTION TYPES TODAY
-- ============================================
SELECT TOP 50
    pt.PartTransaction,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
GROUP BY pt.PartTransaction
ORDER BY TransactionCount DESC;

-- ============================================
-- 2. SEARCH FOR FSR/ECR/B2B PATTERNS
-- ============================================
-- Look for transaction types that might contain these terms
SELECT TOP 50
    pt.PartTransaction,
    COUNT(*) as TransactionCount
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND (
    pt.PartTransaction LIKE '%FSR%' OR
    pt.PartTransaction LIKE '%ECR%' OR
    pt.PartTransaction LIKE '%B2B%' OR
    pt.PartTransaction LIKE '%fsr%' OR
    pt.PartTransaction LIKE '%ecr%' OR
    pt.PartTransaction LIKE '%b2b%'
  )
GROUP BY pt.PartTransaction
ORDER BY TransactionCount DESC;

-- ============================================
-- 3. SAMPLE TRANSACTION DATA
-- ============================================
-- Let's see some actual transaction records
SELECT TOP 20
    pt.PartTransaction,
    pt.Username,
    pt.CreateDate,
    pt.PartNo,
    pt.SerialNo
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
ORDER BY pt.CreateDate DESC;
