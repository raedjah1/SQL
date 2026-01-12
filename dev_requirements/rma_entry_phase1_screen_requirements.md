# DEV REQUIREMENT #2: RTV Request Management - Phase 1

**Title:** RTV Request Management - Request Management Interface

**Background:**
- Program: 10068 (ADT)
- Data Source: query (parts in OEM locations, Monday-Friday of current week)
- Two user types: Internal Users and RMAVENDOR users
- Phase 1 focuses on Entry → Request workflow, vendor approval/decline, and shipment creation after approval

**Screen Overview:**

The RTV Request Management screen displays parts that arrived in OEM locations during the current week (Monday-Friday). Internal users can create requests to vendors, and vendors can approve/decline those requests.

---

## Setup Requirements (Source Data + Security)

This feature works by combining **two generic tables** (vendor mapping + vendor contacts), a **weekly parts query** (parts that arrived in OEM locations), and **role-based filtering** for vendor users.

### 1) Generic Tables (Plus.pls.CodeGenericTable)

#### VENDOR_LOCATIONS (Vendor ↔ Location mapping)
- **Purpose**: Define which **Vendor** owns each OEM **LocationNo**, so the UI can show the vendor and filter vendor users correctly.
- **Storage**: `Plus.pls.CodeGenericTable` where `GenericTableDefinitionID = 247` (labeled `VENDORLOCATION` in the query).
- **Fields used by the query**:
  - `C03` = `LocationNo`
  - `C01` = `Vendor`
- **Behavior**: The query selects **one vendor per location** (most recent row by `LastActivityDate`, then `ID`).

#### VENDOR_CONTACTS (Vendor ↔ Email/ContactType)
- **Purpose**: Provide a **VendorEmail** and **VendorContactType** for display and (optionally) email routing.
- **Storage**: `Plus.pls.CodeGenericTable` where `GenericTableDefinitionID = 245` (labeled `VENDOR_CONTACTS` in the query).
- **Fields used by the query**:
  - `C01` = `Vendor`
  - `C02` = `Email`
  - `C03` = `ContactType` (the query picks `REQUEST`)
- **Note**: Vendor contacts are **not required** to execute the core request/approve workflow, but they’re good to have so the screen can show “who to contact” and support future notification/automation.

### 2) Weekly Parts Query (Parts in OEM locations, Mon–Fri)

- **Purpose**: Provide the screen’s rows: **parts + quantities** that landed in OEM locations during the current work week.
- **Data sources**:
  - `Plus.pls.PartLocation` (locations like `OEM%`)
  - `Plus.pls.PartQty` (part quantities at those locations)
  - `Plus.pls.PartNo` / `Plus.pls.CodeConfiguration` for descriptions
- **Joins that make it “RMA-ready”**:
  - `PartLocation.LocationNo` → `VENDOR_LOCATIONS.LocationNo` to get the vendor
  - `Vendor` → `VENDOR_CONTACTS.Vendor` to get email/type (optional enrichment)

### 3) Security / Roles

- **Internal user**: Sees all rows and can initiate requests.
- **Vendor user (`VENDORRMA` / RMAVENDOR)**: Sees **only rows for their assigned vendor**, and can approve/decline/partially approve requests.

### 4) How requesting works (by PartNo + Quantity, optional RTVReference)

- **Internal user request behavior (Phase 1)**:
  - Internal users request **by row** (PartNo + Configuration + LocationNo) and specify a **QuantityRequested** (must be ≤ `AvailableQty`).
  - Internal users can optionally provide **RTVReference** on the request (free text; optional).
- **Example (from a single week’s output)**:
  - Location `OEM-SUPERMARKET.ADI.MEM.OEM.1` contains multiple parts (`2W-B`, `2WTA-B`, `4WT-B`, `4WTA-B`) with their own `AvailableQty` values.
  - The internal user requests **specific parts and quantities** from that location.

#### Example: what the operator sees (OEM-SUPERMARKET.ADI.MEM.OEM.1), and what happens after “Request”

