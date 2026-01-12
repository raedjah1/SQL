# DEV REQUIREMENT #2: RMA Entry Screen - Phase 2

**Title:** RMA Entry Screen - Vendor Receipt & Credit/Replacement Management

**Background:**
- **Program:** 10068 (ADT)
- **Phase 2 Focus:** SHIPPED → Vendor Receipt → Credit/Replacement Processing → Replacement Receipt

---

## Setup Requirements (Source Data + Integrations + Roles)

Phase 2 starts **after shipment is created** (request status is `SHIPPED`). It covers vendor receipt acknowledgment and credit/replacement processing.

### 1) Data prerequisites

- **Weekly OEM parts data**: `PartLocation` + `PartQty` for OEM locations (Mon–Fri window), joined to vendor mapping.
- **Vendor mapping**: `VENDOR_LOCATIONS` (generic table) is required so requests/shipments can be tied to a vendor and vendor users can be filtered correctly.
- **Vendor contacts (optional)**: `VENDOR_CONTACTS` (generic table) can populate vendor email/contact type for display and future notifications.
- **Request records exist**: request lines per part/config row (the core record Phase 2 transitions through shipment/receipt/credit/replacement statuses).

### 2) Key identifiers (post-shipment)

Phase 2 is driven by the shipped request(s) and their shipment linkage:
- **RequestID / request lines** (what the vendor is responding to)
- **SOHeaderID / TrackingNo** (what was shipped and how it was shipped; read-only context for vendor)

### 3) Roles / Who does what

- **Internal users**: acknowledge replacement receipt.
- **RMAVENDOR / `VENDORRMA` users**: acknowledge receipt, issue credit/replacement decisions.

### 4) Integrations added in Phase 2

- **Receive Orders (Replacement tracking)**: `Plus.pls.ROHeader` / `Plus.pls.ROLine` created when vendor issues replacements (full or partial).

---

## Phase 2 Overview

Phase 2 handles the workflow after shipment:
1. **Vendor Receipt** - Vendor acknowledges receipt on portal
2. **Credit/Replacement Processing** - Vendor issues credits or replacements
3. **Replacement Receipt** - Reconext acknowledges receipt of replacements

### Phase 2 Actions Summary (simple + end-to-end)

Most actions are performed at the **request level** (and can be grouped by shipment in the UI if desired).

**SLA tracking (timestamps are required):** Save dates/times for each lifecycle milestone (pallet ready, shipped, vendor received, credit/replacement issued, replacement received) so we can report SLA performance and investigate delays.

**Internal users**
- **Acknowledge replacement receipt**: update `RO` received quantities/status and transition request(s) to `REPLACEMENT_RECEIVED`.

**RMAVENDOR / `VENDORRMA` users**
- **Mark received**: transition request(s) from `SHIPPED` → `RECEIVED_BY_VENDOR`, set `ReceivedDate/By`, and start the 30-day clock (`CreditDeadlineDate`).
- **Issue credit/replacement**:
  - Credit only → status `CREDITED`
  - Replacement (full/partial) → status `REPLACEMENT_ISSUED` or `PARTIAL_CREDIT_REPLACEMENT` and create an `RO` to track replacement receipts (store `ROHeaderID`)

---

## 1. Vendor Receipt Acknowledgment

### 1.1 Receipt Status Update

**Trigger:** Ship order status = "SHIPPED" (or tracking shows delivered)

**Vendor Actions (RMAVENDOR users only):**
1. View shipped requests in "SHIPPED" status
2. Click "Received by Vendor" button
3. System updates:
   - Request status: "SHIPPED" → "RECEIVED_BY_VENDOR"
   - ReceivedDate: Current date/time
   - ReceivedBy: Vendor user ID
   - Start 30-day credit window timer

### 1.2 Receipt Screen Layout

**Vendor View:**
```
[RequestID] [PartNo] [Qty Shipped] [Shipped Date] [Status]        [Actions]
REQ-001     PART123  50            2025-01-07     SHIPPED         [Mark Received]
REQ-002     PART456  25            2025-01-06     RECEIVED_BY_VENDOR [Process Credits/Replacements]
```

**Actions:**
- "Mark Received" button (only for SHIPPED status)
- "Process Credits/Replacements" button (only for RECEIVED_BY_VENDOR status)

---

## 2. Credit/Replacement Processing

### 2.1 Credit/Replacement Screen

**Access:** Vendor clicks "Process Credits/Replacements" on received request

