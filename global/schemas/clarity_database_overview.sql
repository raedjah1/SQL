-- ============================================
-- CLARITY DATABASE OVERVIEW QUERY
-- ============================================
-- This query provides a complete overview of all tables and columns in the Clarity database
-- Run this query to get current database schema information
-- 
-- Usage: Execute this query against the Clarity database to get:
-- - All tables in the database
-- - All columns with their data types
-- - Nullable constraints
-- - Proper ordering for easy reference
--
-- Last Updated: September 9, 2025
-- ============================================

-- First, get all tables
SELECT 
    'TABLE' as RecordType,
    TABLE_SCHEMA as SchemaName, 
    TABLE_NAME as TableName, 
    '' as ColumnName, 
    '' as DataType, 
    '' as IsNullable,
    0 as SortOrder
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

-- Then get all columns
SELECT 
    'COLUMN' as RecordType,
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE + CASE 
        WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL 
        THEN '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR) + ')'
        WHEN NUMERIC_PRECISION IS NOT NULL 
        THEN '(' + CAST(NUMERIC_PRECISION AS VARCHAR) + ',' + CAST(NUMERIC_SCALE AS VARCHAR) + ')'
        ELSE ''
    END as DataType,
    IS_NULLABLE,
    ORDINAL_POSITION as SortOrder
FROM INFORMATION_SCHEMA.COLUMNS

ORDER BY SchemaName, TableName, RecordType DESC, SortOrder;

-- ============================================
-- ADDITIONAL USEFUL QUERIES FOR CLARITY DATABASE
-- ============================================

-- Get table row counts (useful for understanding data volume)
/*
SELECT 
    SCHEMA_NAME(t.schema_id) as SchemaName,
    t.name as TableName,
    p.rows as RowCount
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
ORDER BY p.rows DESC;
*/

-- Get foreign key relationships
/*
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
*/

-- Get indexes information
/*
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
*/

