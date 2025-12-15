# Memphis Work Order Documentation

## vWOHeader Table (Memphis Work Orders)

### Primary Fields:
- **`ID`** - Work Order ID (Primary Key)
- **`CustomerReference`** - Customer reference number (e.g., C0VLX74, 2JK1ZB4)
- **`ProgramID`** - Program identifier (10053 = DELL)
- **`PartNo`** - Part number (e.g., 0R3FY, 005YR)
- **`SerialNo`** - Serial number (e.g., C0VLX74, 2JK1ZB4)
- **`RepairTypeDescription`** - Type of repair operation
- **`PreviousWorkstationDescription`** - Previous workstation (e.g., Cosmetic)
- **`WorkstationDescription`** - Current workstation (e.g., Triage, gTest0)
- **`IsPass`** - Pass/fail indicator (1 = Pass, 0 = Fail)
- **`StatusDescription`** - Current work order status
- **`BizTalkID`** - BizTalk integration ID
- **`DefaultLocationNo`** - Default location (e.g., FGI.10053.0.0.0)
- **`Username`** - Assigned operator (e.g., tanise.sanford, celeste.virrey)
- **`CreateDate`** - Work order creation timestamp
- **`LastActivityDate`** - Last activity timestamp
- **`SourcePartNo`** - Source part number
- **`SourceSerialNo`** - Source serial number

### Status Values:
- **HOLD** - Work order is on hold
- **WIP** - Work in progress

### Repair Types:
- **10053 BROKER** - Broker operations
- **10053 REIMAGE** - Reimage operations

### Workstations:
- **Triage** - Initial assessment workstation
- **gTest0** - Testing workstation
- **Cosmetic** - Cosmetic repair workstation

### Operators:
- **tanise.sanford** - Triage specialist
- **celeste.virrey** - Testing specialist

## vWOLine Table (Memphis Work Order Lines)

### Primary Fields:
- **`ID`** - Work Order Line ID (Primary Key)
- **`WOHeaderID`** - Links to vWOHeader.ID (Foreign Key)
- **`ComponentPartNo`** - Component part number (e.g., MC-1640260A-01, 807-00313-01)
- **`QtyRequested`** - Quantity requested for the component
- **`QtyConsumed`** - Quantity actually consumed/used
- **`StatusDescription`** - Line status (e.g., CONSUMED)
- **`Username`** - Operator who processed the line (e.g., mitsuru.saito_dhl)
- **`CreateDate`** - Line creation timestamp
- **`LastActivityDate`** - Last activity on the line

### Status Values:
- **CONSUMED** - Component has been consumed/used

### Key Relationships:
- **WOHeaderID** links to vWOHeader.ID to connect lines to their parent work order
- **ComponentPartNo** identifies the specific component being used
- **QtyRequested vs QtyConsumed** shows material usage efficiency

## Business Context:
This table tracks individual work orders with their current status, assigned operators, and repair types for the Memphis DELL program (ProgramID: 10053).

## Key Use Cases:
- Track work order lifecycle and status
- Monitor operator assignments and workload
- Identify work orders that have been sitting for extended periods
- Analyze repair type distribution and performance
- Monitor workstation utilization and flow
