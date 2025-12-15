-- ============================================
-- CLARITY DATABASE EXPLORATION QUERIES
-- ============================================
-- Collection of useful queries for exploring and understanding the Clarity database
-- These queries help with day-to-day development and troubleshooting

-- ============================================
-- QUICK SCHEMA REFERENCE
-- ============================================

-- 1. List all tables with row counts
SELECT 
    SCHEMA_NAME(t.schema_id) as SchemaName,
    t.name as TableName,
    p.rows as EstimatedRowCount,
    CAST(ROUND((SUM(a.total_pages) * 8) / 1024.0, 2) AS DECIMAL(10,2)) as SizeMB
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE p.index_id IN (0,1)
GROUP BY t.schema_id, t.name, p.rows
ORDER BY p.rows DESC;

-- 2. Find tables by name pattern
-- Usage: Replace 'pattern' with your search term
/*
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%pattern%'
    AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
*/

-- 3. Find columns by name pattern
-- Usage: Replace 'pattern' with your search term
/*
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE COLUMN_NAME LIKE '%pattern%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;
*/

-- ============================================
-- DATA QUALITY CHECKS
-- ============================================

-- 4. Check for NULL values in specific column
-- Usage: Replace table_name and column_name
/*
SELECT 
    COUNT(*) as TotalRows,
    COUNT(column_name) as NonNullRows,
    COUNT(*) - COUNT(column_name) as NullRows,
    CAST(ROUND((COUNT(*) - COUNT(column_name)) * 100.0 / COUNT(*), 2) AS DECIMAL(5,2)) as NullPercentage
FROM table_name;
*/

-- 5. Find duplicate values in a column
-- Usage: Replace table_name and column_name
/*
SELECT 
    column_name,
    COUNT(*) as DuplicateCount
FROM table_name
GROUP BY column_name
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;
*/

-- ============================================
-- RELATIONSHIP DISCOVERY
-- ============================================

-- 6. Get all foreign key relationships
SELECT 
    fk.name as ForeignKeyName,
    SCHEMA_NAME(tp.schema_id) as ParentSchema,
    tp.name as ParentTable,
    cp.name as ParentColumn,
    SCHEMA_NAME(tr.schema_id) as ReferencedSchema,
    tr.name as ReferencedTable,
    cr.name as ReferencedColumn
FROM sys.foreign_keys fk
INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
ORDER BY ParentSchema, ParentTable, ForeignKeyName;

-- 7. Find tables that reference a specific table
-- Usage: Replace 'target_table_name' with the table you're interested in
/*
SELECT DISTINCT
    SCHEMA_NAME(tp.schema_id) as ReferencingSchema,
    tp.name as ReferencingTable,
    cp.name as ReferencingColumn
FROM sys.foreign_keys fk
INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
WHERE tr.name = 'target_table_name'
ORDER BY ReferencingSchema, ReferencingTable;
*/

-- ============================================
-- PERFORMANCE ANALYSIS
-- ============================================

-- 8. Get index information for all tables
SELECT 
    SCHEMA_NAME(t.schema_id) as SchemaName,
    t.name as TableName,
    i.name as IndexName,
    i.type_desc as IndexType,
    i.is_unique as IsUnique,
    i.is_primary_key as IsPrimaryKey,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) as IndexColumns
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.type > 0  -- Exclude heaps
GROUP BY SCHEMA_NAME(t.schema_id), t.name, i.name, i.type_desc, i.is_unique, i.is_primary_key
ORDER BY SchemaName, TableName, IndexName;

-- 9. Find tables without primary keys
SELECT 
    SCHEMA_NAME(t.schema_id) as SchemaName,
    t.name as TableName
FROM sys.tables t
WHERE NOT EXISTS (
    SELECT 1 
    FROM sys.indexes i 
    WHERE i.object_id = t.object_id 
    AND i.is_primary_key = 1
)
ORDER BY SchemaName, TableName;

-- ============================================
-- SAMPLE DATA QUERIES
-- ============================================

-- 10. Quick sample of any table
-- Usage: Replace 'table_name' with your target table
/*
SELECT TOP 10 * 
FROM table_name
ORDER BY (SELECT NULL); -- Random order
*/

-- 11. Get column statistics
-- Usage: Replace 'table_name' with your target table
/*
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'table_name'
ORDER BY ORDINAL_POSITION;
*/

