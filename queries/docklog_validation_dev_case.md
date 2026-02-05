# Dev Case: Dock Log ASN ↔ Tracking Number Validation

## Problem Statement
Currently, the Dock Log screen allows operators to mistakenly assign the **same tracking number to multiple ASNs**. This creates data integrity issues where:
- One tracking number could be dock-logged for ASN `X-500661125`
- The same tracking number could be dock-logged again for ASN `X-500661126`
- This breaks the **many-to-one relationship** between tracking numbers and ASN

**Note**: The relationship is **many-to-one** (many tracking numbers can belong to one ASN, but each tracking number can only belong to one ASN).

## Requirement
**Enforce many-to-one relationship**: Each tracking number can only be dock-logged for **one ASN** in the system. Multiple tracking numbers can belong to the same ASN (this is expected), but a single tracking number cannot belong to multiple ASNs.

## Solution: Add Validation to Dock Log Screen

### Validation Rules (Add BEFORE calling `ro.spRONewDockLog`)

1. **Check if tracking number already exists for a DIFFERENT ASN**
2. **Check if tracking number matches the ASN being entered** (via CarrierResult)
3. **Block dock-log creation if validation fails**

### Exact Code to Add

Add this validation block **right after line 114** (after printer check, before calling `ro.spRONewDockLog`):

```sql
-- ============================================================================
-- VALIDATION: Ensure Tracking Number ↔ ASN Many-to-One Relationship
-- (Many tracking numbers can belong to one ASN, but each tracking number 
--  can only belong to one ASN)
-- ============================================================================

-- Rule 1: Check if this tracking number is already dock-logged for a DIFFERENT ASN
IF EXISTS (
    SELECT 1 
    FROM Plus.pls.RODockLog dl
    INNER JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
    WHERE dl.ProgramID = @v_programid
      AND dl.TrackingNo = @v_tracking_no
      AND rh.CustomerReference != @v_customer_reference  -- Different ASN
)
BEGIN
    DECLARE @ExistingASN VARCHAR(100)
    SELECT @ExistingASN = rh.CustomerReference
    FROM Plus.pls.RODockLog dl
    INNER JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
    WHERE dl.ProgramID = @v_programid
      AND dl.TrackingNo = @v_tracking_no
      AND rh.CustomerReference != @v_customer_reference
    
    SET @v_error = CONCAT('ERROR: Tracking number ', @v_tracking_no, 
                         ' is already dock-logged for ASN ', @ExistingASN, 
                         '. Each tracking number can only belong to one ASN.')
    GOTO error
END

-- Rule 2: Verify tracking number actually belongs to this ASN (via CarrierResult)
IF NOT EXISTS (
    SELECT 1 
    FROM Plus.pls.CarrierResult cr
    WHERE cr.ProgramID = @v_programid
      AND cr.CustomerReference = @v_customer_reference
      AND (cr.TrackingNo = @v_tracking_no OR cr.ChildTrackingNumber = @v_tracking_no)
      AND cr.OrderType = 'RO'
)
BEGIN
    SET @v_error = CONCAT('ERROR: Tracking number ', @v_tracking_no, 
                         ' does not belong to ASN ', @v_customer_reference, 
                         '. Please verify the tracking number matches this ASN.')
    GOTO error
END

-- Rule 3: Check if this exact ASN + Tracking combination already exists (duplicate check)
IF EXISTS (
    SELECT 1 
    FROM Plus.pls.RODockLog dl
    INNER JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
    WHERE dl.ProgramID = @v_programid
      AND dl.TrackingNo = @v_tracking_no
      AND rh.CustomerReference = @v_customer_reference  -- Same ASN
)
BEGIN
    SET @v_error = CONCAT('WARNING: Tracking number ', @v_tracking_no, 
                         ' is already dock-logged for ASN ', @v_customer_reference, 
                         '. Duplicate dock-log not allowed.')
    GOTO error
END
```

### Error Handling

The existing error handling (lines 262-267) will catch `@v_error` and update the DataEntry table with the error message, preventing the dock-log from being created.

### Location in Code

**File**: `queries/docklog.md` (Dock Log Screen ExecuteQuery)  
**Insert After**: Line 114 (after printer validation)  
**Insert Before**: Line 117 (before `EXEC ro.spRONewDockLog`)

### Expected Behavior

**Scenario 1: Valid Entry**
- ASN: `X-500661125`
- Tracking: `123456789` (belongs to this ASN, not dock-logged yet)
- **Result**: ✅ Dock-log created successfully

**Scenario 2: Tracking Already Used for Different ASN**
- ASN: `X-500661125`
- Tracking: `123456789` (already dock-logged for `X-500661126`)
- **Result**: ❌ Error: "Tracking number 123456789 is already dock-logged for ASN X-500661126. Each tracking number can only belong to one ASN."

**Scenario 3: Tracking Doesn't Match ASN**
- ASN: `X-500661125`
- Tracking: `999999999` (belongs to different ASN in CarrierResult)
- **Result**: ❌ Error: "Tracking number 999999999 does not belong to ASN X-500661125. Please verify the tracking number matches this ASN."

**Scenario 4: Duplicate Dock-Log**
- ASN: `X-500661125`
- Tracking: `123456789` (already dock-logged for this same ASN)
- **Result**: ❌ Error: "Tracking number 123456789 is already dock-logged for ASN X-500661125. Duplicate dock-log not allowed."

## Testing Checklist

- [ ] Test valid ASN + Tracking combination (should succeed)
- [ ] Test tracking number already used for different ASN (should fail with clear error)
- [ ] Test tracking number that doesn't match ASN in CarrierResult (should fail)
- [ ] Test duplicate dock-log for same ASN + Tracking (should fail)
- [ ] Verify error messages are clear and actionable
- [ ] Verify DataEntry.StatusID is set to 2 (error) when validation fails

## Impact

- **Prevents data corruption**: No more one tracking number → multiple ASNs (enforces many-to-one relationship)
- **Enforces data integrity**: Ensures tracking numbers match their ASNs (validates against CarrierResult)
- **Better error messages**: Operators know exactly what went wrong
- **Audit trail**: Failed attempts are logged in DataEntry table

