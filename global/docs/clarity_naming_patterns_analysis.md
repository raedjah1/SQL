# Clarity Database - Naming Patterns Analysis

Based on the naming conventions query results, here are the key patterns that reveal how Clarity is structured:

## **Most Common Columns (The Database "DNA")**

### **🔑 Core Identity & Tracking**
- **REGION** (254 tables) - Geographic/organizational divisions
- **ROWVERSION** (240 tables) - Optimistic concurrency control
- **CreateDate** (194 tables) - When records were created
- **ID** (185 tables) - Primary identifiers
- **ProgramID** (180 tables) - Which program/project this belongs to
- **Username** (179 tables) - Audit trail - who made changes
- **LastActivityDate** (172 tables) - When last modified

### **🏭 Manufacturing Core Fields**
- **CONTRACT** (163 tables) - Business contract/site identifier
- **PART_NO/PartNo** (124+103 tables) - Part numbers everywhere
- **ORDER_NO** (78 tables) - Order numbers
- **SerialNo** (75 tables) - Serial number tracking
- **RELEASE_NO** (60 tables) - Release/version control

### **📊 Business Logic Fields**
- **Status** (42 tables) - Current state tracking
- **Description** (49+44 tables) - Human-readable descriptions
- **Value** (44 tables) - Numeric values/measurements
- **AttributeName** (38 tables) - Configurable attributes

## **Table Naming Prefixes (Business Areas)**

### **🗂️ Temporary/Working Tables**
- **tmp** (134 tables) - Temporary processing tables

### **📦 Inventory Management**
- **INV** (19 tables) - Inventory operations
- **Examples**: INV_PART_STOCK, INV_TRANSACTION_HIST

### **🛒 Purchasing & Procurement**
- **PUR** (11 tables) - Purchase orders and procurement
- **Examples**: PUR_ORDER_LINE, PUR_RECEIPT

### **👥 Customer Management**
- **CUS** (9 tables) - Customer data
- **Examples**: CUSTOMER_INFO, CUST_ORDER_LINE

### **🏢 Company/Organization**
- **COM** (8 tables) - Company-wide settings
- **SUP** (7 tables) - Supplier management

### **🔄 Routing & Manufacturing**
- **ROU** (6 tables) - Manufacturing routing
- **SHO** (4 tables) - Shop orders
- **MAN** (3 tables) - Manufacturing operations

### **💰 Sales & Orders**
- **SAL** (4 tables) - Sales operations
- **ORD** (4 tables) - Order management

### **🚚 Shipping & Logistics**
- **SHI** (3 tables) - Shipping operations

## **Key Business Insights from Patterns**

### **1. This is a Multi-Site, Multi-Program Operation**
- **REGION** in 254 tables = Global/multi-site operations
- **ProgramID** in 180 tables = Multiple customer programs/projects
- **CONTRACT** in 163 tables = Multiple business contracts

### **2. Heavy Manufacturing Focus**
- **PART_NO** variations in 227+ tables = Everything revolves around parts
- **SerialNo** in 75 tables = Individual unit tracking
- **ORDER_NO** in 78 tables = Order-driven manufacturing

### **3. Comprehensive Audit System**
- **Username** in 179 tables = Who did what
- **CreateDate** in 194 tables = When it happened
- **LastActivityDate** in 172 tables = When last touched
- **ROWVERSION** in 240 tables = Change tracking

### **4. Complex Configuration Management**
- **CONFIGURATION_ID** in 54 tables = Configurable products
- **AttributeName** in 38 tables = Flexible attributes
- **Value** in 44 tables = Attribute values

### **5. Quality & Status Tracking**
- **Status** in 42 tables = Everything has status
- **ROWSTATE** in 80 tables = Workflow states
- **StatusDescription** in 37 tables = Human-readable status

## **Common Query Patterns You'll Need**

### **Find Active Records**
```sql
WHERE Status = 'Active' 
  AND ROWSTATE = 'Released'
```

### **Recent Activity**
```sql
WHERE LastActivityDate >= DATEADD(day, -7, GETDATE())
  OR CreateDate >= DATEADD(day, -7, GETDATE())
```

### **User Activity Tracking**
```sql
WHERE Username = 'specific.user'
  AND CreateDate BETWEEN 'start_date' AND 'end_date'
```

### **Part-Related Queries**
```sql
WHERE PART_NO LIKE 'ABC%'
  OR PartNo LIKE 'ABC%'
```

### **Program/Contract Filtering**
```sql
WHERE ProgramID = 'CUSTOMER_A'
  AND CONTRACT = 'SITE_01'
  AND REGION = 'NORTH_AMERICA'
```

## **Navigation Tips**

### **When Looking for Tables:**
1. **Manufacturing**: Look for SHO*, MAN*, ROU* prefixes
2. **Inventory**: Look for INV* prefix
3. **Orders**: Look for ORD*, SAL*, PUR* prefixes
4. **Customer Data**: Look for CUS*, SUP* prefixes
5. **Temporary/Processing**: Look for tmp* prefix

### **When Writing Queries:**
1. **Always consider REGION** if you need site-specific data
2. **Use ProgramID** to filter by customer program
3. **Check Status/ROWSTATE** for active records only
4. **Include Username** for audit requirements
5. **Use PART_NO/PartNo** as your primary join key

## **Red Flags to Watch For**

### **Performance Concerns:**
- **tmp** tables (134 of them) - may be large and temporary
- Tables with **ROWVERSION** need careful handling for updates
- **REGION** filtering is probably essential for performance

### **Data Quality:**
- Multiple naming conventions (PART_NO vs PartNo)
- Mixed case sensitivity patterns
- Temporary tables mixed with production data

This analysis shows Clarity is a **sophisticated, multi-site manufacturing ERP** with extensive audit trails, configurable products, and complex business workflows!
