-- =====================================================
-- DELL BLOW OUT MOVEMENT VERIFICATION
-- =====================================================
-- Purpose: Verify blow out movement data and operators
-- Program: DELL (ProgramID: 10053) - Memphis
-- Location: INTRANSITTOMEXICO.ARB.MEM.OUT.STG
-- =====================================================

-- =====================================================
-- 1. VERIFY BLOW OUT LOCATION DATA
-- =====================================================

-- Check the specific blow out location data
SELECT 
    'BLOW OUT LOCATION VERIFICATION' as AnalysisType,
    pt.Location as BlowOutLocation,
    pt.PartTransaction as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    MIN(pt.CreateDate) as FirstOccurrence,
    MAX(pt.CreateDate) as LastOccurrence,
    DATEDIFF(day, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActivitySpanDays
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Location = 'INTRANSITTOMEXICO.ARB.MEM.OUT.STG'  -- Blow out location
GROUP BY pt.Location, pt.PartTransaction
ORDER BY TransactionCount DESC;

-- =====================================================
-- 2. VERIFY BLOW OUT OPERATORS
-- =====================================================

-- Find operators working at blow out location
SELECT 
    'BLOW OUT OPERATORS' as AnalysisType,
    pt.Username as Operator,
    COUNT(*) as BlowOutTransactions,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    MIN(pt.CreateDate) as FirstBlowOut,
    MAX(pt.CreateDate) as LastBlowOut,
    DATEDIFF(day, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActivitySpanDays
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Location = 'INTRANSITTOMEXICO.ARB.MEM.OUT.STG'  -- Blow out location
  AND pt.Username IS NOT NULL
GROUP BY pt.Username
ORDER BY BlowOutTransactions DESC;

-- =====================================================
-- 3. VERIFY BLOW OUT HOURLY PATTERNS
-- =====================================================

-- Check hourly patterns for blow out operations
SELECT 
    'BLOW OUT HOURLY PATTERNS' as AnalysisType,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    COUNT(DISTINCT pt.Username) as ActiveOperators,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT pt.Username), 2) as AvgTransactionsPerOperator
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Location = 'INTRANSITTOMEXICO.ARB.MEM.OUT.STG'  -- Blow out location
  AND pt.Username IS NOT NULL
GROUP BY DATEPART(hour, pt.CreateDate)
ORDER BY WorkHour;

-- =====================================================
-- 4. VERIFY BLOW OUT RECENT ACTIVITY
-- =====================================================

-- Check recent blow out activity (last 7 days)
SELECT 
    'BLOW OUT RECENT ACTIVITY' as AnalysisType,
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATENAME(weekday, pt.CreateDate) as DayOfWeek,
    COUNT(*) as DailyTransactions,
    COUNT(DISTINCT pt.Username) as ActiveOperators,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT pt.Username), 2) as AvgTransactionsPerOperator
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Location = 'INTRANSITTOMEXICO.ARB.MEM.OUT.STG'  -- Blow out location
  AND pt.Username IS NOT NULL
GROUP BY CAST(pt.CreateDate as DATE), DATENAME(weekday, pt.CreateDate)
ORDER BY WorkDate DESC;

-- =====================================================
-- 5. VERIFY BLOW OUT TARGET FEASIBILITY
-- =====================================================

-- Check if 32 transactions/hour target is realistic
SELECT 
    'BLOW OUT TARGET FEASIBILITY' as AnalysisType,
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    CASE 
        WHEN COUNT(*) >= 32 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 16 THEN 'YELLOW - Acceptable'
        ELSE 'RED - Below Target'
    END as PerformanceStatus
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Location = 'INTRANSITTOMEXICO.ARB.MEM.OUT.STG'  -- Blow out location
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, DATEPART(hour, pt.CreateDate)
ORDER BY pt.Username, WorkHour;