**Screen Layout:**
```
Request: REQ-001
Part: PART123
Quantity Received: 50

[ ] Issue Credits
    Total Amount: $_______
    Credit per Unit: $_______
    Notes: [________________]

[ ] Issue Replacements
    Replacement Part Number: [___________]
    Replacement Quantity: [___]
    Notes: [________________]

[ ] Partial Processing
    Credits for: [___] units @ $______ per unit = $_______
    Replacements for: [___] units
        Part Number: [___________]
        Quantity: [___]
    Notes: [________________]

[Submit] [Cancel]
```

### 2.2 Processing Options

**Option 1: Full Credit**
- Vendor enters total credit amount
- System calculates: CreditAmount / QuantityReceived = CreditPerUnit
- Status: "CREDITED"
- Process ends (no further action needed)

**Option 2: Full Replacement**
- Vendor enters:
  - ReplacementPartNo
  - ReplacementQuantity (must match QuantityReceived)
- **System Action:** Automatically create Receive Order (RO) to track replacement
- Status: "REPLACEMENT_ISSUED"
- Process continues to replacement receipt

**Option 3: Partial Processing**
- Vendor can split:
  - X units → Credits (enter credit amount for those units)
  - Y units → Replacements (enter part number and quantity)
  - X + Y = QuantityReceived (validation required)
- **System Action:** Automatically create Receive Order (RO) for replacement portion
- Status: "PARTIAL_CREDIT_REPLACEMENT"
- Process continues for replacement portion

### 2.3 Data Storage

**Credit Records:**
- RequestID
- CreditAmount (total)
- CreditPerUnit
- CreditQuantity (number of units credited)
- CreditDate
- CreditIssuedBy (vendor user ID)
- CreditNotes

**Replacement Records:**
- RequestID
- ReplacementPartNo
- ReplacementQuantity
- ReplacementDate
- ReplacementIssuedBy (vendor user ID)
- ReplacementNotes
- ROHeaderID (Foreign Key to Plus.pls.ROHeader) - **Receive Order created to track replacement**

**Combined Records (for partial):**
- Both credit and replacement records linked to same RequestID

### 2.4 Validation Rules

1. **Credit Validation:**
   - CreditAmount > 0
   - CreditQuantity <= QuantityReceived
   - CreditPerUnit = CreditAmount / CreditQuantity

2. **Replacement Validation:**
   - ReplacementPartNo must exist in PartNo table
   - ReplacementQuantity > 0
   - ReplacementQuantity <= QuantityReceived

3. **Partial Validation:**
   - CreditQuantity + ReplacementQuantity = QuantityReceived
   - Cannot exceed QuantityReceived total

4. **30-Day Window:**
   - Credits/Replacements must be issued within 30 days of "RECEIVED_BY_VENDOR" date
   - System warning if approaching deadline
   - System alert if deadline passed

---

## 3. Replacement Receipt Acknowledgment

### 3.1 Replacement Receipt Process

**Trigger:** Replacement status = "REPLACEMENT_ISSUED"

**Reconext User Actions (Internal users only):**
1. View requests with "REPLACEMENT_ISSUED" status
2. Physical receipt of replacement parts at warehouse
3. Click "Acknowledge Receipt" button
4. System updates:
   - Request status: "REPLACEMENT_ISSUED" → "REPLACEMENT_RECEIVED"
   - ReceivedDate: Current date/time
   - ReceivedBy: Reconext user ID

### 3.2 Replacement Receipt Screen

**Internal User View:**
```
[RequestID] [Original Part] [Replacement Part] [Qty] [Issued Date] [Status]              [Actions]
REQ-001     PART123         PART456            25    2025-01-10    REPLACEMENT_ISSUED   [Acknowledge Receipt]
REQ-002     PART789         PART789            10    2025-01-08    REPLACEMENT_RECEIVED [View Details]
```

**Actions:**
- "Acknowledge Receipt" button (only for REPLACEMENT_ISSUED status)
- (Optional) "View Details" link (only for REPLACEMENT_RECEIVED status)

---

## 4. Status Flow & Transitions

### 4.1 Complete Status Flow

```
SHIPPED → RECEIVED_BY_VENDOR → [Credit/Replacement Processing]
                              │
                              ├─→ CREDITED (END)
                              │
                              ├─→ REPLACEMENT_ISSUED → REPLACEMENT_RECEIVED (END)
                              │
                              └─→ PARTIAL_CREDIT_REPLACEMENT → REPLACEMENT_RECEIVED (END)
```

