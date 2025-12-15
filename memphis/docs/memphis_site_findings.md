# Memphis Site Intelligence Findings

## Site Overview
- **Location**: Memphis, AMER Region
- **Time Zone**: Central Standard Time
- **Total Programs**: 2 Active Programs

## Programs at Memphis Site

### Program Details
| ID | Program Name | Customer ID | Address ID | Status | Create Date | Last Activity |
|---|---|---|---|---|---|---|
| 10053 | DELL | 37 | 312160 | 4 | 2023-08-10 | 2023-08-10 |
| 10068 | ADT | 43 | 504171 | 4 | 2024-09-12 | 2024-09-12 |

### Key Observations
- **DELL Program**: Established August 2023, Customer ID 37
- **ADT Program**: Recently added September 2024, Customer ID 43  
- **Status**: Both programs ACTIVE status
- **User Management**: Programs managed by User ID 2 (sandeep.tumuluri@reconext.com for ADT)
- **Recent Activity**: ADT program shows very recent activity (Sept 2024)
- **Growth**: Site expanded from 1 to 2 programs in 2024
- **Address Mapping**: ADT has Address ID 504171 with matching address name "ADT"

### Schema Discovery
- **Correct View Reference**: `pls.vViewName` (not PLUS.pls.vViewName)
- **Available Views**: 100+ views including vProgram, vWOHeader, vUser, vPartNo, etc.

### Program Configuration Analysis

**DELL Program (ID 10053) - Advanced Configuration:**
- **ERP Integration**: IFS-AMER (Program ID: 21160) - FULLY INTEGRATED
- **Shipping**: ConsolidatedShipment=TRUE, ShipPartial=TRUE, ShipSelectedReservedUnits=TRUE
- **Tracking**: CreateOnlyTracking=TRUE, LotTracking=FALSE
- **Warehouse**: DynamicWarehouseLocation=FALSE
- **Multi-User Management**: avik.sharma, sandeep.tumuluri, ricardo.rodriguez, raymundo.mariscal
- **Last Updated**: 2025-03-06 (VERY RECENT - ricardo.rodriguez)

**ADT Program (ID 10068) - Basic Configuration:**
- **ERP Integration**: No ERP settings visible - STANDALONE
- **Shipping**: ConsolidatedShipment=FALSE, ShipPartial=0, ShipSelectedReservedUnits=FALSE
- **Tracking**: CycleCountFlag=0, LotTracking=0
- **Single User Management**: sandeep.tumuluri@reconext.com only
- **Setup**: 2024-09-12 (All settings created same day)

### Critical Business Intelligence Insights
🎯 **DELL = Enterprise Integration** (Full ERP, Advanced Shipping, Multi-User)
🎯 **ADT = Standalone Operation** (Basic Settings, Single User, Limited Features)
🎯 **Active Development**: DELL program under continuous enhancement (March 2025 updates)
🎯 **Operational Scale**: DELL configured for high-volume consolidated operations

## Next Investigation Steps
- Query Program Attributes for additional configuration details
- Investigate Customer information for DELL (ID 37) and ADT (ID 43)
- Analyze Work Orders and operational performance
- Review user and workforce allocation
