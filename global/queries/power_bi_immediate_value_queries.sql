-- ============================================
-- CLARITY POWER BI - IMMEDIATE BUSINESS VALUE QUERIES
-- ============================================
-- 
-- WHAT THIS IS:
-- Ready-to-use queries with ACTUAL column names from your Clarity database.
-- Copy these directly into Power BI for instant dashboards!
--
-- WHY THIS IS VALUABLE:
-- - Uses confirmed column names from pls.vWOHeader
-- - Provides manufacturing KPIs your business needs
-- - Creates actionable insights for operations management
-- - Saves weeks of trial-and-error query building
--
-- HOW TO USE:
-- 1. Copy any query below into Power BI
-- 2. Connect to your Clarity database  
-- 3. Create visualizations from the results
-- 4. Build executive dashboards that matter

-- ============================================
-- 1. WORK ORDER QUALITY DASHBOARD (HIGH PRIORITY)
-- ============================================

-- Quality Overview - Main KPI Card
SELECT 
    COUNT(*) as TotalWorkOrders,
    SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) as PassedOrders,
    SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) as FailedOrders,
    SUM(CASE WHEN IsPass IS NULL THEN 1 ELSE 0 END) as PendingOrders,
    CASE 
        WHEN SUM(CASE WHEN IsPass IS NOT NULL THEN 1 ELSE 0 END) = 0 THEN 0
        ELSE CAST(SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) * 100.0 / 
             SUM(CASE WHEN IsPass IS NOT NULL THEN 1 ELSE 0 END) AS DECIMAL(5,2))
    END as QualityPassRate
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE());

-- Quality by Workstation - Bar Chart
SELECT 
    WorkstationDescription,
    COUNT(*) as TotalOrders,
    SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) as PassedOrders,
    SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) as FailedOrders,
    CASE 
        WHEN COUNT(*) = 0 THEN 0
        ELSE CAST(SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
    END as PassRate
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE())
  AND IsPass IS NOT NULL
GROUP BY WorkstationDescription
ORDER BY FailedOrders DESC;

-- Quality Trend Over Time - Line Chart  
SELECT 
    CAST(CreateDate AS DATE) as Date,
    COUNT(*) as TotalOrders,
    SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) as PassedOrders,
    SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) as FailedOrders,
    CASE 
        WHEN COUNT(*) = 0 THEN 0
        ELSE CAST(SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
    END as DailyPassRate
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE())
  AND IsPass IS NOT NULL
GROUP BY CAST(CreateDate AS DATE)
ORDER BY Date;

-- ============================================
-- 2. PRODUCTION STATUS DASHBOARD
-- ============================================

-- Status Overview - Pie Chart
SELECT 
    StatusDescription,
    COUNT(*) as OrderCount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as Percentage
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE())
GROUP BY StatusDescription
ORDER BY OrderCount DESC;

-- Active Work Orders by Priority - Table
SELECT 
    ID as WorkOrderID,
    CustomerReference,
    PartNo,
    SerialNo,
    WorkstationDescription,
    StatusDescription,
    CreateDate,
    LastActivityDate,
    Username as AssignedTo,
    DATEDIFF(day, CreateDate, GETDATE()) as DaysOpen
FROM pls.vWOHeader
WHERE StatusDescription NOT LIKE '%Complete%' 
  AND StatusDescription NOT LIKE '%Closed%'
  AND StatusDescription NOT LIKE '%Shipped%'
ORDER BY CreateDate;

-- ============================================
-- 3. REPAIR TYPE ANALYSIS
-- ============================================

-- Repair Types by Volume - Bar Chart
SELECT 
    RepairTypeDescription,
    COUNT(*) as RepairCount,
    SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) as SuccessfulRepairs,
    SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) as FailedRepairs,
    CASE 
        WHEN COUNT(*) = 0 THEN 0
        ELSE CAST(SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
    END as SuccessRate
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE())
  AND RepairTypeDescription IS NOT NULL
GROUP BY RepairTypeDescription
ORDER BY RepairCount DESC;

-- ============================================
-- 4. CUSTOMER PERFORMANCE TRACKING
-- ============================================

