# ZPL Label Logic Flow Verification

## Overview
This document verifies that the ZPL label generation script correctly checks warranty status and disposition **AFTER** ExecuteQuery processes the receipt and saves attributes.

## Execution Flow

### 1. Unit Receiving Process
```
User enters data → ServerSideValidation → ExecuteQuery → ZPL Label Generation
```

**Key Point:** ZPL script runs **AFTER** ExecuteQuery has:
- Created PartSerial record
- Calculated WARRANTY_STATUS
- Saved WARRANTY_STATUS to PartSerialAttribute or ROUnitAttribute
- Saved DISPOSITION to PartSerialAttribute or ROUnitAttribute

### 2. ZPL Script Execution Order

#### Step 1: Get PartSerialID (Lines 70-105)
- **Purpose:** Find the PartSerial record that was just created
- **Source:** 
  - If SerialNo provided: Direct lookup from `PartSerial` table
  - If SerialNo NULL: Get from most recent `PartTransaction` with 'RO-RECEIVE'
- **Result:** `@PartSerialID` is set

#### Step 2: Get Warranty Status (Lines 107-156)
- **Purpose:** Check if part is In Warranty (IW) to determine if Vendor should display
- **Source Priority:**
  1. **PRIMARY:** `PartSerialAttribute` (where ExecuteQuery saves it)
  2. **FALLBACK:** `ROUnitAttribute` (for non-serialized parts)
- **Condition Check:**
  - If `WARRANTY_STATUS` IN ('IN WARRANTY', 'IW', 'IN_WARRANTY')
  - Then set `@IsInWarranty = 1`
- **Vendor Lookup:**
  - If In Warranty, get Vendor from `PartNoAttribute` where `AttributeName = 'SUPPLIER_NO'`
- **Result:** `@WarrantyStatus`, `@IsInWarranty`, `@Vendor` are set

#### Step 3: Get Disposition (Lines 158-216)
- **Purpose:** Check if Disposition should display (takes precedence over Vendor)
- **Source Priority:**
  1. **PRIMARY:** `PartSerialAttribute` (where ExecuteQuery saves it)
  2. **FALLBACK 1:** `ROUnitAttribute` (for non-serialized parts)
  3. **FALLBACK 2:** `PartNoAttribute` (default from part master)
- **Condition Check:**
  - If `DISPOSITION` = 'CR PROGRAM' → Display: "CR PROGRAM"
  - If `DISPOSITION` IN ('HOLD', 'WIPE AND HOLD') → Display: "HLD"
- **Result:** `@DispositionDisplay` is set

#### Step 4: Generate ZPL Label (Lines 218-286)
- **Label Length:**
  - Base: `0315` (no vendor/disposition)
  - Extended: `0380` (with vendor or disposition)
- **Display Priority:**
  1. **Disposition** (if exists) → Shows at Y=220
  2. **Vendor** (if IW and no disposition) → Shows at Y=220
- **Position:** Both use Y=220 (only one will show)

## Verification Checklist

### ✅ Warranty Status Check
- [x] Checks `PartSerialAttribute` first (where ExecuteQuery saves it)
- [x] Falls back to `ROUnitAttribute` if not found
- [x] Only checks AFTER PartSerialID exists (after ExecuteQuery creates it)
- [x] Correctly identifies IW status: 'IN WARRANTY', 'IW', 'IN_WARRANTY'

### ✅ Disposition Check
- [x] Checks `PartSerialAttribute` first (where ExecuteQuery saves it)
- [x] Falls back to `ROUnitAttribute` if not found
- [x] Falls back to `PartNoAttribute` as last resort
- [x] Only checks AFTER PartSerialID exists (after ExecuteQuery creates it)
- [x] Correctly maps: 'CR PROGRAM' → "CR PROGRAM", 'HOLD'/'WIPE AND HOLD' → "HLD"

### ✅ Display Logic
- [x] Disposition takes precedence over Vendor
- [x] Only one displays at Y=220
- [x] Vendor truncation works (35 chars max)
- [x] Label length adjusts correctly (315 vs 380)

### ✅ Source Priority
- [x] WARRANTY_STATUS: PartSerialAttribute → ROUnitAttribute
- [x] DISPOSITION: PartSerialAttribute → ROUnitAttribute → PartNoAttribute
- [x] VENDOR: PartNoAttribute (SUPPLIER_NO)

## Key Assumptions

1. **ExecuteQuery saves WARRANTY_STATUS:**
   - To `PartSerialAttribute` for serialized parts
   - To `ROUnitAttribute` for non-serialized parts

2. **ExecuteQuery saves DISPOSITION:**
   - To `PartSerialAttribute` for serialized parts
   - To `ROUnitAttribute` for non-serialized parts

3. **ZPL script runs AFTER ExecuteQuery:**
   - PartSerial record exists
   - Attributes are already saved
   - We can query them immediately

## Testing Scenarios

### Scenario 1: IW Part with Vendor
- **Input:** Warranty Status = "IW", Vendor = "SERCOMM CORP"
- **Expected:** Label shows "Vendor: SERCOMM CORP" at Y=220
- **Label Length:** 380

### Scenario 2: CR PROGRAM Disposition
- **Input:** Disposition = "CR PROGRAM", Warranty Status = "IW"
- **Expected:** Label shows "CR PROGRAM" at Y=220 (NOT vendor)
- **Label Length:** 380

### Scenario 3: HOLD Disposition
- **Input:** Disposition = "HOLD", Warranty Status = "IW"
- **Expected:** Label shows "HLD" at Y=220 (NOT vendor)
- **Label Length:** 380

### Scenario 4: OOW Part (No Vendor, No Disposition)
- **Input:** Warranty Status = "OOW", No Disposition
- **Expected:** Label shows no vendor/disposition line
- **Label Length:** 315

### Scenario 5: Long Vendor Name
- **Input:** Vendor = "VERY LONG VENDOR NAME THAT EXCEEDS 35 CHARACTERS"
- **Expected:** Label shows "Vendor: VERY LONG VENDOR NAME THA..." (truncated)
- **Label Length:** 380

## Conclusion

The ZPL script logic is correctly structured to:
1. ✅ Check warranty status and disposition **AFTER** ExecuteQuery processes the receipt
2. ✅ Use correct source priority (PartSerialAttribute → ROUnitAttribute → PartNoAttribute)
3. ✅ Display only one value at Y=220 (Disposition takes precedence)
4. ✅ Adjust label length appropriately
5. ✅ Handle truncation for long vendor names

The script assumes ExecuteQuery has already saved the attributes, which is the correct flow for a post-processing label generation script.

