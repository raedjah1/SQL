-- ============================================
-- CLARITY DATABASE - LOCATION MAPPING QUERIES
-- ============================================
-- 
-- WHAT THIS DOES (in plain English):
-- These queries help you find WHERE things are physically located in your facilities.
-- When you see "gTest47 has 100% failure rate", you need to know WHERE gTest47 is
-- so your team can go fix it immediately!
--
-- WHY IT'S USEFUL:
-- - Maps workstations to physical locations (building, floor, area)
-- - Shows geographic distribution of your operations
-- - Enables rapid response to quality issues
-- - Helps with resource allocation and capacity planning
--
-- WHEN TO USE THIS:
-- - When you need to dispatch technicians to problem workstations
-- - When planning facility layouts or expansions
-- - When analyzing regional performance differences
-- - When coordinating maintenance activities
--
-- EXAMPLE SITUATION:
-- Dashboard shows "gTest47 has 100% failure rate" → Run these queries →
-- Find "gTest47 is in Building A, Floor 2, Test Lab 3" → 
-- Send technician to exact location immediately!

-- ============================================
-- 1. FIND ALL LOCATION-RELATED TABLES
-- ============================================
-- This finds every table that might contain location information

SELECT 
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Location-related table' as TableType
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND (
    TABLE_NAME LIKE '%location%' OR
    TABLE_NAME LIKE '%address%' OR
    TABLE_NAME LIKE '%site%' OR
    TABLE_NAME LIKE '%warehouse%' OR
    TABLE_NAME LIKE '%facility%' OR
    TABLE_NAME LIKE '%building%' OR
    TABLE_NAME LIKE '%region%' OR
    TABLE_NAME LIKE '%area%'
  )
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 2. FIND ALL LOCATION-RELATED COLUMNS
-- ============================================
-- This finds every column that might contain location data

SELECT 
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE,
    'Location-related column' as ColumnType
FROM INFORMATION_SCHEMA.COLUMNS
WHERE (
    COLUMN_NAME LIKE '%location%' OR
    COLUMN_NAME LIKE '%address%' OR
    COLUMN_NAME LIKE '%site%' OR
    COLUMN_NAME LIKE '%warehouse%' OR
    COLUMN_NAME LIKE '%facility%' OR
    COLUMN_NAME LIKE '%building%' OR
    COLUMN_NAME LIKE '%region%' OR
    COLUMN_NAME LIKE '%area%' OR
    COLUMN_NAME LIKE '%city%' OR
    COLUMN_NAME LIKE '%state%' OR
    COLUMN_NAME LIKE '%country%' OR
    COLUMN_NAME LIKE '%zip%' OR
    COLUMN_NAME LIKE '%postal%' OR
    COLUMN_NAME LIKE '%lat%' OR
    COLUMN_NAME LIKE '%lon%' OR
    COLUMN_NAME LIKE '%coord%'
  )
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 3. WORKSTATION LOCATION MAPPING
-- ============================================
-- Try to find where workstations are physically located

-- Check if workstation location data exists in CodeWorkStation
SELECT 
    'Workstation Location Check' as QueryType,
    COUNT(*) as RecordCount,
    'Records in pls.vCodeWorkStation' as TableInfo
FROM pls.vCodeWorkStation;

-- Get workstation details if available
SELECT TOP 100
    WorkstationDescription,
    -- Look for common location fields
    CASE WHEN 'LocationNo' IN (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vCodeWorkStation' AND TABLE_SCHEMA = 'pls') 
         THEN 'LocationNo column exists' 
         ELSE 'No LocationNo column' END as LocationStatus,
    *
FROM pls.vCodeWorkStation
ORDER BY WorkstationDescription;

-- ============================================
-- 4. PART LOCATION MAPPING
-- ============================================
-- Find where parts are stored and processed

-- Check part location tables
SELECT 
    'Part Location Check' as QueryType,
    COUNT(*) as RecordCount,
    'Records in pls.vPartLocation' as TableInfo
FROM pls.vPartLocation;

-- Get sample part location data
SELECT TOP 100
    PartNo,
    LocationNo,
    -- Look for additional location fields that might exist
    *
FROM pls.vPartLocation
ORDER BY PartNo, LocationNo;

-- ============================================
-- 5. ADDRESS AND FACILITY MAPPING
-- ============================================
-- Find facility and address information

-- Check for address tables
SELECT 
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = t.TABLE_SCHEMA 
       AND TABLE_NAME = t.TABLE_NAME) as ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME LIKE '%address%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- Try to get address/location details from common address tables
-- (This will need to be adjusted based on what tables actually exist)

-- ============================================
-- 6. REGION AND SITE MAPPING
-- ============================================
-- Based on your global operations (AMER, APAC, EMEA), find regional data

SELECT 
    'Regional Analysis' as QueryType,
    'Looking for REGION column patterns' as Analysis,
    COUNT(*) as TablesWithRegion
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%REGION%';

-- Find all unique regions in your system
SELECT DISTINCT
    'Region Values' as DataType,
    REGION as RegionCode,
    COUNT(*) as RecordCount
FROM (
    -- This is a template - will need actual table name
    SELECT 'Sample' as REGION WHERE 1=0
    -- Add actual queries once we know which tables have REGION columns
) regional_data
GROUP BY REGION
ORDER BY RecordCount DESC;

-- ============================================
-- 7. WORKSTATION TO LOCATION CROSS-REFERENCE
-- ============================================
-- Try to connect workstations to their physical locations

-- This query attempts to join workstation data with location data
-- (Will need to be customized based on actual table relationships)

SELECT 
    ws.WorkstationDescription,
    -- Try to find location connections
    'Location mapping needed' as LocationInfo,
    'Run individual queries above to find relationship' as NextStep
FROM pls.vCodeWorkStation ws
WHERE ws.WorkstationDescription IN (
    'gTest47', 'gTest14', 'Refurbish', 'Inspection', 
    'gTask5', 'Audit', 'gTask3'  -- Your problem workstations
)
ORDER BY ws.WorkstationDescription;

-- ============================================
-- 8. FACILITY CAPACITY AND LAYOUT
-- ============================================
-- Understand your facility structure

-- Count workstations by any location grouping that exists
SELECT 
    'Facility Analysis' as AnalysisType,
    COUNT(DISTINCT WorkstationDescription) as TotalWorkstations,
    'Need location grouping data' as LocationGrouping
FROM pls.vCodeWorkStation;

-- ============================================
-- INSTRUCTIONS FOR NEXT STEPS:
-- ============================================
-- 
-- 1. Run queries 1 and 2 first to see what location tables/columns exist
-- 2. Share the results so we can build specific location mapping queries
-- 3. Focus on connecting these problem workstations to physical locations:
--    - gTest47 (100% failure)
--    - gTest14 (100% failure)  
--    - Refurbish (99.95% failure)
--    - Inspection (99.10% failure)
-- 4. Once we have location mapping, we can create:
--    - Facility-specific dashboards
--    - Geographic performance analysis
--    - Maintenance dispatch systems
--    - Capacity planning by location
