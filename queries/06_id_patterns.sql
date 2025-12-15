-- ============================================
-- CLARITY DATABASE - ID PATTERNS
-- ============================================
-- 
-- WHAT THIS DOES (in plain English):
-- This finds all the "ID" columns - the numbers or codes that identify specific
-- records, like customer IDs, order IDs, product IDs, etc.
--
-- WHY IT'S USEFUL:
-- - Shows you how different records are identified and connected
-- - Helps you understand the "plumbing" that connects tables together
-- - Reveals naming patterns (some use "id", others use "customer_id", etc.)
-- - Shows you which IDs are required vs optional
--
-- WHEN TO USE THIS:
-- - When you need to join tables together but don't know which columns to use
-- - When you're looking for a specific record and need to know its ID column
-- - When you're trying to understand how tables are related
-- - When writing queries that need to link data across multiple tables
--
-- EXAMPLE SITUATION:
-- You want to find all orders for a specific customer, but you're not sure how
-- the tables connect. This query shows you that the "orders" table has a
-- "customer_id" column that links to the "id" column in the "customers" table.
-- Now you know how to write your JOIN!

SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CASE 
        WHEN COLUMN_NAME = 'id' OR COLUMN_NAME = 'ID' THEN 'Primary ID'
        WHEN COLUMN_NAME LIKE '%_id' OR COLUMN_NAME LIKE '%ID' THEN 'Foreign Key ID'
        WHEN COLUMN_NAME LIKE 'id_%' THEN 'Prefixed ID'
        ELSE 'Other ID'
    END as IDType,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%id%' OR COLUMN_NAME LIKE '%ID%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, IDType, COLUMN_NAME;
