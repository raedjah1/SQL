# Clarity Database - DateTime Analysis

Based on the datetime patterns query results, here are the key temporal insights for Power BI development:

## **🕐 Key DateTime Discoveries**

### **1. Global Multi-Region Operations Confirmed**
- **tmp tables by region**: `tmpAMER_*`, `tmpAPAC_*`, `tmpEMEA_*` (Americas, Asia-Pacific, Europe/Middle East/Africa)
- This confirms Clarity operates across **multiple global regions** with separate data processing
- **Power BI Impact**: You'll need region-specific filters and potentially separate data models

### **2. Comprehensive Audit Trail System**
**Every table has standardized datetime tracking:**
- **CreateDate** - When record was created (NOT NULL in pls schema)
- **LastActivityDate** - When last modified
- **ROWVERSION** - SQL Server optimistic concurrency control

### **3. Manufacturing Workflow Timestamps**
**Work Orders have complete lifecycle tracking:**
- **WOStartDate/WOEndDate** - Work order execution timeframe
- **RODate** (Repair Order date)
- **SODate** (Sales Order date)
- **StartDate/EndDate** - Work station processing times

### **4. Business Process Timestamps**
**Key business events are tracked:**
- **Order lifecycle**: `ORDER_DATE`, `PLANNED_DELIVERY_DATE`, `REAL_SHIP_DATE`
- **Repair process**: `START_REPAIR_DATE`, `FINISH_REPAIR_DATE`
- **Quality control**: Test start/end times in `tia` schema
- **Shipping**: `SHIPMENT_DATE`, `DELIVERY_DATE`

## **💡 Power BI Opportunities**

### **🎯 High-Impact Dashboards You Can Build**

#### **1. Manufacturing Performance Dashboard**
```sql
-- Work Order Cycle Time Analysis
SELECT 
    wo.WorkOrderNo,
    wo.PartNo,
    ps.WOStartDate,
    ps.WOEndDate,
    DATEDIFF(hour, ps.WOStartDate, ps.WOEndDate) as CycleTimeHours,
    wh.WorkStationCode,
    wh.IsPass
FROM pls.vWOHeader wo
JOIN pls.vPartSerial ps ON wo.ID = ps.WOHeaderID  
JOIN pls.vWOStationHistory wh ON wo.ID = wh.WOHeaderID
WHERE ps.WOStartDate >= DATEADD(month, -3, GETDATE())
```

#### **2. Real-Time Quality Dashboard**
```sql
-- Daily Pass/Fail Rates by Work Station
SELECT 
    CAST(wh.StartDate as DATE) as TestDate,
    wh.WorkStationCode,
    COUNT(*) as TotalTests,
    SUM(CASE WHEN wh.IsPass = 1 THEN 1 ELSE 0 END) as PassCount,
    CAST(SUM(CASE WHEN wh.IsPass = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as PassRate
FROM pls.vWOStationHistory wh
WHERE wh.StartDate >= DATEADD(day, -30, GETDATE())
GROUP BY CAST(wh.StartDate as DATE), wh.WorkStationCode
ORDER BY TestDate DESC, WorkStationCode
```

#### **3. Order Fulfillment Tracking**
```sql
-- Order-to-Ship Performance
SELECT 
    so.OrderNo,
    so.CreateDate as OrderCreateDate,
    si.ShipmentDate,
    DATEDIFF(day, so.CreateDate, si.ShipmentDate) as OrderToShipDays,
    so.CustomerReference,
    so.ProgramID
FROM pls.vSOHeader so
LEFT JOIN pls.vSOShipmentInfo si ON so.ID = si.SOHeaderID
WHERE so.CreateDate >= DATEADD(month, -6, GETDATE())
```

### **🚀 Advanced Analytics Opportunities**

#### **1. Predictive Quality Analysis**
- Use historical `IsPass` data with timestamps to predict failure patterns
- Identify work stations with degrading performance over time

#### **2. Inventory Optimization**
- Track `LastActivityDate` patterns to identify slow-moving inventory
- Predict demand based on historical order patterns

#### **3. Resource Utilization**
- Analyze work station busy/idle times using `StartDate/EndDate`
- Optimize scheduling based on historical cycle times

## **📊 Power BI Data Model Recommendations**

### **Date Dimension Strategy**
```sql
-- Create comprehensive date table for Power BI
WITH DateSeries AS (
    SELECT DATEADD(day, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, '2020-01-01') as DateValue
    FROM sys.objects a CROSS JOIN sys.objects b
)
SELECT 
    DateValue,
    YEAR(DateValue) as Year,
    MONTH(DateValue) as Month,
    DAY(DateValue) as Day,
    DATENAME(weekday, DateValue) as DayOfWeek,
    DATEPART(quarter, DateValue) as Quarter,
    CASE WHEN DATEPART(weekday, DateValue) IN (1,7) THEN 'Weekend' ELSE 'Weekday' END as DayType
FROM DateSeries 
WHERE DateValue <= GETDATE() + 365
```

### **Fact Table Design**
**Manufacturing Facts:**
- Grain: One row per work order operation
- Key dates: WOStartDate, WOEndDate, CreateDate
- Measures: CycleTime, PassRate, DefectCount

**Order Facts:**
- Grain: One row per order line
- Key dates: OrderDate, ShipDate, DeliveryDate  
- Measures: OrderToShipDays, OnTimeDelivery%

### **Incremental Refresh Strategy**
```sql
-- Use LastActivityDate for incremental refresh
WHERE LastActivityDate >= DATEADD(day, -7, GETDATE())
```

## **🎯 Quick Wins for Immediate Value**

### **1. Daily Operations Dashboard (1 week)**
- Work orders in progress
- Quality pass rates by work station
- Orders ready to ship

### **2. Executive KPI Dashboard (2 weeks)**  
- On-time delivery performance
- Manufacturing cycle times
- Quality trends

### **3. Operational Analytics (1 month)**
- Resource utilization analysis
- Bottleneck identification
- Predictive quality alerts

## **⚠️ Important Notes for Power BI**

### **Regional Data Handling**
- Filter by region early in your queries for performance
- Consider separate datasets per region if data volume is large

### **Temporal Filtering Best Practices**
- Always use `CreateDate` and `LastActivityDate` for incremental refresh
- Be aware that `ROWVERSION` is for concurrency, not business dates

### **Performance Optimization**
- Index on datetime columns is likely already in place
- Use date ranges in WHERE clauses to minimize data transfer

This datetime analysis shows you have **everything needed** to build world-class manufacturing analytics in Power BI!
