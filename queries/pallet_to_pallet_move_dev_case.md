# Dev Case: Pallet-to-Pallet Move for Serialized Parts

## Problem Statement
Currently, operators must perform **two separate operations** to move serialized parts from one pallet to another:

1. **Step 1**: Remove/scan individual parts from the source pallet (one-by-one removal)
2. **Step 2**: Rescan each part to the destination pallet (one-by-one addition)

This is **inefficient** and **time-consuming** when moving multiple serialized parts between pallets.

## Requirement
Create a **single screen** that allows operators to move serialized parts directly from one pallet to another in one operation.

## Solution: Pallet-to-Pallet Move Screen

### Screen Design (Plus DataEntryScript)

**Screen Name**: `Pallet to Pallet Move (Serialized)`

**Input Fields**:
- **C01: From Pallet** (required) - Source pallet location/ID
- **C02: To Pallet** (required) - Destination pallet location/ID  
- **C03: Serial Number** (required) - Serial number of the part to move

**Screen Behavior**:
1. User enters **From Pallet** and **To Pallet**
2. User scans/enters **Serial Number**
3. System **validates** the serial number exists on the From Pallet
4. System **displays part details** (PartNo, current location, etc.) for confirmation
5. User **confirms** the move
6. System **moves** the serialized part from From Pallet → To Pallet in **one transaction**
7. User can **continue scanning** more serial numbers to move multiple parts in the same session

### ExecuteQuery Logic

**Validation Steps** (before move):
1. **Validate From Pallet exists** and is a valid pallet location
2. **Validate To Pallet exists** and is a valid pallet location
3. **Validate Serial Number exists** on the From Pallet location
4. **Prevent duplicate moves** (serial already on To Pallet)
5. **Validate part is serialized** (SerialFlag = 1)

**Move Operation**:
- **Single transaction** that:
  1. Updates `PartSerial.LocationID` from From Pallet → To Pallet
  2. Updates `PartLocation` quantities (decrement From, increment To)
  3. Creates `PartTransaction` record with transaction type `WH-MOVEPART` or similar
  4. Records FromLocation and ToLocation

**For Multiple Parts in Same Session**:
- Screen supports **batch processing**: User can scan multiple serial numbers
- Each serial number is processed as a separate row in DataEntry
- All moves share the same From Pallet and To Pallet (entered once)

### Example Usage Flow

```
Operator enters:
- From Pallet: "PALLET001"
- To Pallet: "PALLET002"

Then scans serial numbers:
Row 1: Serial = "ABC123" → Moves ABC123 from PALLET001 to PALLET002
Row 2: Serial = "DEF456" → Moves DEF456 from PALLET001 to PALLET002  
Row 3: Serial = "GHI789" → Moves GHI789 from PALLET001 to PALLET002
```

All three parts moved in one screen session.

### Technical Implementation

**Key Tables**:
- `Plus.pls.PartSerial` - Update LocationID
- `Plus.pls.PartLocation` - Update QtyOnHand/AvailableQty
- `Plus.pls.PartTransaction` - Record the move transaction
- `Plus.pls.PartQty` - Update quantities if used

**Transaction Type**:
- Use existing `WH-MOVEPART` or create new transaction type for pallet-to-pallet moves
- Record `FromLocation` and `ToLocation` in PartTransaction

**Validation Query Pattern**:
```sql
-- Validate serial exists on From Pallet
IF NOT EXISTS (
    SELECT 1 
    FROM Plus.pls.PartSerial ps
    INNER JOIN Plus.pls.PartLocation pl ON pl.ID = ps.LocationID
    WHERE ps.SerialNo = @SerialNumber
      AND ps.ProgramID = @v_programid
      AND pl.LocationNo = @FromPallet  -- Or match by pallet ID/pattern
)
BEGIN
    SET @v_error = 'Serial number not found on From Pallet'
    GOTO error
END

-- Validate serial is NOT already on To Pallet
IF EXISTS (
    SELECT 1 
    FROM Plus.pls.PartSerial ps
    INNER JOIN Plus.pls.PartLocation pl ON pl.ID = ps.LocationID
    WHERE ps.SerialNo = @SerialNumber
      AND ps.ProgramID = @v_programid
      AND pl.LocationNo = @ToPallet
)
BEGIN
    SET @v_error = 'Serial number already exists on To Pallet'
    GOTO error
END
```

### Benefits

- **Faster operations**: One screen instead of two separate operations
- **Reduced errors**: Single transaction ensures data consistency
- **Batch processing**: Move multiple parts in one session
- **Better audit trail**: Clear "pallet-to-pallet" transaction type
- **Improved efficiency**: Operators don't need to switch between remove/add screens

### Edge Cases to Handle

1. **Serial not on From Pallet**: Clear error message
2. **Serial already on To Pallet**: Prevent duplicate move
3. **From Pallet = To Pallet**: Reject (no-op move)
4. **Non-serialized parts**: Reject (this screen is for serialized only)
5. **Part in use/locked**: Check if part can be moved (status checks)

### Testing Checklist

- [ ] Move single serialized part from Pallet A to Pallet B
- [ ] Move multiple serialized parts in one session
- [ ] Validate error when serial not on From Pallet
- [ ] Validate error when serial already on To Pallet
- [ ] Validate error when From = To Pallet
- [ ] Validate error for non-serialized parts
- [ ] Verify PartTransaction record created correctly
- [ ] Verify PartLocation quantities updated correctly
- [ ] Verify PartSerial.LocationID updated correctly

