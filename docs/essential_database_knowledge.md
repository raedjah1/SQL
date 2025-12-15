# Essential Database Knowledge

## vPartTransaction Table Structure

**Table:** `pls.vPartTransaction`  
**Purpose:** Core transaction table for all part movements and adjustments

### Key Columns for Inventory Adjustments:

| Column | Type | Purpose |
|--------|------|---------|
| `ID` | Primary Key | Transaction identifier |
| `ProgramID` | Foreign Key | Program identifier (10068 = ADT) |
| `PartTransaction` | String | Transaction type (WH-ADDPART, WH-REMOVEPART, etc.) |
| `PartNo` | String | SKU/Part number |
| `SerialNo` | String | Serial number |
| `Qty` | Numeric | **Quantity affected** (NOT QtyRequested) |
| `Location` | String | From location |
| `ToLocation` | String | To location |
| `Username` | String | Operator who made the transaction |
| `CreateDate` | DateTime | Transaction timestamp |
| `Reason` | String | Notes/reason for adjustment |
| `CustomerReference` | String | Customer reference number |

### Inventory Adjustment Transaction Types:

| Transaction Type | Meaning | Adjustment Type |
|------------------|---------|-----------------|
| `WH-ADDPART` | Manual add parts | Up Adjust |
| `WH-REMOVEPART` | Manual remove parts | Down Adjust |
| `ERP-ADDPART` | ERP add parts | Up Adjust (ERP) |
| `ERP-REMOVEPART` | ERP remove parts | Down Adjust (ERP) |
| `WO-SCRAP` | Scrap adjustments | Inbound Scrap |
| `WH-DISCREPANCYRECEIVE` | Discrepancy adjustments | Discrepancy Adjust |

### Program Identifiers:

| ProgramID | Program Name | Description |
|-----------|--------------|-------------|
| 10068 | ADT | ADT security equipment program |
| 10053 | DELL | DELL manufacturing program |
| 10072 | Reynosa | Reynosa operations (new warehouse) |

### Excess Centralization (FWD) Program:

- **FWD** = "Excess Centralization" program
- **EX Numbers** = Primary identifier for excess returns (EX2506275, EX2506274, etc.)
- **RO-Header** = Tracks excess unit receiving with EX numbers
- **OrderType** = "Return To Stock" for excess returns
- **Status** = "NEW", "RECEIVED", "CANCELED", "PARTIALLYRECEIVED"

### Excess Centralization Workflow:

1. **Excess Unit Receiving:**
   - Units returned with **EX numbers** (EX2506275, etc.)
   - Tracked in `pls.vROHeader` with OrderType "Return To Stock"
   - Status shows receiving progress

2. **Inventory Transactions:**
   - **RO-RECEIVE** = When excess units are received into system
   - **WH-ADDPART/REMOVEPART** = Manual adjustments to excess inventory
   - **SO-SHIP** = When excess units are shipped out

3. **FWD Part Identification:**
   - **Part numbers** with "FWD" suffix (DS-2CD2122FWD-IS-2.8)
   - **Serial numbers** starting with "EXADT" (dummy serials from excess receiving)
   - **Customer references** with EX numbers

### Common Search Patterns:

```sql
-- Find inventory adjustments for ADT program
WHERE ProgramID = 10068
  AND PartTransaction IN ('WH-ADDPART', 'WH-REMOVEPART', 'ERP-ADDPART', 'ERP-REMOVEPART')

-- Find FWD references
WHERE (
    PartNo LIKE '%FWD%' OR
    SerialNo LIKE '%FWD%' OR
    Location LIKE '%FWD%' OR
    CustomerReference LIKE '%FWD%'
)

-- Find Excess Centralization returns
WHERE CustomerReference LIKE 'EX%'

-- Find excess unit receiving
SELECT * FROM pls.vROHeader 
WHERE ProgramID = 10068 
  AND OrderType = 'Return To Stock'
  AND CustomerReference LIKE 'EX%'

-- Find today's transactions
WHERE CreateDate >= CAST(GETDATE() as DATE)
```

