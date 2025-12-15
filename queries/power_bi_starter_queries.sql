-- ============================================
-- POWER BI STARTER QUERIES FOR CLARITY
-- ============================================
-- Based on your confirmed business patterns, here are the key queries
-- to get you started with high-impact Power BI dashboards

-- ============================================
-- 1. WORK ORDER STATUS DASHBOARD
-- ============================================
-- Your CONFIRMED pattern: Work orders with status tracking

-- Active Work Orders Summary
SELECT 
    wo.ID as WorkOrderID,
    wo.WorkOrderNo,
    wo.PartNo,
    wo.Status,
    wo.CreateDate,
    wo.LastActivityDate,
    wo.Username as CreatedBy,
    wo.ProgramID,
    DATEDIFF(day, wo.CreateDate, GETDATE()) as DaysOld
FROM pls.vWOHeader wo
WHERE wo.Status IN ('Active', 'Released', 'Started', 'In Progress')
ORDER BY wo.CreateDate DESC;

-- Work Order Status Distribution (for pie charts)
SELECT 
    Status,
    COUNT(*) as OrderCount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as Percentage
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(month, -3, GETDATE())
GROUP BY Status
ORDER BY OrderCount DESC;

-- ============================================
-- 2. MANUFACTURING PERFORMANCE METRICS
-- ============================================
-- Based on datetime patterns showing WOStartDate/WOEndDate

-- Work Order Cycle Times (if data exists)
SELECT 
    wo.WorkOrderNo,
    wo.PartNo,
    wo.Status,
    ps.WOStartDate,
    ps.WOEndDate,
    CASE 
        WHEN ps.WOStartDate IS NOT NULL AND ps.WOEndDate IS NOT NULL
        THEN DATEDIFF(hour, ps.WOStartDate, ps.WOEndDate)
        ELSE NULL
    END as CycleTimeHours,
    wo.CreateDate,
    wo.ProgramID
FROM pls.vWOHeader wo
LEFT JOIN pls.vPartSerial ps ON wo.ID = ps.WOHeaderID
WHERE wo.CreateDate >= DATEADD(month, -6, GETDATE())
  AND ps.WOStartDate IS NOT NULL;

-- ============================================
-- 3. QUALITY DASHBOARD FOUNDATION
-- ============================================
-- Based on IsPass fields in business logic analysis

