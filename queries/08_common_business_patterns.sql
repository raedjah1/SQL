-- ============================================
-- CLARITY DATABASE - COMMON BUSINESS PATTERNS
-- ============================================
-- 
-- WHAT THIS DOES (in plain English):
-- Based on the business analysis, this shows you the most important patterns
-- and common queries you'll need when working with Clarity's manufacturing data.
--
-- WHY IT'S USEFUL:
-- - Shows you the "bread and butter" queries for this manufacturing system
-- - Helps you understand the core business workflows
-- - Gives you templates for the most common reporting needs
--
-- WHEN TO USE THIS:
-- - When you need to write reports about manufacturing operations
-- - When tracking work orders, parts, or quality issues
-- - When building dashboards for production management
-- - When investigating problems in the manufacturing process
--
-- EXAMPLE SITUATION:
-- Your manager asks: "Show me all work orders that failed testing this week
-- and which work stations they failed at." This query gives you the patterns
-- to find that information quickly!

-- ============================================
-- CONFIRMED: WORK ORDER STATUS TRACKING
-- ============================================
-- This is the CONFIRMED pattern from your actual database
SELECT 
    'Work Order Status Pattern' as QueryType,
    'Look for tables with WO prefix and status/pass fields' as Pattern,
    'Example: SELECT * FROM pls.vWOHeader WHERE status = ''Active''' as ExampleQuery;

-- ============================================
-- RECOMMENDED: ADDITIONAL PATTERNS TO TEST
-- ============================================
-- Based on your schema analysis, these patterns likely exist but need confirmation:

-- Test this pattern - Serial Number Tracking
-- SELECT 'Serial Number Tracking' as QueryType, 
--        'Individual unit tracking through manufacturing' as Pattern,
--        'Example: SELECT * FROM pls.vPartSerial WHERE SerialNo LIKE ''ABC%''' as ExampleQuery;

-- Test this pattern - Quality Testing Results  
-- SELECT 'Quality Testing Pattern' as QueryType,
--        'Pass/fail results from work stations' as Pattern,
--        'Example: SELECT * FROM pls.vWOStationHistory WHERE IsPass = 0' as ExampleQuery;

-- Test this pattern - Order Management
-- SELECT 'Order Management Pattern' as QueryType,
--        'Sales and Repair Order tracking' as Pattern, 
--        'Example: SELECT * FROM pls.vSOHeader WHERE CreateDate >= DATEADD(day, -30, GETDATE())' as ExampleQuery;

-- Test this pattern - Inventory Tracking
-- SELECT 'Inventory Pattern' as QueryType,
--        'Part locations and quantities' as Pattern,
--        'Example: SELECT * FROM pls.vPartLocation WHERE QtyOnHand > 0' as ExampleQuery;

-- ============================================
-- COMMON BUSINESS QUERIES TO BUILD
-- ============================================

/*
-- MANUFACTURING DASHBOARD QUERIES:

-- 1. Active Work Orders by Status
SELECT 
    wo.WorkOrderNo,
    wo.PartNo,
    wo.Status,
    wo.CreatedDate,
    wo.Username
FROM pls.vWOHeader wo
WHERE wo.Status IN ('Active', 'Released', 'Started')
ORDER BY wo.CreatedDate DESC;

-- 2. Failed Quality Checks This Week  
SELECT 
    wh.WorkOrderNo,
    wh.WorkStationCode,
    wh.CreatedDate,
    wh.Username
FROM pls.vWOStationHistory wh
WHERE wh.IsPass = 0
  AND wh.CreatedDate >= DATEADD(week, -1, GETDATE())
ORDER BY wh.CreatedDate DESC;

-- 3. Shipping Status by Carrier
SELECT 
    sh.OrderNo,
    sh.CarrierCode,
    sh.TrackingNumber,
    sh.ShipDate,
    sh.Username
FROM pls.vSOShipmentInfo sh
WHERE sh.ShipDate >= DATEADD(day, -7, GETDATE())
ORDER BY sh.ShipDate DESC;

-- 4. Inventory by Location
SELECT 
    pl.PartNo,
    pl.LocationCode,
    pl.QtyOnHand,
    pl.LastUpdated
FROM pls.vPartLocation pl
WHERE pl.QtyOnHand > 0
ORDER BY pl.PartNo, pl.LocationCode;

-- 5. Repair Order Status
SELECT 
    ro.RepairOrderNo,
    ro.CustomerNo,
    ro.Status,
    ro.ReceivedDate,
    ro.Username
FROM pls.vROHeader ro
WHERE ro.Status NOT IN ('Completed', 'Shipped')
ORDER BY ro.ReceivedDate;

*/
