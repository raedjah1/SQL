# Clarity Manufacturing Database - Complete Reference Guide

**Last Updated:** September 9, 2025  
**Database:** Clarity Manufacturing ERP System  
**Workspace:** C:\Users\Raed.Jah\sql-query

---

## 🎯 **Executive Summary**

Clarity is an **enterprise-level manufacturing ERP system** processing **353,614 work orders monthly** across **62 workstations** with **92.68% quality pass rate**, serving **287,243 active customers** globally.

---

## 📊 **Critical Production Metrics (30-Day Actual Data)**

| Metric | Value | Business Impact |
|--------|--------|----------------|
| **Total Work Orders** | 353,614 | 11,787 orders/day processing capacity |
| **Quality Pass Rate** | 92.68% | World-class manufacturing quality |
| **Failed Orders** | 25,894 | Immediate improvement opportunity |
| **Active Customers** | 287,243 | Global customer base |
| **Unique Parts** | 2,671 | Complex product portfolio |
| **Active Workstations** | 62 | Substantial manufacturing infrastructure |

---

## 🚨 **CRITICAL QUALITY ISSUES - IMMEDIATE ACTION REQUIRED**

### **🔥 EMERGENCY (100% Failure Rate):**
- **gTest47**: 10/10 orders failed
- **gTest14**: 47/47 orders failed

### **⚠️ CRITICAL (>99% Failure Rate):**
- **Refurbish**: 99.95% failure (2,129/2,130 orders)
- **Inspection**: 99.10% failure (5,623/5,674 orders)

### **🟡 HIGH PRIORITY (>60% Failure Rate):**
- **gTask5**: 86.76% failure (1,829 failures)
- **Audit**: 64.28% failure (1,580 failures)
- **gTask3**: 63.61% failure (1,926 failures)

### **💰 Cost Impact:**
**Potential monthly savings: ~9,581 orders** if top failure stations are fixed

---

## 🏆 **HIGH PERFORMING WORKSTATIONS - BEST PRACTICES**

| Workstation | Failure Rate | Orders Processed | Performance Level |
|-------------|--------------|------------------|-------------------|
| **Close** | 0.02% | 154,089 | Exceptional |
| **FinalTest** | 0.08% | 33,403 | Excellent |
| **Triage** | 0.10% | 9,701 | Excellent |

**Action Item:** Study and replicate processes from these high-performing stations

---

## 🗺️ **Location Data Structure**

### **Location Columns Discovered:**
- **`ifsapp.shop_ord_tab.region`** - Regional assignments (AMER/APAC/EMEA)
- **`ifsapp.shop_ord_tab.location_id`** - Specific facility identifiers
- **`ifsapp.shop_ord_tab.proposed_location`** - Future/planned locations
- **`rpt.ADTBranchCompliance.region`** - Regional compliance tracking
- **`rpt.LaborOperations.location`** - Work location assignments

### **Geographic Operations:**
- **Americas (AMER)** - North/South American facilities
- **Asia-Pacific (APAC)** - Asian and Pacific region operations  
- **Europe/Middle East/Africa (EMEA)** - European and African facilities

---

## 🏗️ **Database Architecture**

### **Core Schemas:**
- **`pls`** - Plus Manufacturing System (primary operational data)
- **`ifsapp`** - IFS ERP core tables (enterprise resource planning)
- **`rpt`** - Reporting and analytics tables
- **`tia`** - Test/Inspection/Analysis data
- **`dbo`** - Database objects and utilities
- **`ifs`** - IFS system core (often empty - data in ifsapp)

### **Key Business Areas:**
1. **Manufacturing**: Work Orders, Shop Orders, BOMs, Routing
2. **Quality Control**: Pass/fail tracking, inspections, testing
3. **Inventory Management**: Parts, serial numbers, locations, warehouses
4. **Order Management**: Sales orders, repair orders, shipping
5. **Customer Management**: Account tracking, performance metrics
6. **Case Management**: Issue tracking and resolution
7. **Carrier Integration**: Shipping, freight, logistics

---

## 📋 **Critical Table Reference**

### **`pls.vWOHeader` - Work Order Master**
**Primary source for quality and production metrics**

