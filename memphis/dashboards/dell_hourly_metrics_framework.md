# DELL HOURLY METRICS FRAMEWORK

## 🎯 **HOURLY PERFORMANCE METRICS BY SPECIALIZATION**

**Based on**: ADT hourly dashboard approach (80 transactions/hour target)  
**Target**: Clear hourly KPIs for each DELL specialization  
**Implementation**: Power BI conditional formatting with color-coded status

---

## 📊 **DASHBOARD 1: WAREHOUSE OPERATIONS - HOURLY METRICS**

### **Primary Specialists**: WH-MOVEPART operators
### **Target Rate**: 80 transactions/hour (same as ADT)

**Key Operators & Their Hourly Performance:**
- **kimberly.smith** (81,301 total) → **~135 transactions/hour**
- **jerrica.applewhite** (67,977 total) → **~113 transactions/hour**
- **heriberto.figueroa** (66,784 total) → **~111 transactions/hour**
- **dawnesty.lindsey** (57,417 total) → **~96 transactions/hour**
- **loueshea.henderson** (40,969 total) → **~68 transactions/hour**

**Hourly KPI Logic:**
```sql
-- Warehouse Operations Hourly Performance
SELECT
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    CASE
        WHEN COUNT(*) >= 100 THEN 'GREEN - Excellent (125% of target)'
        WHEN COUNT(*) >= 80 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 64 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN COUNT(*) >= 40 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    ROUND(COUNT(*) * 100.0 / 80, 2) as PerformancePercentage
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.PartTransaction = 'WH-MOVEPART'  -- Warehouse operations
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, DATEPART(hour, pt.CreateDate)
ORDER BY pt.Username, WorkHour;
```

**Color Coding:**
- **🟢 GREEN**: 80+ transactions/hour (Target Met)
- **🟡 YELLOW**: 64-79 transactions/hour (80% of target)
- **🔴 RED**: <64 transactions/hour (Below target)

---

## 📊 **DASHBOARD 2: MANUFACTURING OPERATIONS - HOURLY METRICS**

### **Primary Specialists**: WO-CONSUMECOMPONENTS / WO-ISSUEPART operators
### **Target Rate**: 60 transactions/hour (manufacturing complexity)

**Key Operators & Their Hourly Performance:**
- **timothy.payne** (78,460 total) → **~131 transactions/hour**
- **dawnesty.lindsey** (57,417 total) → **~96 transactions/hour**
- **maurice.mcdavid** (48,596 total) → **~81 transactions/hour**
- **nubia.perez** (28,101 total) → **~47 transactions/hour**
- **fabrian.moton** (25,206 total) → **~42 transactions/hour**

**Hourly KPI Logic:**
```sql
-- Manufacturing Operations Hourly Performance
SELECT
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    CASE
        WHEN COUNT(*) >= 75 THEN 'GREEN - Excellent (125% of target)'
        WHEN COUNT(*) >= 60 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 48 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN COUNT(*) >= 30 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    ROUND(COUNT(*) * 100.0 / 60, 2) as PerformancePercentage
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.PartTransaction IN ('WO-CONSUMECOMPONENTS', 'WO-ISSUEPART')  -- Manufacturing
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, DATEPART(hour, pt.CreateDate)
ORDER BY pt.Username, WorkHour;
```

**Color Coding:**
- **🟢 GREEN**: 60+ transactions/hour (Target Met)
- **🟡 YELLOW**: 48-59 transactions/hour (80% of target)
- **🔴 RED**: <48 transactions/hour (Below target)

---

## 📊 **DASHBOARD 3: SALES OPERATIONS - HOURLY METRICS**

### **Primary Specialists**: SO-RESERVE / SO-SHIP operators
### **Target Rate**: 40 transactions/hour (sales complexity)

**Key Operators & Their Hourly Performance:**
- **chris.jefferson** (24,055 total) → **~40 transactions/hour**
- **donxabe.burton** (20,260 total) → **~34 transactions/hour**
- **marico.simpson** (18,397 total) → **~31 transactions/hour**
- **shevecia.greene** (17,139 total) → **~29 transactions/hour**
- **steffon.oliver** (2,851 total) → **~5 transactions/hour**

