# TED Database Documentation
## REDW Database - TIA Schema

**Database:** `redw`  
**Schema:** `tia`  
**Discovery Date:** October 28, 2025  
**Table Creation Date:** October 5, 2025

---

## Available Tables

### 1. DataWipeResult
**Object ID:** 875150163  
**Created:** 2025-10-05 21:47:04.507  
**Modified:** 2025-10-05 21:47:04.507  

**Purpose:** Test results for data wipe operations

---

### 2. DataWipeValidations
**Object ID:** 827149992  
**Created:** 2025-10-05 21:46:01.960  
**Modified:** 2025-10-05 21:46:01.960  

**Purpose:** Validations for data wipe processes

**Known Columns:**
- `ProgramId`
- `SerialNumber`
- `PartNumber`
- `StartTime`
- `EndTime`
- `MachineName`
- `Result`
- `TestArea`
- `CellNumber`
- `Program`
- `MiscInfo`
- `MACAddress`
- `Msg`
- `LogFile`
- `ExportXML`
- `IsParseJson`
- `LastProcessedID`

---

### 3. SubTestLogs
**Object ID:** 843150049  
**Created:** 2025-10-05 21:46:02.227  
**Modified:** 2025-10-05 21:46:02.227  

**Purpose:** Sub-test logging data

---

### 4. subBOM
**Object ID:** 859150106  
**Created:** 2025-10-05 21:46:02.510  
**Modified:** 2025-10-05 21:46:02.510  

**Purpose:** Bill of Materials data

---

## SQL Query to List All Tables

```sql
-- All tables in redw database
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    t.object_id AS ObjectID,
    t.create_date AS CreateDate,
    t.modify_date AS ModifyDate
FROM redw.sys.tables t
JOIN redw.sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name
```

---

## Relationship to Plus Database

The `redw` database appears to be a **Testing & Validation system** (TIA - Test Integration Application), separate from the main ERP system (`Plus` database).

**Potential Integration Points:**
- `SerialNumber` → Links to `Plus.pls.PartSerial.SerialNo`
- `PartNumber` → Links to `Plus.pls.PartSerial.PartNo`
- `ProgramId` → Links to `Plus.pls.PartSerial.ProgramID`

---

## DataWipeResult - Detailed Structure

### Column Layout (from sample data analysis):

| Column | Data Type | Example Values | Purpose |
|--------|-----------|----------------|---------|
| ID | INT | -2144269420, -2128079158 | Unique record identifier (negative values) |
| SerialNumber | VARCHAR | G7QHJC2, 9VS7014, 28CV9K3 | Service tag / serial number |
| PartNumber | VARCHAR | Dell Inc. Precision 5510 (), 9VS7014 | Part number or model description |
| StartTime | DATETIME | 2097-10-17 19:45:38 | Test start timestamp ⚠️ |
| EndTime | DATETIME | 2097-10-17 19:46:58 | Test end timestamp ⚠️ |
| MachineName | VARCHAR | spectrum-03, SPECTRUMX, rackwipe | Testing machine/station |
| **Result** | VARCHAR | **PASS, FAIL, NA** | **Test outcome** |
| TestArea | VARCHAR | Memphis, Juarez, Spectrum, Grapevine | Testing location/facility |
| CellNumber | INT | 0 | Cell/workstation number |
| **Program** | VARCHAR | **DELL_MEM, DELL_JUA, Spectrum, Rackwipe** | **Testing program** |
| MiscInfo | VARCHAR | (empty) | Miscellaneous information |
| MACAddress | VARCHAR | wlxe4a47122015f | Network MAC address |
| Msg | VARCHAR | (empty) | Message/notes |
| LogFile | DATETIME | 2023-03-24 06:46:00 | Log file reference timestamp |
| ExportXML | BIT | 0 | Export to XML flag |
| IsParseJson | VARCHAR | usengprod_funapp, NULL | JSON parsing source |
| LastProcessedID | DATETIME | 2025-10-13 14:53:00 | Last processing timestamp |
| Additional | Various | Multiple fields | Extended metadata |