-- Quality Results by Work Station (if data exists)
SELECT 
    wh.WorkStationCode,
    COUNT(*) as TotalTests,
    SUM(CASE WHEN wh.IsPass = 1 THEN 1 ELSE 0 END) as PassCount,
    SUM(CASE WHEN wh.IsPass = 0 THEN 1 ELSE 0 END) as FailCount,
    CAST(SUM(CASE WHEN wh.IsPass = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as PassRate,
    CAST(wh.CreateDate as DATE) as TestDate
FROM pls.vWOStationHistory wh
WHERE wh.CreateDate >= DATEADD(day, -30, GETDATE())
GROUP BY wh.WorkStationCode, CAST(wh.CreateDate as DATE)
HAVING COUNT(*) > 0
ORDER BY TestDate DESC, WorkStationCode;

-- ============================================
-- 4. INVENTORY OVERVIEW
-- ============================================
-- Based on part tracking patterns

-- Current Inventory by Location
SELECT 
    pl.PartNo,
    pl.LocationNo,
    pl.QtyOnHand,
    pl.CreateDate,
    pl.LastActivityDate,
    DATEDIFF(day, pl.LastActivityDate, GETDATE()) as DaysSinceActivity,
    pl.ProgramID
FROM pls.vPartLocation pl
WHERE pl.QtyOnHand > 0
ORDER BY pl.PartNo, pl.LocationNo;

-- Serial Number Tracking
SELECT 
    ps.SerialNo,
    ps.PartNo,
    ps.WOPass,
    ps.Shippable,
    ps.CreateDate,
    ps.LastActivityDate,
    ps.RODate,
    ps.SODate,
    ps.WOStartDate,
    ps.WOEndDate
FROM pls.vPartSerial ps
WHERE ps.CreateDate >= DATEADD(month, -3, GETDATE())
ORDER BY ps.CreateDate DESC;

-- ============================================
-- 5. ORDER MANAGEMENT DASHBOARD
-- ============================================
-- Sales and Repair Orders

-- Sales Orders Summary
SELECT 
    so.ID as OrderID,
    so.OrderNo,
    so.CustomerReference,
    so.Status,
    so.CreateDate,
    so.LastActivityDate,
    so.ProgramID,
    DATEDIFF(day, so.CreateDate, GETDATE()) as DaysOld
FROM pls.vSOHeader so
WHERE so.CreateDate >= DATEADD(month, -6, GETDATE())
ORDER BY so.CreateDate DESC;

-- Repair Orders Summary  
SELECT 
    ro.ID as RepairOrderID,
    ro.RepairOrderNo,
    ro.CustomerReference,
    ro.Status,
    ro.CreateDate,
    ro.LastActivityDate,
    ro.ProgramID,
    DATEDIFF(day, ro.CreateDate, GETDATE()) as DaysOld
FROM pls.vROHeader ro
WHERE ro.CreateDate >= DATEADD(month, -6, GETDATE())
ORDER BY ro.CreateDate DESC;

-- ============================================
-- 6. USER ACTIVITY TRACKING
-- ============================================
-- Based on Username fields in every table

-- Recent Activity by User
SELECT 
    Username,
    COUNT(*) as ActivityCount,
    MAX(LastActivityDate) as LastActivity,
    MIN(CreateDate) as FirstActivity
FROM (
    SELECT Username, LastActivityDate, CreateDate FROM pls.vWOHeader WHERE CreateDate >= DATEADD(day, -7, GETDATE())
    UNION ALL
    SELECT Username, LastActivityDate, CreateDate FROM pls.vPartTransaction WHERE CreateDate >= DATEADD(day, -7, GETDATE())
    UNION ALL  
    SELECT Username, LastActivityDate, CreateDate FROM pls.vSOHeader WHERE CreateDate >= DATEADD(day, -7, GETDATE())
) activity
WHERE Username IS NOT NULL
GROUP BY Username
ORDER BY ActivityCount DESC;

-- ============================================
-- 7. PROGRAM PERFORMANCE
-- ============================================
-- Based on ProgramID in 180+ tables

-- Performance by Program
SELECT 
    ProgramID,
    COUNT(*) as TotalOrders,
    COUNT(CASE WHEN Status = 'Completed' THEN 1 END) as CompletedOrders,
    COUNT(CASE WHEN Status = 'Active' THEN 1 END) as ActiveOrders,
    AVG(DATEDIFF(day, CreateDate, ISNULL(LastActivityDate, GETDATE()))) as AvgDaysToComplete
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(month, -6, GETDATE())
  AND ProgramID IS NOT NULL
GROUP BY ProgramID
ORDER BY TotalOrders DESC;

-- ============================================
-- POWER BI TIPS FOR THESE QUERIES
-- ============================================
/*
1. START WITH WORK ORDERS - Your confirmed pattern
   - Use vWOHeader as your main fact table
   - Status field for filtering and slicing
   - CreateDate for time-based analysis

2. ADD INCREMENTAL REFRESH
   - Use CreateDate and LastActivityDate 
   - Filter last 6-12 months for better performance

3. CREATE DATE HIERARCHY
   - Year, Quarter, Month, Week, Day from CreateDate
   - Enable drill-down capabilities

4. USE PROGRAMID FOR SLICING
   - Appears in 180+ tables - perfect dimension
   - Filter by customer programs

5. BUILD GRADUALLY
   - Start with Work Order dashboard
   - Add quality metrics if vWOStationHistory has data
   - Expand to inventory and orders

6. PERFORMANCE OPTIMIZATION
   - Always filter by date ranges
   - Use TOP clauses for large result sets
   - Consider pre-aggregated views from rpt schema
*/
