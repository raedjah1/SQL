-- ============================================
-- INVESTIGATE KEY TABLES STRUCTURE
-- ============================================
-- This query examines the structure of key tables that might contain
-- the data we need for receipt reports and inbound shipments

-- ============================================
-- 1. EXAMINE PLS.VWOHEADER TABLE STRUCTURE
-- ============================================
-- This is the main work order table we know exists
SELECT 
    'VWOHEADER STRUCTURE' as InfoType,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE as Nullable,
    COLUMN_DEFAULT as DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls' 
  AND TABLE_NAME = 'vWOHeader'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 2. EXAMINE PLS.VPARTTRANSACTION TABLE STRUCTURE
-- ============================================
-- This table might contain receipt/shipment data
SELECT 
    'VPARTTRANSACTION STRUCTURE' as InfoType,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE as Nullable,
    COLUMN_DEFAULT as DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls' 
  AND TABLE_NAME = 'vPartTransaction'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 3. EXAMINE PLS.VSOHEADER TABLE STRUCTURE
-- ============================================
-- This is the sales order header table
SELECT 
    'VSOHEADER STRUCTURE' as InfoType,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE as Nullable,
    COLUMN_DEFAULT as DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls' 
  AND TABLE_NAME = 'vSOHeader'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 4. EXAMINE PLS.VROUNIT TABLE STRUCTURE
-- ============================================
-- This is the repair order unit table
SELECT 
    'VROUNIT STRUCTURE' as InfoType,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE as Nullable,
    COLUMN_DEFAULT as DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls' 
  AND TABLE_NAME = 'vROUnit'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 5. EXAMINE PLS.VPARTSERIAL TABLE STRUCTURE
-- ============================================
-- This table contains serial number tracking
SELECT 
    'VPARTSERIAL STRUCTURE' as InfoType,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE as Nullable,
    COLUMN_DEFAULT as DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls' 
  AND TABLE_NAME = 'vPartSerial'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 6. EXAMINE PLS.VPARTSERIAL TABLE STRUCTURE
-- ============================================
-- This table contains part location data
SELECT 
    'VPARTLOCATION STRUCTURE' as InfoType,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE as Nullable,
    COLUMN_DEFAULT as DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls' 
  AND TABLE_NAME = 'vPartLocation'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 7. EXAMINE PLS.VPROGRAM TABLE STRUCTURE
-- ============================================
-- This table contains program information
SELECT 
    'VPROGRAM STRUCTURE' as InfoType,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE as Nullable,
    COLUMN_DEFAULT as DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls' 
  AND TABLE_NAME = 'vProgram'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 8. EXAMINE PLS.VCUSTOMER TABLE STRUCTURE
-- ============================================
-- This table contains customer information
SELECT 
    'VCUSTOMER STRUCTURE' as InfoType,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    IS_NULLABLE as Nullable,
    COLUMN_DEFAULT as DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls' 
  AND TABLE_NAME = 'vCustomer'
ORDER BY ORDINAL_POSITION;




































