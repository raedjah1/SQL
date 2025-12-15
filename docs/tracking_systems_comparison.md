# Tracking Systems Comparison: PLUS vs Clarity

## Overview
You have **TWO DIFFERENT TRACKING SYSTEMS** serving different purposes:

1. **PLUS Warehouse System** - Internal warehouse routing/logistics
2. **Clarity ERP System** - External carrier shipping/tracking

---

## PLUS Warehouse System (Your Example Query)

### Purpose
Internal warehouse tracking for items moving through facility workstations and research queues.

### Key Tables
- `view_current_Route` - Current routing status of tracking objects
- `tracking_object_attribute` - Flexible attributes system
- Attribute types: Order numbers (65), Waybill (18), SKU (253), LOB (8), Status (4)

### What It Tracks
- **License Plates**: Internal warehouse identifiers
- **Routing Status**: Research, DCR Research, etc.
- **Processing Status**: UnAuthorized-NotExpected, etc.
- **Workstation Flow**: Movement through warehouse locations

### Example Use Case
Items sitting in "Research" queue that are "UnAuthorized-NotExpected" - internal warehouse exceptions that need investigation.

---

## Clarity ERP System (Your Memphis Database)

### Purpose
Outbound shipment tracking with external carriers (FedEx, UPS, DHL, etc.)

### Key Tables
- `pls.vTrackingHeader` - Outbound shipment tracking records
- Integrated with carrier APIs for real-time tracking updates

### What It Tracks
- **FedEx Tracking Numbers**: External carrier tracking (884060370299, etc.)
- **Service Types**: Fedex Ground, Standard Overnight, 2 Day, Priority
- **Delivery Status**: In-transit, delivered, exceptions
- **Customer Shipments**: Ship-to addresses, destinations
- **Carrier Integration**: API status and error messages

### Current Status (⚠️ CRITICAL ISSUE)
- **100% FedEx Integration Failure**
- **Error**: "No carrier account FEDEX found for service type [X] and program ID 10053"
- **Impact**: 50+ shipments with no tracking updates
- **Duration**: 7+ days of failed integration
- **Root Cause**: Missing/expired FedEx carrier account credentials

---

## Side-by-Side Comparison

| Feature | PLUS (Warehouse) | Clarity (ERP) |
|---------|------------------|---------------|
| **Scope** | Internal facility | External shipping |
| **Tracking ID** | License Plate | FedEx/UPS Tracking # |
| **Purpose** | Warehouse routing | Customer delivery |
| **Locations** | Research, DCR, Workstations | City, State, Address |
| **Status Types** | UnAuthorized, Research Queue | In-transit, Delivered, Exception |
| **Aging Metric** | Days in research queue | Days since shipment |
| **Integration** | Internal WMS | External carrier APIs |
| **Error Types** | Processing exceptions | API/Account failures |

---

## Query Mapping: PLUS to Clarity

### PLUS Query Elements → Clarity Equivalents

| PLUS Concept | PLUS Field | Clarity Equivalent | Clarity Field |
|--------------|------------|-------------------|---------------|
| Research date | `route_date_time` | Shipment date | `th.CreateDate` |
| Order number | `attribute_value` (type 65) | Internal ref | `th.OrderNo` or join to SO |
| License plate | `license_plate` | Tracking number | `th.TrackingNo` |
| Waybill | `attribute_value` (type 18) | Carrier tracking | `th.TrackingNo` |
| SKU | `attribute_value` (type 253) | Part number | Join to SO/Parts |
| LOB | `attribute_value` (type 8) | Program | `p.Name` |
| Aging | `DATEDIFF(d, research_date, getdate())` | Days since ship | `DATEDIFF(day, th.CreateDate, GETDATE())` |
| Research status | `to_function_name = 'Research'` | Error status | `th.ErrorMessage IS NOT NULL` |
| UnAuthorized | `attribute_value = 'UnAuthorized-NotExpected'` | Tracking error | `th.ErrorMessage LIKE '%carrier account%'` |

---

## Can You Pull Similar Data in Clarity?

### ✅ YES - For Outbound Shipment Tracking

You can track:
- Shipments with carrier tracking errors
- Aging of shipments by days
- Service type analysis (Ground, Overnight, etc.)
- Customer delivery status
- FedEx integration failures

### ❌ NO - For Internal Warehouse Routing

Clarity does NOT have:
- License plate tracking (PLUS-specific)
- Research queue routing
- DCR/warehouse workstation flow
- Internal facility routing status

---

## Your Use Case Analysis

### If You Need...

**Internal Warehouse Item Tracking** (like your PLUS query):
- Use PLUS system directly
- Track items in research queues
- Monitor warehouse routing exceptions
- Identify UnAuthorized/NotExpected items

**Outbound Shipment Tracking** (Clarity can help):
- Use `pls.vTrackingHeader` table
- Track FedEx/carrier shipments
- Monitor delivery status
- Identify tracking API failures
- See aging of shipments by days

**Serial Number Traceability** (Clarity excels here):
- Use `pls.vPartSerial` and `pls.vPartTransaction`
- Complete manufacturing journey tracking
- Workstation flow (gTest0, gTask1, etc.)
- Location tracking (WIP.10053.0.0.0)
- Operator accountability

---

## Recommended Next Steps

### 1. Clarify Your Goal
Are you trying to:
- **A)** Track items in warehouse research queues? → Use PLUS system
- **B)** Track outbound customer shipments? → Use Clarity query I created
- **C)** Track serial numbers through manufacturing? → Use existing Clarity queries

### 2. Fix FedEx Integration (If Tracking Shipments)
Current 100% failure rate needs IT intervention:
- Validate FedEx carrier account credentials
- Update API configuration for Program ID 10053
- Reconfigure all service types (Ground, Overnight, 2Day, Priority)

### 3. Alternative Tracking Options
If PLUS data isn't accessible:
- **Manufacturing tracking**: Use serial number queries (already working perfectly)
- **Shipment tracking**: Fix FedEx integration or use alternative carriers
- **Order tracking**: Use Sales Order and Work Order queries (working)

---

## Query Files Created

I've created a Clarity equivalent query for you:
- **File**: `queries/memphis_shipping_tracking_research.sql`
- **Purpose**: Track outbound shipments with errors, aging, and carrier issues
- **Structure**: Similar logic to your PLUS query but for external carrier tracking

---

## Bottom Line

**The PLUS query you showed tracks INTERNAL warehouse routing.**  
**Clarity tracks EXTERNAL carrier shipments.**

They serve different purposes in your logistics chain:
1. **PLUS** = Items moving INSIDE your warehouse
2. **Clarity** = Products shipping OUTSIDE to customers

Both systems are important, but they're not directly equivalent. Choose based on what you're actually trying to track!
