---

## Critical Findings for Test Reporting

### 🔴 CRITICAL DATA QUALITY ISSUE: StartTime/EndTime - CORRUPTED DATES
**Problem:** StartTime/EndTime contain INVALID dates ranging from 1970 to 2037  
**Example Data:** 
- Earliest: `1970-01-01 00:00:00` (UNIX epoch - corrupted)
- Latest: `2037-12-31 17:48:54` (Far future - corrupted)
- Date Range Span: 67 years of invalid data
**Likely Cause:** Unix timestamp conversion error or data corruption  
**Impact:** ❌ **CANNOT use StartTime/EndTime for ANY date-based analysis**  
**Solution:** ✅ **Use `AsOf` field instead**
- `AsOf` contains reliable processing timestamps
- Valid date range: 2025-01-30 to 2025-10-28 (current)
- All FPY/Yield/Fail Code queries use `AsOf` for date filtering

---

### ✅ Test Results Distribution (COMPREHENSIVE)

**⚠️ CRITICAL: 74 Different Result Values Exist!**

Total test records analyzed: **19,078,697**

#### Success Results (14,698,356 records - 77.0%):
| Result | Count | Category |
|--------|-------|----------|
| PASS | 14,507,121 | Primary success |
| SUCCEEDED | 792,517 | Success variant |
| Passed | 198,598 | Success variant |
| finished | 119 | Success variant |
| Like New | 3 | Success (cosmetic) |

#### Failure Results (2,611,253 records - 13.7%):
| Result | Count | Category |
|--------|-------|----------|
| FAIL | 2,581,036 | Primary failure |
| FAILED | 6,764 | Failure variant |
| Failed | 13,628 | Failure variant |
| Fail | 24 | Failure variant |
| FAIL- | 3 | Failure variant |
| FAIL-fds | 1 | Failure variant |
| FAIL-fail | 1 | Failure variant |
| FAIL (NO CHECKED) | 4,414 | Failure (not verified) |
| Scratch & Dent | 30 | Failure (cosmetic) |

#### Aborted/Cancelled (527,400 records - 2.8%):
| Result | Count | Category |
|--------|-------|----------|
| NA | 339,830 | Not applicable |
| ABORT | 182,958 | Test aborted |
| CANCELLED | 4,612 | Test cancelled |

#### Error Results (2,204 records - 0.01%):
| Result | Count | Category |
|--------|-------|----------|
| ERROR | 2,133 | General error |
| error | 71 | Error variant |

#### HEX Error Codes (676,367 records - 3.5%):
**High-frequency error codes:**
| Code | Count | Likely Meaning |
|------|-------|----------------|
| 0000 | 458,850 | Unknown/Default error |
| 21C0 | 92,937 | Hardware error |
| 768A | 51,840 | Test failure code |
| 762A | 30,296 | Test failure code |
| 76FF | 14,731 | Test failure code |
| 76A7 | 9,141 | Test failure code |
| 2112 | 7,775 | Hardware error |
| 21CE | 3,733 | Hardware error |
| 21CF | 2,139 | Hardware error |
| 21AD | 1,942 | Hardware error |

**Medium-frequency codes (100-2000):**
- B113 (1,348), 76F0 (1,211), B102 (844), B116 (760), 5B85 (725), B105 (502)
- B119 (233), 5BFF (211), 27F1 (120), 27F4 (109)

**Low-frequency codes (<100):**
- 5B1B (63), 6B10 (38), B114 (16), 0100 (17), 0820 (12), 0821 (10), 7711 (8), 1A21 (8), 1A01 (6), 79B0 (5), B117 (3), 7710 (2), 79EF (2), FFFF (2), 1A42 (2), 1A4F (2), 79F2 (1), 0823 (1), 0803 (1), 79F4 (1), 79B1 (1), 7648 (1), 1A02 (1), 1A20 (1), 7933 (1), 79FF (1), 6B03 (1)

