-- =====================================================
-- DELL RECEIVING OPERATIONS ANALYSIS
-- =====================================================
-- Purpose: Analyze what receiving operations actually exist in DELL
-- Program: DELL (ProgramID: 10053) - Memphis
-- =====================================================

-- =====================================================
-- 1. DISCOVER ALL RECEIVING-RELATED TRANSACTION TYPES
-- =====================================================

-- Find ALL transaction types that contain "RECEIVE" or are receiving-related
SELECT 
    'DELL RECEIVING TRANSACTIONS' as AnalysisType,
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
      pt.PartTransaction LIKE '%RECEIVE%' 
      OR pt.PartTransaction LIKE '%RECEIPT%'
      OR pt.PartTransaction LIKE '%INBOUND%'
      OR pt.PartTransaction LIKE '%INCOMING%'
  )
GROUP BY pt.PartTransaction
ORDER BY TransactionCount DESC;

-- =====================================================
-- 2. ANALYZE RO-RECEIVE SPECIFICALLY (REPAIR RECEIVING)
-- =====================================================

-- Detailed analysis of RO-RECEIVE operations
SELECT 
    'DELL RO-RECEIVE ANALYSIS' as AnalysisType,
    pt.Username as Operator,
    COUNT(*) as ReceiveTransactions,
    COUNT(DISTINCT pt.PartNo) as UniquePartsReceived,
    COUNT(DISTINCT pt.SerialNo) as UnitsReceived,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as OperatorPercent,
    MIN(pt.CreateDate) as FirstReceive,
    MAX(pt.CreateDate) as LastReceive
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.PartTransaction = 'RO-RECEIVE'
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
GROUP BY pt.Username
ORDER BY ReceiveTransactions DESC;

-- =====================================================
-- 3. ANALYZE WH-DISCREPANCYRECEIVE (WAREHOUSE RECEIVING)
-- =====================================================

-- Detailed analysis of WH-DISCREPANCYRECEIVE operations
SELECT 
    'DELL WH-DISCREPANCYRECEIVE ANALYSIS' as AnalysisType,
    pt.Username as Operator,
    COUNT(*) as DiscrepancyReceiveTransactions,
    COUNT(DISTINCT pt.PartNo) as UniquePartsReceived,
    COUNT(DISTINCT pt.SerialNo) as UnitsReceived,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as OperatorPercent,
    MIN(pt.CreateDate) as FirstReceive,
    MAX(pt.CreateDate) as LastReceive
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.PartTransaction = 'WH-DISCREPANCYRECEIVE'
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
GROUP BY pt.Username
ORDER BY DiscrepancyReceiveTransactions DESC;

-- =====================================================
-- 4. COMPARE RECEIVING VS OTHER OPERATIONS
-- =====================================================

-- Compare receiving operations to other major transaction types
SELECT 
    'DELL OPERATIONS COMPARISON' as AnalysisType,
    pt.PartTransaction as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT pt.Username), 2) as AvgTransactionsPerOperator
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN (
      'WH-MOVEPART',           -- Warehouse operations
      'WO-CONSUMECOMPONENTS',  -- Manufacturing
      'WO-ISSUEPART',          -- Manufacturing
      'SO-RESERVE',            -- Sales
      'SO-SHIP',               -- Sales
      'RO-RECEIVE',            -- Repair receiving
      'RO-CLOSE',              -- Repair closing
      'WH-DISCREPANCYRECEIVE'  -- Warehouse receiving
  )
GROUP BY pt.PartTransaction
ORDER BY TransactionCount DESC;

-- =====================================================
-- 5. HOURLY RECEIVING PERFORMANCE ANALYSIS
-- =====================================================

-- Analyze hourly performance for receiving operations
SELECT 
    'DELL RECEIVING HOURLY PERFORMANCE' as AnalysisType,
    pt.PartTransaction as TransactionType,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    COUNT(DISTINCT pt.Username) as ActiveOperators,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT pt.Username), 2) as AvgTransactionsPerOperator
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE')
GROUP BY pt.PartTransaction, DATEPART(hour, pt.CreateDate)
ORDER BY pt.PartTransaction, WorkHour;

-- =====================================================
-- 6. RECEIVING OPERATORS BY SPECIALIZATION
-- =====================================================

-- Find operators who do receiving work and their other specializations
SELECT 
    'DELL RECEIVING OPERATORS' as AnalysisType,
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
        AND pt2.PartTransaction IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE')
        AND pt2.CreateDate >= DATEADD(month, -3, GETDATE())
  )
GROUP BY pt.Username
ORDER BY TotalTransactions DESC;
























