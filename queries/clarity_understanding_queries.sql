-- ============================================
-- CLARITY DATABASE UNDERSTANDING QUERIES
-- ============================================
-- These queries help build comprehensive understanding of the Clarity database
-- beyond just schema - relationships, data patterns, business logic, etc.

-- ============================================
-- 1. RELATIONSHIP MAPPING
-- ============================================

-- Get all foreign key relationships (already in exploration_queries.sql, but critical)
SELECT 
    fk.name as ForeignKeyName,
    SCHEMA_NAME(tp.schema_id) + '.' + tp.name as ParentTable,
    cp.name as ParentColumn,
    SCHEMA_NAME(tr.schema_id) + '.' + tr.name as ReferencedTable,
    cr.name as ReferencedColumn,
    fk.delete_referential_action_desc as DeleteAction,
    fk.update_referential_action_desc as UpdateAction
FROM sys.foreign_keys fk
INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
ORDER BY ParentTable, ForeignKeyName;

-- ============================================
-- 2. PRIMARY KEY AND UNIQUE CONSTRAINTS
-- ============================================

-- Get all primary keys and unique constraints
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

-- ============================================
-- 3. DATA VOLUME AND DISTRIBUTION
-- ============================================

-- Table sizes and row counts (estimated)
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

-- ============================================
-- 4. NAMING PATTERNS AND CONVENTIONS
-- ============================================

-- Analyze table naming patterns
SELECT 
    'Table Prefixes' as AnalysisType,
    LEFT(TABLE_NAME, 3) as Pattern,
    COUNT(*) as Count
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
GROUP BY LEFT(TABLE_NAME, 3)
HAVING COUNT(*) > 1

UNION ALL

-- Common column name patterns
SELECT 
    'Common Columns' as AnalysisType,
    COLUMN_NAME as Pattern,
    COUNT(DISTINCT TABLE_NAME) as Count
FROM INFORMATION_SCHEMA.COLUMNS
GROUP BY COLUMN_NAME
HAVING COUNT(DISTINCT TABLE_NAME) > 5

ORDER BY AnalysisType, Count DESC;

-- ============================================
-- 5. DATE/TIME PATTERNS
-- ============================================

-- Find date/time columns (common in business systems)
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
    END as DateTimeType
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('datetime', 'datetime2', 'date', 'time', 'timestamp', 'smalldatetime')
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 6. ID PATTERNS AND RELATIONSHIPS
-- ============================================

-- Find ID columns and their patterns
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
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%id%' OR COLUMN_NAME LIKE '%ID%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, IDType, COLUMN_NAME;

-- ============================================
-- 7. BUSINESS LOGIC INDICATORS
-- ============================================

-- Look for common business fields
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
    END as BusinessFieldType
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

-- ============================================
-- 8. CHECK CONSTRAINTS AND BUSINESS RULES
-- ============================================

-- Get check constraints (business rules)
SELECT 
    SCHEMA_NAME(t.schema_id) as SchemaName,
    t.name as TableName,
    cc.name as ConstraintName,
    cc.definition as ConstraintDefinition,
    cc.is_disabled as IsDisabled
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
ORDER BY SchemaName, TableName, ConstraintName;

-- ============================================
-- 9. VIEWS AND COMPUTED LOGIC
-- ============================================

-- Get all views (often contain business logic)
SELECT 
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as ViewName,
    'VIEW' as ObjectType
FROM INFORMATION_SCHEMA.VIEWS
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 10. STORED PROCEDURES AND FUNCTIONS
-- ============================================

-- Get stored procedures and functions
SELECT 
    SCHEMA_NAME(schema_id) as SchemaName,
    name as ObjectName,
    type_desc as ObjectType,
    create_date as CreatedDate,
    modify_date as ModifiedDate
FROM sys.objects
WHERE type IN ('P', 'FN', 'TF', 'IF') -- Procedures, Functions, Table Functions, Inline Functions
ORDER BY type_desc, SchemaName, name;

-- ============================================
-- SAMPLE QUERIES TO RUN AFTER SCHEMA ANALYSIS
-- ============================================

/*
-- After running the above queries, you might want to:

-- 1. Look at sample data from key tables
SELECT TOP 5 * FROM [largest_table_name];

-- 2. Check referential integrity
SELECT COUNT(*) FROM [child_table] c
LEFT JOIN [parent_table] p ON c.parent_id = p.id
WHERE p.id IS NULL;

-- 3. Look for common lookup/reference tables
SELECT * FROM [table_name] WHERE [table_name] LIKE '%type%' OR [table_name] LIKE '%status%';

-- 4. Check for soft deletes
SELECT COUNT(*) as Total, 
       COUNT(CASE WHEN deleted_date IS NULL THEN 1 END) as Active,
       COUNT(CASE WHEN deleted_date IS NOT NULL THEN 1 END) as Deleted
FROM [table_with_deleted_date];
*/
