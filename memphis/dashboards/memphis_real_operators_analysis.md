# 👥 MEMPHIS REAL OPERATORS ANALYSIS

## 🎯 **ACTUAL SHOP FLOOR WORKFORCE DISCOVERED**

> **✅ CONFIRMED:** Found 863 real Memphis operators (UserType = NULL) with production activity data.

---

## 📊 **TOP PERFORMING OPERATORS**

### **🏆 HIGHEST PRODUCTION VOLUME:**
| Operator | Full Name | Components Processed | Last Activity |
|----------|-----------|---------------------|---------------|
| `imran.murtaza@reconext.com` | Imran Murtaza | **23,056** | 2025-09-10 |
| `marco.cantu@reconext.com` | Marco Anibal Cantu Jimenez | **9,887** | 2024-07-02 |
| `raul.martinez@reconext.com` | Raul Martinez Enriquez | **4,692** | 2021-07-30 |
| `ariadna.fernandez@reconext.com` | Ariadna Alexia Fernandez Marreros | **4,609** | 2021-07-31 |
| `adan.arzola@reconext.com` | Adan Roberto Arzola Perez | **3,333** | 2025-08-19 |

### **⚡ CURRENTLY ACTIVE (2025):**
| Operator | Full Name | Components | Last Activity | Status |
|----------|-----------|------------|---------------|---------|
| `imran.murtaza@reconext.com` | Imran Murtaza | 23,056 | 2025-09-10 | **ACTIVE** |
| `pradhumna.aryal@reconext.com` | Pradhumna Aryal | 402 | 2025-09-10 | **ACTIVE** |
| `sara.corona@reconext.com` | Sara Corona Cortez | 230 | 2025-09-05 | **ACTIVE** |
| `adan.arzola@reconext.com` | Adan Roberto Arzola Perez | 3,333 | 2025-08-19 | **ACTIVE** |
| `luis.marquez@reconext.com` | Luis Manuel Marquez Bello | 165 | 2025-09-09 | **ACTIVE** |

---

## 🔧 **UPDATED DASHBOARD QUERIES FOR REAL OPERATORS**

### **Query 1: Real Memphis Shop Floor Operators Performance**
```sql
-- Real Memphis shop floor operators with production activity
SELECT 
    u.Username as Operator,
    u.FirstName + ' ' + u.LastName as FullName,
    COUNT(*) as ComponentsProcessed,
    CASE 
        WHEN SUM(wu.QtyIssued) > 0 THEN 
            ROUND(CAST(SUM(wu.QtyConsumed) as FLOAT) / SUM(wu.QtyIssued) * 100, 2)
        ELSE 100 
    END as EfficiencyRate,
    ws.Description as PreferredWorkstation,
    MAX(wu.ConsumedDate) as LastActivity,
    DATEDIFF(MINUTE, MIN(wu.ConsumedDate), MAX(wu.ConsumedDate)) as ActiveMinutes
FROM pls.WOUnit wu
INNER JOIN pls.WOLine wl ON wu.WOLineID = wl.ID
INNER JOIN pls.WOHeader wh ON wl.WOHeaderID = wh.ID
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
INNER JOIN pls.[User] u ON wu.ConsumedUserID = u.ID
LEFT JOIN pls.CodeWorkStation ws ON wu.ConsumeWorkStationID = ws.ID
WHERE p.Site = 'MEMPHIS' 
    AND wu.ConsumedUserID IS NOT NULL
    AND u.UserType IS NULL  -- Focus on shop floor operators only
GROUP BY u.Username, u.FirstName, u.LastName, ws.Description
ORDER BY ComponentsProcessed DESC;
```

