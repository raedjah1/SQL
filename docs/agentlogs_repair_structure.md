# AgentLogs.Repair Table Structure Documentation

## Overview

**Table:** `ClarityWarehouse.agentlogs.repair`  
**Schema:** `agentlogs`  
**Purpose:** Stores repair agent logs that process GCF errors and attempt to find parts for repair

## Key Fields

| Field Name | Data Type | Description | Notes |
|------------|-----------|-------------|-------|
| `agentName` | varchar | Agent name | Value: "quincy" |
| `programID` | int | Program identifier | Value: `10053` (DELL) |
| `woHeaderID` | int | Work Order Header ID | Can be NULL |
| `partNo` | varchar | Part number | Can be NULL |
| `serialNo` | varchar | **Serial number / Service tag** | Main identifier (e.g., "1FPBK44", "B7LR2G4") |
| `createDate` | datetime2 | Record creation timestamp | When the repair attempt was logged |
| `initialError` | varchar(max) | **XML message with GCF error details** | Contains full GCF XML response |
| `initialErrorDate` | datetime2 | Date of the initial GCF error | When the error originally occurred |
| `isSuccess` | bit | Success indicator | `0` = Failed, `1` = Success |
| `log` | varchar(max) | **JSON log with repair details** | Contains repair attempts, reasoning, parts selected |
| `debug` | bit | Debug flag | `0` or `1` |

## InitialError Field (XML Structure)

The `initialError` field contains XML with the following structure:

```xml
<?xml version="1.0" encoding="utf-8" ?>
<GCF>
    <MSGID>Unique message ID</MSGID>
    <MSGVER>1.0</MSGVER>
    <CREATED>Date/time</CREATED>
    <MSGTYP>GCF</MSGTYP>
    <SENDID>MSS</SENDID>
    <RECEID>OPP</RECEID>
    <STATUS>Fail</STATUS>
    <STATUSCODE>102</STATUSCODE>
    <STATUSREASON>Error message here</STATUSREASON>
    <VENDORWORKORDERID>Serial number</VENDORWORKORDERID>
    <TIEGROUP>1</TIEGROUP>
    <GPO_ORDER>Serial number</GPO_ORDER>
    <SALESORDNUM>Serial number</SALESORDNUM>
    <REGION>DAO</REGION>
    <PRODUCTIONLEVEL>Production</PRODUCTIONLEVEL>
    <MDIAGSLEVEL>Production</MDIAGSLEVEL>
    <DATACONTAINERS>...</DATACONTAINERS>
</GCF>
```

### Key XML Elements:
- **`STATUSREASON`**: The actual error message (used for categorization)
  - Examples:
    - "System does not contain a processor"
    - "Too many processors for available sockets"
    - "No boot hard drive can be determined"
    - "Could not find an OS Part Number for the order"
    - "InfoHolder::Validate: Too many dimms(260) for available risers slots (48)"
- **`VENDORWORKORDERID`**: Serial number / Service tag
- **`STATUS`**: Always "Fail" for GCF errors
- **`STATUSCODE`**: Error code (e.g., "102")

## Log Field (JSON Structure)

The `log` field contains JSON with repair attempt details:

### Success Case (`isSuccess = 1`):
```json
{
    "modsToRepair": [
        {
            "InventoryPart": {
                "PartType": "DellManufacturingPart",
                "PartTypeConstraint": "DAO",
                "PartNumber": "892CN",
                "InventoryStructureId": "2279217126",
                "Status": "Integrated",
                "AllowsStatusChange": "false",
                "Type": "Unknown",
                "Qty": "1",
                "Description": "MOD,ASSY,BASE,U9X11,24,AA18250"
            }
        }
    ],
    "reasoning": "Error text contains 'processor', triggering category 'processor'. Selected parts whose descriptions include processor-related codes: PWA, ASSY, BASE.",
    "extractedError": ["processor"],
    "extractedMODs": ["PWA", "ASSY", "BASE", "PRC", "CPU"]
}
```

### Failure Case (`isSuccess = 0`):
```json
{
    "error": "No inventory parts were found, likely incorrect route location or failed GTO call."
}
```

Or:
```json
{
    "error": "Attempted too many times to fix."
}
```

### JSON Fields:
- **`modsToRepair`**: Array of parts selected for repair (when adding parts)
  - Each part has: PartNumber, Description, Qty, Status, etc.
