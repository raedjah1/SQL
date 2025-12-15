-- ============================================
-- CLARITY DATABASE - DATE/TIME PATTERNS
-- ============================================
-- 
-- WHAT THIS DOES (in plain English):
-- This finds all the date and time columns in your database and groups them by
-- what they're used for - like "when was this created?" or "when was it last updated?"
--
-- WHY IT'S USEFUL:
-- - Shows you the timeline/history tracking in your database
-- - Helps you find audit trails (who did what when)
-- - Reveals business dates that matter (order dates, due dates, etc.)
-- - Shows you which tables track changes over time
--
-- WHEN TO USE THIS:
-- - When you need to write reports about "what happened when"
-- - When investigating data issues (when did this get corrupted?)
-- - When you need to find the newest or oldest records
-- - When building features that need to show history or timelines
--
-- EXAMPLE SITUATION:
-- Your boss asks: "Show me all orders from last month that were updated this week."
-- You need to find tables with order dates AND update dates. This query shows you
-- exactly which tables have "created_date", "updated_date", "order_date" columns
-- so you know where to look!

SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CASE 
        WHEN COLUMN_NAME LIKE '%created%' OR COLUMN_NAME LIKE '%create%' THEN 'Creation Date'
        WHEN COLUMN_NAME LIKE '%updated%' OR COLUMN_NAME LIKE '%modified%' THEN 'Update Date'
        WHEN COLUMN_NAME LIKE '%deleted%' THEN 'Deletion Date'
        WHEN COLUMN_NAME LIKE '%date%' THEN 'Date Field'
        WHEN COLUMN_NAME LIKE '%time%' THEN 'Time Field'
        ELSE 'Other DateTime'
    END as DateTimeType,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('datetime', 'datetime2', 'date', 'time', 'timestamp', 'smalldatetime')
ORDER BY TABLE_SCHEMA, TABLE_NAME, DateTimeType, COLUMN_NAME;
