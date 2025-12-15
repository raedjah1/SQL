-- =====================================================
-- DELL WORKFORCE ANALYSIS - MEMPHIS SITE
-- =====================================================
-- Purpose: Analyze DELL program workforce performance and operations
-- Program: DELL (ProgramID: 10053)
-- Site: Memphis (AMER Region)
-- =====================================================

-- =====================================================
-- 1. DELL OPERATOR DISCOVERY & ACTIVITY ANALYSIS
-- =====================================================

-- Find all DELL operators and their activity levels
SELECT 
    'DELL OPERATOR DISCOVERY' as AnalysisType,
    pt.Username as Operator,
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT CAST(pt.CreateDate as DATE)) as ActiveDays,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    MIN(pt.CreateDate) as FirstActivity,
    MAX(pt.CreateDate) as LastActivity,
    DATEDIFF(day, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActivitySpanDays,
    -- Calculate average transactions per day
    CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT CAST(pt.CreateDate as DATE)), 0) AS DECIMAL(10,2)) as AvgTransactionsPerDay
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
GROUP BY pt.Username
ORDER BY TotalTransactions DESC;

-- =====================================================
-- 2. DELL TRANSACTION TYPE ANALYSIS
-- =====================================================

-- Analyze DELL transaction types and their distribution
SELECT 
    'DELL TRANSACTION TYPES' as AnalysisType,
    pt.PartTransaction as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent,
    -- Calculate average per operator
    CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT pt.Username), 0) AS DECIMAL(10,2)) as AvgPerOperator
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
GROUP BY pt.PartTransaction
ORDER BY TransactionCount DESC;

-- =====================================================
-- 3. DELL HOURLY PERFORMANCE ANALYSIS
-- =====================================================

-- DELL operator hourly performance (similar to ADT analysis)
SELECT 
    'DELL HOURLY PERFORMANCE' as AnalysisType,
    pt.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATEPART(HOUR, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActiveMinutes,
    -- KPI Status based on 80 transactions/hour target (same as ADT)
    CASE
        WHEN COUNT(*) >= 100 THEN 'GREEN - Excellent (125% of target)'
        WHEN COUNT(*) >= 80 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 64 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN COUNT(*) >= 40 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    -- Performance percentage
    CAST(COUNT(*) * 100.0 / 80 AS DECIMAL(5,1)) as PerformancePercentage
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, CAST(pt.CreateDate as DATE), DATEPART(HOUR, pt.CreateDate)
ORDER BY WorkDate DESC, WorkHour DESC, TransactionCount DESC;

-- =====================================================
-- 4. DELL WORKSTATION UTILIZATION
-- =====================================================

-- Analyze DELL workstation usage patterns
SELECT 
    'DELL WORKSTATION UTILIZATION' as AnalysisType,
    pt.WorkstationDescription as Workstation,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as UtilizationPercent,
    MIN(pt.CreateDate) as FirstActivity,
    MAX(pt.CreateDate) as LastActivity
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
  AND pt.WorkstationDescription IS NOT NULL
GROUP BY pt.WorkstationDescription
ORDER BY TransactionCount DESC;

-- =====================================================
-- 5. DELL DAILY PERFORMANCE TRENDS
-- =====================================================

-- DELL operator daily performance trends
SELECT 
    'DELL DAILY PERFORMANCE' as AnalysisType,
    pt.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    COUNT(*) as DailyTransactions,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    -- Calculate average transactions per hour for the day
    CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) AS DECIMAL(10,2)) as AvgTransactionsPerHour,
    -- Daily KPI Status
    CASE
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) AS DECIMAL(10,2)) >= 100 THEN 'GREEN - Excellent (125% of target)'
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) AS DECIMAL(10,2)) >= 80 THEN 'GREEN - Target Met'
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) AS DECIMAL(10,2)) >= 64 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) AS DECIMAL(10,2)) >= 40 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as DailyKPI_Status
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, CAST(pt.CreateDate as DATE)
HAVING DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) > 0
ORDER BY Operator, WorkDate;

-- =====================================================
-- 6. DELL QUALITY PERFORMANCE ANALYSIS
-- =====================================================

-- Analyze DELL quality-related transactions
SELECT 
    'DELL QUALITY ANALYSIS' as AnalysisType,
    pt.PartTransaction as TransactionType,
    pt.Condition as PartCondition,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN (
    'WO-SCRAP', 'WO-REPAIR', 'WO-HARVEST', 'WO-RTS', 
    'WO-CANCEL', 'WO-REOPEN', 'WH-DISCREPANCYRECEIVE'
  )
GROUP BY pt.PartTransaction, pt.Condition
ORDER BY TransactionCount DESC;

-- =====================================================
-- 7. DELL TOP PERFORMERS IDENTIFICATION
-- =====================================================

-- Identify top DELL performers for dashboard recognition
SELECT 
    'DELL TOP PERFORMERS' as AnalysisType,
    pt.Username as Operator,
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT CAST(pt.CreateDate as DATE)) as ActiveDays,
    CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT CAST(pt.CreateDate as DATE)), 0) AS DECIMAL(10,2)) as AvgTransactionsPerDay,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    -- Performance rating
    CASE
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT CAST(pt.CreateDate as DATE)), 0) AS DECIMAL(10,2)) >= 200 THEN 'EXCELLENT - Training Candidate'
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT CAST(pt.CreateDate as DATE)), 0) AS DECIMAL(10,2)) >= 150 THEN 'VERY GOOD - High Performer'
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT CAST(pt.CreateDate as DATE)), 0) AS DECIMAL(10,2)) >= 100 THEN 'GOOD - Solid Performer'
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT CAST(pt.CreateDate as DATE)), 0) AS DECIMAL(10,2)) >= 50 THEN 'ACCEPTABLE - Needs Improvement'
        ELSE 'NEEDS ATTENTION - Coaching Required'
    END as PerformanceRating
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Username IS NOT NULL
GROUP BY pt.Username
ORDER BY AvgTransactionsPerDay DESC;