- **`modsToRemove`**: Array of parts selected for removal (when removing parts)
  - Same structure as `modsToRepair`
  - Example: Removing "MOD,INFO,NO OS MEDIA" parts
- **`reasoning`**: Explanation of why these parts were selected
- **`extractedError`**: Array of error categories extracted from STATUSREASON
  - Examples: `["processor"]`, `["boot drive"]`, etc.
- **`extractedMODs`**: Array of MOD codes extracted
  - Examples: `["PWA", "ASSY", "BASE", "PRC", "CPU"]`
- **`error`**: Error message if repair attempt failed

### Complete Error Categories (from log JSON):

**Key Finding:** Records with "No error field" (1,461 records) = Successful resolutions (`isSuccess = 1`) with `modsToRepair` or `modsToRemove` in log JSON.

| Error Message Pattern | Log Category | Definition | Count (Sample) |
|----------------------|--------------|------------|---------------|
| *(No error field - has modsToRepair/modsToRemove)* | **Has Repair Parts (Success)** | Successful resolution with parts found | 1,461 |
| `"error":"Unknown error, not trained to resolve."` | **Not yet trained to resolve** | Not yet trained to resolve this error type | 1,104 |
| `"error":"No repair parts found."` | **No repair parts found** | Could not find MODs it's looking for based on the coded descriptions | 407 |
| `"error":"No inventory parts were found, likely incorrect route location or failed GTO call."` | **No inventory parts were found, likely incorrect route location or failed GTO call** | GTO Call was unsuccessful for whatever reason | 401 |
| `"error":"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."` | **Could not find any GCF errors in B2B outbound data** | Error potentially resolved OR too many attempts | 161 |
| `"error":"Could not find any GCF errors in B2B outbound data."` | **Could not find any GCF errors in B2B outbound data** | Error potentially resolved (no GCF error found in BizTalk) | 15 |
| `"error":"Unit is not in correct ReImage (897) location. Currently in [LOCATION]."` | **Routing Errors** | Unit is not in correct reimage location (multiple location variations: 907, 900, 909, 919, 923, 921, 894, 914, 892, 927, 902, 279, etc.) | 356+ |
| `"error":"Unit is not in the correct route."` | **Routing Errors** | Unit is not in correct route | 2 |
| `"error":"Unit is not in the correct route. Currently in [LOCATION]"` | **Routing Errors** | Unit is not in correct route (with location) | 1 |
| `"error":"No pre-existing family found in FG to use as a reference."` | **Unable to locate a unit for reference** | Unable to locate a unit for reference | 28 |
| `"error":"No required MODs found from pre-existing family: [SERIAL]."` | **Unable to locate a unit for reference** | Unable to locate a unit for reference (with specific serial numbers) | 18 |
| `"error":"Unit does not have a work order created yet."` | **Unit does not have a work order created yet** | Occurs due to time difference and sync delays with Clarity replication database | 28 |
| `"error":"Attempted too many times to fix."` | **Attempted too many times** | Too many attempts for resolution (retry limit reached) | 21 |
| `"error":"Unit does not have a PartSerial entry."` | **Unit does not have PartSerial entry** | Not found in PartSerial Table | *(Not in sample but documented)* |
| `"error":"Could not find route/location code for the unit in Plus."` | **Routing Errors** | Unit is not in reimage location | *(Not in sample but documented)* |
| `"error":"No route found for pre-existing family ."` | **Routing Errors** | Unit is not in reimage | *(Not in sample but documented)* |

**Note:** All error messages have `isSuccess = 0` (failed attempts). Only records with `modsToRepair`/`modsToRemove` (no error field) have `isSuccess = 1`.

### Success Cases:
- **`modsToRepair` exists** = Parts found to add/repair
- **`modsToRemove` exists** = Parts found to remove

### SQL Pattern Matching for Error Categories:

