-- =====================================================
-- DELL PICK DASHBOARD
-- =====================================================
-- Purpose: Floor dashboard for pick operations
-- Program: DELL (ProgramID: 10053) - Memphis
-- Targets: Green-30, Yellow-15, Red-<15
-- =====================================================

SELECT 
    'DELL PICK DASHBOARD' as AnalysisType,
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    
    -- Target: 30 transactions/hour for pick
    ROUND(COUNT(*) * 100.0 / 30, 2) as PerformancePercentage,
    
    -- Color-coded KPI status (management targets)
    CASE 
        WHEN COUNT(*) >= 30 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 15 THEN 'YELLOW - Acceptable (50% of target)'
        ELSE 'RED - Below Target'
    END as KPI_Status,
    
    -- Specialization
    'PICK OPERATIONS' as SpecializationCategory,
    
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
  AND pt.PartTransaction IN ('WO-ISSUEPART', 'WO-CONSUMECOMPONENTS')  -- Pick operations
GROUP BY 
    pt.Username, 
    DATEPART(hour, pt.CreateDate),
    CAST(pt.CreateDate as DATE),
    DATENAME(weekday, pt.CreateDate),
    pt.PartTransaction
ORDER BY 
    pt.Username, 
    WorkHour;








































