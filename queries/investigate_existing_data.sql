-- ============================================
-- INVESTIGATE EXISTING DATA IN KEY TABLES
-- ============================================
-- This query looks at actual data in tables that might contain
-- receipt report and inbound shipment information

-- ============================================
-- 1. LOOK AT PLS SCHEMA TABLES (MANUFACTURING SYSTEM)
-- ============================================
-- Check what's in the pls schema - this seems to be the main system
SELECT TOP 10
    'PLS TABLES SAMPLE' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Sample data available' as Status
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'pls'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- ============================================
-- 2. LOOK FOR RECEIPT-RELATED DATA IN PLS SCHEMA
-- ============================================
-- Check if there are any receipt-related tables in pls
SELECT 
    'PLS RECEIPT TABLES' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Found in pls schema' as Status
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'pls'
  AND (TABLE_NAME LIKE '%receipt%' 
       OR TABLE_NAME LIKE '%RECEIPT%'
       OR TABLE_NAME LIKE '%receiving%'
       OR TABLE_NAME LIKE '%RECEIVING%')
ORDER BY TABLE_NAME;

-- ============================================
-- 3. LOOK FOR SHIPMENT-RELATED DATA IN PLS SCHEMA
-- ============================================
-- Check if there are any shipment-related tables in pls
SELECT 
    'PLS SHIPMENT TABLES' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Found in pls schema' as Status
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'pls'
  AND (TABLE_NAME LIKE '%shipment%' 
       OR TABLE_NAME LIKE '%SHIPMENT%'
       OR TABLE_NAME LIKE '%shipping%'
       OR TABLE_NAME LIKE '%SHIPPING%'
       OR TABLE_NAME LIKE '%inbound%'
       OR TABLE_NAME LIKE '%INBOUND%')
ORDER BY TABLE_NAME;

-- ============================================
-- 4. LOOK FOR REFERENCE FIELDS IN PLS SCHEMA
-- ============================================
-- Check what reference fields exist in pls tables
SELECT TOP 20
    'PLS REFERENCE FIELDS' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls'
  AND (COLUMN_NAME LIKE '%reference%' 
       OR COLUMN_NAME LIKE '%REFERENCE%'
       OR COLUMN_NAME LIKE '%ref%'
       OR COLUMN_NAME LIKE '%REF%')
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 5. LOOK FOR RMA/RTV FIELDS IN PLS SCHEMA
-- ============================================
-- Check what RMA/RTV fields exist in pls tables
SELECT 
    'PLS RMA/RTV FIELDS' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls'
  AND (COLUMN_NAME LIKE '%rma%' 
       OR COLUMN_NAME LIKE '%RMA%'
       OR COLUMN_NAME LIKE '%rtv%'
       OR COLUMN_NAME LIKE '%RTV%'
       OR COLUMN_NAME LIKE '%return%'
       OR COLUMN_NAME LIKE '%RETURN%')
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 6. LOOK FOR DEPARTMENT FIELDS IN PLS SCHEMA
-- ============================================
-- Check what department fields exist in pls tables
SELECT 
    'PLS DEPARTMENT FIELDS' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls'
  AND (COLUMN_NAME LIKE '%department%' 
       OR COLUMN_NAME LIKE '%DEPARTMENT%'
       OR COLUMN_NAME LIKE '%dept%'
       OR COLUMN_NAME LIKE '%DEPT%')
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 7. LOOK FOR QUANTITY/UNIT FIELDS IN PLS SCHEMA
-- ============================================
-- Check what quantity/unit fields exist in pls tables
SELECT TOP 20
    'PLS QUANTITY FIELDS' as InfoType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls'
  AND (COLUMN_NAME LIKE '%qty%' 
       OR COLUMN_NAME LIKE '%QTY%'
       OR COLUMN_NAME LIKE '%quantity%'
       OR COLUMN_NAME LIKE '%QUANTITY%'
       OR COLUMN_NAME LIKE '%unit%'
       OR COLUMN_NAME LIKE '%UNIT%'
       OR COLUMN_NAME LIKE '%total%'
       OR COLUMN_NAME LIKE '%TOTAL%')
ORDER BY TABLE_NAME, COLUMN_NAME;




































