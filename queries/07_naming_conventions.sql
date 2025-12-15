-- ============================================
-- CLARITY DATABASE - NAMING CONVENTIONS
-- ============================================
-- 
-- WHAT THIS DOES (in plain English):
-- This looks for patterns in how tables and columns are named - like do all
-- customer tables start with "cust_"? Do all tables have "created_date" columns?
--
-- WHY IT'S USEFUL:
-- - Helps you guess what tables might exist (if you know the naming pattern)
-- - Shows you the "style guide" that was used to build the database
-- - Helps you find similar tables or columns quickly
-- - Reveals consistency (or lack of it) in the database design
--
-- WHEN TO USE THIS:
-- - When you're looking for a table but don't know its exact name
-- - When you want to understand the database design philosophy
-- - When you're adding new tables and want to follow existing conventions
-- - When you need to find all tables that might contain similar data
--
-- EXAMPLE SITUATION:
-- You need to find tables related to invoicing, but you don't know what they're called.
-- This query shows you that many tables start with "inv_" (inv_header, inv_lines, inv_payments).
-- Now you know the pattern and can look for other "inv_" tables!

-- Table naming patterns (prefixes)
SELECT 
    'Table Prefixes' as AnalysisType,
    LEFT(TABLE_NAME, 3) as Pattern,
    COUNT(*) as Count,
    'See individual query below for examples' as Examples
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
GROUP BY LEFT(TABLE_NAME, 3)
HAVING COUNT(*) > 1

UNION ALL

-- Common column names across tables
SELECT 
    'Common Columns' as AnalysisType,
    COLUMN_NAME as Pattern,
    COUNT(DISTINCT TABLE_NAME) as Count,
    'See individual query below for examples' as Examples
FROM INFORMATION_SCHEMA.COLUMNS
GROUP BY COLUMN_NAME
HAVING COUNT(DISTINCT TABLE_NAME) > 3  -- Appears in 3+ tables

ORDER BY AnalysisType, Count DESC;

-- ============================================
-- SEPARATE QUERIES FOR EXAMPLES (run individually if needed)
-- ============================================

-- To see examples of table prefixes, run this after the main query:
/*
SELECT 
    LEFT(TABLE_NAME, 3) as Prefix,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY LEFT(TABLE_NAME, 3), TABLE_NAME;
*/

-- To see which tables have common columns, run this:
/*
SELECT 
    COLUMN_NAME,
    TABLE_SCHEMA + '.' + TABLE_NAME as TableName
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME IN (
    SELECT COLUMN_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS
    GROUP BY COLUMN_NAME
    HAVING COUNT(DISTINCT TABLE_NAME) > 3
)
ORDER BY COLUMN_NAME, TableName;
*/
