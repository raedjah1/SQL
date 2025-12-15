-- ============================================
-- VERIFY FACILITY DATA - CONFIRM OUR FINDINGS
-- ============================================
-- 
-- This script will verify the facility counts and activity levels
-- to make sure our analysis is correct

-- ============================================
-- VERIFICATION 1: TOTAL FACILITIES BY REGION
-- ============================================
-- Count all unique location_ids by region (historical total)

SELECT 
    'TOTAL FACILITIES (All Time)' as AnalysisType,
    region,
    COUNT(DISTINCT location_id) as TotalFacilities,
    MIN(date_entered) as FirstRecordDate,
    MAX(date_entered) as LastRecordDate
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
GROUP BY region
ORDER BY TotalFacilities DESC;

-- ============================================
-- VERIFICATION 2: ACTIVE FACILITIES (LAST 30 DAYS)
-- ============================================
-- Count facilities with activity in last 30 days

SELECT 
    'ACTIVE FACILITIES (Last 30 Days)' as AnalysisType,
    region,
    COUNT(DISTINCT location_id) as ActiveFacilities,
    COUNT(*) as TotalOperations,
    COUNT(*) / COUNT(DISTINCT location_id) as AvgOpsPerActiveFacility
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
  AND date_entered >= DATEADD(day, -30, GETDATE())
GROUP BY region
ORDER BY ActiveFacilities DESC;

-- ============================================
-- VERIFICATION 3: FACILITY ACTIVITY TIMELINE
-- ============================================
-- Show when facilities were last active by region

SELECT 
    'FACILITY ACTIVITY TIMELINE' as AnalysisType,
    region,
    COUNT(DISTINCT location_id) as Facilities,
    'Last 7 days' as TimeRange
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
  AND date_entered >= DATEADD(day, -7, GETDATE())
GROUP BY region

UNION ALL

SELECT 
    'FACILITY ACTIVITY TIMELINE' as AnalysisType,
    region,
    COUNT(DISTINCT location_id) as Facilities,
    'Last 30 days' as TimeRange
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
  AND date_entered >= DATEADD(day, -30, GETDATE())
GROUP BY region

UNION ALL

SELECT 
    'FACILITY ACTIVITY TIMELINE' as AnalysisType,
    region,
    COUNT(DISTINCT location_id) as Facilities,
    'Last 90 days' as TimeRange
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
  AND date_entered >= DATEADD(day, -90, GETDATE())
GROUP BY region

UNION ALL

SELECT 
    'FACILITY ACTIVITY TIMELINE' as AnalysisType,
    region,
    COUNT(DISTINCT location_id) as Facilities,
    'Last 365 days' as TimeRange
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
  AND date_entered >= DATEADD(day, -365, GETDATE())
GROUP BY region

ORDER BY region, TimeRange;

-- ============================================
-- VERIFICATION 4: AMER FACILITY DEEP DIVE
-- ============================================
-- Let's specifically look at AMER facilities to confirm the 90 vs 10 numbers

-- Total AMER facilities ever
SELECT 
    'AMER TOTAL FACILITIES' as AnalysisType,
    COUNT(DISTINCT location_id) as TotalFacilities,
    MIN(date_entered) as FirstRecord,
    MAX(date_entered) as LastRecord
FROM ifsapp.shop_ord_tab 
WHERE region = 'AMER'
  AND location_id IS NOT NULL;

-- AMER facilities active in last 30 days
SELECT 
    'AMER ACTIVE FACILITIES (30 days)' as AnalysisType,
    COUNT(DISTINCT location_id) as ActiveFacilities,
    COUNT(*) as TotalOperations
FROM ifsapp.shop_ord_tab 
WHERE region = 'AMER'
  AND location_id IS NOT NULL
  AND date_entered >= DATEADD(day, -30, GETDATE());

-- AMER facilities active in last 90 days
SELECT 
    'AMER ACTIVE FACILITIES (90 days)' as AnalysisType,
    COUNT(DISTINCT location_id) as ActiveFacilities,
    COUNT(*) as TotalOperations
FROM ifsapp.shop_ord_tab 
WHERE region = 'AMER'
  AND location_id IS NOT NULL
  AND date_entered >= DATEADD(day, -90, GETDATE());

-- ============================================
-- VERIFICATION 5: SAMPLE AMER FACILITY DATA
-- ============================================
-- Show some actual AMER location_ids and their activity

SELECT TOP 20
    'AMER FACILITY SAMPLE' as AnalysisType,
    location_id,
    COUNT(*) as TotalOperations,
    MIN(date_entered) as FirstOperation,
    MAX(date_entered) as LastOperation,
    CASE 
        WHEN MAX(date_entered) >= DATEADD(day, -30, GETDATE()) THEN 'ACTIVE (30 days)'
        WHEN MAX(date_entered) >= DATEADD(day, -90, GETDATE()) THEN 'RECENT (90 days)'
        WHEN MAX(date_entered) >= DATEADD(day, -365, GETDATE()) THEN 'INACTIVE (1 year)'
        ELSE 'OLD (>1 year)'
    END as ActivityStatus
FROM ifsapp.shop_ord_tab 
WHERE region = 'AMER'
  AND location_id IS NOT NULL
GROUP BY location_id
ORDER BY MAX(date_entered) DESC;

-- ============================================
-- VERIFICATION 6: DOUBLE-CHECK OUR ORIGINAL RESULTS
-- ============================================
-- Recreate the exact queries that gave us our original numbers

-- Original Query 2: Facility breakdown by region
SELECT 
    'ORIGINAL QUERY 2 RECREATION' as VerificationType,
    region,
    COUNT(DISTINCT location_id) as NumberOfFacilities,
    COUNT(*) as TotalOperations,
    CASE 
        WHEN COUNT(DISTINCT location_id) = 0 THEN 0
        ELSE COUNT(*) / COUNT(DISTINCT location_id)
    END as AvgOperationsPerFacility
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
GROUP BY region
ORDER BY NumberOfFacilities DESC;

-- Original Query 3: Recent activity by region  
SELECT 
    'ORIGINAL QUERY 3 RECREATION' as VerificationType,
    region,
    COUNT(*) as RecentActivity,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as PercentOfRecentActivity,
    COUNT(DISTINCT location_id) as ActiveFacilities,
    COUNT(DISTINCT order_no) as ActiveOrders
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND date_entered >= DATEADD(day, -30, GETDATE())
GROUP BY region
ORDER BY RecentActivity DESC;

-- ============================================
-- WHAT THIS VERIFICATION WILL SHOW:
-- ============================================
-- 
-- 1. TOTAL FACILITIES: How many unique location_ids exist historically
-- 2. ACTIVE FACILITIES: How many have recent activity (7, 30, 90, 365 days)
-- 3. ACTIVITY TIMELINE: When facilities were last active
-- 4. AMER DEEP DIVE: Specific verification of AMER's 90 total vs 10 active
-- 5. SAMPLE DATA: Actual location_ids and their activity status
-- 6. ORIGINAL RESULTS: Exact recreation of our previous queries
--
-- This will confirm whether:
-- - AMER really has 90 total facilities with only 10 currently active
-- - EMEA really has 3,994 total facilities with 562 currently active
-- - Our analysis about facility consolidation opportunity is correct
