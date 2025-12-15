-- =====================================================
-- DELL BLOW OUT MOVEMENT DISCOVERY
-- =====================================================
-- Purpose: Discover what "blow out movement" refers to in DELL operations
-- Program: DELL (ProgramID: 10053) - Memphis
-- Targets: Green-32, Yellow-16, Red-<16
-- =====================================================

-- =====================================================
-- 1. DISCOVER ALL MOVEMENT-RELATED TRANSACTION TYPES
-- =====================================================

-- Find ALL transaction types that could be "blow out movement"
SELECT 
    'DELL MOVEMENT TRANSACTIONS' as AnalysisType,
    pt.PartTransaction as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent,
    MIN(pt.CreateDate) as FirstOccurrence,
    MAX(pt.CreateDate) as LastOccurrence
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND (
      pt.PartTransaction LIKE '%MOVE%' 
      OR pt.PartTransaction LIKE '%TRANSFER%'
      OR pt.PartTransaction LIKE '%SHIFT%'
      OR pt.PartTransaction LIKE '%RELOCATE%'
      OR pt.PartTransaction LIKE '%BLOW%'
      OR pt.PartTransaction LIKE '%OUT%'
      OR pt.PartTransaction LIKE '%WH-%'  -- Warehouse operations
  )
GROUP BY pt.PartTransaction
ORDER BY TransactionCount DESC;

-- =====================================================
-- 2. ANALYZE WH-MOVEPART SPECIFICALLY (MAIN MOVEMENT)
-- =====================================================

-- Detailed analysis of WH-MOVEPART operations (most likely blow out movement)
SELECT 
    'DELL WH-MOVEPART ANALYSIS' as AnalysisType,
    pt.Username as Operator,
    COUNT(*) as MoveTransactions,
    COUNT(DISTINCT pt.PartNo) as UniquePartsMoved,
    COUNT(DISTINCT pt.SerialNo) as UnitsMoved,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as OperatorPercent,
    MIN(pt.CreateDate) as FirstMove,
    MAX(pt.CreateDate) as LastMove
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.PartTransaction = 'WH-MOVEPART'
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
GROUP BY pt.Username
ORDER BY MoveTransactions DESC;

-- =====================================================
-- 3. ANALYZE LOCATION PATTERNS FOR MOVEMENT
-- =====================================================

-- Find location patterns that might indicate "blow out" operations
SELECT 
    'DELL MOVEMENT LOCATIONS' as AnalysisType,
    pt.Location as FromLocation,
    pt.PartTransaction as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction = 'WH-MOVEPART'
  AND pt.Location IS NOT NULL
GROUP BY pt.Location, pt.PartTransaction
ORDER BY TransactionCount DESC;

-- =====================================================
-- 4. HOURLY MOVEMENT PERFORMANCE ANALYSIS
-- =====================================================

-- Analyze hourly performance for movement operations
SELECT 
    'DELL MOVEMENT HOURLY PERFORMANCE' as AnalysisType,
    pt.PartTransaction as TransactionType,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    COUNT(DISTINCT pt.Username) as ActiveOperators,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT pt.Username), 2) as AvgTransactionsPerOperator
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction = 'WH-MOVEPART'
GROUP BY pt.PartTransaction, DATEPART(hour, pt.CreateDate)
ORDER BY pt.PartTransaction, WorkHour;

-- =====================================================
-- 5. MOVEMENT OPERATORS BY SPECIALIZATION
-- =====================================================

-- Find operators who do movement work and their other specializations
SELECT 
    'DELL MOVEMENT OPERATORS' as AnalysisType,
    pt.Username as Operator,
    COUNT(DISTINCT pt.PartTransaction) as TotalTransactionTypes,
    STRING_AGG(pt.PartTransaction, ', ') as TransactionTypes,
    COUNT(*) as TotalTransactions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as OperatorPercent
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
  AND pt.Username IN (
      SELECT DISTINCT pt2.Username 
      FROM pls.vPartTransaction pt2 
      WHERE pt2.ProgramID = 10053 
        AND pt2.PartTransaction = 'WH-MOVEPART'
        AND pt2.CreateDate >= DATEADD(month, -3, GETDATE())
  )
GROUP BY pt.Username
ORDER BY TotalTransactions DESC;
