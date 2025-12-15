-- =====================================================
-- DELL PUTAWAY DASHBOARD
-- =====================================================
-- Purpose: Floor dashboard for putaway operations
-- Program: DELL (ProgramID: 10053) - Memphis
-- Targets: Green-35, Yellow-17, Red-<17
-- =====================================================

SELECT 
    'DELL PUTAWAY DASHBOARD' as AnalysisType,
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    
    -- Target: 35 transactions/hour for putaway
    ROUND(COUNT(*) * 100.0 / 35, 2) as PerformancePercentage,
    
    -- Color-coded KPI status (management targets)
    CASE 
        WHEN COUNT(*) >= 35 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 17 THEN 'YELLOW - Acceptable (49% of target)'
        ELSE 'RED - Below Target'
    END as KPI_Status,
    
    -- Specialization
    'PUTAWAY OPERATIONS' as SpecializationCategory,
    
    -- Date information
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATENAME(weekday, pt.CreateDate) as DayOfWeek,
    
    -- Additional metrics
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    
    -- Transaction type
    pt.PartTransaction as TransactionType

FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction = 'WH-MOVEPART'  -- Putaway operations
GROUP BY 
    pt.Username, 
    DATEPART(hour, pt.CreateDate),
    CAST(pt.CreateDate as DATE),
    DATENAME(weekday, pt.CreateDate),
    pt.PartTransaction
ORDER BY 
    pt.Username, 
    WorkHour;








































