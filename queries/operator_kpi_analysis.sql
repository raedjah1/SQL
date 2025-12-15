-- ============================================
-- OPERATOR KPI ANALYSIS - HOURLY OUTPUT TRACKING
-- ============================================
-- Track operator performance, hourly output, and green/red status
-- Based on part transactions data in Clarity

-- ============================================
-- 1. OPERATOR HOURLY OUTPUT SUMMARY
-- ============================================
-- Shows each operator's hourly transaction volume
SELECT TOP 100
    pt.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATEPART(HOUR, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActiveMinutes
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, CAST(pt.CreateDate as DATE), DATEPART(HOUR, pt.CreateDate)
ORDER BY WorkDate DESC, WorkHour DESC, TransactionCount DESC;

-- ============================================
-- 2. DAILY OPERATOR PERFORMANCE WITH KPI STATUS
-- ============================================
-- Shows daily performance with green/red status based on thresholds
WITH DailyOperatorStats AS (
    SELECT 
        pt.Username as Operator,
        CAST(pt.CreateDate as DATE) as WorkDate,
        COUNT(*) as DailyTransactions,
        COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
        COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
        COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT DATEPART(HOUR, pt.CreateDate)), 0) as AvgTransactionsPerHour,
        MIN(pt.CreateDate) as StartTime,
        MAX(pt.CreateDate) as EndTime,
        DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1 as HoursWorked
    FROM pls.vPartTransaction pt
    WHERE pt.CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
      AND pt.Username IS NOT NULL
    GROUP BY pt.Username, CAST(pt.CreateDate as DATE)
)
SELECT TOP 100
    Operator,
    WorkDate,
    DailyTransactions,
    UnitsProcessed,
    HoursWorked,
    CAST(AvgTransactionsPerHour AS DECIMAL(8,2)) as TransactionsPerHour,
    -- KPI Status Logic (Engineering Target: 80/hour = 600 per 7.5 hours)
    CASE 
        WHEN AvgTransactionsPerHour >= 100 THEN 'GREEN - Excellent (125% of target)'
        WHEN AvgTransactionsPerHour >= 80 THEN 'GREEN - Target Met'
        WHEN AvgTransactionsPerHour >= 64 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN AvgTransactionsPerHour >= 40 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    -- Performance Rating (1-5 scale)
    CASE 
        WHEN AvgTransactionsPerHour >= 100 THEN 5  -- 125%+ of target
        WHEN AvgTransactionsPerHour >= 80 THEN 4   -- 100% of target
        WHEN AvgTransactionsPerHour >= 64 THEN 3   -- 80% of target
        WHEN AvgTransactionsPerHour >= 40 THEN 2   -- 50% of target
        ELSE 1                                     -- Below 50%
    END as PerformanceRating
FROM DailyOperatorStats
ORDER BY WorkDate DESC, AvgTransactionsPerHour DESC;

-- ============================================
-- 3. REAL-TIME HOURLY PERFORMANCE DASHBOARD
-- ============================================
-- Current day hourly breakdown with live KPI status
SELECT TOP 100
    pt.Username as Operator,
    DATEPART(HOUR, pt.CreateDate) as Hour,
    COUNT(*) as HourlyTransactions,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    -- Real-time KPI status (Target: 80/hour)
    CASE 
        WHEN COUNT(*) >= 100 THEN 'GREEN - Excellent'
        WHEN COUNT(*) >= 80 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 64 THEN 'YELLOW - Acceptable'
        WHEN COUNT(*) >= 40 THEN 'RED - Below Target'
        ELSE 'RED - Critical'
    END as HourlyKPI_Status,
    MIN(pt.CreateDate) as HourStart,
    MAX(pt.CreateDate) as HourEnd
FROM pls.vPartTransaction pt
WHERE CAST(pt.CreateDate as DATE) = CAST(GETDATE() as DATE)  -- Today only
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, DATEPART(HOUR, pt.CreateDate)
ORDER BY Hour DESC, HourlyTransactions DESC;

-- ============================================
-- 4. OPERATOR RANKING AND BENCHMARKING
-- ============================================
-- Ranks operators by performance over last 7 days
WITH OperatorPerformance AS (
    SELECT 
        pt.Username as Operator,
        COUNT(*) as TotalTransactions,
        COUNT(DISTINCT CAST(pt.CreateDate as DATE)) as DaysWorked,
        COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT CAST(pt.CreateDate as DATE)), 0) as AvgDailyTransactions,
        COUNT(DISTINCT pt.PartNo) as PartVariety,
        COUNT(DISTINCT pt.SerialNo) as TotalUnitsProcessed
    FROM pls.vPartTransaction pt
    WHERE pt.CreateDate >= DATEADD(day, -7, GETDATE())
      AND pt.Username IS NOT NULL
    GROUP BY pt.Username
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY AvgDailyTransactions DESC) as Rank,
    Operator,
    TotalTransactions,
    DaysWorked,
    CAST(AvgDailyTransactions AS DECIMAL(8,2)) as AvgDailyTransactions,
    TotalUnitsProcessed,
    PartVariety,
    -- Performance tier
    CASE 
        WHEN AvgDailyTransactions >= 300 THEN 'TOP PERFORMER'
        WHEN AvgDailyTransactions >= 200 THEN 'HIGH PERFORMER'
        WHEN AvgDailyTransactions >= 100 THEN 'AVERAGE PERFORMER'
        ELSE 'NEEDS IMPROVEMENT'
    END as PerformanceTier