Assume the operator opens the RTV Request Management screen and sees one OEM location containing **5 different parts**, with a total of **300 units** across all rows (quantities split randomly for illustration):

```
LocationNo                    Vendor  PartNo    AvailableQty  Qty Requested  RTVReference  Status
OEM-SUPERMARKET.ADI.MEM.OEM.1 ADI     2W-B      80            80             RTV-12345     (blank)
OEM-SUPERMARKET.ADI.MEM.OEM.1 ADI     2WTA-B    55            55             RTV-12345     (blank)
OEM-SUPERMARKET.ADI.MEM.OEM.1 ADI     4WT-B     65            65             RTV-12345     (blank)
OEM-SUPERMARKET.ADI.MEM.OEM.1 ADI     4WTA-B    40            40             RTV-12345     (blank)
OEM-SUPERMARKET.ADI.MEM.OEM.1 ADI     SMK-001   60            60             RTV-12345     (blank)
-- Total AvailableQty across the location = 300
```

**Design-wise**, the operator is interacting with **rows** (part + config + location) and requesting specific quantities.

**When the operator clicks “Request”** (or submits the requested quantities):
- The system creates request record(s) for the selected rows, including `QuantityRequested` and optional `RTVReference`.
- The system generates/assigns a **PalletBoxNo** for the request and prints a pallet label for the operator to attach to the physical pallet/box.
  - This PalletBoxNo is the identifier the warehouse operator will use to stage/identify the requested material going forward.
- The system then **systemically moves the inventory to a “REQUESTED” virtual location** so it does not show up as requestable again, even though it is still physically sitting in the OEM area.
  - Implementation expectation: create PartTransaction(s) and update PartQty/Location to move from `OEM%` → `OEM.REQUESTED%` (or whatever virtual requested location naming standard is used).
  - The UI should treat anything already moved to the requested virtual location as **not requestable** (hide it from the main list or show it with a non-actionable status).

#### Pallet Label Printing (ZPL)

The system should support printing a pallet/box label immediately after request creation so the operator can label the physical pallet/box.

**ZPL (to be provided):**

```
^XA
^LL0450
^PW1280
^LH0,0

^FO450,30^BQN,2,3^FDQA,PB=@PalletBoxNo;DT=@RequestDate;V=@VendorDisplay;Q=@OriginalQty^FS
^FO450,120^A0,25^FD@PalletBoxNo^FS

^FO530,70^A0,30^FDVendor: @VendorDisplay^FS

^FO450,170^A0,30^FDRequest Date:^FS
^FO720,170^A0,30^FD@RequestDate^FS

^FO450,220^A0,30^FDOrig Qty:^FS
^FO620,220^A0,30^FD@OriginalQty^FS

^XZ
```

### 5) After vendor approval (Pallet prep + Ship + Declined disposition)

After the vendor approves/partially approves:
- Calculate **QuantityDeclined = QuantityRequested - QuantityApproved** (cannot be negative).
- Create the ship order for the approved quantity.
  - **RMAReferenceNo must be written onto the ship order** so it travels with the shipment.
  - Recommended implementation: store vendor RMA reference on the ship order header (e.g., `Plus.pls.SOHeader.ThirdPartyReference = RMAReferenceNo`, or an equivalent ship-order header attribute if your schema prefers attributes).
- Prepare the pallet for shipment:
  - Approved quantities remain for shipment.
  - Declined quantities are moved to their disposition.

**Declined quantities → Disposition:**
- Use the part-level **DISPOSITION** attribute from `Plus.pls.PartNoAttribute` (`CodeAttribute.AttributeName = 'DISPOSITION'`) to determine where declined inventory should go.
- The system should create the appropriate PartTransaction(s) and update PartQty accordingly.

**Outbound tracking number (vendor visibility):**
- Once shipment is created, vendor users can see the outbound tracking number (read-only).

### 6) Optional vendor email notifications (request sent)

