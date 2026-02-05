# Warranty Logic Override Implementation

## Overview

This document describes the implementation of a warranty logic override mechanism to handle cases where vendors have multiple warranty identification logic patterns for parts, even when they share the same `WARRANTY_IDENTIFIER`.

## Problem Statement

Currently, the receiving screen determines In-Warranty (IW) status based on the `WARRANTY_IDENTIFIER` attribute from `PartNoAttribute`. The system matches this attribute along with `Supplier_NO` to a generic data table that selects the appropriate warranty logic.

**Issue:** Some vendors have multiple warranty identification logic patterns for different parts, even when those parts share the same `WARRANTY_IDENTIFIER`.

**Example:**
- Part A uses date code format: `yymm` (e.g., `2401` = January 2024)
- Part B uses date code format: `mmyy` (e.g., `0124` = January 2024)
- Both parts have the same `WARRANTY_IDENTIFIER` value

## Solution

Implement a unit-level attribute override that takes precedence over the part-level `WARRANTY_IDENTIFIER` when determining warranty logic.

## Attribute Name

**Attribute:** `WARRANTY_IDENTIFIER_OVERRIDE`

**Location:** Unit-level attribute (stored in `PartSerialAttribute` or `ROUnitAttribute`)

**Purpose:** When present, this attribute value will be used instead of the part-level `WARRANTY_IDENTIFIER` to determine which warranty logic to apply from the generic data table.

## Current Logic Flow

```
1. Get WARRANTY_IDENTIFIER from PartNoAttribute (part-level)
2. Get Supplier_NO
3. Match (WARRANTY_IDENTIFIER, Supplier_NO) to generic data table
4. Use the warranty logic from the matched record
```

## New Logic Flow

```
1. Check if unit has WARRANTY_IDENTIFIER_OVERRIDE attribute
   ├─ YES: Use WARRANTY_IDENTIFIER_OVERRIDE value
   └─ NO:  Use WARRANTY_IDENTIFIER from PartNoAttribute (current logic)
   
2. Get Supplier_NO
3. Match (WARRANTY_IDENTIFIER_OVERRIDE or WARRANTY_IDENTIFIER, Supplier_NO) to generic data table
4. Use the warranty logic from the matched record
```

## Implementation Details

### Receiving Screen Logic

**Pseudocode:**
```sql
-- Determine which warranty identifier to use
DECLARE @WarrantyIdentifier VARCHAR(100)

-- Check for unit-level override first
SELECT @WarrantyIdentifier = psa.Value
FROM PartSerialAttribute psa
INNER JOIN CodeAttribute ca ON ca.ID = psa.AttributeID
WHERE psa.PartSerialID = @PartSerialID
  AND ca.AttributeName = 'WARRANTY_IDENTIFIER_OVERRIDE'

-- If no override, use part-level identifier
IF @WarrantyIdentifier IS NULL
BEGIN
    SELECT @WarrantyIdentifier = pna.Value
    FROM PartNoAttribute pna
    INNER JOIN CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE pna.PartNo = @PartNo
      AND pna.ProgramID = @ProgramID
      AND ca.AttributeName = 'WARRANTY_IDENTIFIER'
END

-- Match to generic data table using @WarrantyIdentifier and Supplier_NO
-- Apply the warranty logic from the matched record
```

### Attribute Storage

**For Active Units:**
- Table: `Plus.pls.PartSerialAttribute`
- Links to: `PartSerial` via `PartSerialID`
- Attribute ID: Lookup from `CodeAttribute` where `AttributeName = 'WARRANTY_IDENTIFIER_OVERRIDE'`

**For RMA Units (if applicable):**
- Table: `Plus.pls.ROUnitAttribute`
- Links to: `ROUnit` via `ROUnitID`
- Attribute ID: Lookup from `CodeAttribute` where `AttributeName = 'WARRANTY_IDENTIFIER_OVERRIDE'`

## Benefits

1. **Flexibility:** Allows different warranty logic for parts from the same vendor that share a `WARRANTY_IDENTIFIER`
2. **Backward Compatible:** Existing parts without the override continue to use current logic
3. **Unit-Level Control:** Override can be set per unit, allowing for edge cases
4. **No Breaking Changes:** Current logic remains the default fallback

## Example Use Cases

### Use Case 1: Date Code Format Variations
- **Part:** `ABC123`
- **WARRANTY_IDENTIFIER:** `DATE_CODE`
- **Supplier:** `VENDOR_X`
- **Issue:** Some units use `yymm`, others use `mmyy`
- **Solution:** Set `WARRANTY_IDENTIFIER_OVERRIDE = 'DATE_CODE_MMYY'` for units with `mmyy` format

### Use Case 2: Serial Number Pattern Variations
- **Part:** `XYZ789`
- **WARRANTY_IDENTIFIER:** `SERIAL_BASED`
- **Supplier:** `VENDOR_Y`
- **Issue:** Some units have warranty in serial positions 3-6, others in positions 5-8
- **Solution:** Set `WARRANTY_IDENTIFIER_OVERRIDE = 'SERIAL_BASED_ALT'` for units with alternate pattern

## Database Schema Requirements

### CodeAttribute Entry
```sql
-- Ensure this attribute exists in CodeAttribute table
INSERT INTO Plus.pls.CodeAttribute (AttributeName, Description, DataType)
VALUES ('WARRANTY_IDENTIFIER_OVERRIDE', 'Override warranty identifier for unit-level warranty logic', 'VARCHAR')
-- Note: Only insert if it doesn't already exist
```

### Query to Check for Override
```sql
-- Check if a unit has the override attribute
SELECT 
    psa.Value AS WarrantyIdentifierOverride,
    ca.AttributeName
FROM Plus.pls.PartSerialAttribute psa
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
WHERE psa.PartSerialID = @PartSerialID
  AND ca.AttributeName = 'WARRANTY_IDENTIFIER_OVERRIDE'
```

## Testing Checklist

- [ ] Verify override attribute takes precedence when present
- [ ] Verify fallback to part-level `WARRANTY_IDENTIFIER` when override is absent
- [ ] Test with units that have override set
- [ ] Test with units that don't have override set
- [ ] Verify generic data table matching works with override value
- [ ] Test edge cases (null values, empty strings, etc.)
- [ ] Verify backward compatibility with existing parts

## Notes for Developers

1. **Priority:** Always check for `WARRANTY_IDENTIFIER_OVERRIDE` first before falling back to part-level `WARRANTY_IDENTIFIER`
2. **Null Handling:** If override is NULL or empty, use the part-level identifier
3. **Generic Data Table:** The matching logic in the generic data table should work the same way regardless of whether the identifier comes from override or part-level
4. **Performance:** Consider caching the attribute lookup to avoid repeated queries during receiving operations