### Important Notes:

1. **Quantity Field:** Use `Qty`, NOT `QtyRequested`
2. **Program Filter:** Always filter by `ProgramID` for program-specific data
3. **Date Filtering:** Use `CreateDate` for transaction timestamps
4. **Location Format:** Locations follow pattern like `3RMRAWG.ARB.0.0.0`
5. **Serial Numbers:** Can contain `*` for bulk operations
6. **Excess Centralization:** Use EX numbers (EX2506275) to track excess returns
7. **FWD vs EX:** FWD = part identification, EX = return tracking

## ECR (Excess Centralization Returns) Report Data Sources

### Report Requirements vs Data Availability

**✅ Available Data (80% Complete):**

| **Report Column** | **Data Source** | **Table.Column** | **Notes** |
|-------------------|-----------------|------------------|-----------|
| **Item No** | Part Master | `pls.vPartNo.PartNo` | Part number identification |
| **RDC Item** | Part Master | `pls.vPartNo.PartNo` | Same as Item No |
| **Item Description** | Part Master | `pls.vPartNo.Description` | Part description |
| **Qty to Return** | Return Orders | `pls.vROHeader` (planned) | From EX numbers |
| **Qty actually returned** | Transactions | `pls.vPartTransaction` (RO-RECEIVE) | Actual received quantity |
| **Delta** | Calculated | Qty to Return - Qty actually returned | Variance calculation |
| **INBOUND GOOD** | Transactions | `pls.vPartTransaction` (RO-RECEIVE) | Good quality received |
| **SCRAP** | Transactions | `pls.vPartTransaction` (WH-REMOVEPART to SCRAP) | Scrap quantity |
| **TOTAL** | Calculated | INBOUND GOOD + SCRAP | Total processed |
| **VARIANCE** | Calculated | Qty to Return - TOTAL | Quantity variance |
| **Box #** | Transactions | `pls.vPartTransaction.PalletBoxNo` | Box identifier |
| **Notes** | Transactions | `pls.vPartTransaction.Reason` | Transaction notes |

**❌ Missing Data (20% Complete):**

| **Report Column** | **Status** | **Required Source** | **Notes** |
|-------------------|------------|---------------------|-----------|
| **Organization** | Missing | Address/Location master | Map AddressID to org names (160 - Reno NV) |
| **Subinventory Code** | Missing | Location mapping | Map locations to codes (160EX009) |
| **Item Cost** | Missing | Cost table | Unit cost per part ($19.46, $17.00, etc.) |
| **Ext Cost** | Missing | Calculated | Qty to Return × Item Cost |
| **Returned Ext Cost** | Missing | Calculated | Qty actually returned × Item Cost |
| **SCRAP EXT COST** | Missing | Calculated | SCRAP quantity × Item Cost |
| **VARIANCE EXT COST** | Missing | Calculated | VARIANCE quantity × Item Cost |

### Data Flow for ECR Report

1. **Excess Returns Tracking:**
   - **EX numbers** (EX2506275) in `pls.vROHeader`
   - **OrderType** = "Return To Stock"
   - **Status** = "NEW", "RECEIVED", "CANCELED", "PARTIALLYRECEIVED"

2. **Part Master Data:**
   - **Part details** from `pls.vPartNo`
   - **Descriptions, commodities, types**

3. **Transaction Data:**
   - **RO-RECEIVE** = When excess units are received
   - **WH-REMOVEPART** = When units are scrapped
   - **Quantities, locations, operators**

4. **Missing Cost Data:**
   - Need to find cost table (likely `vPartCost` or similar)
   - Cost tied to PartNo, not EX number
   - Same part = Same cost across all returns

### Next Steps for Complete ECR Report

1. **Find cost table** for Item Cost data
2. **Find address table** for Organization mapping
3. **Create location mapping** for Subinventory codes
4. **Build calculated fields** for all cost columns

---

*Last Updated: October 2025*
*Source: Database schema analysis, query testing, and ECR report requirements*
