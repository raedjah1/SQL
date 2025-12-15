-- ============================================
-- DEEP REGIONAL ANALYSIS - LOCATION INTELLIGENCE
-- ============================================
-- 
-- WHAT WE DISCOVERED:
-- EMEA: 10,691,509 records (63.5%) - MASSIVE OPERATION
-- AMER: 4,780,383 records (28.4%) - MAJOR OPERATION  
-- APAC: 1,363,108 records (8.1%) - SPECIALIZED OPERATION
--
-- NOW WE NEED TO GO DEEPER TO FIND:
-- 1. Are your quality problems concentrated in specific regions?
-- 2. Which regions have the best performance?
-- 3. Where are your problem workstations located?
-- 4. What are the regional operational patterns?

-- ============================================
-- QUERY 1: REGIONAL OPERATIONAL PATTERNS
-- ============================================
-- Let's understand what these 16.8 million records represent

SELECT 
    'Regional Operation Analysis' as AnalysisType,
    region,
    COUNT(*) as TotalRecords,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as PercentageOfTotal,
    MIN(CREATE_DATE) as EarliestRecord,
    MAX(CREATE_DATE) as LatestRecord,
    DATEDIFF(day, MIN(CREATE_DATE), MAX(CREATE_DATE)) as OperationalDays
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND CREATE_DATE IS NOT NULL
GROUP BY region
ORDER BY TotalRecords DESC;

-- ============================================
-- QUERY 2: REGIONAL ACTIVITY TIMELINE
-- ============================================
-- When are these regions most active?

SELECT 
    region,
    YEAR(CREATE_DATE) as Year,
    MONTH(CREATE_DATE) as Month,
    COUNT(*) as MonthlyActivity,
    COUNT(*) * 1.0 / DAY(EOMONTH(CREATE_DATE)) as AvgDailyActivity
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND CREATE_DATE >= DATEADD(month, -6, GETDATE())
GROUP BY region, YEAR(CREATE_DATE), MONTH(CREATE_DATE)
ORDER BY region, Year DESC, Month DESC;

-- ============================================
-- QUERY 3: LOCATION_ID BREAKDOWN BY REGION
-- ============================================
-- Find specific facilities within each region

SELECT 
    region,
    location_id,
    COUNT(*) as RecordsAtLocation,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY region) as PercentWithinRegion
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
GROUP BY region, location_id
ORDER BY region, RecordsAtLocation DESC;

-- ============================================
-- QUERY 4: PROPOSED LOCATION ANALYSIS
-- ============================================
-- Understand future planning by region

SELECT 
    region,
    proposed_location,
    location_id as current_location,
    COUNT(*) as PlannedMoves,
    'Future facility planning' as Insight
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND proposed_location IS NOT NULL
  AND proposed_location != location_id
GROUP BY region, proposed_location, location_id
ORDER BY region, PlannedMoves DESC;

-- ============================================
-- QUERY 5: CROSS-REFERENCE WITH WORK ORDERS
-- ============================================
-- THIS IS CRITICAL: Connect regional data to your quality problems!
-- We need to find the relationship between shop_ord_tab and vWOHeader

-- First, let's see if we can find common fields
SELECT 
    'Shop Order Table Columns' as TableType,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ifsapp'
  AND TABLE_NAME = 'shop_ord_tab'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- QUERY 6: FIND THE CONNECTION TO WORK ORDERS
-- ============================================
-- Look for common identifiers between regional data and work orders

-- Check for ORDER_NO patterns
SELECT TOP 10
    'Shop Order Numbers' as DataType,
    ORDER_NO,
    region,
    location_id
FROM ifsapp.shop_ord_tab 
WHERE ORDER_NO IS NOT NULL
ORDER BY CREATE_DATE DESC;

-- Check work order numbers in your quality data
SELECT TOP 10
    'Work Order IDs' as DataType,
    ID,
    CustomerReference,
    WorkstationDescription
FROM pls.vWOHeader
ORDER BY CreateDate DESC;

-- ============================================
-- QUERY 7: REGIONAL BUSINESS PATTERNS
-- ============================================
-- What types of operations happen in each region?

SELECT 
    region,
    -- Look for pattern indicators in shop order data
    COUNT(DISTINCT ORDER_NO) as UniqueOrders,
    COUNT(DISTINCT PART_NO) as UniqueParts,
    AVG(QTY_DUE) as AvgQuantityDue,
    SUM(QTY_DUE) as TotalQuantityDue
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
GROUP BY region
ORDER BY TotalQuantityDue DESC;

-- ============================================
-- QUERY 8: REGIONAL STATUS ANALYSIS
-- ============================================
-- What's the status distribution by region?

SELECT 
    region,
    ROWSTATE as OrderStatus,
    COUNT(*) as StatusCount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY region) as PercentInRegion
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND ROWSTATE IS NOT NULL
GROUP BY region, ROWSTATE
ORDER BY region, StatusCount DESC;

-- ============================================
-- INSTRUCTIONS FOR RUNNING THESE QUERIES:
-- ============================================
-- 
-- RUN IN THIS ORDER:
-- 1. Query 1 - Regional operational patterns (shows timeline and scale)
-- 2. Query 3 - Location_ID breakdown (shows facilities within regions)  
-- 3. Query 5 - Column analysis (helps us find connection to work orders)
-- 4. Query 6 - Find connection patterns (critical for quality mapping)
-- 5. Query 7 - Regional business patterns (shows what each region does)
-- 6. Query 8 - Regional status analysis (shows operational health)
--
-- CRITICAL GOAL:
-- We need to connect your QUALITY PROBLEMS (gTest47, gTest14, Refurbish, Inspection)
-- to these REGIONAL OPERATIONS to answer:
-- - Are quality issues concentrated in EMEA (63.5% of operations)?
-- - Which region has the best quality performance?
-- - Should you focus improvement efforts on specific regions?
-- 
-- This will unlock MILLIONS in targeted improvement opportunities!
