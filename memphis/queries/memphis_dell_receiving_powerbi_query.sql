-- =====================================================
-- DELL RECEIVING DASHBOARD - POWER BI QUERY
-- =====================================================
-- Purpose: Ready-to-use query for Power BI dashboard
-- Program: DELL (ProgramID: 10053) - Memphis
-- Target: Floor supervisors and receiving operators
-- =====================================================

-- Main query for Power BI dashboard
SELECT 
    'DELL RECEIVING DASHBOARD' as AnalysisType,
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    
    -- Calculate performance percentage based on management targets
    -- Target: 25 transactions/hour for receiving (management specified)
    ROUND(COUNT(*) * 100.0 / 25, 2) as PerformancePercentage,
    
    -- Color-coded KPI status (management targets)
    CASE 
        WHEN COUNT(*) >= 25 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 12 THEN 'YELLOW - Acceptable (48% of target)'
        ELSE 'RED - Below Target'
    END as KPI_Status,
    
    -- Receiving specialization
    'RECEIVING OPERATIONS' as SpecializationCategory,
    
    -- Date information
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATENAME(weekday, pt.CreateDate) as DayOfWeek,
    
    -- Additional metrics
    COUNT(DISTINCT pt.PartNo) as UniquePartsReceived,
    COUNT(DISTINCT pt.SerialNo) as UnitsReceived,
    
    -- Transaction type breakdown
    pt.PartTransaction as TransactionType,
    
    -- Time details for filtering
    YEAR(pt.CreateDate) as Year,
    MONTH(pt.CreateDate) as Month,
    DAY(pt.CreateDate) as Day,
    DATEPART(weekday, pt.CreateDate) as DayOfWeekNumber

FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days for better analysis
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE')  -- Receiving operations
GROUP BY 
    pt.Username, 
    DATEPART(hour, pt.CreateDate),
    CAST(pt.CreateDate as DATE),
    DATENAME(weekday, pt.CreateDate),
    pt.PartTransaction,
    YEAR(pt.CreateDate),
    MONTH(pt.CreateDate),
    DAY(pt.CreateDate),
    DATEPART(weekday, pt.CreateDate)
ORDER BY 
    pt.Username, 
    WorkHour;
