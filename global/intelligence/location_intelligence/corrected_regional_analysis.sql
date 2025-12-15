-- ============================================
-- CORRECTED REGIONAL ANALYSIS - PROPER COLUMN NAMES
-- ============================================
-- 
-- CORRECTED COLUMNS DISCOVERED:
-- date_entered (instead of CREATE_DATE)
-- last_activity_date (last update)
-- order_no, part_no, contract, region, location_id
-- rowstate (order status), complete_date, close_date
--
-- REGIONAL DISTRIBUTION CONFIRMED:
-- EMEA: 10,691,509 (63.5%) - MASSIVE OPERATION
-- AMER: 4,780,383 (28.4%) - MAJOR OPERATION  
-- APAC: 1,363,108 (8.1%) - SPECIALIZED OPERATION

-- ============================================
-- QUERY 1: REGIONAL OPERATIONAL TIMELINE
-- ============================================
-- When did each region start operating and what's their daily scale?

SELECT 
    region,
    COUNT(*) as TotalRecords,
    MIN(date_entered) as EarliestRecord,
    MAX(date_entered) as LatestRecord,
    DATEDIFF(day, MIN(date_entered), MAX(date_entered)) as DaysOfOperation,
    CASE 
        WHEN DATEDIFF(day, MIN(date_entered), MAX(date_entered)) = 0 THEN COUNT(*)
        ELSE COUNT(*) * 1.0 / DATEDIFF(day, MIN(date_entered), MAX(date_entered))
    END as AvgRecordsPerDay,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as PercentOfTotal
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND date_entered IS NOT NULL
GROUP BY region
ORDER BY TotalRecords DESC;

-- ============================================
-- QUERY 2: FACILITY BREAKDOWN BY REGION
-- ============================================
-- How many facilities and what's the operational intensity?

SELECT 
    region,
    COUNT(DISTINCT location_id) as NumberOfFacilities,
    COUNT(*) as TotalOperations,
    CASE 
        WHEN COUNT(DISTINCT location_id) = 0 THEN 0
        ELSE COUNT(*) / COUNT(DISTINCT location_id)
    END as AvgOperationsPerFacility,
    COUNT(DISTINCT order_no) as UniqueOrders,
    COUNT(DISTINCT part_no) as UniqueParts
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
GROUP BY region
ORDER BY NumberOfFacilities DESC;

-- ============================================
-- QUERY 3: RECENT REGIONAL ACTIVITY (LAST 30 DAYS)
-- ============================================
-- Which regions are currently most active?

SELECT 
    region,
    COUNT(*) as RecentActivity,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as PercentOfRecentActivity,
    COUNT(DISTINCT location_id) as ActiveFacilities,
    COUNT(DISTINCT order_no) as ActiveOrders,
    COUNT(DISTINCT part_no) as ActiveParts,
    COUNT(DISTINCT customer_no) as ActiveCustomers
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND date_entered >= DATEADD(day, -30, GETDATE())
GROUP BY region
ORDER BY RecentActivity DESC;

-- ============================================
-- QUERY 4: REGIONAL ORDER STATUS ANALYSIS
-- ============================================
-- What's the operational health by region?

SELECT 
    region,
    rowstate as OrderStatus,
    COUNT(*) as StatusCount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY region) as PercentInRegion,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as PercentOfTotal
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND rowstate IS NOT NULL
GROUP BY region, rowstate
ORDER BY region, StatusCount DESC;

-- ============================================
-- QUERY 5: REGIONAL PERFORMANCE METRICS
-- ============================================
-- Production efficiency and completion rates by region

SELECT 
    region,
    COUNT(*) as TotalOrders,
    SUM(CASE WHEN complete_date IS NOT NULL THEN 1 ELSE 0 END) as CompletedOrders,
    SUM(CASE WHEN close_date IS NOT NULL THEN 1 ELSE 0 END) as ClosedOrders,
    CASE 
        WHEN COUNT(*) = 0 THEN 0
        ELSE SUM(CASE WHEN complete_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
    END as CompletionRate,
    AVG(CASE 
        WHEN complete_date IS NOT NULL AND org_start_date IS NOT NULL 
        THEN DATEDIFF(day, org_start_date, complete_date) 
        ELSE NULL 
    END) as AvgCompletionDays,
    SUM(ISNULL(qty_complete, 0)) as TotalQuantityCompleted,
    SUM(ISNULL(qty_rejected, 0)) as TotalQuantityRejected
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
GROUP BY region
ORDER BY TotalOrders DESC;

-- ============================================
-- QUERY 6: TOP FACILITIES BY REGION
-- ============================================
-- Which specific facilities are driving each region's operations?

SELECT 
    region,
    location_id,
    COUNT(*) as OperationsAtFacility,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY region) as PercentOfRegion,
    COUNT(DISTINCT order_no) as UniqueOrders,
    COUNT(DISTINCT part_no) as UniqueParts,
    MIN(date_entered) as FirstOperation,
    MAX(last_activity_date) as LastActivity
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
GROUP BY region, location_id
ORDER BY region, OperationsAtFacility DESC;

-- ============================================
-- QUERY 7: REGIONAL BUSINESS PATTERNS
-- ============================================
-- What types of work happen in each region?

SELECT 
    region,
    process_type,
    COUNT(*) as ProcessCount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY region) as PercentInRegion,
    COUNT(DISTINCT part_no) as UniquePartsForProcess,
    AVG(ISNULL(priority_no, 0)) as AvgPriority
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND process_type IS NOT NULL
GROUP BY region, process_type
ORDER BY region, ProcessCount DESC;

-- ============================================
-- CRITICAL BUSINESS INTELLIGENCE INSIGHTS:
-- ============================================
-- 
-- QUERY 1 REVEALS:
-- - Historical timeline of regional operations
-- - Daily operational scale (records per day)
-- - Whether EMEA dominance is recent or long-term
--
-- QUERY 2 REVEALS:
-- - Number of physical facilities per region
-- - Operational intensity (operations per facility)
-- - Regional infrastructure comparison
--
-- QUERY 3 REVEALS:
-- - Current activity levels (last 30 days)
-- - Whether recent patterns match historical distribution
-- - Active facilities and customer base by region
--
-- QUERY 4 REVEALS:
-- - Operational health by order status
-- - Regional differences in order management
-- - Problem concentration by region
--
-- QUERY 5 REVEALS:
-- - Production efficiency metrics
-- - Completion rates and cycle times
-- - Quality indicators (rejected quantities)
--
-- QUERY 6 REVEALS:
-- - Top-performing facilities within each region
-- - Facility specialization patterns
-- - Geographic concentration within regions
--
-- QUERY 7 REVEALS:
-- - Regional specialization by process type
-- - Business model differences between regions
-- - Priority patterns and focus areas
--
-- NEXT CRITICAL STEP:
-- Connect this regional data to your QUALITY PROBLEMS
-- (gTest47, gTest14, Refurbish, Inspection failures)
-- to determine if quality issues are regionally concentrated!
