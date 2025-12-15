-- ===============================================
-- MEMPHIS SITE INTELLIGENCE - SCHEMA DISCOVERY
-- Find Available Tables in PLUS.pls Schema
-- ===============================================

-- Query to discover all tables in PLUS.pls schema
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'pls'
ORDER BY TABLE_NAME;

-- Alternative query if above doesn't work
SELECT 
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS table_name,
    type_desc AS table_type
FROM sys.tables 
WHERE SCHEMA_NAME(schema_id) = 'pls'
ORDER BY name;

-- Check what columns are available in the Program table
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'pls' 
AND TABLE_NAME = 'Program'
ORDER BY ORDINAL_POSITION;
