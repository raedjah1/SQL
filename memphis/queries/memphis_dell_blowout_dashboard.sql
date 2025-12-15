-- =====================================================
-- DELL BLOW OUT MOVEMENT DASHBOARD
-- =====================================================
-- Purpose: Floor dashboard for blow out movement operations
-- Program: DELL (ProgramID: 10053) - Memphis
-- Targets: Green-32, Yellow-16, Red-<16
-- Transaction: WH-MOVEPART (363,127 transactions, 84% of movement)
-- =====================================================

-- Main query for Blow Out Movement dashboard
SELECT 
    'DELL BLOW OUT MOVEMENT DASHBOARD' as AnalysisType,
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    
    -- Target: 32 transactions/hour for blow out movement (management specified)
    ROUND(COUNT(*) * 100.0 / 32, 2) as PerformancePercentage,
    
    -- Color-coded KPI status (management targets)
    CASE 
        WHEN COUNT(*) >= 32 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 16 THEN 'YELLOW - Acceptable (50% of target)'
        ELSE 'RED - Below Target'
    END as KPI_Status,
    
    -- Specialization
    'BLOW OUT MOVEMENT' as SpecializationCategory,
    
    -- Date information
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATENAME(weekday, pt.CreateDate) as DayOfWeek,
    
    -- Additional metrics
    COUNT(DISTINCT pt.PartNo) as UniquePartsMoved,
    COUNT(DISTINCT pt.SerialNo) as UnitsMoved,
    
    -- Transaction type
    pt.PartTransaction as TransactionType,
    
    -- Location information for movement tracking
    pt.Location as FromLocation,
    
    -- Time details for filtering
    YEAR(pt.CreateDate) as Year,
    MONTH(pt.CreateDate) as Month,
    DAY(pt.CreateDate) as Day,
    DATEPART(weekday, pt.CreateDate) as DayOfWeekNumber

FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction = 'WH-MOVEPART'  -- Blow out movement operations
  AND pt.Location = 'INTRANSITTOMEXICO.ARB.MEM.OUT.STG'  -- Specific blow out location
GROUP BY 
    pt.Username, 
    DATEPART(hour, pt.CreateDate),
    CAST(pt.CreateDate as DATE),
    DATENAME(weekday, pt.CreateDate),
    pt.PartTransaction,
    pt.Location,
    YEAR(pt.CreateDate),
    MONTH(pt.CreateDate),
    DAY(pt.CreateDate),
    DATEPART(weekday, pt.CreateDate)
ORDER BY 
    pt.Username, 
    WorkHour;
