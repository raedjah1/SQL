-- ============================================
-- FIND FSR/ECR/B2B IN THE DATA
-- ============================================
-- Look for these values in different columns

-- ============================================
-- 1. CHECK PROGRAM FIELD
-- ============================================
SELECT TOP 20
    pt.Program,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND pt.Program IS NOT NULL
GROUP BY pt.Program
ORDER BY TransactionCount DESC;

-- ============================================
-- 2. CHECK PROGRAMID FIELD
-- ============================================
SELECT TOP 20
    pt.ProgramID,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND pt.ProgramID IS NOT NULL
GROUP BY pt.ProgramID
ORDER BY TransactionCount DESC;

-- ============================================
-- 3. SEARCH ALL TEXT FIELDS FOR FSR/ECR/B2B
-- ============================================
-- Look across multiple fields
SELECT TOP 50
    'Program' as FieldName,
    pt.Program as FieldValue,
    COUNT(*) as TransactionCount
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND (
    pt.Program LIKE '%FSR%' OR pt.Program LIKE '%ECR%' OR pt.Program LIKE '%B2B%' OR
    pt.Program LIKE '%fsr%' OR pt.Program LIKE '%ecr%' OR pt.Program LIKE '%b2b%'
  )
GROUP BY pt.Program

UNION ALL

SELECT TOP 50
    'ProgramID' as FieldName,
    pt.ProgramID as FieldValue,
    COUNT(*) as TransactionCount
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
  AND (
    pt.ProgramID LIKE '%FSR%' OR pt.ProgramID LIKE '%ECR%' OR pt.ProgramID LIKE '%B2B%' OR
    pt.ProgramID LIKE '%fsr%' OR pt.ProgramID LIKE '%ecr%' OR pt.ProgramID LIKE '%b2b%'
  )
GROUP BY pt.ProgramID

ORDER BY TransactionCount DESC;

-- ============================================
-- 4. SAMPLE DATA WITH ALL RELEVANT FIELDS
-- ============================================
SELECT TOP 10
    pt.PartTransaction,
    pt.Program,
    pt.ProgramID,
    pt.Username,
    pt.CreateDate,
    pt.PartNo
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)
  AND pt.Username IS NOT NULL
ORDER BY pt.CreateDate DESC;
