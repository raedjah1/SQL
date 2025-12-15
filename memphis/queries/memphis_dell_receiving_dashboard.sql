-- =====================================================
-- DELL RECEIVING OPERATIONS DASHBOARD
-- =====================================================
-- Purpose: Floor dashboard for receiving operations with color coding
-- Program: DELL (ProgramID: 10053) - Memphis
-- Target: Floor supervisors and receiving operators
-- =====================================================

-- =====================================================
-- 1. RECEIVING HOURLY PERFORMANCE DASHBOARD
-- =====================================================

-- Main receiving performance query with color coding
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
    COUNT(DISTINCT pt.SerialNo) as UnitsReceived

FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE')  -- Receiving operations
GROUP BY 
    pt.Username, 
    DATEPART(hour, pt.CreateDate),
    CAST(pt.CreateDate as DATE),
    DATENAME(weekday, pt.CreateDate)
ORDER BY 
    pt.Username, 
    WorkHour;

-- =====================================================
-- 2. RECEIVING OPERATOR SUMMARY DASHBOARD
-- =====================================================

-- Summary view for floor supervisors
SELECT 
    'DELL RECEIVING SUMMARY' as AnalysisType,
    pt.Username as Operator,
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT CAST(pt.CreateDate as DATE)) as ActiveDays,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT CAST(pt.CreateDate as DATE)), 2) as AvgTransactionsPerDay,
    ROUND(COUNT(*) * 1.0 / (COUNT(DISTINCT CAST(pt.CreateDate as DATE)) * 8), 2) as AvgTransactionsPerHour,
    
    -- Performance status based on daily average (realistic targets)
    CASE 
        WHEN ROUND(COUNT(*) * 1.0 / (COUNT(DISTINCT CAST(pt.CreateDate as DATE)) * 8), 2) >= 20 THEN 'GREEN - High Performer'
        WHEN ROUND(COUNT(*) * 1.0 / (COUNT(DISTINCT CAST(pt.CreateDate as DATE)) * 8), 2) >= 15 THEN 'YELLOW - Good Performer'
        WHEN ROUND(COUNT(*) * 1.0 / (COUNT(DISTINCT CAST(pt.CreateDate as DATE)) * 8), 2) >= 10 THEN 'RED - Needs Improvement'
        ELSE 'RED - Critical Performance'
    END as PerformanceStatus,
    
    -- Receiving breakdown
    SUM(CASE WHEN pt.PartTransaction = 'RO-RECEIVE' THEN 1 ELSE 0 END) as RO_Receive_Count,
    SUM(CASE WHEN pt.PartTransaction = 'WH-DISCREPANCYRECEIVE' THEN 1 ELSE 0 END) as WH_Discrepancy_Count,
    
    -- Date range
    MIN(pt.CreateDate) as FirstActivity,
    MAX(pt.CreateDate) as LastActivity

FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE')  -- Receiving operations
GROUP BY pt.Username
ORDER BY TotalTransactions DESC;

-- =====================================================
-- 3. RECEIVING HOURLY TRENDS DASHBOARD
-- =====================================================

-- Hourly trends for floor management
SELECT 
    'DELL RECEIVING TRENDS' as AnalysisType,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT pt.Username) as ActiveOperators,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT pt.Username), 2) as AvgTransactionsPerOperator,
    
    -- Hourly performance status (realistic targets)
    CASE 
        WHEN ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT pt.Username), 2) >= 20 THEN 'GREEN - Peak Performance'
        WHEN ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT pt.Username), 2) >= 15 THEN 'YELLOW - Good Performance'
        WHEN ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT pt.Username), 2) >= 10 THEN 'RED - Below Target'
        ELSE 'RED - Critical Performance'
    END as HourlyStatus,
    
    -- Receiving breakdown by hour
    SUM(CASE WHEN pt.PartTransaction = 'RO-RECEIVE' THEN 1 ELSE 0 END) as RO_Receive_Count,
    SUM(CASE WHEN pt.PartTransaction = 'WH-DISCREPANCYRECEIVE' THEN 1 ELSE 0 END) as WH_Discrepancy_Count

FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE')  -- Receiving operations
GROUP BY DATEPART(hour, pt.CreateDate)
ORDER BY WorkHour;

-- =====================================================
-- 4. RECEIVING QUALITY METRICS DASHBOARD
-- =====================================================

-- Quality and efficiency metrics for receiving
SELECT 
    'DELL RECEIVING QUALITY' as AnalysisType,
    pt.Username as Operator,
    pt.PartTransaction as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    
    -- Quality metrics
    ROUND(COUNT(DISTINCT pt.PartNo) * 100.0 / COUNT(*), 2) as PartDiversityPercentage,
    ROUND(COUNT(DISTINCT pt.SerialNo) * 100.0 / COUNT(*), 2) as SerializationPercentage,
    
    -- Performance status (realistic targets)
    CASE 
        WHEN COUNT(*) >= 20 THEN 'GREEN - High Volume'
        WHEN COUNT(*) >= 15 THEN 'YELLOW - Good Volume'
        WHEN COUNT(*) >= 10 THEN 'RED - Low Volume'
        ELSE 'RED - Critical Volume'
    END as VolumeStatus

FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE')  -- Receiving operations
GROUP BY pt.Username, pt.PartTransaction
ORDER BY pt.Username, TransactionCount DESC;