Optionally notify the vendor when a request is created:
- Use `VendorEmail` from `VENDOR_CONTACTS` (if present).
- If email/contact is missing, the request flow still works; notification is simply skipped.

---

## Data Display

### Data Source
**Baseline query:** The RTV Request Management screen uses the query below (or an equivalent implementation) to return all parts in OEM locations for the week (Monday-Friday), including vendor mapping (and optional vendor contact enrichment).

```sql
-- ============================================
-- ALL PARTS AND QUANTITIES IN OEM LOCATIONS (MONDAY TO FRIDAY OF CURRENT WEEK)
-- WITH VENDOR MAPPING FROM VENDORLOCATION TABLE
-- ProgramID: 10068 (ADT)
-- ============================================
-- TESTING: Change @WeeksBack to 1 for last week, 0 for current week
DECLARE @WeeksBack INT = 0;  -- 0 = current week, 1 = last week, 2 = two weeks ago, etc.

-- UNCOMMENT BELOW TO VERIFY DATE RANGE (run this separately to see what dates are being used)
/*
SELECT 
    DATEADD(WEEK, -@WeeksBack, DATEADD(DAY, -(DATEPART(WEEKDAY, GETDATE()) + 5) % 7, CAST(GETDATE() AS DATE))) AS WeekMonday,
    DATEADD(DAY, 4, DATEADD(WEEK, -@WeeksBack, DATEADD(DAY, -(DATEPART(WEEKDAY, GETDATE()) + 5) % 7, CAST(GETDATE() AS DATE)))) AS WeekFriday,
    GETDATE() AS CurrentDate,
    DATENAME(WEEKDAY, GETDATE()) AS CurrentDayName;
*/

WITH WeekDates AS (
    -- Calculate Monday and Friday of specified week
    -- Monday: Go back to the most recent Monday (or previous week's Monday if today is weekend)
    -- Then subtract @WeeksBack weeks for testing
    SELECT 
        DATEADD(WEEK, -@WeeksBack, DATEADD(DAY, -(DATEPART(WEEKDAY, GETDATE()) + 5) % 7, CAST(GETDATE() AS DATE))) AS WeekMonday,
        DATEADD(DAY, 4, DATEADD(WEEK, -@WeeksBack, DATEADD(DAY, -(DATEPART(WEEKDAY, GETDATE()) + 5) % 7, CAST(GETDATE() AS DATE)))) AS WeekFriday
),
VendorLocationMapping AS (
    -- Get one vendor per location (most recent record)
    SELECT 
        LocationNo,
        Vendor,
        Status,
        LastActivityDate,
        ID
    FROM (
        SELECT 
            cgt.C03 AS LocationNo,
            cgt.C01 AS Vendor,
            cs.Description AS Status,
            cgt.LastActivityDate,
            cgt.ID,
            -- Rank records by most recent activity, then by ID (for tie-breaking)
            ROW_NUMBER() OVER (
                PARTITION BY cgt.C03 
                ORDER BY cgt.LastActivityDate DESC, cgt.ID DESC
            ) AS RowNum
        FROM Plus.pls.CodeGenericTable cgt
            LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = cgt.StatusID
        WHERE cgt.GenericTableDefinitionID = 247  -- VENDORLOCATION
            AND cgt.C03 IS NOT NULL  -- Only locations with LocationNo
            AND cgt.C01 IS NOT NULL  -- Only records with Vendor
    ) AS RankedVendors
    WHERE RowNum = 1  -- Only the most recent vendor per location
),
VendorContacts AS (
    -- Get vendor contact information (Email and Type)
    -- C01 = Vendor, C02 = Email, C03 = Type
    -- Matches on Vendor name from VENDORLOCATION table
    -- Only get "Request" contact type (not Follow-up)
    -- If multiple Request contacts exist for same vendor, get most recent one
    SELECT 
        Vendor,
        Email,
        ContactType,
        Status,
        LastActivityDate
    FROM (
        SELECT 
            cgt.C01 AS Vendor,
            cgt.C02 AS Email,
            cgt.C03 AS ContactType,
            cs.Description AS Status,
            cgt.LastActivityDate,
            cgt.ID,
            -- Rank records by most recent activity, then by ID (for tie-breaking)
            ROW_NUMBER() OVER (
                PARTITION BY cgt.C01 
                ORDER BY cgt.LastActivityDate DESC, cgt.ID DESC
            ) AS RowNum
        FROM Plus.pls.CodeGenericTable cgt
            LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = cgt.StatusID
        WHERE cgt.GenericTableDefinitionID = 245  -- VENDOR_CONTACTS
            AND cgt.C01 IS NOT NULL  -- Only records with Vendor
            AND cgt.C02 IS NOT NULL  -- Only records with Email
            AND UPPER(LTRIM(RTRIM(cgt.C03))) = 'REQUEST'  -- Only Request contact type
    ) AS RankedContacts
    WHERE RowNum = 1  -- Only the most recent Request contact per vendor
)
SELECT 
    pl.LocationNo,
    pl.Warehouse,
    pl.Bin,
    vlm.Vendor,  -- Vendor from VENDORLOCATION table (NULL = no vendor mapping, needs to be added)
    vc.Email AS VendorEmail,  -- Email from VENDOR_CONTACTS table
    vc.ContactType AS VendorContactType,  -- Type from VENDOR_CONTACTS table
    pq.PartNo,
    pn.Description AS PartDescription,
    cc.Description AS Configuration,
    pq.AvailableQty,
    pq.PalletBoxNo,
    pq.LotNo,
    pq.CreateDate AS QtyCreateDate,
    pq.LastActivityDate AS QtyLastActivity
FROM WeekDates wd
CROSS JOIN Plus.pls.PartLocation pl
INNER JOIN Plus.pls.PartQty pq ON pq.LocationID = pl.ID
INNER JOIN Plus.pls.PartNo pn ON pn.PartNo = pq.PartNo
INNER JOIN Plus.pls.CodeConfiguration cc ON cc.ID = pq.ConfigurationID
-- LEFT JOIN ensures all parts show even if no vendor mapping exists (Vendor will be NULL)
LEFT JOIN VendorLocationMapping vlm ON vlm.LocationNo = pl.LocationNo
-- LEFT JOIN vendor contacts on Vendor name (may have multiple contacts per vendor)
-- NULL Email/ContactType = no contact info for this vendor (needs to be added)
LEFT JOIN VendorContacts vc ON vc.Vendor = vlm.Vendor
WHERE pl.ProgramID = 10068
    AND pq.ProgramID = 10068
    AND pl.LocationNo LIKE 'OEM%'
    -- Filter for Monday to Friday of current week (inclusive of both days)
    AND CAST(pq.CreateDate AS DATE) >= wd.WeekMonday
    AND CAST(pq.CreateDate AS DATE) <= wd.WeekFriday
ORDER BY pl.LocationNo, pq.PartNo, cc.Description;
```

