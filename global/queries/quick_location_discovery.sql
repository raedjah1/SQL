-- ============================================
-- QUICK LOCATION DISCOVERY - RUN THIS FIRST
-- ============================================
-- 
-- Run these queries in order to quickly find location data in Clarity

-- 1. FIND ALL LOCATION TABLES (Run this first!)
SELECT 
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Location table found' as TableType
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND (
    TABLE_NAME LIKE '%location%' OR
    TABLE_NAME LIKE '%address%' OR
    TABLE_NAME LIKE '%site%' OR
    TABLE_NAME LIKE '%warehouse%' OR
    TABLE_NAME LIKE '%region%'
  )
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- 2. FIND ALL LOCATION COLUMNS (Run this second!)
SELECT 
    TABLE_SCHEMA + '.' + TABLE_NAME as FullTableName,
    COLUMN_NAME as LocationColumn,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS
WHERE (
    COLUMN_NAME LIKE '%location%' OR
    COLUMN_NAME LIKE '%address%' OR
    COLUMN_NAME LIKE '%site%' OR
    COLUMN_NAME LIKE '%region%' OR
    COLUMN_NAME LIKE '%warehouse%'
  )
  AND TABLE_SCHEMA IN ('pls', 'rpt', 'ifsapp', 'ifs', 'dbo')
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- 3. CHECK WORKSTATION TABLE STRUCTURE (Run this third!)
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'pls'
  AND TABLE_NAME = 'vCodeWorkStation'
ORDER BY ORDINAL_POSITION;
