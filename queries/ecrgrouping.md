## ECR Grouping / Consolidation (Receipt Gating by Dock-Log)

### Requirement (SOW intent)
**Receiving must not begin until all tracking numbers for a Group ID are physically dock-logged.**

Current pain points:
- **ECR data arrives piecemeal**
- **No “Group complete / consolidated” signal exists**
- **Receiving screens can’t reliably allow vs block receipt**

---

## Proposed solution (2 phases)

### Phase 1 — Plus Upload Screen → store on RO header attributes
Create a **Plus upload screen** (DataEntryScript/Workstation) that allows users to upload **Group ID + Tracking Numbers** directly into Plus.

**Store in Plus ROHeaderAttribute** because the receipt-time validation runs in Plus and needs fast access with no external joins.

#### Upload Screen (Plus DataEntryScript)
Create a new Plus screen with two input fields per row:
- **Input Field 1: Group ID** (required)
- **Input Field 2: Tracking Number** (required)

**Screen behavior:**
- User enters Group ID + one tracking number per row
- User can process multiple rows to add multiple tracking numbers to the same Group ID
- Supports **incremental uploads**: Users can run the screen multiple times to add more tracking numbers to an existing Group ID

**Example usage:**
```
Row 1: Group ID = "ABC123", Tracking Number = "123456789"
Row 2: Group ID = "ABC123", Tracking Number = "987654321"
Row 3: Group ID = "ABC123", Tracking Number = "555666777"
```
All three tracking numbers will be associated with Group ID "ABC123".

#### Plus Upload Screen → ROHeaderAttribute storage
The upload screen ExecuteQuery will:
1. **Find the RO** that matches the tracking number (via `CarrierResult.TrackingNo` → `ROHeader.CustomerReference`)
2. **Write/update ROHeaderAttribute** on the matched RO:
   - **`ECR_GROUP_ID`**: the Group ID string
   - **`ECR_TRACKING_NUMBERS`**: CSV list of all tracking numbers for this Group ID (comma-separated)
   - **`ECR_TRACKING_COUNT`**: **automatically calculated** count of tracking numbers in the CSV list (stored as string)

**For incremental uploads (adding more tracking numbers to existing Group ID):**
- If Group ID already exists on the RO, **append** the new tracking number to the CSV list (check for duplicates first)
- **Automatically recalculate** the tracking count from the updated CSV list
- **Update** the ROHeaderAttribute values

**Automatic count calculation logic:**
```sql
-- After building the CSV list, automatically calculate the count
DECLARE @TrackingCSV VARCHAR(MAX) = '123456789,987654321,555666777'
DECLARE @TrackingCount INT

-- Count commas + 1 = number of tracking numbers
SET @TrackingCount = LEN(@TrackingCSV) - LEN(REPLACE(@TrackingCSV, ',', '')) + 1

-- Store as string in ROHeaderAttribute
-- ECR_TRACKING_COUNT = '3'
```

Notes:
- **Tracking count is derived, not entered**: The system calculates it from the CSV list to ensure accuracy
- **Incremental uploads are supported**: Users can add tracking numbers later (day 1 partial list, day 3 additional tracking numbers)
- **Count provides fast validation gate**: At receipt time, count check first, then exact tracking match

#### Phase 1 validations (upload screen ExecuteQuery)
1. **Validate tracking number exists in CarrierResult** (ensures tracking number is known to the system)
2. **Find the correct RO** via `CarrierResult` → `ROHeader` lookup
3. **Check for duplicate tracking numbers** within the same Group ID (if adding to existing group, check against existing CSV list)
4. **Prevent tracking number from being in multiple Group IDs** (one tracking number can only belong to one Group ID)

**Validation logic:**
```sql
-- Check if tracking number already assigned to a DIFFERENT Group ID
IF EXISTS (
    SELECT 1 FROM Plus.pls.ROHeaderAttribute rha
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = rha.AttributeID
    WHERE ca.AttributeName = 'ECR_GROUP_ID'
      AND rha.Value != @GroupID  -- Different Group ID
      AND EXISTS (
          SELECT 1 FROM Plus.pls.ROHeaderAttribute rha2
          INNER JOIN Plus.pls.CodeAttribute ca2 ON ca2.ID = rha2.AttributeID
          WHERE ca2.AttributeName = 'ECR_TRACKING_NUMBERS'
            AND rha2.ROHeaderID = rha.ROHeaderID
            AND rha2.Value LIKE '%' + @TrackingNo + '%'
      )
)
BEGIN
    SET @v_error = 'ERROR: Tracking number already assigned to a different Group ID'
    GOTO error
END
```

---

### Phase 2 — Receipt-time validation in Plus (gate receiving)
In the **Excess Unit Receiving ADT** (or whichever receiving ADT/SP executes `RO-RECEIVE`), add a server-side validation:

1) **Identify Group ID** for the RO being received via `ROHeaderAttribute.ECR_GROUP_ID`
2) **Find all RO headers in that Group ID**
3) **Compute the expected tracking list** as the distinct union of `ECR_TRACKING_NUMBERS` across the group
4) **Count-check (fast gate)**:
   - Compare expected tracking count vs **distinct dock-logged tracking numbers** (`Plus.pls.RODockLog`) across the entire group
   - If mismatch → **block receiving**
5) **Exact-match check (backstop)**:
   - Verify every expected tracking number exists in `RODockLog` for some RO in the group
   - (Optional strictness) also verify there are no extra dock-logged tracking numbers not present in the expected list

**Blocking error message**
> “Receiving is not allowed. This Group ID has not been fully consolidated.”

---

## Supervisor override (exception handling)
Receiving prior to consolidation is allowed **only via supervisor override**, with:
- **Supervisor role authorization**
- **Mandatory reason captured**
- **Audit log** (who / when / why)
- **Reportable visibility** for compliance

---

## UI/Usability ask (optional but aligned)
Add a **Group ID summary / list view**:
- Lists Group IDs
- Shows consolidation status
- Drilldown to tracking numbers
- Allows edits **only for authorized users** and logs username + change history

---

## Implementation notes
- Receipt gating should be based on **dock-log existence per tracking number** (not “all units”).
- The validation should operate at the **Group level** (all ROs sharing the Group ID), not only the single RO currently being received.

See: `queries/ecr_grouping_receiving_validation.sql` for a ready-to-paste validation query skeleton.