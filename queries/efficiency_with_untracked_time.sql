-- =====================================================
-- EFFICIENCY ANALYSIS WITH UNTRACKED TIME IDENTIFICATION
-- =====================================================
-- Step-by-step approach to identify gaps in operator activity

-- STEP 1: Add transaction-level time gap analysis
WITH TransactionGaps AS (
    SELECT 
        Username,
        CreateDate,
        DATEPART(HOUR, CreateDate) as Hour,
        CAST(CreateDate AS DATE) as Date,
        PartTransaction,
        
        -- CALCULATE TIME GAPS BETWEEN CONSECUTIVE TRANSACTIONS
        LAG(CreateDate) OVER (PARTITION BY Username, CAST(CreateDate AS DATE), DATEPART(HOUR, CreateDate) ORDER BY CreateDate) as PreviousTransaction,
        
        DATEDIFF(SECOND, 
            LAG(CreateDate) OVER (PARTITION BY Username, CAST(CreateDate AS DATE), DATEPART(HOUR, CreateDate) ORDER BY CreateDate),
            CreateDate
        ) as SecondsFromPreviousTransaction,
        
        -- FLAG SIGNIFICANT GAPS (>5 minutes = 300 seconds)
        CASE 
            WHEN DATEDIFF(SECOND, 
                LAG(CreateDate) OVER (PARTITION BY Username, CAST(CreateDate AS DATE), DATEPART(HOUR, CreateDate) ORDER BY CreateDate),
                CreateDate) > 300 THEN 1
            ELSE 0
        END as HasSignificantGap,
        
        -- CALCULATE GAP DURATION
        CASE 
            WHEN DATEDIFF(SECOND, 
                LAG(CreateDate) OVER (PARTITION BY Username, CAST(CreateDate AS DATE), DATEPART(HOUR, CreateDate) ORDER BY CreateDate),
                CreateDate) > 300 
            THEN DATEDIFF(SECOND, 
                LAG(CreateDate) OVER (PARTITION BY Username, CAST(CreateDate AS DATE), DATEPART(HOUR, CreateDate) ORDER BY CreateDate),
                CreateDate) - 300  -- Subtract 5min buffer
            ELSE 0
        END as UntrackedSeconds
        
    FROM pls.vPartTransaction 
    WHERE ProgramID = '10053' 
      AND Username IS NOT NULL
      AND CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
),

-- STEP 2: Aggregate untracked time per operator per hour
HourlyUntrackedTime AS (
    SELECT 
        Username,
        Date,
        Hour,
        COUNT(*) as TransactionCount,
        MIN(CreateDate) as FirstTransaction,
        MAX(CreateDate) as LastTransaction,
        
        -- CURRENT METHOD (MIN to MAX span)
        DATEDIFF(MINUTE, MIN(CreateDate), MAX(CreateDate)) as TotalMinutesSpan,
        
        -- NEW METHOD (Sum of gaps)
        SUM(UntrackedSeconds) / 60.0 as UntrackedMinutes,
        
        -- ACTUAL WORKING TIME (Span minus gaps)
        DATEDIFF(MINUTE, MIN(CreateDate), MAX(CreateDate)) - (SUM(UntrackedSeconds) / 60.0) as EstimatedWorkingMinutes,
        
        -- GAP ANALYSIS
        SUM(HasSignificantGap) as NumberOfGaps,
        AVG(CASE WHEN SecondsFromPreviousTransaction > 0 THEN SecondsFromPreviousTransaction END) / 60.0 as AvgMinutesBetweenTransactions,
        
        -- TIME UTILIZATION
        CASE 
            WHEN DATEDIFF(MINUTE, MIN(CreateDate), MAX(CreateDate)) > 0 
            THEN ((DATEDIFF(MINUTE, MIN(CreateDate), MAX(CreateDate)) - (SUM(UntrackedSeconds) / 60.0)) / 
                  DATEDIFF(MINUTE, MIN(CreateDate), MAX(CreateDate))) * 100
            ELSE 100
        END as TimeUtilizationPercentage
        
    FROM TransactionGaps
    GROUP BY Username, Date, Hour
),

-- STEP 3: Calculate efficiency using ACTUAL working time
CorrectedEfficiency AS (
    SELECT 
        *,
        
        -- OLD EFFICIENCY (using total span)
        CASE 
            WHEN TotalMinutesSpan > 0 
            THEN CAST(TransactionCount AS FLOAT) / TotalMinutesSpan * 60 
            ELSE TransactionCount 
        END as OldTransactionsPerHour,
        
        -- NEW EFFICIENCY (using actual working time)
        CASE 
            WHEN EstimatedWorkingMinutes > 0 
            THEN CAST(TransactionCount AS FLOAT) / EstimatedWorkingMinutes * 60 
            ELSE TransactionCount 
        END as CorrectedTransactionsPerHour,
        
        -- EFFICIENCY IMPROVEMENT
        CASE 
            WHEN TotalMinutesSpan > 0 AND EstimatedWorkingMinutes > 0
            THEN ((CAST(TransactionCount AS FLOAT) / EstimatedWorkingMinutes * 60) - 
                  (CAST(TransactionCount AS FLOAT) / TotalMinutesSpan * 60))
            ELSE 0
        END as EfficiencyImprovement
        
    FROM HourlyUntrackedTime
    WHERE TransactionCount >= 5  -- Filter out low-activity hours
)

-- FINAL OUTPUT: Efficiency with untracked time analysis
SELECT 
    Username,
    Date,
    Hour,
    TransactionCount,
    
    -- TIME ANALYSIS
    TotalMinutesSpan,
    UntrackedMinutes,
    EstimatedWorkingMinutes,
    TimeUtilizationPercentage,
    
    -- GAP ANALYSIS  
    NumberOfGaps,
    AvgMinutesBetweenTransactions,
    
    -- EFFICIENCY COMPARISON
    ROUND(OldTransactionsPerHour, 1) as OldEfficiency,
    ROUND(CorrectedTransactionsPerHour, 1) as CorrectedEfficiency,
    ROUND(EfficiencyImprovement, 1) as EfficiencyGain,
    
    -- PERFORMANCE INDICATORS
    CASE 
        WHEN CorrectedTransactionsPerHour >= 40 THEN 'HIGH - Excellent'
        WHEN CorrectedTransactionsPerHour >= 25 THEN 'GOOD - Above Target'  
        WHEN CorrectedTransactionsPerHour >= 15 THEN 'FAIR - Below Target'
        ELSE 'LOW - Needs Improvement'
    END as CorrectedPerformanceLevel
    
FROM CorrectedEfficiency
ORDER BY Date DESC, Hour DESC, CorrectedTransactionsPerHour DESC;






