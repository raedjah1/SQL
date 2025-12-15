-- ============================================
-- FIND EXISTING ADT REPORTS AND VIEWS
-- ============================================
-- This query looks for existing reports and views that might be
-- the "branch report" for ADT program (ProgramID = 10068)

-- ============================================
-- 1. FIND ALL VIEWS THAT MIGHT CONTAIN ADT DATA
-- ============================================
SELECT 
    'POTENTIAL ADT VIEWS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as ViewName,
    'View' as ObjectType
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME LIKE '%adt%' 
   OR TABLE_NAME LIKE '%ADT%'
   OR TABLE_NAME LIKE '%branch%'
   OR TABLE_NAME LIKE '%BRANCH%'
   OR TABLE_NAME LIKE '%portal%'
   OR TABLE_NAME LIKE '%PORTAL%'
   OR TABLE_NAME LIKE '%report%'
   OR TABLE_NAME LIKE '%REPORT%'
   OR TABLE_NAME LIKE '%overview%'
   OR TABLE_NAME LIKE '%OVERVIEW%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 2. FIND ALL TABLES THAT MIGHT CONTAIN ADT DATA
-- ============================================
SELECT 
    'POTENTIAL ADT TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%adt%' 
   OR TABLE_NAME LIKE '%ADT%'
   OR TABLE_NAME LIKE '%branch%'
   OR TABLE_NAME LIKE '%BRANCH%'
   OR TABLE_NAME LIKE '%portal%'
   OR TABLE_NAME LIKE '%PORTAL%'
   OR TABLE_NAME LIKE '%report%'
   OR TABLE_NAME LIKE '%REPORT%'
   OR TABLE_NAME LIKE '%overview%'
   OR TABLE_NAME LIKE '%OVERVIEW%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 3. EXAMINE RPT.ADTBRANCHCOMPLIANCE TABLE STRUCTURE
-- ============================================
-- This table was mentioned in the codebase analysis
SELECT 
    'ADT BRANCH COMPLIANCE STRUCTURE' as InfoType,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE as Nullable,
    COLUMN_DEFAULT as DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'rpt' 
  AND TABLE_NAME = 'ADTBranchCompliance'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 4. EXAMINE RPT.LABOROPERATIONS TABLE STRUCTURE
-- ============================================
-- This table was also mentioned in the codebase analysis
SELECT 
    'LABOR OPERATIONS STRUCTURE' as InfoType,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE as Nullable,
    COLUMN_DEFAULT as DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'rpt' 
  AND TABLE_NAME = 'LaborOperations'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 5. LOOK FOR ADT-SPECIFIC COLUMNS IN ALL TABLES
-- ============================================
SELECT 
    'ADT-SPECIFIC COLUMNS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME LIKE '%adt%' 
   OR COLUMN_NAME LIKE '%ADT%'
   OR COLUMN_NAME LIKE '%branch%'
   OR COLUMN_NAME LIKE '%BRANCH%'
   OR COLUMN_NAME LIKE '%portal%'
   OR COLUMN_NAME LIKE '%PORTAL%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 6. LOOK FOR REFERENCE FIELDS IN ADT CONTEXT
-- ============================================
SELECT 
    'ADT REFERENCE FIELDS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE (COLUMN_NAME LIKE '%reference%' 
       OR COLUMN_NAME LIKE '%REFERENCE%'
       OR COLUMN_NAME LIKE '%ref%'
       OR COLUMN_NAME LIKE '%REF%')
  AND (TABLE_NAME LIKE '%adt%' 
       OR TABLE_NAME LIKE '%ADT%'
       OR TABLE_NAME LIKE '%branch%'
       OR TABLE_NAME LIKE '%BRANCH%'
       OR TABLE_NAME LIKE '%portal%'
       OR TABLE_NAME LIKE '%PORTAL%')
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 7. LOOK FOR TOTAL UNITS FIELDS IN ADT CONTEXT
-- ============================================
SELECT 
    'ADT TOTAL UNITS FIELDS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE (COLUMN_NAME LIKE '%total%' 
       OR COLUMN_NAME LIKE '%TOTAL%'
       OR COLUMN_NAME LIKE '%unit%'
       OR COLUMN_NAME LIKE '%UNIT%'
       OR COLUMN_NAME LIKE '%qty%'
       OR COLUMN_NAME LIKE '%QTY%'
       OR COLUMN_NAME LIKE '%quantity%'
       OR COLUMN_NAME LIKE '%QUANTITY%')
  AND (TABLE_NAME LIKE '%adt%' 
       OR TABLE_NAME LIKE '%ADT%'
       OR TABLE_NAME LIKE '%branch%'
       OR TABLE_NAME LIKE '%BRANCH%'
       OR TABLE_NAME LIKE '%portal%'
       OR TABLE_NAME LIKE '%PORTAL%')
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 8. LOOK FOR RMA/RTV FIELDS IN ADT CONTEXT
-- ============================================
SELECT 
    'ADT RMA/RTV FIELDS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE (COLUMN_NAME LIKE '%rma%' 
       OR COLUMN_NAME LIKE '%RMA%'
       OR COLUMN_NAME LIKE '%rtv%'
       OR COLUMN_NAME LIKE '%RTV%'
       OR COLUMN_NAME LIKE '%return%'
       OR COLUMN_NAME LIKE '%RETURN%')
  AND (TABLE_NAME LIKE '%adt%' 
       OR TABLE_NAME LIKE '%ADT%'
       OR TABLE_NAME LIKE '%branch%'
       OR TABLE_NAME LIKE '%BRANCH%'
       OR TABLE_NAME LIKE '%portal%'
       OR TABLE_NAME LIKE '%PORTAL%')
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;




