### Query Output Columns
- Columns displayed:
  - LocationNo
  - Warehouse
  - Bin
  - Vendor (from VENDORLOCATION table)
  - VendorEmail (from VENDOR_CONTACTS table)
  - VendorContactType (from VENDOR_CONTACTS table)
  - PartNo
  - PartDescription
  - Configuration
  - AvailableQty
  - PalletBoxNo
  - LotNo
  - QtyCreateDate
  - QtyLastActivity

### Data Filtering
- **Internal Users:** See all data (no filtering)
- **RMAVENDOR Users:** See only their assigned vendor's data (filtered by vendor assignment)

---

## Internal User View

### Initial State
- See all parts from the query for the week(Friday)
- Each row represents a part that arrived in an OEM location
- Can see vendor assignment, vendor email, and contact type

### Actions Available

#### 1. Request Button
- **Individual Request:** Request that specific row (PartNo + Configuration + LocationNo) with a **QuantityRequested** and optional **RTVReference**
- **Request All:** Create requests for a specific vendor (or all vendors); default QuantityRequested to `AvailableQty` per row (internal user can adjust before submitting, if UI supports)
- **Behavior:**
  - When clicked, creates request records
  - Lines are added to vendor's screen so they can see the requests
  - Request status: "PENDING" or "REQUESTED"

