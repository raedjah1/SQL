-- Quick test to find working schema references

-- Test 1: Try views without PLUS prefix
SELECT TOP 1 * FROM pls.vProgram;

-- Test 2: Try just the view name
SELECT TOP 1 * FROM vProgram;

-- Test 3: Check what's actually in the database
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.type_desc
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'pls'
UNION ALL
SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    'VIEW' as type_desc
FROM sys.views v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE s.name = 'pls'
ORDER BY schema_name, table_name;

-- Test 4: Find tables that might have Program in the name
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%Program%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