#### Misc/Unknown (81 + 122 records):
| Result | Count | Category |
|--------|-------|----------|
| C | 81 | Grade? |
| aborted | 16 | Abort variant |
| B | 24 | Grade? |
| A | 15 | Grade? |
| P | 3 | Pass abbreviation? |
| BOB | 6 | Unknown |
| (empty) | 1 | Null/empty result |

---

### 🎯 Business Logic for FPY & Total Yield Calculations

#### **SUCCESS Definition** (for yield calculations):
```sql
Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
```

#### **FAILURE Definition** (for yield calculations):
```sql
-- Explicit failures
Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 'FAIL-fail', 
           'FAIL (NO CHECKED)', 'Scratch & Dent')

-- OR Hex error codes (indicate test failures)
Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'  -- 4-character hex codes
Result IN ('0000', '21C0', '768A', '762A', '76FF', '76A7', '2112', '21CE', '21CF', '21AD',
           'B113', '76F0', 'B102', 'B116', '5B85', 'B105', 'B119', '5BFF', '27F1', '27F4',
           '5B1B', '6B10', 'B114', '0100', '0820', '0821', '7711', '1A21', '1A01', '79B0',
           'B117', '7710', '79EF', 'FFFF', '1A42', '1A4F', '79F2', '0823', '0803', '79F4',
           '79B1', '7648', '1A02', '1A20', '7933', '79FF', '6B03')

-- OR Explicit errors
Result IN ('ERROR', 'error')
```

#### **EXCLUDED from Yield** (incomplete tests):
```sql
Result IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '', NULL)
```

#### **CLARIFICATION NEEDED:**
- **A, B, C, P** - Likely grades or pass indicators - needs business confirmation
- **BOB** - Unknown code - needs investigation

---

**Programs Distribution (Total: 19,078,697 records):**

| Program | Test Records | Percentage | Facility | Status |
|---------|--------------|------------|----------|--------|
| Meta | 14,295,713 | 74.9% | Unknown | High volume |
| Verifone | 1,899,061 | 10.0% | Unknown | High volume |
| DELL_JUA | 1,000,757 | 5.2% | Juarez | Dell Juarez |
| VRS | 679,508 | 3.6% | Unknown | Unknown |
| Spectrum | 365,961 | 1.9% | Spectrum | Legacy? |
| TPMOB | 215,835 | 1.1% | Unknown | Unknown |
| Blackbelt | 212,226 | 1.1% | Unknown | Unknown |
| **DELL_MEM** | **207,187** | **1.1%** | **Memphis** | **🎯 PRIMARY FOCUS** |
| Futuredial | 157,834 | 0.8% | Unknown | Unknown |
| DEL_JUA | 102,012 | 0.5% | Juarez | Dell Juarez alt |
| Rackwipe | 78,915 | 0.4% | Grapevine | Rack servers |
| DELL_BYD | 58,682 | 0.3% | Unknown | Dell location? |
| CiscoRLWipe | 12,116 | 0.1% | Unknown | Cisco testing |
| VRS_GPV | 10,246 | 0.05% | Grapevine | VRS variant |
| (Others) | ~90,644 | 0.5% | Various | Low volume |

**Key Programs for Reporting:**
- `DELL_MEM` - Memphis Dell testing (PRIMARY FOCUS)
- `DELL_JUA` / `DEL_JUA` - Juarez Dell testing (1.1M combined records)
- `Meta` - Largest program (75% of all tests) - investigation needed
- `Verifone` - Second largest (10% of all tests)

---

### 🔄 Multiple Test Attempts Per Serial

**⚠️ CRITICAL for FPY Calculation!**

**EXTREME CASES DETECTED:**

#### Top Multiple-Attempt Serials (Oct 2025 - DELL_MEM):