```sql
CASE 
    -- Success cases (no error field, has modsToRepair or modsToRemove)
    WHEN log LIKE '%modsToRepair%' OR log LIKE '%modsToRemove%' THEN 'Has Repair Parts (Success)'
    
    -- Error categories (all have isSuccess = 0)
    WHEN log LIKE '%"error":"Unknown error, not trained to resolve."%' THEN 'Not yet trained to resolve'
    WHEN log LIKE '%"error":"No repair parts found."%' THEN 'No repair parts found'
    WHEN log LIKE '%"error":"No inventory parts were found, likely incorrect route location or failed GTO call."%' THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
    WHEN log LIKE '%"error":"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."%' THEN 'Could not find any GCF errors in B2B outbound data'
    WHEN log LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' THEN 'Could not find any GCF errors in B2B outbound data'
    
    -- Routing Errors (multiple patterns)
    WHEN log LIKE '%"error":"Unit is not in correct ReImage%' THEN 'Routing Errors'
    WHEN log LIKE '%"error":"Unit is not in the correct route%' THEN 'Routing Errors'
    WHEN log LIKE '%"error":"Could not find route/location code for the unit in Plus."%' THEN 'Routing Errors'
    WHEN log LIKE '%"error":"No route found for pre-existing family%' THEN 'Routing Errors'
    
    -- Other error categories
    WHEN log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' THEN 'Unable to locate a unit for reference'
    WHEN log LIKE '%"error":"No required MODs found from pre-existing family%' THEN 'Unable to locate a unit for reference'
    WHEN log LIKE '%"error":"Unit does not have a work order created yet."%' THEN 'Unit does not have a work order created yet'
    WHEN log LIKE '%"error":"Attempted too many times to fix."%' THEN 'Attempted too many times'
    WHEN log LIKE '%"error":"Unit does not have a PartSerial entry."%' THEN 'Unit does not have PartSerial entry'
    
    -- Default
    ELSE 'Other/Unknown'
END AS ErrorCategory
```

**Important Notes:**
- **Order matters**: Check for `modsToRepair`/`modsToRemove` FIRST (success cases)
- **Routing Errors**: Multiple patterns all map to same category (location variations)
- **"Could not find any GCF errors"**: Two variants - one with "or there were too many attempts" suffix
- **All error messages**: Have `isSuccess = 0`
- **Success cases**: Have `isSuccess = 1` and no error field

## Common Error Patterns in STATUSREASON

Based on the data:

1. **Processor Errors:**
   - "System does not contain a processor"
   - "Too many processors for available sockets"

2. **Boot Drive Errors:**
   - "No boot hard drive can be determined"

3. **OS Part Number Errors:**
   - "Could not find an OS Part Number for the order"

4. **DIMM/Riser Errors:**
   - "InfoHolder::Validate: Too many dimms(260) for available risers slots (48)"

## Relationship to GCF/BizTalk Data

- **Links via:** `serialNo` (in repair table) = `Customer_order_No` (in BizTalk GCF errors)
- **Purpose:** Repair agent ("quincy") processes GCF errors and attempts to find parts to repair
- **Workflow:**
  1. GCF error occurs (logged in BizTalk)
  2. Repair agent processes the error
  3. Extracts error category and MOD codes
  4. Searches for matching parts
  5. Logs result in `agentlogs.repair` table

## Common Query Patterns

### Get repair attempts for a serial number
```sql
SELECT 
    agentName,
    serialNo,
    woHeaderID,
    createDate,
    initialErrorDate,
    isSuccess,
    log
FROM ClarityWarehouse.agentlogs.repair
WHERE serialNo = 'SERIAL_NUMBER'
    AND programID = 10053
ORDER BY createDate DESC;
```

### Get successful repair attempts
```sql
SELECT 
    serialNo,
    createDate,
    initialErrorDate,
    log
FROM ClarityWarehouse.agentlogs.repair
WHERE isSuccess = 1
    AND programID = 10053
ORDER BY createDate DESC;
```

### Get failed repair attempts
```sql
SELECT 
    serialNo,
    createDate,
    initialErrorDate,
    log
FROM ClarityWarehouse.agentlogs.repair
WHERE isSuccess = 0
    AND programID = 10053
ORDER BY createDate DESC;
```

## Resolution Attempt Logic

**What counts as a "Resolution Attempt":**
- Record has `log` field populated (not NULL or empty)
- `log` contains either:
  - `modsToRepair` OR `modsToRemove` (parts found - can be `isSuccess = 1` OR `isSuccess = 0`)
    - `isSuccess = 1` = Successful resolution (1,461 records)
    - `isSuccess = 0` = Failed attempt but parts were found (407 records)
  - `"error"` field BUT NOT one of the "no attempt" errors listed below

