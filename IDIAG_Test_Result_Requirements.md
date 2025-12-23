u a# IDIAG Test Result Integration Requirements

## Overview
This document outlines the requirements for integrating IDIAG test results into the work order routing system and BOMFIX screen functionality.

---

## 1. IDIAG Test Result Query

### Query Location
`queries/idiag.sql`

### Query Purpose
Retrieves the latest IDIAG test results for a given serial number, including all subtest results.

### Query Returns
- **DataWipeResult fields**: Main test information (ID, SerialNumber, Result, StartTime, EndTime, etc.)
- **SubTestLogs fields**: Individual subtest details (TestName, TestDesc, Result, ErrorMessage, etc.)

### Key Fields Used
- `dwr.Result` - Main test result (PASS/FAIL)
- `stl.TestName` - Name of individual subtest (e.g., TEST_STATUS_AUDIO_LOOPBACK, TEST_STATUS_BLUETOOTH)
- `stl.Result` - Subtest result (PASSED/FAILED)

---

## 2. Overall Test Result Logic

### Rule: Determine Overall Result from Subtests

**Logic:**
```
IF query returns NO rows:
    Overall Result = "NO LOG"
    
ELSE IF ANY subtest Result = "FAILED" OR main Result = "FAIL":
    Overall Result = "FAIL"
    
ELSE IF ALL subtest Results = "PASSED" AND main Result = "PASS":
    Overall Result = "PASS"
    
ELSE:
    Overall Result = "NO LOG" (incomplete/invalid data)
```

### Implementation Notes
- Check `stl.Result` field for each subtest
- Check `dwr.Result` field for main test result
- If query returns no rows, treat as "NO LOG"
- One failed subtest = overall FAIL
- All passed = overall PASS

---

## 3. Work Order Creation Flow

### Step 1: Any Station → TEARDOWN
When a unit moves from any station to TEARDOWN location:
1. Create IDIAG Work Order
   - Transaction Type: `WO-WIP` (Work Order - Work In Progress)
   - ProgramID: 10053 (DELL)
   - Workstation: IDIAG (10053 IDIAG)

2. Add Teardown Location Attribute
   - Attribute Name: `TEARDOWN_LOCATION` (or similar)
   - Value: Current location where unit is being torn down
   - Purpose: Track where unit came from for routing back

3. Put Work Order on Hold
   - Transaction Type: `WO-ONHOLD` (Work Order - On Hold)
   - Hold Type: MLP Hold
   - Reason: Waiting for IDIAG test results

### Step 2: Update Banner to Show IDIAG
- Display "IDIAG" in work order banner/header
- Indicates this work order is waiting for IDIAG test results

### Step 3: Route Based on Test Logs
After IDIAG test completes, route based on overall result:

#### PASS Route:
- Remove from hold
- Route to appropriate next station based on routing configuration
- Status: Continue normal workflow

#### FAIL Route:
- **Validation**: User can only manually fail if NO test log exists in TED (Test Execution Database)
- If test log exists and shows FAIL, use that
- If no test log but user manually fails, allow manual fail
- Route to appropriate repair/failure station

#### NO LOG Route:
- Keep on hold or route to manual review station
- Requires manual intervention to determine next steps

---

## 4. BOMFIX Screen Requirements

### Display Test Names
The BOMFIX screen MUST display:
- **All Test Names** from SubTestLogs
- Format: List of `stl.TestName` values from the IDIAG query
- Display as: "Test Name: [TestName]" or similar format
- Show for reference when operator is making BOMFIX decisions

### BOMFIX Options Based on Result

#### Scenario 1: PASS Result
**Available Options:**
1. 'Add Mod'
2. 'Add Remove Mod or Part'
3. 'InDemand - Remove to Inventory Functional'
4. 'NoDemand - Remove to Inventory Functional'

#### Scenario 2: FAIL Result OR No Test Log but Manual WO Fail
**Available Options:**
1. 'Add Mod'
2. 'Add Remove Mod or Part'
3. 'InDemand - Remove to Inventory Non Functional'
4. 'NoDemand - Remove to Inventory Non Functional'

