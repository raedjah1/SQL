-- ============================================
-- CLARITY DATABASE - PRIMARY & UNIQUE KEYS
-- ============================================
-- 
-- WHAT THIS DOES (in plain English):
-- This shows you the "special" columns in each table - the ones that make each 
-- row unique, like a person's Social Security Number or a product's barcode.
--
-- WHY IT'S USEFUL:
-- - Shows you which column(s) uniquely identify each row in a table
-- - Helps you write queries that find exactly one specific record
-- - Tells you which fields can't have duplicate values
-- - Shows you the "natural keys" that the business uses to identify things
--
-- WHEN TO USE THIS:
-- - When you need to write UPDATE or DELETE queries for specific records
-- - When you're joining tables and need to know which columns to join on
-- - When you're trying to understand what makes each record unique
-- - Before inserting new data (to avoid duplicate key errors)
--
-- EXAMPLE SITUATION:
-- You need to update a specific customer's email address. You need to know:
-- "What column uniquely identifies this customer? Is it customer_id, email, 
-- or maybe a combination like first_name + last_name + birth_date?"
-- This query tells you exactly which columns are the unique identifiers!

SELECT 
    SCHEMA_NAME(t.schema_id) as SchemaName,
    t.name as TableName,
    i.name as ConstraintName,
    CASE 
        WHEN i.is_primary_key = 1 THEN 'PRIMARY KEY'
        WHEN i.is_unique_constraint = 1 THEN 'UNIQUE'
        ELSE 'OTHER'
    END as ConstraintType,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) as Columns
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE (i.is_primary_key = 1 OR i.is_unique_constraint = 1)
GROUP BY SCHEMA_NAME(t.schema_id), t.name, i.name, i.is_primary_key, i.is_unique_constraint
ORDER BY SchemaName, TableName, ConstraintType;
