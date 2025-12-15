# Clarity Database - Table Sizes Analysis

## **🎯 Critical Discovery: Data Architecture**

The table sizes reveal the true architecture of Clarity:

### **Empty Core Tables (0 rows each):**
- **`ifs` schema** - IFS ERP structure tables (configuration only)
- **`tmp` schema** - Regional temporary tables (AMER, APAC, EMEA) - currently empty
- **Core `rpt` tables** - Some reporting tables are empty

### **This Means:**
1. **IFS ERP** provides the **framework and configuration**
2. **Plus Manufacturing (`pls`)** contains the **actual operational data**
3. **Regional processing** happens via temporary tables that get cleared after processing

## **💡 Power BI Strategy Implications**

### **Focus on `pls` Schema Tables**
Since the `pls` schema contains the real data, your Power BI models should prioritize:

```sql
-- Core operational tables to investigate:
pls.vWOHeader           -- Work Orders (manufacturing jobs)
pls.vWOStationHistory   -- Quality testing results  
pls.vPartSerial         -- Individual unit tracking
pls.vSOHeader           -- Sales Orders
pls.vROHeader           -- Repair Orders
pls.vPartLocation       -- Inventory locations
pls.vPartTransaction    -- Inventory movements
```

### **Configuration vs. Operational Data**
- **`ifs` tables** = Master data (part definitions, routing templates, etc.)
- **`pls` tables** = Transactional data (actual orders, tests, movements)
- **`rpt` tables** = Pre-aggregated reporting data

## **🚀 Recommended Next Steps**

### **1. Focus Your Analysis on `pls` Schema**
Run targeted queries to find the largest `pls` tables:

```sql
-- Find the biggest pls tables
SELECT 
    SCHEMA_NAME(t.schema_id) as SchemaName,
    t.name as TableName,
    p.rows as EstimatedRows,
    CAST(ROUND((SUM(a.total_pages) * 8) / 1024.0, 2) AS DECIMAL(10,2)) as SizeMB
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE SCHEMA_NAME(t.schema_id) = 'pls'
  AND p.index_id IN (0,1)
  AND p.rows > 0
GROUP BY t.schema_id, t.name, p.rows
ORDER BY p.rows DESC;
```

### **2. Investigate Key Operational Tables**
Focus on these high-value `pls` tables for Power BI:

#### **Manufacturing Operations:**
- `pls.vWOHeader` - Work order management
- `pls.vWOStationHistory` - Quality testing and manufacturing steps
- `pls.vWOUnit` - Individual units in production

#### **Order Management:**
- `pls.vSOHeader` / `pls.vSOLine` - Sales orders
- `pls.vROHeader` / `pls.vROLine` - Repair orders
- `pls.vSOShipmentInfo` - Shipping information

#### **Inventory & Parts:**
- `pls.vPartSerial` - Serial number tracking
- `pls.vPartLocation` - Inventory by location
- `pls.vPartTransaction` - Inventory movements

#### **Quality & Testing:**
- `pls.vQACheckAudit` - Quality audits
- `tia.vDataWipeResult` - Test results

### **3. Build Power BI Data Model Strategy**

#### **Star Schema Approach:**
- **Fact Tables**: Work orders, quality tests, inventory transactions
- **Dimension Tables**: Parts, locations, work stations, time
- **Bridge Tables**: Use `pls` operational data with `ifs` master data

#### **Performance Optimization:**
- Focus on `pls` tables with actual data
- Use `CreateDate` and `LastActivityDate` for incremental refresh
- Pre-filter by `ProgramID` and `REGION` for better performance

## **🎯 Immediate Power BI Wins**

### **1. Manufacturing Dashboard (Week 1)**
Focus on `pls.vWOStationHistory` for:
- Real-time quality pass/fail rates
- Work station performance
- Cycle time analysis

### **2. Inventory Dashboard (Week 2)**
Use `pls.vPartLocation` and `pls.vPartSerial` for:
- Current inventory levels
- Serial number tracking
- Part movement analysis

### **3. Order Management Dashboard (Week 3)**
Combine `pls.vSOHeader` and `pls.vROHeader` for:
- Order status tracking
- Fulfillment performance
- Customer service metrics

## **⚠️ Important Notes**

### **Regional Processing Pattern**
The empty `tmp` regional tables suggest:
1. Data gets loaded into regional temp tables
2. Processed and moved to operational `pls` tables
3. Temp tables are cleared after processing

### **Master Data Strategy**
- Use `ifs` tables for master data (even if small/empty)
- They contain the structure and configuration
- Join operational `pls` data with `ifs` master data for complete picture

### **Reporting Layer**
- `rpt` schema contains pre-built business views
- May have better performance than building from scratch
- Check which `rpt` tables have data for quick wins

This analysis shows you exactly where to focus your Power BI development efforts for maximum impact!
