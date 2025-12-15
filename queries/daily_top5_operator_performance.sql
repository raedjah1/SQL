-- =====================================================
-- DAILY TOP 5 OPERATOR PERFORMANCE LEADERBOARD
-- =====================================================
-- Companion query to hourly performance analysis
-- Aggregates hourly data to daily totals with ranking
-- Compatible with same date slicers and process filters

WITH DailyOperatorPerformance AS (
    SELECT 
        u.Username as Operator,
        CAST(pt.CreateDate as DATE) as WorkDate,
        
        -- CUSTOMER CATEGORY FOR SLICER (Same logic as hourly query)
        CASE
            WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
            WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
            ELSE 'FSR'
        END as CustomerCategory,
        
        -- DAILY AGGREGATED METRICS
        COUNT(*) as DailyTransactionCount,
        COUNT(DISTINCT pt.PartNo) as DailyUniquePartsHandled,
        COUNT(DISTINCT pt.SerialNo) as DailyUnitsProcessed,
        COUNT(DISTINCT DATEPART(HOUR, pt.CreateDate)) as ActiveHours,
        
        -- TIME SPAN METRICS
        MIN(pt.CreateDate) as FirstTransaction,
        MAX(pt.CreateDate) as LastTransaction,
        DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as TotalActiveMinutes,
        
        -- CALCULATE DAILY TARGET (Sum of hourly targets based on actual hours worked)
        SUM(
            CASE
                -- ECR Thresholds (Ultra-High - ~250/hour baseline)
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 125
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 195
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 195
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' THEN 250
                
                -- FSR Thresholds (Original targets)
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 19
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 29
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 29
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' THEN 38
                
                -- No Customer Reference Thresholds (Lower targets)
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 15
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 22
                WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 22
                ELSE 30
            END
        ) as DailyTarget
        
    FROM Plus.pls.PartTransaction pt
    JOIN Plus.pls.[User] u ON u.ID = pt.UserID
    JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    WHERE pt.CreateDate >= DATEADD(day, -7, GETDATE())
      AND u.Username IS NOT NULL
      AND pt.ProgramID = 10068
      AND cpt.Description = 'RO-RECEIVE'
    GROUP BY 
        u.Username, 
        CAST(pt.CreateDate as DATE),
        CASE
            WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
            WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
            ELSE 'FSR'
        END
),

RankedPerformance AS (
    SELECT 
        *,
        -- PERFORMANCE CALCULATIONS
        CAST(DailyTransactionCount * 100.0 / NULLIF(DailyTarget, 0) AS DECIMAL(10,2)) as DailyPerformancePercentage,
        CAST(DailyTransactionCount * 1.0 / NULLIF(ActiveHours, 0) AS DECIMAL(10,2)) as AvgTransactionsPerHour,
        
        -- DAILY KPI STATUS
        CASE
            WHEN DailyTransactionCount >= DailyTarget THEN 'GREEN - Daily Target Met'
            WHEN DailyTransactionCount >= (DailyTarget * 0.8) THEN 'YELLOW - Close to Target'
            ELSE 'RED - Below Target'
        END as DailyKPI_Status,
        
        -- RANKING BY TRANSACTION COUNT (Primary metric)
        ROW_NUMBER() OVER (
            PARTITION BY WorkDate, CustomerCategory 
            ORDER BY DailyTransactionCount DESC, DailyPerformancePercentage DESC
        ) as DailyRank_ByVolume,
        
        -- RANKING BY PERFORMANCE PERCENTAGE
        ROW_NUMBER() OVER (
            PARTITION BY WorkDate, CustomerCategory 
            ORDER BY CAST(DailyTransactionCount * 100.0 / NULLIF(DailyTarget, 0) AS DECIMAL(10,2)) DESC, DailyTransactionCount DESC
        ) as DailyRank_ByPercentage,
        
        -- OVERALL RANKING (ALL PROCESSES COMBINED)
        ROW_NUMBER() OVER (
            PARTITION BY WorkDate 
            ORDER BY DailyTransactionCount DESC, CAST(DailyTransactionCount * 100.0 / NULLIF(DailyTarget, 0) AS DECIMAL(10,2)) DESC
        ) as OverallDailyRank
        
    FROM DailyOperatorPerformance
)

-- FINAL OUTPUT: TOP 5 PERFORMERS
SELECT 
    Operator,
    WorkDate,
    CustomerCategory,
    DailyTransactionCount,
    DailyUniquePartsHandled,
    DailyUnitsProcessed,
    ActiveHours,
    FirstTransaction,
    LastTransaction,
    TotalActiveMinutes,
    DailyTarget,
    DailyPerformancePercentage,
    AvgTransactionsPerHour,
    DailyKPI_Status,
    
    -- RANKING INFORMATION
    DailyRank_ByVolume as ProcessRank,
    OverallDailyRank,
    
    -- PERFORMANCE INDICATORS
    CASE 
        WHEN OverallDailyRank = 1 THEN '🥇 #1 - Top Performer'
        WHEN OverallDailyRank = 2 THEN '🥈 #2 - Excellent'
        WHEN OverallDailyRank = 3 THEN '🥉 #3 - Great Work'
        WHEN OverallDailyRank = 4 THEN '⭐ #4 - Strong Performance'
        WHEN OverallDailyRank = 5 THEN '⭐ #5 - Good Performance'
        ELSE CAST(OverallDailyRank as VARCHAR(3))
    END as PerformanceBadge
    
FROM RankedPerformance
WHERE OverallDailyRank <= 5  -- TOP 5 ONLY
ORDER BY WorkDate DESC, OverallDailyRank ASC;

-- =====================================================
-- USAGE NOTES:
-- =====================================================
-- 1. Use same date slicer as hourly query
-- 2. Filter by CustomerCategory for process-specific top 5
-- 3. OverallDailyRank shows top 5 across all processes
-- 4. ProcessRank shows top 5 within each process type
-- 5. Performance badges provide visual hierarchy
-- =====================================================