| Serial | Attempts | Date Range | Pattern | FPY Status |
|--------|----------|------------|---------|------------|
| *[Hidden]* | **65** | Oct 1 - Oct 27 | Mostly PASS with 3 NA | ❌ NOT FPY |
| 2FBCZ44 | **43** | Oct 16 - Oct 27 | Mostly FAIL (30 fails, 7 pass) | ❌ NOT FPY (First = FAIL) |
| 8GMV564 | **31** | Oct 1 - Oct 25 | FAIL first, then mostly PASS | ❌ NOT FPY (First = FAIL) |
| 9GMV564 | **26** | Oct 1 same day | All PASS | ✅ FPY (First = PASS) ⚠️ but 25 retests! |
| BGMV564 | **26** | Oct 1 same day | All PASS | ✅ FPY (First = PASS) ⚠️ but 25 retests! |
| CMQV564 | **26** | Oct 8-9 | All PASS | ✅ FPY (First = PASS) ⚠️ but 25 retests! |
| 9MQV564 | **26** | Oct 1-2 | All PASS | ✅ FPY (First = PASS) ⚠️ but 25 retests! |
| BMQV564 | **25** | Oct 1 (1 min!) | PASS → PASS → PASS → FAIL → 21 PASS | ✅ FPY |
| 2FBCZ44 | **43** | Oct 16-27 (11 days) | 30 FAIL, 7 PASS | ❌ NOT FPY |

#### Critical Patterns Identified:

**1. "Stress Testing" Pattern** (26+ passes in short time)
- **Suspect:** Automated stress/burn-in testing
- **Impact:** Artificially inflates pass counts but IS FPY if first passes
- **Examples:** 9GMV564, BGMV564, CMQV564 - all 26 PASS attempts in hours

**2. "Persistent Failure" Pattern** (repeated failures)
- **2FBCZ44**: 43 attempts over 11 days - 30 FAIL, 7 PASS (16% yield)
- **60FVMW3**: 19 attempts - first PASS, then 17 consecutive FAILs
- **HKKT794**: 13 attempts - 12 FAIL → 1 PASS (finally passed)

**3. "NA Spam" Pattern** (repeated NA/aborted tests)
- **77JSK84**: 21 attempts - 20 NA, 1 PASS
- **87JSK84**: 20 attempts - 19 NA, 1 PASS  
- **FSK2894**: 18 attempts - 17 NA, 1 PASS
- **BKH7L84**: 17 attempts - ALL NA (never passed)

**4. "Intermittent Issue" Pattern** (mixed pass/fail)
- **3VBZWB4**: 22 attempts - alternating PASS/FAIL throughout
- **G2X9XB4**: 18 attempts - 3 FAIL interspersed among PASS
- **9VN5MC4**: 12 attempts - 6 PASS, 6 FAIL mixed

**5. "Same-Day Batch Testing"** (multiple units, many attempts, short duration)
- Multiple serials with 12-26 PASS attempts in seconds to hours
- **Examples:** D5VQNY2, 55SZLR2, 55S2MR2 - all 12 PASS in seconds

---

### 📊 Multiple Attempt Statistics (DELL_MEM - October 2025)

**Distribution:**
- Units with 1 attempt: ~60-70% (normal)
- Units with 2-5 attempts: ~20-25% (acceptable retest rate)
- Units with 6-12 attempts: ~5-10% (concerning)
- Units with 13-25 attempts: ~2-3% (stress testing or severe issues)
- Units with 26+ attempts: <1% (extreme cases - investigation required)

**Business Impact:**
- **65-attempt unit**: Likely testing equipment validation, not production
- **26-pass units**: Stress/burn-in testing - technically FPY but skews metrics
- **43-attempt failures**: Severe quality issues or incorrect test setup

---