-- Customer Work Order Summary - Table
SELECT 
    CustomerReference,
    COUNT(*) as TotalOrders,
    SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) as PassedOrders,
    SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) as FailedOrders,
    COUNT(DISTINCT PartNo) as UniquePartNumbers,
    AVG(DATEDIFF(day, CreateDate, LastActivityDate)) as AvgProcessingDays,
    CASE 
        WHEN COUNT(*) = 0 THEN 0
        ELSE CAST(SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
    END as CustomerPassRate
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE())
  AND CustomerReference IS NOT NULL
GROUP BY CustomerReference
ORDER BY TotalOrders DESC;

-- ============================================
-- 5. OPERATIONAL EFFICIENCY METRICS
-- ============================================

-- Daily Production Volume - Line Chart
SELECT 
    CAST(CreateDate AS DATE) as ProductionDate,
    COUNT(*) as OrdersCreated,
    COUNT(DISTINCT CustomerReference) as CustomersServed,
    COUNT(DISTINCT PartNo) as UniquePartsProcessed,
    COUNT(DISTINCT WorkstationDescription) as WorkstationsUsed
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE())
GROUP BY CAST(CreateDate AS DATE)
ORDER BY ProductionDate;

-- Workstation Utilization - Bar Chart
SELECT 
    WorkstationDescription,
    COUNT(*) as OrdersProcessed,
    COUNT(DISTINCT PartNo) as UniquePartsHandled,
    COUNT(DISTINCT CustomerReference) as CustomersServed,
    MIN(CreateDate) as FirstOrder,
    MAX(CreateDate) as LastOrder,
    CASE 
        WHEN DATEDIFF(day, MIN(CreateDate), MAX(CreateDate)) = 0 THEN COUNT(*)
        ELSE COUNT(*) * 1.0 / DATEDIFF(day, MIN(CreateDate), MAX(CreateDate))
    END as AvgOrdersPerDay
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE())
GROUP BY WorkstationDescription
ORDER BY OrdersProcessed DESC;

-- ============================================
-- 6. PROBLEM IDENTIFICATION QUERIES
-- ============================================

-- Failed Work Orders Requiring Attention
SELECT 
    ID as WorkOrderID,
    CustomerReference,
    PartNo,
    SerialNo,
    RepairTypeDescription,
    WorkstationDescription,
    StatusDescription,
    CreateDate,
    LastActivityDate,
    Username,
    DATEDIFF(day, CreateDate, GETDATE()) as DaysOld
FROM pls.vWOHeader
WHERE IsPass = 0
  AND CreateDate >= DATEADD(day, -30, GETDATE())
ORDER BY CreateDate;

-- Workstations with High Failure Rates
SELECT 
    WorkstationDescription,
    COUNT(*) as TotalOrders,
    SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) as FailedOrders,
    CASE 
        WHEN COUNT(*) = 0 THEN 0
        ELSE CAST(SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
    END as FailureRate
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE())
  AND IsPass IS NOT NULL
GROUP BY WorkstationDescription
HAVING COUNT(*) >= 5  -- Only include workstations with meaningful volume
ORDER BY FailureRate DESC;

-- ============================================
-- 7. EXECUTIVE SUMMARY QUERY
-- ============================================

-- Single query for executive dashboard
SELECT 
    'Last 30 Days' as Period,
    COUNT(*) as TotalWorkOrders,
    COUNT(DISTINCT CustomerReference) as ActiveCustomers,
    COUNT(DISTINCT PartNo) as UniquePartsProcessed,
    COUNT(DISTINCT WorkstationDescription) as ActiveWorkstations,
    SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) as PassedOrders,
    SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) as FailedOrders,
    CASE 
        WHEN SUM(CASE WHEN IsPass IS NOT NULL THEN 1 ELSE 0 END) = 0 THEN 0
        ELSE CAST(SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) * 100.0 / 
             SUM(CASE WHEN IsPass IS NOT NULL THEN 1 ELSE 0 END) AS DECIMAL(5,2))
    END as OverallQualityRate,
    COUNT(*) * 1.0 / 30 as AvgOrdersPerDay
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE());