### **Query 2: Real Operators Workstation Utilization**
```sql
-- Workstation utilization by real shop floor operators
SELECT 
    ws.Description as WorkstationDescription,
    COUNT(*) as ActiveOrders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as UtilizationPercent,
    COUNT(DISTINCT u.Username) as OperatorsActive
FROM pls.WOHeader wh
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
INNER JOIN pls.CodeWorkStation ws ON wh.WorkStationID = ws.ID
INNER JOIN pls.[User] u ON wh.UserID = u.ID
INNER JOIN pls.CodeStatus st ON wh.StatusID = st.ID
WHERE p.Site = 'MEMPHIS' 
    AND wh.LastActivityDate >= DATEADD(DAY, -30, GETDATE())
    AND st.Description = 'WIP'
    AND u.UserType IS NULL  -- Real operators only
GROUP BY ws.Description
ORDER BY ActiveOrders DESC;
```

### **Query 3: Real Operators Performance Trends**
```sql
-- Performance trends for real shop floor operators
SELECT 
    u.Username as Operator,
    u.FirstName + ' ' + u.LastName as FullName,
    CAST(wu.ConsumedDate AS DATE) as WorkDate,
    COUNT(*) as DailyComponents,
    CASE 
        WHEN SUM(wu.QtyIssued) > 0 THEN 
            ROUND(CAST(SUM(wu.QtyConsumed) as FLOAT) / SUM(wu.QtyIssued) * 100, 2)
        ELSE 100 
    END as DailyEfficiency,
    COUNT(DISTINCT ws.Description) as WorkstationsUsed
FROM pls.WOUnit wu
INNER JOIN pls.WOLine wl ON wu.WOLineID = wl.ID
INNER JOIN pls.WOHeader wh ON wl.WOHeaderID = wh.ID
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
INNER JOIN pls.[User] u ON wu.ConsumedUserID = u.ID
LEFT JOIN pls.CodeWorkStation ws ON wu.ConsumeWorkStationID = ws.ID
WHERE p.Site = 'MEMPHIS' 
    AND wu.ConsumedDate >= DATEADD(DAY, -30, GETDATE())
    AND wu.ConsumedUserID IS NOT NULL
    AND u.UserType IS NULL  -- Real operators only
GROUP BY u.Username, u.FirstName, u.LastName, CAST(wu.ConsumedDate AS DATE)
ORDER BY Operator, WorkDate;
```

---

## 📈 **KEY INSIGHTS**

### **Workforce Composition:**
- **Total Real Operators:** 863 (UserType = NULL)
- **Active in 2025:** ~15 operators with recent activity
- **Top Performer:** Imran Murtaza (23,056 components)
- **Production Range:** 1 to 23,056 components per operator

### **Operational Patterns:**
- **High Volume Operators:** 5 operators with 3,000+ components
- **Consistent Performers:** 20+ operators with 100+ components
- **Specialized Roles:** Various workstation specializations
- **Recent Activity:** Strong 2025 performance data

### **Dashboard Focus:**
- **Primary Target:** Real shop floor operators (UserType = NULL)
- **Performance Metrics:** Components processed, efficiency rates
- **Workstation Analysis:** Actual production floor utilization
- **Trend Analysis:** Daily performance patterns

---

## 🎨 **DASHBOARD COLOR CODING FOR REAL OPERATORS**

### **Performance Tiers:**
- 🟢 **ELITE (5,000+ components):** Imran Murtaza, Marco Cantu
- 🟡 **HIGH (1,000-4,999 components):** Raul Martinez, Ariadna Fernandez, Adan Arzola
- 🔵 **GOOD (100-999 components):** 20+ consistent performers
- ⚫ **TRAINING (1-99 components):** New or specialized operators

### **Activity Status:**
- 🟢 **CURRENTLY ACTIVE:** 2025 activity
- 🟡 **RECENT:** 2024 activity
- 🔴 **INACTIVE:** 2021-2023 only

---

## 🚀 **NEXT STEPS**

1. **Test Updated Queries:** Verify all 3 queries work with real operator data
2. **Build Power BI Dashboard:** Use real operator queries for accurate workforce intelligence
3. **Focus on Active Operators:** Prioritize 2025 active workforce in dashboard
4. **Performance Analysis:** Track top performers and identify training opportunities

---

*This analysis provides the foundation for building an accurate Memphis Workforce Dashboard focused on real shop floor operators rather than system users.*






























