# Unit Receiving ADT ZPL Label - Additions & Dev Requirements

**Date:** 2025-12-26  
**File Modified:** `queries/UnitReceicingZPL.sql`  
**Configuration ID:** 1806 (pls.DataDocumentConfiguration)  
**ProgramID:** 10068

---

## Summary of Changes

Added conditional display logic to the ZPL label generation script to show:
1. **Vendor** - When part is In Warranty (IW) - **ONLY AFTER warranty logic determines IW status**
2. **Disposition** - When Disposition is "CR PROGRAM" (displays as "CR PROGRAM") or "HOLD"/"WIPE AND HOLD" (displays as "HLD")

**Priority Logic:** Disposition takes precedence over Vendor. Only one will display at a time.

**Execution Timing:** This script runs AFTER `ExecuteQuery` in `UnitReceivingADT.sql` has processed the receipt and saved WARRANTY_STATUS and DISPOSITION to attributes.

---

## Requirements

### ⚠️ IMPORTANT: Execution Timing
**This ZPL script runs AFTER `ExecuteQuery` in `UnitReceivingADT.sql` has:**
- Created the `PartSerial` record
- Calculated WARRANTY_STATUS using Warranty Identifier logic
- Saved WARRANTY_STATUS to `PartSerialAttribute` or `ROUnitAttribute`
- Saved DISPOSITION to `PartSerialAttribute` or `ROUnitAttribute`

**The ZPL script reads these already-saved attributes - it does NOT calculate warranty status.**

---

### 1. Vendor Display (IW Parts)

**Prerequisite:** Warranty logic in `UnitReceivingADT.sql` ExecuteQuery must have already determined the part as In Warranty (IW) using the Warranty Identifier and saved it to attributes.

- **Condition:** Warranty Status = "IW", "IN WARRANTY", or "IN_WARRANTY"
- **Display:** "Vendor: [VendorName]" at Y=220
- **WARRANTY_STATUS Source Priority:**
  1. `PartSerialAttribute` (AttributeName = 'WARRANTY_STATUS') - **PRIMARY SOURCE**
  2. `ROUnitAttribute` (AttributeName = 'WARRANTY_STATUS') - **FALLBACK** (for non-serialized parts)
- **Vendor Source:** `PartNoAttribute` where `AttributeName = 'SUPPLIER_NO'`
- **Truncation:** Vendor names longer than 35 characters are truncated to **32 chars + "..."** (total 35 chars)

### 2. Disposition Display

**Prerequisite:** DISPOSITION must have been saved by ExecuteQuery to attributes.

- **Condition:** Disposition exists and is one of:
  - "CR PROGRAM" → Display: **"CR PROGRAM"** (note: displays as-is, not "CR PRGORAM")
  - "HOLD" or "WIPE AND HOLD" → Display: **"HLD"**
- **Display:** Disposition text at Y=220
- **Source Priority:**
  1. `PartSerialAttribute` (AttributeName = 'DISPOSITION') - **PRIMARY SOURCE**
  2. `ROUnitAttribute` (AttributeName = 'DISPOSITION') - **FALLBACK 1** (for non-serialized parts)
  3. `PartNoAttribute` (AttributeName = 'DISPOSITION') - **FALLBACK 2** (default from part master)

### 3. Display Priority & Label Length Adjustment

**Display Priority (CRITICAL):**
1. **Disposition takes precedence** - If Disposition exists ("CR PROGRAM" or "HLD"), show it and **DO NOT** show Vendor
2. **Vendor only shows** if In Warranty AND no Disposition to display

- **Base Length:** 315 (no vendor/disposition)
- **With Disposition or Vendor:** 380
- **Position:** Both display at Y=220 (same position, only one shows based on priority)

---

## Code Changes

### Variables Added

```sql
DECLARE @WarrantyStatus     VARCHAR(100)
DECLARE @Vendor             VARCHAR(100)
DECLARE @IsInWarranty       BIT = 0
DECLARE @Disposition        VARCHAR(100)
DECLARE @DispositionDisplay VARCHAR(100)
```

### 1. Warranty Status & Vendor Logic (Lines ~107-149)

