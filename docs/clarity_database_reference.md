# Clarity Database Reference

## Overview
This workspace is configured to work with the **Clarity** database. This document serves as a persistent reference for database structure, common queries, and development patterns.

## Database Information
- **Database Name**: Clarity
- **Last Schema Review**: September 9, 2025
- **Schema Query Location**: `schemas/clarity_database_overview.sql`

## Quick Start

### Getting Database Schema
To get the complete current database schema, run the query in:
```sql
-- File: schemas/clarity_database_overview.sql
```

This query will return:
- All tables in the database
- All columns with data types
- Nullable constraints
- Proper ordering for reference

### Workspace Structure
```
sql-query/
├── config/          # Database connection configurations
├── docs/           # Documentation (this file)
├── examples/       # Example queries and use cases
├── queries/        # Working SQL queries
├── schemas/        # Database schema documentation and queries
└── scripts/        # Utility scripts for database operations
```

## Common Development Patterns

### 1. Schema Exploration
Use the overview query to understand table relationships and structure before writing complex queries.

### 2. Query Development
1. Start with schema exploration
2. Build queries incrementally in the `queries/` folder
3. Document complex queries with comments
4. Test queries against sample data first

### 3. Documentation
- Keep this reference updated when schema changes
- Document business logic and complex relationships
- Note any database-specific features or constraints

## Useful Query Templates

### Table Analysis
```sql
-- Get row counts for all tables
SELECT 
    SCHEMA_NAME(t.schema_id) as SchemaName,
    t.name as TableName,
    p.rows as RowCount
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
ORDER BY p.rows DESC;
```

### Relationship Discovery
```sql
-- Find foreign key relationships
SELECT 
    fk.name as ForeignKeyName,
    SCHEMA_NAME(tp.schema_id) + '.' + tp.name as ParentTable,
    cp.name as ParentColumn,
    SCHEMA_NAME(tr.schema_id) + '.' + tr.name as ReferencedTable,
    cr.name as ReferencedColumn
FROM sys.foreign_keys fk
-- ... (full query in schemas/clarity_database_overview.sql)
```

## Best Practices

1. **Always run the schema overview query first** when working on new features
2. **Use the workspace structure** to organize your work
3. **Document complex business logic** in queries with comments
4. **Test queries incrementally** - start simple, add complexity
5. **Keep this reference updated** when you discover new patterns or schema changes

## Notes
- This workspace maintains persistent context about the Clarity database
- Schema information is refreshed by running the overview query
- All database-specific knowledge should be documented here or in related files