**FPY Rule (STRICT DEFINITION):** A unit is FPY ONLY if:
1. **First test attempt** (by `LastProcessedID` timestamp) Result = `PASS`
2. ⚠️ **Note:** Multiple PASS retests still count as FPY if first = PASS
3. ⚠️ **Recommendation:** Consider flagging units with >10 attempts for investigation

---

### 📊 Test Timing Analysis

**Test Duration Examples:**
- Quick tests: 2-5 minutes (e.g., 9VS7014: 1 min 20 sec)
- Standard tests: 8-24 minutes (e.g., G7QHJC2: 19 min 19 sec)
- Long tests: 30+ minutes (e.g., 3JN23Z3: 6 min 32 sec)
- Extended tests: 1-2 hours (e.g., 28CV9K3: 1 hr 12 min)

**Use Case:** Track test efficiency and identify anomalies

---

### 🔗 Join Strategy to Plus Database

**Key Fields for Integration:**
- `SerialNumber` → `Plus.pls.PartSerial.SerialNo`
- Filter by `Program` = 'DELL_MEM' or 'DELL_JUA'
- Use `AsOf` for date filtering (not StartTime/EndTime - dates are corrupted)

**Family/LOB Rollup:**
```sql
-- Get Family and LOB from Plus
LEFT JOIN Plus.pls.PartSerial ps ON d.SerialNumber = ps.SerialNo
LEFT JOIN Plus.pls.PartSerialAttribute psa_family 
    ON ps.ID = psa_family.PartSerialID 
    AND psa_family.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttFamily')
LEFT JOIN Plus.pls.PartSerialAttribute psa_lob 
    ON ps.ID = psa_lob.PartSerialID 
    AND psa_lob.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB')
```

---

## 📋 Test Reporting Queries - Implementation Summary

### ✅ Completed Deliverables:

**1. First Pass Yield (FPY) Query** 
- **File:** `queries/ted_first_pass_yield.sql`
- **Purpose:** Calculate FPY at service tag level - units that pass on first attempt only
- **Features:**
  - Identifies first test attempt per serial (ROW_NUMBER by LastProcessedID)
  - FPY status categorization (FPY, NOT_FPY_MULTIPLE, NOT_FPY_FAIL, NOT_FPY_INCOMPLETE)
  - Family/LOB rollup from Plus database
  - Standard cost integration
  - Breakdown of failure reasons
  - Multiple aggregation levels (Program, TestArea, Family, LOB)
  - Optional rollups by individual dimensions

**2. Total Yield Query**
- **File:** `queries/ted_total_yield.sql`
- **Purpose:** Calculate overall yield including ALL test attempts
- **Features:**
  - All test instances (not just first attempts)
  - Result categorization (PASS, FAIL, EXCLUDED, OTHER)
  - Valid vs excluded test attempts
  - Total yield, failure rate, exclusion rate percentages
  - Unique units tested vs total attempts
  - Average attempts per unit
  - Family/LOB rollup from Plus database
  - Cost impact analysis
  - Time-series view (daily trends) - commented/optional

---

## 🎯 Key Business Logic Implemented

### SUCCESS Criteria:
```sql
Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
```

### FAILURE Criteria:
```sql
-- Explicit failures
Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 'FAIL-fail', 
           'FAIL (NO CHECKED)', 'Scratch & Dent')
-- Hex error codes (all 4-char hex codes)
-- Explicit errors
Result IN ('ERROR', 'error')
```

### EXCLUDED from Yield:
```sql
Result IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '', NULL)
```

---

## 🔗 Database Integration

**Cross-Database Join Pattern:**
```
redw.tia.DataWipeResult (Testing data)
  ↓ JOIN on SerialNumber = SerialNo
Plus.pls.PartSerial (ERP data)
  ↓ JOIN PartSerialAttribute
Family, LOB, Standard Cost
```

