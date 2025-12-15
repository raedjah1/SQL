-- ============================================
-- CLARITY DATABASE - BUSINESS LOGIC FIELDS
-- ============================================
-- 
-- WHAT THIS DOES (in plain English):
-- This finds columns that represent business concepts - like "is this order paid?",
-- "what type of customer is this?", "what's the price?", "what's their email?"
--
-- WHY IT'S USEFUL:
-- - Shows you the real-world business concepts stored in the database
-- - Helps you understand what the business actually does
-- - Finds the important fields for reports and business logic
-- - Reveals the "vocabulary" of the business domain
--
-- WHEN TO USE THIS:
-- - When you're new to the business and need to understand what it does
-- - When writing business reports or dashboards
-- - When looking for specific types of data (emails, phone numbers, prices)
-- - When you need to understand business rules and processes
--
-- EXAMPLE SITUATION:
-- You're asked to build a report showing "all premium customers who haven't paid
-- their recent orders." You need to find: customer type fields, payment status fields,
-- and order status fields. This query shows you exactly where those business
-- concepts are stored in the database!

SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CASE 
        WHEN COLUMN_NAME LIKE '%status%' THEN 'Status Field'
        WHEN COLUMN_NAME LIKE '%type%' THEN 'Type Field'
        WHEN COLUMN_NAME LIKE '%flag%' OR DATA_TYPE = 'bit' THEN 'Flag/Boolean'
        WHEN COLUMN_NAME LIKE '%amount%' OR COLUMN_NAME LIKE '%price%' OR COLUMN_NAME LIKE '%cost%' THEN 'Financial'
        WHEN COLUMN_NAME LIKE '%name%' THEN 'Name Field'
        WHEN COLUMN_NAME LIKE '%email%' THEN 'Email Field'
        WHEN COLUMN_NAME LIKE '%phone%' THEN 'Phone Field'
        WHEN COLUMN_NAME LIKE '%address%' THEN 'Address Field'
        ELSE 'Other'
    END as BusinessFieldType,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%status%' 
   OR COLUMN_NAME LIKE '%type%'
   OR COLUMN_NAME LIKE '%flag%'
   OR DATA_TYPE = 'bit'
   OR COLUMN_NAME LIKE '%amount%'
   OR COLUMN_NAME LIKE '%price%'
   OR COLUMN_NAME LIKE '%cost%'
   OR COLUMN_NAME LIKE '%name%'
   OR COLUMN_NAME LIKE '%email%'
   OR COLUMN_NAME LIKE '%phone%'
   OR COLUMN_NAME LIKE '%address%'
ORDER BY BusinessFieldType, TABLE_SCHEMA, TABLE_NAME;