**Hourly KPI Logic:**
```sql
-- Sales Operations Hourly Performance
SELECT
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    CASE
        WHEN COUNT(*) >= 50 THEN 'GREEN - Excellent (125% of target)'
        WHEN COUNT(*) >= 40 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 32 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN COUNT(*) >= 20 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    ROUND(COUNT(*) * 100.0 / 40, 2) as PerformancePercentage
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.PartTransaction IN ('SO-RESERVE', 'SO-SHIP')  -- Sales operations
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, DATEPART(hour, pt.CreateDate)
ORDER BY pt.Username, WorkHour;
```

**Color Coding:**
- **🟢 GREEN**: 40+ transactions/hour (Target Met)
- **🟡 YELLOW**: 32-39 transactions/hour (80% of target)
- **🔴 RED**: <32 transactions/hour (Below target)

---

## 📊 **DASHBOARD 4: REPAIR OPERATIONS - HOURLY METRICS**

### **Primary Specialists**: RO-RECEIVE / RO-CLOSE operators
### **Target Rate**: 30 transactions/hour (repair complexity)

**Key Operators & Their Hourly Performance:**
- **alexis.scott** (15,751 total) → **~26 transactions/hour**
- **andre.martin** (12,843 total) → **~21 transactions/hour**
- **charlotte.lanier** (924 total) → **~2 transactions/hour**
- **raed.jah** (585 total) → **~1 transaction/hour**

**Hourly KPI Logic:**
```sql
-- Repair Operations Hourly Performance
SELECT
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    CASE
        WHEN COUNT(*) >= 38 THEN 'GREEN - Excellent (125% of target)'
        WHEN COUNT(*) >= 30 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 24 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN COUNT(*) >= 15 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    ROUND(COUNT(*) * 100.0 / 30, 2) as PerformancePercentage
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.PartTransaction IN ('RO-RECEIVE', 'RO-CLOSE')  -- Repair operations
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
GROUP BY pt.Username, DATEPART(hour, pt.CreateDate)
ORDER BY pt.Username, WorkHour;
```

**Color Coding:**
- **🟢 GREEN**: 30+ transactions/hour (Target Met)
- **🟡 YELLOW**: 24-29 transactions/hour (80% of target)
- **🔴 RED**: <24 transactions/hour (Below target)

---

## 📊 **DASHBOARD 5: CROSS-FUNCTIONAL - HOURLY METRICS**

### **Primary Specialists**: Multi-specialist operators
### **Target Rate**: 100 transactions/hour (combined operations)

**Key Operators & Their Hourly Performance:**
- **heriberto.figueroa** (28 transaction types) → **~111 transactions/hour**
- **dawnesty.lindsey** (23 transaction types) → **~96 transactions/hour**
- **kimberly.smith** (22 transaction types) → **~135 transactions/hour**
- **cambria.herzon** (21 transaction types) → **~47 transactions/hour**

**Hourly KPI Logic:**
```sql
-- Cross-Functional Hourly Performance
SELECT
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    CASE
        WHEN COUNT(*) >= 125 THEN 'GREEN - Excellent (125% of target)'
        WHEN COUNT(*) >= 100 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 80 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN COUNT(*) >= 50 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    ROUND(COUNT(*) * 100.0 / 100, 2) as PerformancePercentage
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
  -- Multi-specialist operators (20+ transaction types)
  AND pt.Username IN (
      'heriberto.figueroa', 'dawnesty.lindsey', 'kimberly.smith', 'cambria.herzon'
  )
GROUP BY pt.Username, DATEPART(hour, pt.CreateDate)
ORDER BY pt.Username, WorkHour;
```

**Color Coding:**
- **🟢 GREEN**: 100+ transactions/hour (Target Met)
- **🟡 YELLOW**: 80-99 transactions/hour (80% of target)
- **🔴 RED**: <80 transactions/hour (Below target)

---

## 📊 **DASHBOARD 6: QUALITY & COMPLIANCE - HOURLY METRICS**

### **Primary Specialists**: Quality control operators
### **Target Rate**: 20 transactions/hour (quality focus)

**Key Operators & Their Hourly Performance:**
- **damon.pike** (7,000+ total) → **~12 transactions/hour**
- **dominique.gray** (7,000+ total) → **~12 transactions/hour**
- **michelle.fuenmayor** (4,000+ total) → **~7 transactions/hour**

