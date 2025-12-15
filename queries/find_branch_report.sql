-- ============================================
-- FIND BRANCH REPORT AND WHAT'S IN IT
-- ============================================
-- This query specifically looks for branch-related reports and data
-- to understand what the manager meant by "branch report"

-- ============================================
-- 1. FIND ALL TABLES WITH "BRANCH" IN THE NAME
-- ============================================
SELECT 
    'BRANCH TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%branch%' 
   OR TABLE_NAME LIKE '%BRANCH%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 2. FIND ALL VIEWS WITH "BRANCH" IN THE NAME
-- ============================================
SELECT 
    'BRANCH VIEWS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as ViewName,
    'View' as ObjectType
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME LIKE '%branch%' 
   OR TABLE_NAME LIKE '%BRANCH%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 3. FIND ALL COLUMNS WITH "BRANCH" IN THE NAME
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
-- 4. FIND ALL TABLES WITH "PORTAL" IN THE NAME
-- ============================================
SELECT 
    'PORTAL TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%portal%' 
   OR TABLE_NAME LIKE '%PORTAL%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 5. FIND ALL VIEWS WITH "PORTAL" IN THE NAME
-- ============================================
SELECT 
    'PORTAL VIEWS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as ViewName,
    'View' as ObjectType
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME LIKE '%portal%' 
   OR TABLE_NAME LIKE '%PORTAL%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 6. FIND ALL COLUMNS WITH "PORTAL" IN THE NAME
-- ============================================
SELECT 
    'PORTAL COLUMNS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME LIKE '%portal%' 
   OR COLUMN_NAME LIKE '%PORTAL%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 7. FIND ALL TABLES WITH "REPORT" IN THE NAME
-- ============================================
SELECT 
    'REPORT TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%report%' 
   OR TABLE_NAME LIKE '%REPORT%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 8. FIND ALL VIEWS WITH "REPORT" IN THE NAME
-- ============================================
SELECT 
    'REPORT VIEWS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as ViewName,
    'View' as ObjectType
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME LIKE '%report%' 
   OR TABLE_NAME LIKE '%REPORT%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 9. FIND ALL TABLES WITH "OVERVIEW" IN THE NAME
-- ============================================
SELECT 
    'OVERVIEW TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%overview%' 
   OR TABLE_NAME LIKE '%OVERVIEW%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 10. FIND ALL VIEWS WITH "OVERVIEW" IN THE NAME
-- ============================================
SELECT 
    'OVERVIEW VIEWS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as ViewName,
    'View' as ObjectType
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME LIKE '%overview%' 
   OR TABLE_NAME LIKE '%OVERVIEW%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;




