```sql
-- ============================================
-- ADDED: Warranty Status and Vendor Logic
-- Date: 2025-12-26
-- Purpose: Display Vendor on label when part is In Warranty (IW)
-- ============================================

-- Get Warranty Status from PartSerialAttribute (with fallback to ROUnitAttribute)
SELECT TOP 1
    @WarrantyStatus = psa.Value
FROM pls.PartSerialAttribute psa
INNER JOIN pls.CodeAttribute ca ON ca.ID = psa.AttributeID
WHERE psa.PartSerialID = @PartSerialID
    AND ca.AttributeName = 'WARRANTY_STATUS'
ORDER BY psa.LastActivityDate DESC

-- If not found in PartSerialAttribute, try ROUnitAttribute
IF (@WarrantyStatus IS NULL)
BEGIN
    SELECT TOP 1
        @WarrantyStatus = rua.Value
    FROM pls.PartSerial ps
    INNER JOIN pls.ROLine rl ON rl.PartNo = ps.PartNo AND rl.ROHeaderID = ps.ROHeaderID
    INNER JOIN pls.ROUnit ru ON ru.ROLineID = rl.ID AND ru.SerialNo = ps.SerialNo
    INNER JOIN pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID
    INNER JOIN pls.CodeAttribute ca ON ca.ID = rua.AttributeID
    WHERE ps.ID = @PartSerialID
        AND ca.AttributeName = 'WARRANTY_STATUS'
    ORDER BY rua.LastActivityDate DESC
END

-- ADDED: Check if In Warranty (IW) and get Vendor
-- Logic: If Warranty Status = IW, display Vendor on label
IF (@WarrantyStatus IS NOT NULL)
BEGIN
    SET @WarrantyStatus = UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@WarrantyStatus, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' '))))
    IF (@WarrantyStatus IN ('IN WARRANTY', 'IW', 'IN_WARRANTY'))
    BEGIN
        SET @IsInWarranty = 1
        
        -- ADDED: Get Vendor/Supplier from PartNoAttribute for IW parts
        SELECT TOP 1
            @Vendor = pna.Value
        FROM pls.PartNoAttribute pna
        INNER JOIN pls.CodeAttribute ca ON ca.ID = pna.AttributeID
        WHERE pna.ProgramID = @v_ProgramID
            AND pna.PartNo = @PartNo
            AND ca.AttributeName = 'SUPPLIER_NO'
        ORDER BY pna.LastActivityDate DESC
    END
END
```

### 2. Disposition Logic (Lines ~151-201)

```sql
-- ============================================
-- ADDED: Disposition Display Logic
-- Date: 2025-12-26
-- Purpose: Display Disposition (CR PROGRAM or HLD) on label
-- Note: Disposition takes precedence over Vendor - only one will show
-- ============================================

-- Get Disposition from PartSerialAttribute (with fallback to ROUnitAttribute, then PartNoAttribute)
SELECT TOP 1
    @Disposition = psa.Value
FROM pls.PartSerialAttribute psa
INNER JOIN pls.CodeAttribute ca ON ca.ID = psa.AttributeID
WHERE psa.PartSerialID = @PartSerialID
    AND ca.AttributeName = 'DISPOSITION'
ORDER BY psa.LastActivityDate DESC

-- If not found in PartSerialAttribute, try ROUnitAttribute
IF (@Disposition IS NULL)
BEGIN
    SELECT TOP 1
        @Disposition = rua.Value
    FROM pls.PartSerial ps
    INNER JOIN pls.ROLine rl ON rl.PartNo = ps.PartNo AND rl.ROHeaderID = ps.ROHeaderID
    INNER JOIN pls.ROUnit ru ON ru.ROLineID = rl.ID AND ru.SerialNo = ps.SerialNo
    INNER JOIN pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID
    INNER JOIN pls.CodeAttribute ca ON ca.ID = rua.AttributeID
    WHERE ps.ID = @PartSerialID
        AND ca.AttributeName = 'DISPOSITION'
    ORDER BY rua.LastActivityDate DESC
END

-- If still not found, try PartNoAttribute
IF (@Disposition IS NULL)
BEGIN
    SELECT TOP 1
        @Disposition = pna.Value
    FROM pls.PartNoAttribute pna
    INNER JOIN pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE pna.ProgramID = @v_ProgramID
        AND pna.PartNo = @PartNo
        AND ca.AttributeName = 'DISPOSITION'
    ORDER BY pna.LastActivityDate DESC
END

-- ADDED: Clean and set Disposition display value
-- Logic: CR PROGRAM -> "CR PROGRAM", HOLD/WIPE AND HOLD -> "HLD"
IF (@Disposition IS NOT NULL)
BEGIN
    SET @Disposition = UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@Disposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' '))))
    
    IF (@Disposition = 'CR PROGRAM')
    BEGIN
        SET @DispositionDisplay = 'CR PROGRAM'
    END
    ELSE IF (@Disposition IN ('HOLD', 'WIPE AND HOLD'))
    BEGIN
        SET @DispositionDisplay = 'HLD'
    END
END
```