**Hourly KPI Logic:**
```sql
-- Quality & Compliance Hourly Performance
SELECT
    pt.Username as Operator,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    CASE
        WHEN COUNT(*) >= 25 THEN 'GREEN - Excellent (125% of target)'
        WHEN COUNT(*) >= 20 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 16 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN COUNT(*) >= 10 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    ROUND(COUNT(*) * 100.0 / 20, 2) as PerformancePercentage
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
  -- Quality control operators
  AND pt.Username IN (
      'damon.pike', 'dominique.gray', 'michelle.fuenmayor'
  )
GROUP BY pt.Username, DATEPART(hour, pt.CreateDate)
ORDER BY pt.Username, WorkHour;
```

**Color Coding:**
- **🟢 GREEN**: 20+ transactions/hour (Target Met)
- **🟡 YELLOW**: 16-19 transactions/hour (80% of target)
- **🔴 RED**: <16 transactions/hour (Below target)

---

## 📊 **DASHBOARD 7: EXECUTIVE OVERVIEW - HOURLY METRICS**

### **Target Users**: Site Managers, Regional Directors
### **Target Rate**: 50 transactions/hour (overall average)

**Hourly KPI Logic:**
```sql
-- Executive Overview Hourly Performance
SELECT
    'DELL OVERALL' as Program,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    CASE
        WHEN COUNT(*) >= 63 THEN 'GREEN - Excellent (125% of target)'
        WHEN COUNT(*) >= 50 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 40 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN COUNT(*) >= 25 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    ROUND(COUNT(*) * 100.0 / 50, 2) as PerformancePercentage
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
GROUP BY DATEPART(hour, pt.CreateDate)
ORDER BY WorkHour;
```

**Color Coding:**
- **🟢 GREEN**: 50+ transactions/hour (Target Met)
- **🟡 YELLOW**: 40-49 transactions/hour (80% of target)
- **🔴 RED**: <40 transactions/hour (Below target)

---

## 🎯 **POWER BI IMPLEMENTATION**

### **CONDITIONAL FORMATTING RULES**

**For Each Dashboard:**
1. **PerformancePercentage** field (Sum aggregation)
2. **Green**: >= 100% (Target Met)
3. **Yellow**: 80-99% (80% of target)
4. **Red**: <80% (Below target)

### **MATRIX VISUAL SETUP**
- **Rows**: Operator
- **Columns**: WorkHour (Text data type)
- **Values**: PerformancePercentage (Sum)
- **Conditional Formatting**: Based on PerformancePercentage

### **SLICERS**
- **Date Range**: Last 7 days, 30 days, 90 days
- **Specialization**: WH-MOVEPART, WO-CONSUMECOMPONENTS, etc.
- **Performance Level**: Green, Yellow, Red

---

## 🎯 **TARGET RATES SUMMARY**

| Specialization | Target Rate | Green Threshold | Yellow Threshold | Red Threshold |
|----------------|-------------|-----------------|------------------|---------------|
| **Warehouse Operations** | 80/hour | 80+ | 64-79 | <64 |
| **Manufacturing Operations** | 60/hour | 60+ | 48-59 | <48 |
| **Sales Operations** | 40/hour | 40+ | 32-39 | <32 |
| **Repair Operations** | 30/hour | 30+ | 24-29 | <24 |
| **Cross-Functional** | 100/hour | 100+ | 80-99 | <80 |
| **Quality & Compliance** | 20/hour | 20+ | 16-19 | <16 |
| **Executive Overview** | 50/hour | 50+ | 40-49 | <40 |

---

## 🎯 **CONCLUSION**

**ALL DELL SPECIALIZATIONS NOW HAVE CLEAR HOURLY METRICS** with:

1. ✅ **Specialized Target Rates** - Based on process complexity
2. ✅ **Color-Coded Performance** - Green/Yellow/Red status
3. ✅ **Consistent KPI Logic** - Same approach as ADT
4. ✅ **Power BI Ready** - Conditional formatting and matrix visuals
5. ✅ **Scalable Framework** - Easy to adjust targets as needed

**Ready to implement hourly dashboards for each specialization!** 🚀

