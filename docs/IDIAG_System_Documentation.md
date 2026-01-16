# IDIAG System Documentation

## Overview

**IDIAG** is a hardware diagnostic testing system used in the DELL Memphis facility (ProgramID: 10053) to perform comprehensive component-level testing on laptops/computers. It is one of several diagnostic machines in the facility, specifically designed for detailed hardware validation.

---

## What is IDIAG?

IDIAG is an **automated diagnostic testing machine** that:
- Tests individual hardware components on laptops/computers
- Records pass/fail results for each component (subtests)
- Determines overall unit pass/fail status
- Helps route units through the repair/recovery workflow

**Table**: `[redw].[tia].[DataWipeResult]` - Main test results  
**Table**: `[redw].[tia].[SubTestLogs]` - Individual component test results

---

## IDIAG Machine Types

### 1. **IDIAGS** (Full Diagnostic Test)
- **Purpose**: Comprehensive hardware component testing
- **Test Count**: ~6,302 tests (as of Jan 2026)
- **Pass Rate**: ~64% (4,037 PASS / 2,265 FAIL)
- **Average Duration**: ~5,000 seconds (~1.4 hours) for both PASS and FAIL
- **When Used**: Primary diagnostic test for incoming units

### 2. **IDIAGS-MB-RESET** (Motherboard Reset Test)
- **Purpose**: Specialized motherboard reset and validation
- **Test Count**: ~1,864 tests (as of Jan 2026)
- **Pass Rate**: ~78% (1,458 PASS / 406 FAIL)
- **Average Duration**: 
  - PASS: ~114,019 seconds (~31.7 hours) ⚠️ *Very long*
  - FAIL: ~276 seconds (~4.6 minutes)
- **When Used**: After IDIAG test, specifically for motherboard issues
- **Note**: When PartNumber is populated, it's typically a motherboard part number (VN0... format)

---

## Other Diagnostic Machines in Facility

IDIAG is **not** the only testing machine. The facility also uses:

| Machine Name | Test Count | Purpose |
|--------------|------------|---------|
| **SPECTRUMX** | 55,540 | Most common test machine (likely data wipe/imaging) |
| **FICORE** | 44,353 | Second most common (likely firmware/core testing) |
| **IDIAGS** | 6,302 | Hardware component diagnostics |
| **IDIAGS-MB-RESET** | 1,864 | Motherboard reset/validation |

---

## Test Structure

### Main Test Level
- **Result**: Overall test outcome (`PASS` or `FAIL`)
- **Duration**: Total test time (StartTime to EndTime)
- **One main test record per test execution**

### Subtest Level (Component Testing)
- **30+ individual component tests** per main test
- Each subtest has its own result (`PASSED` or `FAILED`)
- Subtests run as part of the main test execution
- **One subtest record per component tested**

### Test Flow Example
```
Unit arrives → IDIAGS Test → Main Result: PASS/FAIL
                          ↓
                    Component Tests:
                    - Battery: PASSED
                    - Bluetooth: PASSED
                    - Keyboard: FAILED ← This causes main test to FAIL
                    - Display: PASSED
                    ... (30+ more components)
```

---

## Component Tests (Subtests)

### Most Common Component Tests
| Test Name | Occurrences | Pass Rate | What It Tests |
|-----------|-------------|-----------|---------------|
| `TEST_STATUS_DISPLAY` | 5,187 | 99.9% | Display/screen functionality |
| `TEST_STATUS_USB` | 5,119 | 99.98% | USB port functionality |
| `TEST_STATUS_VIDPORTS` | 5,118 | 99.9% | Video port functionality |
| `TEST_STATUS_KEYBOARD` | 5,102 | 99.96% | Keyboard functionality |
| `TEST_STATUS_CHARGER_WATTS` | 5,078 | 97.8% | Charger/power adapter |

### Most Problematic Components (Highest Failure Rates)
| Test Name | Failures | Failure Rate | Issue |
|-----------|----------|--------------|-------|
| `TEST_STATUS_MB_HW_MSR` | 421 | 100% | Motherboard hardware MSR (all fail) |
| `TEST_STATUS_PCI` | 187 | 4.1% | PCI component issues |
| `TEST_STATUS_KBL` | 179 | 4.2% | Keyboard backlight issues |
| `TEST_STATUS_SOUND_OUT` | 145 | 4.0% | Audio output issues |
| `TEST_STATUS_RJ45` | 149 | 4.5% | Ethernet port issues |