### 3. Label Length Calculation (Lines ~208-220)

```sql
-- ADDED: Calculate label length based on what needs to be shown
-- Logic: Disposition takes precedence over vendor - only one will show
-- Base length: 315, With disposition/vendor: 380
DECLARE @LabelLength VARCHAR(10) = '0315'

-- Increase length if disposition OR vendor (but not both) is shown
IF (@DispositionDisplay IS NOT NULL AND LEN(@DispositionDisplay) > 0)
BEGIN
    SET @LabelLength = '0380'  -- Disposition at Y=220
END
ELSE IF (@IsInWarranty = 1 AND @Vendor IS NOT NULL AND LEN(@Vendor) > 0)
BEGIN
    SET @LabelLength = '0380'  -- Vendor at Y=220
END
```

### 4. ZPL Display Logic (Lines ~235-258)

```sql
-- ============================================
-- ADDED: Conditional Display Logic
-- Priority: 1) Disposition (CR PROGRAM/HLD), 2) Vendor (if IW)
-- Only one will display at Y=220 position
-- ============================================

-- ADDED: Add Disposition line (takes precedence over vendor)
-- Shows: "CR PROGRAM" or "HLD" based on Disposition value
IF (@DispositionDisplay IS NOT NULL AND LEN(@DispositionDisplay) > 0)
BEGIN
    SET @labelCode = CONCAT(
        @labelCode,
        '^FO450,220^A0,30^FD', @DispositionDisplay, '^FS'
    )
END
-- ADDED: Add Vendor line only if In Warranty AND no disposition to show
-- Shows: "Vendor: [VendorName]" when Warranty Status = IW
ELSE IF (@IsInWarranty = 1 AND @Vendor IS NOT NULL AND LEN(@Vendor) > 0)
BEGIN
    -- ADDED: Truncate vendor name if too long (max ~35 characters for 30pt font at position 580 with 1280 width)
    DECLARE @VendorDisplay VARCHAR(100) = @Vendor
    IF (LEN(@VendorDisplay) > 35)
    BEGIN
        SET @VendorDisplay = LEFT(@VendorDisplay, 32) + '...'
    END
    
    SET @labelCode = CONCAT(
        @labelCode,
        '^FO450,220^A0,30^FDVendor:^FS',
        '^FO580,220^A0,30^FD', @VendorDisplay, '^FS'
    )
END
```

---

## Display Priority

1. **Disposition** (CR PROGRAM or HLD) - Highest priority
2. **Vendor** (if IW and no disposition) - Lower priority
3. **Neither** - If neither condition is met

**Note:** Only one will display at Y=220. They never display together.

---

## ZPL Positioning

- **Base Elements:**
  - QR Code: Y=30
  - SerialNo: Y=120
  - Datecode: Y=70
  - Reception Date: Y=170

- **Conditional Elements (Y=220):**
  - Disposition: `^FO450,220^A0,30^FD@DispositionDisplay^FS`
  - Vendor: `^FO450,220^A0,30^FDVendor:^FS` + `^FO580,220^A0,30^FD@VendorDisplay^FS`

---

## ZPL Template Convention

**For Developers:** All ZPL examples below use `@VariableName` placeholders to indicate dynamic values that must be replaced with actual data from variables or database queries.

**Common Dynamic Variables:**
- `@SerialNo` - Serial number from PartSerial
- `@DateCode` - Date code from input field C10
- `@ReceiveDate` - Reception date formatted as MM/dd/yyyy
- `@LabelLength` - Label length: `0315` (base) or `0380` (with vendor/disposition)
- `@VendorDisplay` - Vendor name (truncated if > 35 chars)
- `@DispositionDisplay` - Disposition text: `CR PROGRAM` or `HLD`

