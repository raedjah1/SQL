
# Memphis Sales Order Table Structure

## **SO Table Architecture for Order Drop Dashboard**

### **Core Sales Order Tables**

#### **1. SOHeader (Order Master)**
- **Purpose**: Sales order header/master information
- **Key Fields**:
  - `ID` - Order ID
  - `ProgramID` - Program identifier (10053 = Memphis DELL)
  - `CustomerReference` - ASN/Customer reference
  - `StatusID` - Order status (7=NEW, 12=RESERVED, 13=PARTIALLYRESERVED, 18=SHIPPED, 3=CANCELED)
  - `AddressID` - Shipping address
  - `CreateDate` - Order drop date
  - `LastActivityDate` - Last activity timestamp
  - `UserID` - User who created order

#### **2. SOLine (Order Details)**
- **Purpose**: Individual line items on sales order
- **Key Fields**:
  - `ID` - Line ID
  - `SOHeaderID` - Links to order header
  - `PartNo` - Part number
  - `ConfigurationID` - Configuration
  - `QtyToShip` - Total quantity to ship (tags needed)
  - `QtyReserved` - **Quantity pulled/shipped** (this is the "shipped" quantity)
  - `StatusID` - Line status (18 = SHIPPED)
  - `CreateDate` - Line creation date
  - `LastActivityDate` - Last activity timestamp

**CRITICAL**: `QtyReserved` IS the shipped quantity. When `StatusID = 18` (SHIPPED), `QtyReserved` = `QtyToShip`

#### **3. SOHeaderAttribute (Order Attributes)**
- **Purpose**: Custom attributes on order header
- **Key Attributes**:
  - `ORDERTYPE` - Single vs Consolidated order
  - Values: 'OemOrderRequest', 'OemOrderRequestExg' = Consolidated
  - Other values = Single order

#### **4. SOLineAttribute (Line Item Attributes)**
- **Purpose**: Attributes on individual line items
- **Common Attributes**:
  - `SERVICETAG` - Service tag information
  - Various product/serial attributes

#### **5. SOPickList (Picker Assignments)**
- **Purpose**: Links pickers to orders/lines
- **Key Fields**:
  - `SOHeaderID` - Order being picked
  - `SOLineID` - Specific line being picked
  - `AssignedToUserID` - Picker assigned
  - `CreateDate` - Assignment date

#### **6. SOUnit (Shipped Units)**
- **Purpose**: Tracks actual shipped units
- **Key Fields**:
  - `SOHeaderID` - Links to order
  - `SOLineID` - Links to line
  - `SerialNo` - Serial number shipped
  - `ShippedDate` - Actual ship date

#### **7. SOConsolidatedShipmentHeader (Consolidated Shipments)**
- **Purpose**: Groups multiple orders for consolidated shipping
- **Key Fields**:
  - `ID` - Consolidation ID
  - Links multiple SOHeader records together
  - `StatusID` - Consolidation status

#### **8. SOConsolidatedShipmentLine (Consolidation Details)**
- **Purpose**: Links orders to consolidated shipments
- **Key Fields**:
  - `ConsolidatedShipmentID` - Links to header
  - `SOHeaderID` - Individual order in consolidation
  - `OrderSequence` - Sequence within consolidation

#### **9. SOShipmentInfo (Shipping Information)**
- **Purpose**: Carrier and tracking details
- **Key Fields**:
  - `SOHeaderID` - Order being shipped
  - `CarrierName` - Shipping carrier
  - `TrackingNumber` - Tracking number
  - `ShipDate` - Actual ship date

### **Supporting Tables**

#### **10. CodeOrderType (Order Type Lookup)**
- **Purpose**: Defines order type codes
- **Values**:
  - Single orders
  - Consolidated orders
  - Bulk orders

#### **11. SOBulkReservationLock (Bulk Processing)**
- **Purpose**: Locks for bulk reservation processing
- **Use**: Prevents conflicts during mass reservation operations

#### **12. SOFreightPackageDetails (Freight Info)**
- **Purpose**: Package-level freight information
- **Key Details**:
  - Weight, dimensions
  - Freight cost
  - Package tracking

#### **13. SOUnitPreReserved (Pre-Reservations)**
- **Purpose**: Advance reservations before actual picking
- **Use**: Pre-allocate units for upcoming orders

### **Dashboard Data Flow**

```
SOHeader (Order Drop Date, ASN, Status)
    ↓
SOLine (QtyToShip, QtyReserved) ← KEY: Tags needed vs pulled
    ↓
SOHeaderAttribute (ORDERTYPE) ← Determines Single vs Consolidated
    ↓
SOPickList (AssignedToUserID) ← Who is picking this?
    ↓
SOUnit (Shipped units with SerialNo) ← FINAL: What actually shipped
```

### **Status Codes (CodeStatus)**

| StatusID | Description | Order State |
|----------|-------------|-------------|
| 3 | CANCELED | Order canceled |
| 7 | NEW | Just dropped, not picked |
| 12 | RESERVED | Fully picked/reserved |
| 13 | PARTIALLYRESERVED | Partially picked |
| 18 | SHIPPED | Complete and shipped |

### **Key Metrics for Dashboard**

1. **TagsNeeded** = `SUM(SOLine.QtyToShip)`
2. **TagsPulled** = `SUM(SOLine.QtyReserved)`
3. **TagsRemaining** = `TagsNeeded - TagsPulled`
4. **PercentageComplete** = `(TagsPulled / TagsNeeded) * 100`
5. **OrderAging** = `DATEDIFF(day, SOHeader.CreateDate, GETDATE())`
6. **OrderType** = From `SOHeaderAttribute` where `AttributeName = 'ORDERTYPE'`
7. **PickerAssigned** = From `SOPickList` joined to `User.Username`

### **Notes**

- **QtyReserved** = Shipped quantity (when StatusID = 18)
- **ShipDate** = `MAX(CASE WHEN StatusID = 18 THEN LastActivityDate ELSE NULL END)` from SOHeader
- **Consolidated orders** have multiple SOHeaders linked via `SOConsolidatedShipmentHeader`
- **Picker assignments** tracked in `SOPickList`, not directly in SOHeader
- **Service tags** stored in `SOLineAttribute` or `SOUnit.SerialNo`
- **Shipping info** (tracking, carrier) in `SOShipmentInfo` table
- **Configuration** comes from `CodeConfiguration` joined via `SOLine.ConfigurationID`

### **Validation Queries**

See `parts_automation_queries.sql` for validation queries that check:
- Order header structure
- Line item quantities
- Picker assignments
- Status distributions
- Consolidated vs single orders

