-- ============================================
-- EXAMINE BRANCH DATA CONTENT
-- ============================================
-- This query looks at the actual data in branch-related tables
-- to understand what the manager meant by "branch report"

-- ============================================
-- 1. EXAMINE RPT.ADTBRANCHCOMPLIANCE TABLE
-- ============================================
-- This table was mentioned in the codebase analysis
SELECT TOP 10
    'ADT BRANCH COMPLIANCE SAMPLE' as InfoType,
    *
FROM rpt.ADTBranchCompliance
ORDER BY 1 DESC;

-- ============================================
-- 2. EXAMINE RPT.LABOROPERATIONS TABLE
-- ============================================
-- This table was also mentioned in the codebase analysis
SELECT TOP 10
    'LABOR OPERATIONS SAMPLE' as InfoType,
    *
FROM rpt.LaborOperations
ORDER BY 1 DESC;

-- ============================================
-- 3. LOOK FOR BRANCH-RELATED DATA IN PLS SCHEMA
-- ============================================
-- Check if there are any branch-related fields in the main pls tables
SELECT 
    'PLS BRANCH FIELDS' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls'
  AND (COLUMN_NAME LIKE '%branch%' 
       OR COLUMN_NAME LIKE '%BRANCH%'
       OR COLUMN_NAME LIKE '%portal%'
       OR COLUMN_NAME LIKE '%PORTAL%')
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 4. LOOK FOR REFERENCE FIELDS IN BRANCH TABLES
-- ============================================
-- Check what reference fields exist in branch-related tables
SELECT 
    'BRANCH REFERENCE FIELDS' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE (TABLE_NAME LIKE '%branch%' 
       OR TABLE_NAME LIKE '%BRANCH%'
       OR TABLE_NAME LIKE '%portal%'
       OR TABLE_NAME LIKE '%PORTAL%')
  AND (COLUMN_NAME LIKE '%reference%' 
       OR COLUMN_NAME LIKE '%REFERENCE%'
       OR COLUMN_NAME LIKE '%ref%'
       OR COLUMN_NAME LIKE '%REF%')
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 5. LOOK FOR TOTAL UNITS FIELDS IN BRANCH TABLES
-- ============================================
-- Check what total units fields exist in branch-related tables
SELECT 
    'BRANCH TOTAL UNITS FIELDS' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE (TABLE_NAME LIKE '%branch%' 
       OR TABLE_NAME LIKE '%BRANCH%'
       OR TABLE_NAME LIKE '%portal%'
       OR TABLE_NAME LIKE '%PORTAL%')
  AND (COLUMN_NAME LIKE '%total%' 
       OR COLUMN_NAME LIKE '%TOTAL%'
       OR COLUMN_NAME LIKE '%unit%'
       OR COLUMN_NAME LIKE '%UNIT%'
       OR COLUMN_NAME LIKE '%qty%'
       OR COLUMN_NAME LIKE '%QTY%'
       OR COLUMN_NAME LIKE '%quantity%'
       OR COLUMN_NAME LIKE '%QUANTITY%')
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 6. LOOK FOR DEPARTMENT FIELDS IN BRANCH TABLES
-- ============================================
-- Check what department fields exist in branch-related tables
SELECT 
    'BRANCH DEPARTMENT FIELDS' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE (TABLE_NAME LIKE '%branch%' 
       OR TABLE_NAME LIKE '%BRANCH%'
       OR TABLE_NAME LIKE '%portal%'
       OR TABLE_NAME LIKE '%PORTAL%')
  AND (COLUMN_NAME LIKE '%department%' 
       OR COLUMN_NAME LIKE '%DEPARTMENT%'
       OR COLUMN_NAME LIKE '%dept%'
       OR COLUMN_NAME LIKE '%DEPT%')
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 7. LOOK FOR RMA/RTV FIELDS IN BRANCH TABLES
-- ============================================
-- Check what RMA/RTV fields exist in branch-related tables
SELECT 
    'BRANCH RMA/RTV FIELDS' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE (TABLE_NAME LIKE '%branch%' 
       OR TABLE_NAME LIKE '%BRANCH%'
       OR TABLE_NAME LIKE '%portal%'
       OR TABLE_NAME LIKE '%PORTAL%')
  AND (COLUMN_NAME LIKE '%rma%' 
       OR COLUMN_NAME LIKE '%RMA%'
       OR COLUMN_NAME LIKE '%rtv%'
       OR COLUMN_NAME LIKE '%RTV%'
       OR COLUMN_NAME LIKE '%return%'
       OR COLUMN_NAME LIKE '%RETURN%')
ORDER BY TABLE_NAME, COLUMN_NAME;




