### 4.2 Status Definitions

| Status | Description | Who Can Set | Next Possible Status |
|--------|-------------|-------------|---------------------|
| SHIPPED | Ship order created and shipped | System | RECEIVED_BY_VENDOR |
| RECEIVED_BY_VENDOR | Vendor acknowledged receipt | Vendor | CREDITED, REPLACEMENT_ISSUED, PARTIAL_CREDIT_REPLACEMENT |
| CREDITED | Vendor issued credit | Vendor | (END) |
| REPLACEMENT_ISSUED | Vendor issued replacement | Vendor | REPLACEMENT_RECEIVED |
| PARTIAL_CREDIT_REPLACEMENT | Vendor issued partial credit + replacement | Vendor | REPLACEMENT_RECEIVED |
| REPLACEMENT_RECEIVED | Reconext acknowledged replacement receipt | Internal User | (END) |

---

## 5. Data Storage Requirements

### 5.1 Request Table Extensions (Phase 2)

**Additional Fields:**
- ReceivedDate (datetime, nullable)
- ReceivedBy (UserID, nullable) - Vendor user who acknowledged receipt
- CreditDeadlineDate (datetime, nullable) - ReceivedDate + 30 days
- CreditAmount (decimal, nullable)
- CreditPerUnit (decimal, nullable)
- CreditQuantity (int, nullable)
- CreditDate (datetime, nullable)
- CreditIssuedBy (UserID, nullable)
- CreditNotes (varchar, nullable)
- ReplacementPartNo (varchar, nullable)
- ReplacementQuantity (int, nullable)
- ReplacementDate (datetime, nullable)
- ReplacementIssuedBy (UserID, nullable)
- ReplacementNotes (varchar, nullable)
- ReplacementReceivedDate (datetime, nullable)
- ReplacementReceivedBy (UserID, nullable)

### 5.2 New Tables (if needed)

**Credit Table (optional, if multiple credits per request):**
- CreditID (Primary Key)
- RequestID (Foreign Key)
- CreditAmount
- CreditPerUnit
- CreditQuantity
- CreditDate
- CreditIssuedBy
- CreditNotes

**Replacement Table (optional, if multiple replacements per request):**
- ReplacementID (Primary Key)
- RequestID (Foreign Key)
- ReplacementPartNo
- ReplacementQuantity
- ReplacementDate
- ReplacementIssuedBy
- ReplacementNotes
- ReplacementReceivedDate
- ReplacementReceivedBy

---

## 6. Screen Requirements

### 6.1 Vendor Receipt Screen (RMAVENDOR Users)

**Purpose:** Acknowledge receipt of shipped items

**Columns:**
- RequestID
- PartNo
- QuantityShipped
- ShippedDate
- Status
- DaysSinceShipped
- Actions

**Actions:**
- "Mark Received" button (for SHIPPED status)
- "Process Credits/Replacements" button (for RECEIVED_BY_VENDOR status)

**Filters:**
- Status: SHIPPED, RECEIVED_BY_VENDOR
- Date range

### 6.2 Credit/Replacement Processing Screen (RMAVENDOR Users)

**Purpose:** Issue credits or replacements for received items

**Layout:** See Section 3.1

**Features:**
- Simple, intuitive interface
- Clear validation messages
- 30-day deadline countdown
- Save draft (optional)
- Submit button

### 6.3 Replacement Receipt Screen (Internal Users)

**Purpose:** Acknowledge receipt of replacement parts

**Columns:**
- RequestID
- Original PartNo
- Replacement PartNo
- ReplacementQuantity
- ReplacementIssuedDate
- Status
- DaysSinceIssued
- Actions

**Actions:**
- "Acknowledge Receipt" button (for REPLACEMENT_ISSUED status)
- (Optional) "View Details" link (for REPLACEMENT_RECEIVED status)

**Filters:**
- Status: REPLACEMENT_ISSUED, REPLACEMENT_RECEIVED
- Date range

---

## 7. Business Rules & Validations

### 7.1 Credit/Replacement Rules

1. **30-Day Window:**
   - Credits/Replacements must be issued within 30 days of RECEIVED_BY_VENDOR date
   - System warning at 25 days
   - System alert at 30 days
   - Can still process after 30 days (with warning)

2. **Quantity Validation:**
   - CreditQuantity + ReplacementQuantity = QuantityReceived
   - Cannot exceed QuantityReceived
   - Cannot be negative