#### 2. View Vendor Responses
- Can see vendor's response status:
  - **APPROVED** - Vendor approved the request
  - **DECLINED** - Vendor declined the request
  - **Quantity Approved** - Vendor approved partial quantity (declined quantity calculated automatically)

#### 3. Request Management Actions
- **CANCEL:** Cancel a request (available for internal users only)
- **HOLD:** Put a request on hold (available for internal users only)
- **Cannot:** Approve or decline requests (vendor-only actions)

### Screen Layout (Internal User)
```
[LocationNo] [Vendor] [PartNo] [AvailableQty] [Qty Requested] [RTVReference] [Status] [Actions]
OEM.XXX      Vendor1  PART123  10             8              RTV-12345       REQUESTED [Request] [Cancel] [Hold]
OEM.YYY      Vendor2  PART456  5              5              (blank)        SHIPPED   [View]   [Cancel] [Hold]
```

---

## Vendor (RMAVENDOR) User View

### Initial State
- See only their assigned vendor's data (filtered)
- See individual requests that were sent to them by internal users
- Cannot see requests for other vendors

### Actions Available

#### 1. View Requests
- See all requests sent to their vendor
- Each request shows:
  - LocationNo
  - PartNo
  - PartDescription
  - Configuration
  - AvailableQty
  - QuantityRequested
  - RTVReference (if provided)
  - Request status
  - OutboundTrackingNo (only once shipment is created)

#### 2. Request Response Actions
- **APPROVED Button:**
  - Approve the entire request
  - Sets status to "APPROVED"
  - All quantity approved

- **DECLINE Button:**
  - Decline the entire request
  - Sets status to "DECLINED"
  - No quantity approved

- **Quantity Approved Field:**
  - Can enter a specific quantity to approve (partial approval)
  - Declined quantity calculated automatically: `QuantityRequested - QuantityApproved = DeclinedQty`
  - Example: If QuantityRequested = 10 and QuantityApproved = 7, then DeclinedQty = 3

- **RMA (Reference number) (REQUIRED for approval):**
  - Vendor must enter an RMA reference number when approving (full or partial).
  - If the vendor is declining, RMA reference number is not required.

#### 3. Cannot Perform
- Cannot CANCEL requests
- Cannot HOLD requests
- Cannot see other vendors' data

### Screen Layout (Vendor User)
```
[LocationNo] [PartNo] [Qty] [Qty Requested] [RTVReference] [Status]     [Qty Approved] [TrackingNo] [Actions]
[LocationNo] [PartNo] [Qty] [Qty Requested] [RTVReference] [RMA Ref#] [Status]     [Qty Approved] [TrackingNo] [Actions]
OEM.XXX      PART123  10    8             RTV-12345       [_______]   REQUESTED    [____]         (blank)       [APPROVED] [DECLINE]
OEM.YYY      PART456  5     5             (blank)        RMA-778899   SHIPPED      5              1Z...         [View]
```

---

## Request States & Status Flow

### Request Status Values
1. **REQUESTED** - Internal user created request, waiting for vendor response
2. **APPROVED** - Vendor approved (full quantity)
3. **DECLINED** - Vendor declined
4. **PARTIAL** - Vendor approved partial quantity
5. **CANCELLED** - Internal user cancelled the request
6. **HOLD** - Internal user put request on hold
7. **SHIPPED** - Ship order created and shipped (tracking visible to vendor)

### Status Transitions
```
REQUESTED → APPROVED (vendor clicks APPROVED)
REQUESTED → DECLINED (vendor clicks DECLINE)
REQUESTED → PARTIAL (vendor enters quantity approved)
REQUESTED → CANCELLED (internal user clicks CANCEL)
REQUESTED → HOLD (internal user clicks HOLD)
HOLD → REQUESTED (internal user removes hold)
APPROVED/PARTIAL → SHIPPED (system prepares pallet, creates ship order, and ships approved quantities)
CANCELLED → (final state, cannot change)
```

