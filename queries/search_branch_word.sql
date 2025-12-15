-- ============================================
-- SEARCH FOR THE WORD "BRANCH" EVERYWHERE
-- ============================================
-- Simple search for "branch" in all table names, column names, and data

-- ============================================
-- 1. FIND ALL TABLES WITH "BRANCH" IN THE NAME
-- ============================================
SELECT 
    'BRANCH TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%branch%' 
   OR TABLE_NAME LIKE '%BRANCH%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 2. FIND ALL COLUMNS WITH "BRANCH" IN THE NAME
-- ============================================
SELECT 
    'BRANCH COLUMNS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME LIKE '%branch%' 
   OR COLUMN_NAME LIKE '%BRANCH%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 3. FIND ALL VIEWS WITH "BRANCH" IN THE NAME
-- ============================================
SELECT 
    'BRANCH VIEWS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as ViewName
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME LIKE '%branch%' 
   OR TABLE_NAME LIKE '%BRANCH%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

