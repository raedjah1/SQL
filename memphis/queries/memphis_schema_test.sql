-- Test different schema variations to find the correct one

-- Test 1: Try without PLUS prefix
SELECT TOP 5 * FROM pls.vProgram;

-- Test 2: Try with different database reference
SELECT TOP 5 * FROM vProgram;

-- Test 3: Check if it's in a different schema
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%Program%' OR TABLE_NAME LIKE '%vProgram%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- Test 4: Check current database context
SELECT DB_NAME() as CurrentDatabase;

-- Test 5: Find all schemas with views
SELECT DISTINCT 
    TABLE_SCHEMA,
    COUNT(*) as ViewCount
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'VIEW'
GROUP BY TABLE_SCHEMA
ORDER BY ViewCount DESC;
