-- ============================================
-- CLARITY DATABASE - RELATIONSHIPS & KEYS
-- ============================================
-- 
-- WHAT THIS DOES (in plain English):
-- Think of this like a family tree for your database tables. It shows which tables 
-- are "parents" and which are "children", and how they're connected to each other.
--
-- WHY IT'S USEFUL:
-- - Shows you which tables depend on other tables
-- - Helps you understand what happens when you delete or update data
-- - Prevents you from breaking connections between related data
--
-- WHEN TO USE THIS:
-- - Before writing complex queries that join multiple tables
-- - When you need to delete data (to avoid breaking relationships)
-- - When you're trying to understand how the business data flows
-- - When designing new features that need to connect to existing data
--
-- EXAMPLE SITUATION:
-- You want to delete a customer record, but first you need to know:
-- "What other tables depend on this customer? Will deleting the customer 
-- break orders, payments, or addresses that belong to them?"
-- This query shows you all those connections!

-- Foreign Key Relationships
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