---

## Data Storage Requirements

### Request Table Structure (to be created)
- RequestID (Primary Key)
- LocationNo
- Vendor
- PartNo
- ConfigurationID
- AvailableQty (from query)
- QuantityRequested (internal user input; must be <= AvailableQty)
- RTVReference (varchar, nullable) - optional internal user input
- PalletBoxNo (varchar, nullable) - assigned/generated when request is created (used for pallet/box label and staging)
- QuantityApproved (vendor input)
- QuantityDeclined (calculated: QuantityRequested - QuantityApproved)
- Status (REQUESTED, APPROVED, DECLINED, PARTIAL, CANCELLED, HOLD, SHIPPED)
- RequestedBy (UserID of internal user)
- RequestedDate
- ApprovedBy (UserID of vendor user, if approved)
- ApprovedDate
- RMAReferenceNo (varchar, nullable) - vendor input; **required when approving** (full or partial)
- SOHeaderID (int, nullable) - link to ship order
- ShippedDate (datetime, nullable)
- ShippedBy (UserID, nullable)
- OutboundTrackingNo (varchar, nullable)
- CreateDate
- LastActivityDate

---

## Acceptance Criteria

### Internal User
- [ ] Can see all data from RMAVendorLocations query
- [ ] Can click "Request" button on individual rows
- [ ] Can click "Request All" button (for vendor or all vendors)
- [ ] Can enter QuantityRequested (<= AvailableQty) when creating a request
- [ ] Can optionally enter RTVReference when creating a request
- [ ] When a request is submitted, a PalletBoxNo is generated/assigned and a pallet label can be printed
- [ ] Requests are created and visible to vendors
- [ ] Can see vendor responses (APPROVED, DECLINED, quantity approved)
- [ ] Can CANCEL requests
- [ ] Can HOLD requests
- [ ] Cannot approve or decline requests
- [ ] After vendor approval/partial approval, the system prepares pallet/shipment and transitions requests to SHIPPED
- [ ] Declined quantities are moved to their DISPOSITION (PartNo attribute) via PartTransaction/PartQty updates

### Vendor (RMAVENDOR) User
- [ ] Can see only their assigned vendor's data (filtered)
- [ ] Can see requests sent to them
- [ ] Can click APPROVED button
- [ ] Can click DECLINE button
- [ ] Can enter quantity approved (partial approval)
- [ ] When approving (full or partial), vendor must enter RMAReferenceNo (required)
- [ ] Declined quantity calculated automatically
- [ ] Can see OutboundTrackingNo once shipment is created (read-only)
- [ ] Cannot CANCEL requests
- [ ] Cannot HOLD requests
- [ ] Cannot see other vendors' data

### Data & Calculations
- [ ] QuantityDeclined = QuantityRequested - QuantityApproved (when partial approval)
- [ ] Status updates correctly based on actions
- [ ] Request history tracked (who, when, what action)
- [ ] Week filtering works correctly (Monday-Friday)

---

## Technical Notes

### Query Integration
- Use the query above as the baseline; changes should be **additive** (e.g., join to the request table for status, apply role-based filtering) while preserving the same output meaning.
- Add LEFT JOIN to request table to show current request status (if request exists)
- Apply role-based filtering:
  - Internal users: No additional WHERE clause (see all data)
  - RMAVENDOR users: Add `AND vlm.Vendor = @UserAssignedVendor` to WHERE clause
- Query file location: `queries/RMAVendorLocations`

### Permissions
- Internal users: Full view, request actions, cancel/hold
- RMAVENDOR users: Filtered view, approve/decline actions only

### UI Considerations
- Request button should be disabled if already requested
- Show status badges/colors for quick visual reference
- Quantity approved field should validate (cannot exceed AvailableQty)
- Confirmation dialogs for approve/decline/cancel actions