**Replacement:** In actual code, these `@VariableName` placeholders should be replaced with the corresponding SQL variables (e.g., `@SerialNo`, `@VendorDisplay`, etc.) using `CONCAT()` or string concatenation.

---

## Complete ZPL Code Examples

**Note:** All examples use `@VariableName` to indicate dynamic values that should be replaced with actual data.

### Example 1: Base Label (No Disposition, No IW)
**Scenario:** Out of Warranty, No special disposition

```zpl
^XA
^LL@LabelLength
^PW1280
^LH0,0
^FO450,30^BQN,2,3^FDQA,@SerialNo^FS
^FO450,120^A0,25^FD@SerialNo^FS
^FO530,70^A0,30^FDDatecode: @DateCode^FS
^FO450,170^A0,30^FDReception Date:^FS
^FO680,170^A0,30^FD@ReceiveDate^FS
^XZ
```

**Dynamic Values:**
- `@LabelLength` = `0315` (base length)
- `@SerialNo` = Serial number (e.g., `2503CYD002490`)
- `@DateCode` = Date code (e.g., `1231`)
- `@ReceiveDate` = Reception date formatted as MM/dd/yyyy (e.g., `12/15/2025`)

### Example 2: IW with Vendor (No Disposition)
**Scenario:** In Warranty, Has Vendor, No special disposition

```zpl
^XA
^LL@LabelLength
^PW1280
^LH0,0
^FO450,30^BQN,2,3^FDQA,@SerialNo^FS
^FO450,120^A0,25^FD@SerialNo^FS
^FO530,70^A0,30^FDDatecode: @DateCode^FS
^FO450,170^A0,30^FDReception Date:^FS
^FO680,170^A0,30^FD@ReceiveDate^FS
^FO450,220^A0,30^FDVendor:^FS
^FO580,220^A0,30^FD@VendorDisplay^FS
^XZ
```

**Dynamic Values:**
- `@LabelLength` = `0380` (extended length for vendor/disposition)
- `@SerialNo` = Serial number (e.g., `2503CYD002490`)
- `@DateCode` = Date code (e.g., `1231`)
- `@ReceiveDate` = Reception date formatted as MM/dd/yyyy (e.g., `12/15/2025`)
- `@VendorDisplay` = Vendor name (truncated to 32 chars + "..." if > 35 chars) (e.g., `SERCOMM CORP`)

### Example 3: Disposition = CR PROGRAM
**Scenario:** Has CR PROGRAM disposition (takes precedence over vendor)

```zpl
^XA
^LL@LabelLength
^PW1280
^LH0,0
^FO450,30^BQN,2,3^FDQA,@SerialNo^FS
^FO450,120^A0,25^FD@SerialNo^FS
^FO530,70^A0,30^FDDatecode: @DateCode^FS
^FO450,170^A0,30^FDReception Date:^FS
^FO680,170^A0,30^FD@ReceiveDate^FS
^FO450,220^A0,30^FD@DispositionDisplay^FS
^XZ
```

**Dynamic Values:**
- `@LabelLength` = `0380` (extended length for vendor/disposition)
- `@SerialNo` = Serial number (e.g., `2503CYD002490`)
- `@DateCode` = Date code (e.g., `1231`)
- `@ReceiveDate` = Reception date formatted as MM/dd/yyyy (e.g., `12/15/2025`)
- `@DispositionDisplay` = `CR PROGRAM` (when Disposition = "CR PROGRAM")

### Example 4: Disposition = HLD (HOLD)
**Scenario:** Has HOLD or WIPE AND HOLD disposition

```zpl
^XA
^LL@LabelLength
^PW1280
^LH0,0
^FO450,30^BQN,2,3^FDQA,@SerialNo^FS
^FO450,120^A0,25^FD@SerialNo^FS
^FO530,70^A0,30^FDDatecode: @DateCode^FS
^FO450,170^A0,30^FDReception Date:^FS
^FO680,170^A0,30^FD@ReceiveDate^FS
^FO450,220^A0,30^FD@DispositionDisplay^FS
^XZ
```