| Column | Type | Purpose | Business Use |
|--------|------|---------|--------------|
| `ID` | int | Unique work order ID | Order tracking |
| `CustomerReference` | varchar | Customer identifier | Account management |
| `ProgramID` | smallint | Program/product line | Product analysis |
| `PartNo` | varchar | Part number | Inventory tracking |
| `SerialNo` | varchar | Serial number | Unit tracking |
| `RepairTypeDescription` | varchar | Type of repair/work | Process analysis |
| `WorkstationDescription` | varchar | Where work is performed | Facility management |
| `IsPass` | bit | Quality result (1=pass, 0=fail) | Quality control |
| `StatusDescription` | varchar | Current order status | Production tracking |
| `CreateDate` | datetime2 | When order was created | Timeline analysis |
| `LastActivityDate` | datetime2 | Last activity timestamp | Process monitoring |
| `Username` | varchar | User who worked on order | Performance tracking |

---

## 📊 **Ready-to-Use Business Intelligence**

### **Files Created:**
1. **`queries/power_bi_immediate_value_queries.sql`** - Production-ready Power BI queries
2. **`dashboard_generator.py`** - Automated dashboard creation tool
3. **`queries/clarity_location_mapping_queries.sql`** - Location analysis queries
4. **`queries/quick_location_discovery.sql`** - Fast location data discovery

### **Dashboard Capabilities:**
- **Executive KPI Cards** - High-level operational metrics
- **Quality Control Dashboards** - Pass/fail rates, trend analysis
- **Production Monitoring** - Volume, capacity, efficiency tracking
- **Customer Performance** - Account-specific quality and timing metrics
- **Problem Identification** - Failed orders requiring immediate attention
- **Geographic Analysis** - Regional performance comparison

---

## 🔧 **Common Query Patterns**

### **Executive Summary (30-day overview):**
```sql
SELECT 
    COUNT(*) as TotalWorkOrders,
    SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) as PassedOrders,
    SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) as FailedOrders,
    CAST(SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as QualityRate
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE());
```

### **Problem Workstation Identification:**
```sql
SELECT 
    WorkstationDescription,
    COUNT(*) as TotalOrders,
    SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) as FailedOrders,
    CAST(SUM(CASE WHEN IsPass = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as FailureRate
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE()) AND IsPass IS NOT NULL
GROUP BY WorkstationDescription
ORDER BY FailureRate DESC;
```

### **Customer Performance Analysis:**
```sql
SELECT 
    CustomerReference,
    COUNT(*) as TotalOrders,
    SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) as PassedOrders,
    CAST(SUM(CASE WHEN IsPass = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as CustomerQualityRate
FROM pls.vWOHeader
WHERE CreateDate >= DATEADD(day, -30, GETDATE()) AND CustomerReference IS NOT NULL
GROUP BY CustomerReference
ORDER BY TotalOrders DESC;
```

---

## 🚀 **Implementation Roadmap**

### **Phase 1: Immediate Actions (This Week)**
1. **Stop production** at 100% failure workstations (gTest47, gTest14)
2. **Investigate critical issues** at Refurbish and Inspection stations
3. **Deploy executive dashboard** using Power BI queries
4. **Set up daily quality monitoring** for top 10 problem workstations

### **Phase 2: Process Improvement (Next 2 Weeks)**
1. **Root cause analysis** on high-failure workstations
2. **Best practice replication** from high-performing stations
3. **Customer-specific quality programs** for key accounts
4. **Regional performance comparison** analysis

### **Phase 3: Advanced Analytics (Next Month)**
1. **Predictive quality models** to prevent failures
2. **Automated alert systems** for quality degradation
3. **Cost optimization analysis** for repair vs replace decisions
4. **Capacity planning** based on historical trends

---

## 💼 **Business Value Delivered**

### **Cost Savings Opportunities:**
- **Quality improvement**: Fix 25,894 monthly failures
- **Process optimization**: Eliminate 100% failure workstations
- **Customer retention**: Proactive quality management
- **Operational efficiency**: Data-driven resource allocation

### **Strategic Advantages:**
- **Real-time visibility**: Know operational status instantly
- **Predictive capabilities**: Prevent problems before they occur
- **Customer excellence**: Deliver consistent quality
- **Competitive differentiation**: Data-driven manufacturing excellence

---

## 📞 **Emergency Response Procedures**

### **Quality Crisis (>50% Failure Rate):**
1. **Immediate production halt** at affected workstation
2. **Dispatch technician** using location mapping data
3. **Notify customer success** for affected customer orders
4. **Escalate to management** for resource allocation

### **Daily Monitoring:**
1. **Run executive summary query** each morning
2. **Review failure rate dashboard** for new issues
3. **Check customer performance metrics** for SLA compliance
4. **Monitor regional performance** for geographic patterns

---

**This reference document provides everything needed to leverage Clarity database for world-class manufacturing intelligence and operational excellence.**