FROM OperatorPerformance
WHERE DaysWorked >= 3  -- Only operators who worked at least 3 days
ORDER BY AvgDailyTransactions DESC;

-- ============================================
-- 5. SHIFT ANALYSIS AND PRODUCTIVITY PATTERNS
-- ============================================
-- Analyzes productivity by shift and time of day
SELECT 
    pt.Username as Operator,
    CASE 
        WHEN DATEPART(HOUR, pt.CreateDate) BETWEEN 6 AND 14 THEN 'Day Shift (6AM-2PM)'
        WHEN DATEPART(HOUR, pt.CreateDate) BETWEEN 14 AND 22 THEN 'Evening Shift (2PM-10PM)'  
        ELSE 'Night Shift (10PM-6AM)'
    END as Shift,
    DATEPART(HOUR, pt.CreateDate) as Hour,
    COUNT(*) as Transactions,
    COUNT(DISTINCT CAST(pt.CreateDate as DATE)) as DaysWorked,
    CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT CAST(pt.CreateDate as DATE)), 0) AS DECIMAL(8,2)) as AvgTransactionsPerDay
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= DATEADD(day, -14, GETDATE())
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, 
         CASE 
             WHEN DATEPART(HOUR, pt.CreateDate) BETWEEN 6 AND 14 THEN 'Day Shift (6AM-2PM)'
             WHEN DATEPART(HOUR, pt.CreateDate) BETWEEN 14 AND 22 THEN 'Evening Shift (2PM-10PM)'  
             ELSE 'Night Shift (10PM-6AM)'
         END,
         DATEPART(HOUR, pt.CreateDate)
ORDER BY Operator, Hour;

-- ============================================
-- 6. QUALITY AND ERROR TRACKING (IF AVAILABLE)
-- ============================================
-- Links part transactions to quality results if possible
SELECT 
    pt.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    COUNT(*) as TotalTransactions,
    -- If you have quality data linked to part transactions
    COUNT(CASE WHEN wh.IsPass = 1 THEN 1 END) as PassedUnits,
    COUNT(CASE WHEN wh.IsPass = 0 THEN 1 END) as FailedUnits,
    CASE 
        WHEN COUNT(CASE WHEN wh.IsPass = 0 THEN 1 END) = 0 THEN 'GREEN - No Failures'
        WHEN COUNT(CASE WHEN wh.IsPass = 0 THEN 1 END) * 100.0 / COUNT(*) <= 2 THEN 'GREEN - Low Error Rate'
        WHEN COUNT(CASE WHEN wh.IsPass = 0 THEN 1 END) * 100.0 / COUNT(*) <= 5 THEN 'YELLOW - Moderate Error Rate'
        ELSE 'RED - High Error Rate'
    END as QualityStatus
FROM pls.vPartTransaction pt
LEFT JOIN pls.vWOStationHistory wh ON pt.SerialNo = wh.SerialNo 
    AND CAST(pt.CreateDate as DATE) = CAST(wh.CreateDate as DATE)
WHERE pt.CreateDate >= DATEADD(day, -7, GETDATE())
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, CAST(pt.CreateDate as DATE)
ORDER BY WorkDate DESC, TotalTransactions DESC;

-- ============================================
-- 7. POWER BI FRIENDLY SUMMARY FOR DASHBOARDS
-- ============================================
-- Optimized for Power BI visualization
SELECT 
    pt.Username as Operator,
    CAST(pt.CreateDate as DATE) as Date,
    DATEPART(HOUR, pt.CreateDate) as Hour,
    DATENAME(WEEKDAY, pt.CreateDate) as DayOfWeek,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    COUNT(DISTINCT pt.PartNo) as PartTypes,
    -- KPI Metrics
    CASE WHEN COUNT(*) >= 50 THEN 1 ELSE 0 END as IsGreenHour,
    CASE WHEN COUNT(*) < 15 THEN 1 ELSE 0 END as IsRedHour,
    -- Performance Score (1-100)
    CASE 
        WHEN COUNT(*) >= 75 THEN 100
        WHEN COUNT(*) >= 50 THEN 85
        WHEN COUNT(*) >= 30 THEN 70
        WHEN COUNT(*) >= 15 THEN 50
        ELSE 25
    END as PerformanceScore
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= DATEADD(day, -30, GETDATE())
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, CAST(pt.CreateDate as DATE), DATEPART(HOUR, pt.CreateDate), DATENAME(WEEKDAY, pt.CreateDate)
ORDER BY Date DESC, Hour DESC;

-- ============================================
-- CUSTOMIZATION NOTES
-- ============================================
/*
ADJUST THESE THRESHOLDS BASED ON YOUR STANDARDS:
- Green Performance: >= 50 transactions/hour
- Yellow Performance: 20-49 transactions/hour  
- Red Performance: < 20 transactions/hour

POSSIBLE ENHANCEMENTS:
1. Add shift differentials
2. Include part complexity weighting
3. Factor in break times
4. Add overtime calculations
5. Include quality metrics
6. Track training/certification status

FOR POWER BI:
- Use query #7 as your main data source
- Create calculated measures for targets
- Build drill-down from daily to hourly
- Add operator photos and details
- Create alerts for red performance
*/