**What counts as "No Resolution Attempt" (Quincy Interaction, No Resolution Attempt):**
- `log` is NULL or empty
- OR `log` contains one of these specific "no attempt" error messages:
  - `"error":"Could not find any GCF errors in B2B outbound data."`
  - `"error":"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."`
  - `"error":"Unknown error, not trained to resolve."` (maps to "Not yet trained to resolve")
  - `"error":"Could not find route/location code for the unit in Plus."` (Routing Errors)
  - `"error":"Unit is not in correct ReImage (897) location. Currently in [LOCATION]."` (Routing Errors - all location variations)
  - `"error":"Unit is not in the correct route."` (Routing Errors)
  - `"error":"No route found for pre-existing family ."` (Routing Errors)
  - `"error":"Unit does not have a PartSerial entry."` (Unit does not have PartSerial entry)
  - `"error":"Unit does not have a work order created yet."` (Unit does not have a work order created yet)
  - `"error":"No pre-existing family found in FG to use as a reference."` (Unable to locate a unit for reference)
  - `"error":"No required MODs found from pre-existing family: [SERIAL]."` (Unable to locate a unit for reference)

**Note:** These errors are considered "attempts" (not "no attempt"):
- `"error":"No inventory parts were found, likely incorrect route location or failed GTO call."`
- `"error":"No repair parts found."`
- `"error":"Attempted too many times to fix."`

**Important Distinction:**
- **"Could not find any GCF errors in B2B outbound data."** = No attempt (error potentially resolved, no GCF error to process)
- **"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."** = No attempt (either resolved OR too many attempts - both mean no attempt)
- **"Attempted too many times to fix."** = Attempt (tried but hit retry limit)

**Key Findings from Data Analysis:**

| isSuccess | LogType | Count | Meaning |
|-----------|---------|-------|---------|
| 1 | Has modsToRepair | 1,044 | Successful resolution (parts found to add/repair) |
| 1 | Has modsToRemove | 417 | Successful resolution (parts found to remove) |
| 0 | Has modsToRepair | 407 | **Failed attempt** (parts found but attempt failed) |
| 0 | Has error | 2,187 | Failed attempt (with error message) |

**Important Insights:**
- **Total successful resolutions:** 1,044 + 417 = **1,461** (`isSuccess = 1`)
- **Failed attempts with parts found:** 407 (`isSuccess = 0` but has `modsToRepair`) - These are resolution attempts that found parts but failed for some reason
- **Failed attempts with errors:** 2,187 (`isSuccess = 0` with error field)
- **Most common error:** "Unknown error, not trained to resolve" (1,104 records) = No Resolution Attempt
- **"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve"** = This is a "no attempt" error (isSuccess = 0, but should not count as resolution attempt)

**Key Insight:**
- `isSuccess = 1` with `modsToRepair`/`modsToRemove` = Successful resolution attempt
- `isSuccess = 0` with `modsToRepair`/`modsToRemove` = Failed resolution attempt (tried but failed)
- `isSuccess = 0` with `"error"` = Failed attempt with specific error reason
- `isSuccess = 1` with `"Other"` log type = May be a different type of success (needs investigation)

## Business Context

- **Agent Name:** "quincy" - Automated repair agent
- **Purpose:** Automatically process GCF errors and suggest parts for repair
- **Success Criteria:** `isSuccess = 1` means parts were found and selected for repair
- **Failure Reasons:**
  - No inventory parts found (incorrect route location or failed GTO call)
  - Too many retry attempts
  - Unknown error types (not trained)
  - Location/routing issues
- **Integration:** Works with GCF errors from BizTalk to provide automated repair suggestions

## Dashboard Metrics Logic

Based on Excel formulas and data analysis:

1. **Total Quincy Interactions** = `COUNT(*)` per date from `agentlogs.repair`

2. **Resolution Attempts** = Records where `log` contains `modsToRepair` OR `modsToRemove` OR `"error"` field (excluding "no attempt" errors)

3. **No Resolution Attempt** = Records where `log` is NULL/empty OR contains "no attempt" error messages

4. **Resolved by Quincy** = Resolution attempts where `isSuccess = 1` AND no new GCF error occurred after `initialErrorDate`

5. **Encountered New Error** = Resolution attempts where new GCF error occurred after `initialErrorDate` (check BizTalk for new errors)

6. **Same Error** = New error has same STATUSREASON as initial error

7. **Full Resolutions (Msg Sent Ok)** = Resolution attempts that fully resolved (no new errors, `isSuccess = 1`)