**Dynamic Values:**
- `@LabelLength` = `0380` (extended length for vendor/disposition)
- `@SerialNo` = Serial number (e.g., `2503CYD002490`)
- `@DateCode` = Date code (e.g., `1231`)
- `@ReceiveDate` = Reception date formatted as MM/dd/yyyy (e.g., `12/15/2025`)
- `@DispositionDisplay` = `HLD` (when Disposition = "HOLD" or "WIPE AND HOLD")

### Example 5: Long Vendor Name (Truncated)
**Scenario:** In Warranty with very long vendor name (> 35 characters)

```zpl
^XA
^LL@LabelLength
^PW1280
^LH0,0
^FO450,30^BQN,2,3^FDQA,@SerialNo^FS
^FO450,120^A0,25^FD@SerialNo^FS
^FO530,70^A0,30^FDDatecode: @DateCode^FS
^FO450,170^A0,30^FDReception Date:^FS
^FO680,170^A0,30^FD@ReceiveDate^FS
^FO450,220^A0,30^FDVendor:^FS
^FO580,220^A0,30^FD@VendorDisplay^FS
^XZ
```

**Dynamic Values:**
- `@LabelLength` = `0380` (extended length for vendor/disposition)
- `@SerialNo` = Serial number (e.g., `2503CYD002490`)
- `@DateCode` = Date code (e.g., `1231`)
- `@ReceiveDate` = Reception date formatted as MM/dd/yyyy (e.g., `12/15/2025`)
- `@VendorDisplay` = Vendor name truncated to 32 chars + "..." if > 35 chars (e.g., `VERY LONG VENDOR NAME CORP...`)

**Truncation Logic:** If vendor name > 35 characters, `@VendorDisplay` = LEFT(vendor, 32) + "..."

### Example 6: IW with Vendor but Disposition = CR PROGRAM
**Scenario:** In Warranty with vendor, but CR PROGRAM takes precedence

```zpl
^XA
^LL@LabelLength
^PW1280
^LH0,0
^FO450,30^BQN,2,3^FDQA,@SerialNo^FS
^FO450,120^A0,25^FD@SerialNo^FS
^FO530,70^A0,30^FDDatecode: @DateCode^FS
^FO450,170^A0,30^FDReception Date:^FS
^FO680,170^A0,30^FD@ReceiveDate^FS
^FO450,220^A0,30^FD@DispositionDisplay^FS
^XZ
```

**Dynamic Values:**
- `@LabelLength` = `0380` (extended length for vendor/disposition)
- `@SerialNo` = Serial number (e.g., `2503CYD002490`)
- `@DateCode` = Date code (e.g., `1231`)
- `@ReceiveDate` = Reception date formatted as MM/dd/yyyy (e.g., `12/15/2025`)
- `@DispositionDisplay` = `CR PROGRAM` (when Disposition = "CR PROGRAM")

**Note:** Vendor is NOT shown because Disposition takes precedence. Even if `@IsInWarranty = 1` and `@Vendor` exists, only `@DispositionDisplay` shows.

---

## Testing

### Test Cases

1. **IW with Vendor, No Disposition**
   - Expected: Shows "Vendor: [VendorName]"
   - Label Length: 380

2. **IW with Vendor, Disposition = CR PROGRAM**
   - Expected: Shows "CR PROGRAM" (not vendor)
   - Label Length: 380

3. **IW with Vendor, Disposition = HOLD**
   - Expected: Shows "HLD" (not vendor)
   - Label Length: 380

4. **OOW (Out of Warranty), No Disposition**
   - Expected: No additional line
   - Label Length: 315

5. **OOW, Disposition = CR PROGRAM**
   - Expected: Shows "CR PROGRAM"
   - Label Length: 380

6. **Long Vendor Name (>35 chars)**
   - Expected: Truncated to 32 chars + "..."

---

## Future Enhancements (Not Yet Implemented)

Based on requirements, the following should be added:

1. **IW Text Display** - Show "IW" text when In Warranty (in addition to or instead of vendor)
2. **CDR Display** - Show "CDR" when "New" attribute = "YES"
3. **ETST Display** - Show "ETST" when ETest attribute exists
4. **CRP Abbreviation** - Change "CR PROGRAM" to "CRP"

---

## Notes

- All existing label functionality remains intact
- Changes are additive and conditional
- No breaking changes to existing logic
- Vendor truncation prevents label overflow
- Disposition takes precedence to ensure critical information is always visible