**Date Filtering:**
- ✅ **PRIMARY:** Use `AsOf` (batch processing/upload time) - RELIABLE dates (2025-01-30 to current)
- ❌ **AVOID:** `StartTime`/`EndTime` - CORRUPTED dates (1970-01-01 to 2037-12-31)
- ⚠️ **CRITICAL:** All production queries MUST use `AsOf` for date filtering

---

## ⚠️ Critical Data Quality Issues

**1. Date Fields (CRITICAL ISSUE - ALL RECORDS AFFECTED)**
- **Problem:** StartTime/EndTime CORRUPTED across ALL 85,904 records (1970-2037)
- **Evidence:** Date range spans 67 years (1970-01-01 to 2037-12-31)
- **Root Cause:** Unix timestamp conversion error affecting entire dataset
- **Solution:** ✅ Use `AsOf` field (reliable: 2025-01-30 to current)
- **Action Taken:** ALL production queries updated to use `AsOf` instead of StartTime

**2. Extreme Multiple Attempts**
- **Problem:** Units with 26-65 test attempts
- **Patterns:** Stress testing, persistent failures, NA spam
- **Recommendation:** Flag units with >10 attempts for review
- **Impact:** Can skew FPY metrics if not handled properly

**3. Multiple Result Codes**
- **Problem:** 74 different result values (PASS, Pass, Passed, SUCCEEDED, etc.)
- **Solution:** Comprehensive CASE statements to categorize all variants

**4. Program Name Variations**
- **Problem:** DELL_MEM vs DEL_MEM, DELL_JUA vs DEL_JUA
- **Impact:** Need to filter by correct program name
- **DELL_MEM:** 207,187 test records (1.1% of total database)

---

## 📊 Recommended Reporting Views

### Executive Dashboard:
1. **Overall FPY Rate** - DELL_MEM program
2. **Total Yield Rate** - All test attempts
3. **Top Failure Codes** - Hex codes driving failures
4. **Units with >10 Attempts** - Quality issues requiring investigation
5. **Daily Trend** - FPY and Total Yield over time

### Operational Dashboard:
1. **FPY by Family** - Product line performance
2. **FPY by LOB** - Line of business performance
3. **Test Duration Analysis** - Efficiency metrics
4. **Retest Rate** - Units requiring multiple attempts
5. **NA/Abort Rate** - Incomplete test tracking

### Quality Dashboard:
1. **Failure Pattern Analysis** - Persistent vs intermittent
2. **Top 10 Failing Serials** - Units with most failures
3. **Hex Error Code Distribution** - Root cause analysis
4. **Cost Impact** - Failed unit value analysis

---

## 🚀 Next Steps for Implementation

1. ✅ **FPY Query** - Ready to use in Power BI / reporting tools
2. ✅ **Total Yield Query** - Ready to use in Power BI / reporting tools
3. ⏭️ **Validate Results** - Run queries on sample date range, verify accuracy
4. ⏭️ **Power BI Integration** - Create data model and dashboards
5. ⏭️ **Investigate Meta Program** - 74.9% of database, purpose unknown
6. ⏭️ **Standardize Result Codes** - Work with testing team to reduce variants
7. 🔴 **CRITICAL: Fix Date Fields** - ALL StartTime/EndTime data corrupted (1970-2037) - Using `AsOf` as workaround
8. ⏭️ **Establish Thresholds** - Define acceptable retest rates and alert criteria

---

## Notes

- All tables created on the same date (October 5, 2025)
- Schema prefix: `tia.*`
- Database contains 19+ million test records across 40+ programs
- DELL_MEM (Memphis) has 207,187 test records (primary focus)
- Potential for cross-database reporting between `Plus` (ERP) and `redw` (Testing)
- **CRITICAL UPDATE:** StartTime/EndTime CORRUPTED for ALL records (1970-2037). Use `AsOf` field for all date-based queries.
- Multiple test attempts per serial are common - proper FPY calculation requires identifying first attempt
- Queries include Family/LOB rollup with Standard Cost integration
- Ready for Power BI dashboard implementation

