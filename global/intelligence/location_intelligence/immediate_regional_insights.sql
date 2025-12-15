-- ============================================
-- IMMEDIATE REGIONAL INSIGHTS - RUN THESE FIRST
-- ============================================
-- 
-- Based on your MASSIVE regional distribution:
-- EMEA: 10,691,509 (63.5%) - DOMINANT
-- AMER: 4,780,383 (28.4%) - MAJOR  
-- APAC: 1,363,108 (8.1%) - SPECIALIZED
--
-- These 3 queries will give IMMEDIATE business intelligence

-- ============================================
-- QUERY 1: WHAT ARE THESE 16.8 MILLION RECORDS?
-- ============================================
-- Let's understand the scale and timeline of your operations

SELECT 
    region,
    COUNT(*) as TotalRecords,
    MIN(date_entered) as EarliestRecord,
    MAX(date_entered) as LatestRecord,
    DATEDIFF(day, MIN(date_entered), MAX(date_entered)) as DaysOfOperation,
    CASE 
        WHEN DATEDIFF(day, MIN(date_entered), MAX(date_entered)) = 0 THEN COUNT(*)
        ELSE COUNT(*) * 1.0 / DATEDIFF(day, MIN(date_entered), MAX(date_entered))
    END as AvgRecordsPerDay
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND date_entered IS NOT NULL
GROUP BY region
ORDER BY TotalRecords DESC;

-- ============================================
-- QUERY 2: FACILITY BREAKDOWN BY REGION
-- ============================================
-- How many facilities do you have in each region?

SELECT 
    region,
    COUNT(DISTINCT location_id) as NumberOfFacilities,
    COUNT(*) as TotalOperations,
    COUNT(*) / NULLIF(COUNT(DISTINCT location_id), 0) as AvgOperationsPerFacility
FROM ifsapp.shop_ord_tab 
WHERE region IS NOT NULL
  AND location_id IS NOT NULL
GROUP BY region
ORDER BY NumberOfFacilities DESC;

-- ============================================
-- QUERY 3: RECENT ACTIVITY BY REGION (CRITICAL!)
-- ============================================
-- Which regions are currently most active?

SELECT 
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
-- CRITICAL BUSINESS QUESTIONS THESE ANSWER:
-- ============================================
-- 
-- QUERY 1 REVEALS:
-- - How long has each region been operating?
-- - What's the daily operational scale in each region?
-- - Is EMEA dominance recent or historical?
--
-- QUERY 2 REVEALS:  
-- - How many physical facilities you have globally
-- - Which regions have the most/fewest facilities
-- - Operational intensity per facility by region
--
-- QUERY 3 REVEALS:
-- - Current operational activity (last 30 days)
-- - Whether recent activity matches historical patterns
-- - Which regions are currently driving your business
--
-- IMMEDIATE BUSINESS VALUE:
-- - If EMEA has 63.5% of operations AND most of your quality problems,
--   you know WHERE to focus improvement efforts
-- - If APAC has fewer facilities but high efficiency,
--   you know WHAT processes to replicate globally
-- - If recent activity differs from historical patterns,
--   you know your business is shifting geographically
