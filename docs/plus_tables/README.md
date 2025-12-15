# Plus Tables Documentation

This folder contains detailed documentation for all key `Plus.pls` database tables used in queries.

## Purpose

Having these reference documents saves time when writing queries by:
- Knowing exact column names and data types
- Understanding relationships between tables
- Having example queries ready to use
- Avoiding "Invalid column name" errors

## Tables Documented

1. **PartQty** - Part quantities at locations
2. **PartLocation** - Physical warehouse locations
3. **PartTransaction** - Part movement history
4. **SOHeader** - Sales order headers
5. **ROHeader** - Return order headers

## Common Query Patterns

- **Finding Parts from Customer Reference** - How to find part numbers associated with a customer reference across different tables

## How to Use

1. Check the relevant table structure document before writing queries
2. Use the example queries as templates
3. Reference column names and relationships
4. Understand data types to avoid errors

## Adding New Tables

When investigating a new table:
1. Run structure query to get column names
2. Create a new markdown file with the structure
3. Document key relationships
4. Add example queries
5. Update this README

## Quick Reference

### Common Program IDs
- **10068** = ADT
- **10072** = ADT (alternate)
- **10053** = Memphis DELL

### Common Configuration IDs
- **1** = Good
- **2** = Bad

### Common Status IDs (SOHeader/ROHeader)
- **3** = CANCELED
- **7** = NEW
- **12** = RESERVED
- **13** = PARTIALLYRESERVED
- **18** = SHIPPED

### Common Warehouse Values (PartLocation)
- **FGI** = Finished Goods Inventory (pickable)
- **SCRAP** = Scrap location (NOT pickable)
- **RESERVE** = Reserve location
- **STAGE** = Staging area