3. **Part Number Validation:**
   - ReplacementPartNo must exist in PartNo table
   - ReplacementPartNo can be different from original PartNo

### 7.2 Replacement Receipt Rules

1. **Status Validation:**
   - Can only acknowledge receipt for REPLACEMENT_ISSUED status
   - Cannot acknowledge if already REPLACEMENT_RECEIVED

2. **Audit / traceability:**
   - Capture receipt details (who/when/what) so the lifecycle is measurable and auditable

---

## 8. Integration Points

### 8.1 Receive Order (RO) Integration

**System:** Plus.pls.ROHeader / Plus.pls.ROLine

**Integration:**
- **Trigger:** When vendor issues replacement (full or partial)
- **Action:** Automatically create Receive Order to systematically track replacement
- **ROHeader Fields:**
  - CustomerReference: "RMA Replacement - Request [RequestID]"
  - ProgramID: 10068 (ADT)
  - StatusID: "NEW" (status for newly created receive orders)
  - CreateDate: Current date/time
  - UserID: System user or vendor user
- **ROLine Fields:**
  - PartNo: ReplacementPartNo (from vendor input)
  - QtyExpected: ReplacementQuantity (from vendor input)
  - QtyReceived: 0 (initially, updated when replacement received)
- **Link to Request:**
  - Add RequestID reference to ROHeader (via custom field or attribute)
  - Store ROHeaderID in Request table

**Purpose:**
- Systematically track replacement parts from vendor
- Match replacement receipt to expected replacement
- Update QtyReceived when Reconext acknowledges receipt
- Complete RO when replacement fully received

---

## 9. Acceptance Criteria

### 9.1 Vendor Receipt

- [ ] RMAVENDOR users can mark requests as "Received by Vendor"
- [ ] Status updates to RECEIVED_BY_VENDOR
- [ ] ReceivedDate and ReceivedBy recorded
- [ ] 30-day credit window timer starts
- [ ] Credit deadline date calculated (ReceivedDate + 30 days)

### 9.2 Credit Processing

- [ ] RMAVENDOR users can issue full credits
- [ ] RMAVENDOR users can issue partial credits
- [ ] Credit amount validation works
- [ ] Credit per unit calculated correctly
- [ ] Status updates to CREDITED
- [ ] Credit details saved to database
- [ ] Process ends after credit issued

### 9.3 Replacement Processing

- [ ] RMAVENDOR users can issue full replacements
- [ ] RMAVENDOR users can issue partial replacements
- [ ] Replacement part number validation works
- [ ] Replacement quantity validation works
- [ ] **Receive Order (RO) automatically created when replacement issued**
- [ ] **ROHeaderID saved to request record**
- [ ] **RO created with correct ReplacementPartNo and ReplacementQuantity**
- [ ] **RO status set to NEW**
- [ ] Status updates to REPLACEMENT_ISSUED
- [ ] Replacement details saved to database
- [ ] Process continues to replacement receipt

### 9.4 Partial Credit/Replacement

- [ ] RMAVENDOR users can split between credits and replacements
- [ ] Validation ensures CreditQuantity + ReplacementQuantity = QuantityReceived
- [ ] Status updates to PARTIAL_CREDIT_REPLACEMENT
- [ ] Both credit and replacement details saved
- [ ] Process continues to replacement receipt (for replacement portion)

### 9.5 Replacement Receipt

- [ ] Internal users can acknowledge replacement receipt
- [ ] **RO QtyReceived updated when replacement received**
- [ ] **RO status updated to RECEIVED**
- [ ] Status updates to REPLACEMENT_RECEIVED
- [ ] ReceivedDate and ReceivedBy recorded
- [ ] Process ends after receipt acknowledged

**All timestamps should be captured for SLA tracking** (Ship, Vendor Received, Credit/Replacement Issued, Replacement Received, etc.) so the full lifecycle is auditable and measurable.

### 9.6 Data Integrity

- [ ] All status transitions validated
- [ ] All quantities validated
- [ ] All dates recorded correctly
- [ ] All user actions logged
- [ ] Request history maintained

---

## 10. Implementation Notes (keep simple)

- **Transactions**: Each user action that changes inventory/status should be atomic (commit all or rollback all).
- **Concurrency**: Prevent two users from processing the same pallet/request at the same time (row-level locking).
- **SLA timestamps**: Store milestone timestamps so lifecycle/SLA reporting is possible.