### Most Reliable Components (Zero Failures)
- `TEST_STATUS_BATTERY`: 4,790 tests, 0 failures
- `TEST_STATUS_VIDEO_STRESS`: 4,277 tests, 0 failures
- `TEST_STATUS_NPU_STRESS`: 3,520 tests, 0 failures

### Complete Component Test List
| Test Name | Component Tested |
|-----------|-------------------|
| `TEST_STATUS_BATTERY` | Battery health and functionality |
| `TEST_STATUS_BLUETOOTH` | Bluetooth connectivity |
| `TEST_STATUS_CABLES` | Cable connections |
| `TEST_STATUS_CAMERA` | Camera functionality |
| `TEST_STATUS_CHARGER_WATTS` | Charger/power adapter |
| `TEST_STATUS_CPU_PRIME95` | CPU stress test (Prime95) |
| `TEST_STATUS_CPU_STRESS` | CPU stress test |
| `TEST_STATUS_DISPLAY` | Display/screen |
| `TEST_STATUS_FAN` | Cooling fan |
| `TEST_STATUS_FINGERPRINT` | Fingerprint reader |
| `TEST_STATUS_KBL` | Keyboard backlight |
| `TEST_STATUS_KEYBOARD` | Keyboard functionality |
| `TEST_STATUS_LIDSENSOR` | Lid sensor |
| `TEST_STATUS_MEMORY_STRESS` | Memory stress test |
| `TEST_STATUS_NFC` | NFC functionality |
| `TEST_STATUS_NPU_STRESS` | NPU (Neural Processing Unit) stress test |
| `TEST_STATUS_PCI` | PCI component |
| `TEST_STATUS_RJ45` | Ethernet port |
| `TEST_STATUS_SMARTCARD` | Smart card reader |
| `TEST_STATUS_SOUND_OUT` | Audio output |
| `TEST_STATUS_STORAGE_STRESS` | Storage stress test |
| `TEST_STATUS_TOUCHPAD` | Touchpad |
| `TEST_STATUS_TOUCHSCREEN` | Touchscreen |
| `TEST_STATUS_TPM` | Trusted Platform Module |
| `TEST_STATUS_USB` | USB ports |
| `TEST_STATUS_VIDEO_STRESS` | Video stress test |
| `TEST_STATUS_VIDPORTS` | Video ports |
| `TEST_STATUS_WLAN` | Wireless LAN (WiFi) |

### Special/Unusual Tests
- `TEST_STATUS_0TTT`: 870 occurrences, 0 passes, 0 fails (status unknown)
- `TEST_STATUS_INVENTORY`: 27 occurrences, all failures (inventory check)
- `TEST_STATUS_MB_HW_MSR`: 421 occurrences, all failures (motherboard hardware MSR)

---

## Test Result Logic

### Overall Result Determination
```
IF ANY subtest = FAILED OR main Result = FAIL:
    Overall Result = FAIL
    
ELSE IF ALL subtests = PASSED AND main Result = PASS:
    Overall Result = PASS
    
ELSE:
    Overall Result = NO LOG (incomplete/invalid data)
```

### Key Rules
- **One failed subtest = overall FAIL**
- **All subtests must pass for overall PASS**
- Main test result must also be PASS

---

## Workflow Integration

### Typical Unit Flow
```
Unit arrives at facility
    ↓
IDIAGS Test (Full Diagnostic)
    ↓
    ├─→ PASS → Continue processing
    │
    └─→ FAIL → May go to:
                ├─→ Retest (multiple attempts possible)
                ├─→ IDIAGS-MB-RESET (if motherboard issue suspected)
                └─→ TEARDOWN (if unit cannot be repaired)
```

### Retest Patterns
- Units can be tested **multiple times per day**
- Attempt types: `First`, `Last`, `Middle`, `Only`
- Retests are tracked to measure:
  - How many attempts to pass
  - Time between attempts
  - Component failure persistence

### Relationship to Teardown
- Failed IDIAG tests may lead to teardown
- Units that fail multiple IDIAG attempts often go to teardown
- Teardown extracts parts from units that cannot be repaired

---

## Data Structure

### Key Fields in DataWipeResult (Main Test)
| Field | Description | Example |
|-------|-------------|---------|
| `ID` | Unique test ID | -2123782058 |
| `SerialNumber` | Unit serial number | 6PK6194 |
| `PartNumber` | Part number (often empty for IDIAGS, populated for MB-RESET) | VN02GFGGWSV0057H0544A03 |
| `MachineName` | Test machine name | IDIAGS, IDIAGS-MB-RESET |
| `Result` | Main test result | PASS, FAIL |
| `StartTime` | Test start time (UTC) | 2026-01-13 21:19:38 |
| `EndTime` | Test end time (UTC) | 2026-01-13 22:19:04 |
| `TestArea` | Test area location | MEMPHIS |
| `Contract` | Program contract | 10053 |
| `Program` | Program identifier | DELL_MEM |