#### Scenario 3: NO LOG (No test results found)
**Available Options:**
1. 'Add Mod'
2. 'Add Remove Mod or Part'
3. 'Boxing'
4. 'Correct Receiving Error'
5. 'Identical Exchange'
6. 'Substitute Exchange'
7. 'Repair Consumption'
8. *(Note: User's message was cut off, may have more options)*

---

## 5. Technical Implementation Details

### Query Integration
- Use `idiag.sql` query with parameterized SerialNumber
- Query should be called when:
  - Work order is created for IDIAG
  - User opens BOMFIX screen
  - System needs to determine routing

### Result Calculation Function
Create a function/stored procedure:
```sql
-- Pseudo-code
FUNCTION GetIDIAGResult(@SerialNumber VARCHAR(50))
RETURNS VARCHAR(10)
AS
BEGIN
    -- Execute idiag.sql query
    -- Analyze results
    -- Return: 'PASS', 'FAIL', or 'NO LOG'
END
```

### BOMFIX Screen Logic
```sql
-- Pseudo-code for BOMFIX options
DECLARE @OverallResult VARCHAR(10) = GetIDIAGResult(@SerialNumber)
DECLARE @TestNames TABLE(TestName VARCHAR(100))

-- Populate test names
INSERT INTO @TestNames
SELECT DISTINCT stl.TestName
FROM [redw].[tia].[DataWipeResult] AS dwr
JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.SerialNumber = @SerialNumber
    AND dwr.MachineName = 'IDIAGS'
    AND dwr.TestArea = 'MEMPHIS'
    AND dwr.ID = (SELECT MAX(ID) FROM [redw].[tia].[DataWipeResult] 
                  WHERE SerialNumber = @SerialNumber 
                  AND MachineName = 'IDIAGS' 
                  AND TestArea = 'MEMPHIS')

-- Determine available options based on @OverallResult
IF @OverallResult = 'PASS'
    -- Show PASS options
ELSE IF @OverallResult = 'FAIL'
    -- Show FAIL options
ELSE
    -- Show NO LOG options
```

---

## 6. Validation Rules

### Rule 1: Manual Fail Validation
- **IF** test log exists in TED showing FAIL → Use test log result
- **IF** no test log exists → Allow user to manually fail
- **IF** test log exists showing PASS → Cannot manually fail (validation error)

### Rule 2: Test Name Display
- Always show test names if query returns results
- If no results, show message: "No IDIAG test log found"
- Display test names in a readable list format

### Rule 3: Option Availability
- Options MUST be filtered based on overall result
- User should only see relevant options for the result type
- Options should be clearly labeled (Functional vs Non-Functional)

---

## 7. Data Flow Summary

```
1. Unit moves to TEARDOWN
   ↓
2. Create IDIAG Work Order (WO-WIP)
   ↓
3. Add Teardown Location Attribute
   ↓
4. Put Work Order on Hold (WO-ONHOLD)
   ↓
5. IDIAG Test Executes
   ↓
6. Query Test Results (idiag.sql)
   ↓
7. Calculate Overall Result (PASS/FAIL/NO LOG)
   ↓
8. Update Banner to Show IDIAG
   ↓
9. Route Based on Result
   ↓
10. BOMFIX Screen Shows:
    - Test Names (for reference)
    - Filtered Options (based on result)
```

---

## 8. Acceptance Criteria

### Must Have:
- [ ] Query returns latest test results for serial number
- [ ] Overall result correctly calculated from subtests
- [ ] Work order created with IDIAG workstation
- [ ] Teardown location attribute added
- [ ] Work order placed on hold
- [ ] Banner displays "IDIAG"
- [ ] Routing works for PASS/FAIL/NO LOG scenarios
- [ ] BOMFIX screen displays test names
- [ ] BOMFIX options filtered by result type
- [ ] Manual fail validation prevents invalid fails

### Should Have:
- [ ] Error handling for query failures
- [ ] Logging of result calculations
- [ ] Audit trail of routing decisions
- [ ] Performance optimization for query

---

## 9. Open Questions / Clarifications Needed

1. What happens if test log shows partial results (some subtests missing)?
2. Should "NO LOG" scenario allow manual override to PASS/FAIL?
3. Are there additional BOMFIX options beyond what was listed?
4. What is the exact attribute name for Teardown Location?
5. Should test names be displayed in a specific order (alphabetical, by test sequence)?
6. What happens if multiple test runs exist - always use latest (MAX ID)?

---

## 10. Related Files
- `queries/idiag.sql` - Test result query
- Work Order routing configuration tables
- BOMFIX screen definition
- Workstation routing logic

