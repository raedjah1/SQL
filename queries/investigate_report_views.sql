-- ============================================
-- INVESTIGATE REPORT VIEWS AND TABLES
-- ============================================
-- This query looks for views and tables that might contain report data
-- for receipt reports and inbound shipments

-- ============================================
-- 1. FIND ALL VIEWS (REPORTS ARE OFTEN VIEWS)
-- ============================================
SELECT 
    'REPORT VIEWS' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as ViewName,
    'View' as ObjectType
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME LIKE '%receipt%' 
   OR TABLE_NAME LIKE '%RECEIPT%'
   OR TABLE_NAME LIKE '%shipment%' 
   OR TABLE_NAME LIKE '%SHIPMENT%'
   OR TABLE_NAME LIKE '%inbound%'
   OR TABLE_NAME LIKE '%INBOUND%'
   OR TABLE_NAME LIKE '%report%'
   OR TABLE_NAME LIKE '%REPORT%'
   OR TABLE_NAME LIKE '%overview%'
   OR TABLE_NAME LIKE '%OVERVIEW%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 2. FIND ALL TABLES WITH "RPT" SCHEMA (REPORTING)
-- ============================================
SELECT 
    'RPT SCHEMA TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'rpt'
   OR TABLE_SCHEMA = 'RPT'
ORDER BY TABLE_NAME;

-- ============================================
-- 3. FIND ALL TABLES WITH "REPORT" IN THE NAME
-- ============================================
SELECT 
    'REPORT TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%report%' 
   OR TABLE_NAME LIKE '%REPORT%'
   OR TABLE_NAME LIKE '%rpt%'
   OR TABLE_NAME LIKE '%RPT%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 4. FIND ALL TABLES WITH "OVERVIEW" IN THE NAME
-- ============================================
SELECT 
    'OVERVIEW TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%overview%' 
   OR TABLE_NAME LIKE '%OVERVIEW%'
   OR TABLE_NAME LIKE '%summary%'
   OR TABLE_NAME LIKE '%SUMMARY%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 5. FIND ALL TABLES WITH "BRANCH" IN THE NAME
-- ============================================
SELECT 
    'BRANCH TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%branch%' 
   OR TABLE_NAME LIKE '%BRANCH%'
   OR TABLE_NAME LIKE '%portal%'
   OR TABLE_NAME LIKE '%PORTAL%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 6. FIND ALL TABLES WITH "RECEIVING" OR "RECEIPT" IN THE NAME
-- ============================================
SELECT 
    'RECEIVING TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%receiving%' 
   OR TABLE_NAME LIKE '%RECEIVING%'
   OR TABLE_NAME LIKE '%receipt%'
   OR TABLE_NAME LIKE '%RECEIPT%'
   OR TABLE_NAME LIKE '%receive%'
   OR TABLE_NAME LIKE '%RECEIVE%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 7. FIND ALL TABLES WITH "SHIPPING" OR "SHIPMENT" IN THE NAME
-- ============================================
SELECT 
    'SHIPPING TABLES' as SearchType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    'Table' as ObjectType
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%shipping%' 
   OR TABLE_NAME LIKE '%SHIPPING%'
   OR TABLE_NAME LIKE '%shipment%'
   OR TABLE_NAME LIKE '%SHIPMENT%'
   OR TABLE_NAME LIKE '%ship%'
   OR TABLE_NAME LIKE '%SHIP%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