### Key Fields in SubTestLogs (Component Tests)
| Field | Description | Example |
|-------|-------------|---------|
| `ID` | Unique subtest ID | -1581403543 |
| `MainTestID` | Links to DataWipeResult.ID | -2124044076 |
| `TestName` | Component test name | TEST_STATUS_BATTERY |
| `Result` | Subtest result | PASSED, FAILED |
| `StartTime` | Subtest start time | 2026-01-06 01:00:22 |
| `EndTime` | Subtest end time | 2026-01-06 01:00:25 |
| `TestIDNumber` | Test sequence number | 1, 2, 3... |

---

## Data Quality Notes

### Known Issues
1. **Empty SerialNumbers**: Many test records have blank SerialNumber fields
2. **Empty PartNumbers**: PartNumber often empty for IDIAGS tests (populated for MB-RESET)
3. **Empty Metadata**: Most optional fields are empty:
   - `MiscInfo`
   - `MACAddress`
   - `Msg`
   - `FileReference`
   - `FailureReference`
   - `BatteryHealthGrade`
   - `LogFileStatus`

### Data Completeness
- **Main test records**: Always have Result, StartTime, EndTime
- **Subtest records**: Always linked to MainTestID, have TestName and Result
- **SerialNumber**: ~70-80% populated (varies by test type)

---

## Performance Metrics

### Test Duration
- **IDIAGS**: ~1.4 hours average (both PASS and FAIL)
- **IDIAGS-MB-RESET**: 
  - PASS: ~31.7 hours (very long - likely includes extended validation)
  - FAIL: ~4.6 minutes (quick failure detection)

### Pass Rates
- **IDIAGS**: 64% pass rate
- **IDIAGS-MB-RESET**: 78% pass rate

### Component Reliability
- **Most reliable**: Battery, Video Stress, NPU Stress (0% failure rate)
- **Most problematic**: MB_HW_MSR (100% failure rate), PCI (4.1%), KBL (4.2%)

---

## Query Usage

### Finding Latest Test for a Serial
```sql
SELECT TOP 1 *
FROM [redw].[tia].[DataWipeResult]
WHERE SerialNumber = 'YOUR_SERIAL'
  AND Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
ORDER BY EndTime DESC;
```

### Getting All Subtests for a Test
```sql
SELECT stl.*
FROM [redw].[tia].[SubTestLogs] AS stl
WHERE stl.MainTestID = @TestID
ORDER BY stl.TestName;
```

### Finding Failed Components
```sql
SELECT 
    stl.TestName,
    COUNT(*) AS FailureCount
FROM [redw].[tia].[SubTestLogs] AS stl
INNER JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.ID = stl.MainTestID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND stl.Result = 'FAILED'
GROUP BY stl.TestName
ORDER BY FailureCount DESC;
```

---

## Related Systems

### Work Orders
- IDIAG tests may create work orders (Workstation: IDIAG)
- Work orders track unit routing based on test results

### PartTransactions
- Units may move to/from IDIAG locations
- Transactions track unit movement through the facility

### Teardown
- Failed IDIAG tests may route units to teardown
- Teardown extracts parts from units that fail diagnostics

---

## Key Takeaways

1. **IDIAG is a hardware diagnostic system** that tests individual components
2. **Two types**: IDIAGS (full test) and IDIAGS-MB-RESET (motherboard reset)
3. **30+ component tests** per main test execution
4. **One failed component = overall FAIL**
5. **Used for quality control** and routing decisions
6. **Part of larger workflow** with other machines (SPECTRUMX, FICORE)
7. **Data stored in**: DataWipeResult (main) and SubTestLogs (components)

---

## Questions for Further Investigation

1. What are SPECTRUMX and FICORE machines? (More common than IDIAG)
2. Why does MB-RESET PASS take 32 hours but FAIL only 5 minutes?
3. What is TEST_STATUS_0TTT? (870 occurrences, no pass/fail results)
4. Why are so many SerialNumbers empty?
5. What is TEST_STATUS_MB_HW_MSR? (100% failure rate)

---

**Last Updated**: January 2026  
**Data Source**: `[redw].[tia].[DataWipeResult]` and `[redw].[tia].[SubTestLogs]`  
**Program**: DELL (ProgramID: 10053)  
**Location**: MEMPHIS

