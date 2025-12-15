-- ============================================
-- CLARITY DATABASE - TABLE SIZES & VOLUMES
-- ============================================
-- 
-- WHAT THIS DOES (in plain English):
-- This is like looking at the size of different filing cabinets in an office.
-- It shows you which tables have the most data and take up the most space.
--
-- WHY IT'S USEFUL:
-- - Shows you which tables are the "big players" in your database
-- - Helps you focus on the tables that matter most to the business
-- - Warns you about performance issues (big tables = slower queries)
-- - Helps you understand where most of your data lives
--
-- WHEN TO USE THIS:
-- - When your database feels slow and you want to know why
-- - When you're new to the database and want to understand what's important
-- - Before writing queries (so you know which tables might be slow)
-- - When planning database maintenance or cleanup
--
-- EXAMPLE SITUATION:
-- Your database is running slowly and you need to investigate. You run this query
-- and discover that the "transaction_log" table has 50 million rows and takes up
-- 10GB of space - much bigger than everything else. Now you know where to focus
-- your optimization efforts!

SELECT 
    SCHEMA_NAME(t.schema_id) as SchemaName,
    t.name as TableName,
    p.rows as EstimatedRows,
    CAST(ROUND((SUM(a.total_pages) * 8) / 1024.0, 2) AS DECIMAL(10,2)) as SizeMB,
    CAST(ROUND((SUM(a.used_pages) * 8) / 1024.0, 2) AS DECIMAL(10,2)) as UsedMB,
    CAST(ROUND((SUM(a.data_pages) * 8) / 1024.0, 2) AS DECIMAL(10,2)) as DataMB
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE p.index_id IN (0,1) -- Clustered index or heap
GROUP BY t.schema_id, t.name, p.rows
ORDER BY p.rows DESC;
