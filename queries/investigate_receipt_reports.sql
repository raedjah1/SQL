-- ============================================
-- INVESTIGATE RECEIPT REPORTS & INBOUND SHIPMENTS
-- ============================================
-- This query helps us understand what tables and fields exist for:
-- 1. Receipt reports
-- 2. Inbound shipments overview
-- 3. Branch portal reference fields
-- 4. RMA/RTV data
-- 5. Department information
-- 6. Total units data

-- ============================================
-- 1. FIND ALL TABLES WITH "RECEIPT" IN THE NAME
-- ============================================
SELECT 
    'RECEIPT TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%receipt%' 
   OR TABLE_NAME LIKE '%RECEIPT%'
   OR TABLE_NAME LIKE '%receiving%'
   OR TABLE_NAME LIKE '%RECEIVING%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 2. FIND ALL TABLES WITH "SHIPMENT" OR "INBOUND" IN THE NAME
-- ============================================
SELECT 
    'SHIPMENT TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%shipment%' 
   OR TABLE_NAME LIKE '%SHIPMENT%'
   OR TABLE_NAME LIKE '%inbound%'
   OR TABLE_NAME LIKE '%INBOUND%'
   OR TABLE_NAME LIKE '%shipping%'
   OR TABLE_NAME LIKE '%SHIPPING%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 3. FIND ALL COLUMNS WITH "REFERENCE" IN THE NAME
-- ============================================
SELECT 
    'REFERENCE COLUMNS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    'Column' as ObjectType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME LIKE '%reference%' 
   OR COLUMN_NAME LIKE '%REFERENCE%'
   OR COLUMN_NAME LIKE '%ref%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 4. FIND ALL COLUMNS WITH "RMA" OR "RTV" IN THE NAME
-- ============================================
SELECT 
    'RMA/RTV COLUMNS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    'Column' as ObjectType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME LIKE '%rma%' 
   OR COLUMN_NAME LIKE '%RMA%'
   OR COLUMN_NAME LIKE '%rtv%'
   OR COLUMN_NAME LIKE '%RTV%'
   OR COLUMN_NAME LIKE '%return%'
   OR COLUMN_NAME LIKE '%RETURN%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 5. FIND ALL COLUMNS WITH "DEPARTMENT" OR "DEPT" IN THE NAME
-- ============================================
SELECT 
    'DEPARTMENT COLUMNS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    'Column' as ObjectType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME LIKE '%department%' 
   OR COLUMN_NAME LIKE '%DEPARTMENT%'
   OR COLUMN_NAME LIKE '%dept%'
   OR COLUMN_NAME LIKE '%DEPT%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 6. FIND ALL COLUMNS WITH "TOTAL" AND "UNIT" IN THE NAME
-- ============================================
SELECT 
    'TOTAL UNITS COLUMNS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    'Column' as ObjectType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE (COLUMN_NAME LIKE '%total%' AND COLUMN_NAME LIKE '%unit%')
   OR (COLUMN_NAME LIKE '%TOTAL%' AND COLUMN_NAME LIKE '%UNIT%')
   OR COLUMN_NAME LIKE '%qty%'
   OR COLUMN_NAME LIKE '%QTY%'
   OR COLUMN_NAME LIKE '%quantity%'
   OR COLUMN_NAME LIKE '%QUANTITY%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 7. FIND ALL COLUMNS WITH "TRACKING" OR "AS" IN THE NAME
-- ============================================
SELECT 
    'TRACKING COLUMNS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    'Column' as ObjectType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME LIKE '%tracking%' 
   OR COLUMN_NAME LIKE '%TRACKING%'
   OR COLUMN_NAME LIKE '%track%'
   OR COLUMN_NAME LIKE '%TRACK%'
   OR COLUMN_NAME = 'AS'
   OR COLUMN_NAME = 'as'
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 8. FIND ALL COLUMNS WITH "BRANCH" IN THE NAME
-- ============================================
SELECT 
    'BRANCH COLUMNS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    'Column' as ObjectType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME LIKE '%branch%' 
   OR COLUMN_NAME LIKE '%BRANCH%'
   OR COLUMN_NAME LIKE '%portal%'
   OR COLUMN_NAME LIKE '%PORTAL%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;




































