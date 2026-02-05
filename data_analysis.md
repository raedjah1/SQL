# Data Analysis: Warehouse Status & Workstation Description

## Executive Summary
- **Total Records**: 1,816 records
- **Primary Status**: RECEIVED (86% of records)
- **Workstation Population**: 89% have NULL WorkstationDescription
- **Location Types**: Mix of ARB Locations and Put Away locations
- **Warehouse definition (new)**: **Warehouse = `Level1_Prefix` from `PartLocationNo`** (the text before the first `.`), uppercased. Example: `WIP.10053.0.0.0` → `WIP`, `RAPENDING.SNP.0...` → `RAPENDING`.

---

## 1. Warehouse Status (StatusDescription) Analysis

### Status Distribution:
| Status | Count | % of Total | Unique Serials | Unique Parts | Date Range |
|--------|-------|------------|----------------|--------------|------------|
| **RECEIVED** | 1,567 | 86.3% | 1,564 | 147 | 2024-08-23 to 2026-01-16 |
| **NEW** | 143 | 7.9% | 143 | 32 | 2024-07-02 to 2025-12-23 |
| **WIP** | 67 | 3.7% | 67 | 19 | 2024-09-11 to 2026-01-12 |
| **HOLD** | 23 | 1.3% | 23 | 11 | 2024-11-01 to 2025-12-10 |
| **REPAIR** | 12 | 0.7% | 12 | 8 | 2024-11-06 to 2025-12-23 |
| **UNREPAIR** | 3 | 0.2% | 3 | 3 | 2024-11-01 (single day) |
| **SCRAP** | 1 | 0.1% | 1 | 1 | 2024-11-26 (single day) |

### Status Workflow Understanding:
- **RECEIVED**: Initial receiving status - items just arrived
- **NEW**: Newly created/entered items
- **WIP**: Work In Progress - items actively being processed
- **HOLD**: Items on hold (quality issues, waiting for decisions)
- **REPAIR**: Items being repaired
- **UNREPAIR**: Items that cannot be repaired
- **SCRAP**: Items marked for scrapping

---

## 2. Workstation Description Analysis

### Workstation Distribution:
| Workstation | Count | % of Total | Unique Serials | Unique Parts |
|-------------|-------|------------|----------------|--------------|
| **NULL** | 1,710 | 94.2% | 1,705 | 162 |
| **Cosmetic** | 38 | 2.1% | 38 | 18 |
| **Close** | 26 | 1.4% | 26 | 12 |
| **gTest0** | 17 | 0.9% | 17 | 6 |
| **Triage** | 7 | 0.4% | 7 | 1 |
| **gTask5** | 5 | 0.3% | 5 | 4 |
| **Scrap** | 5 | 0.3% | 5 | 5 |
| **Datawipe** | 4 | 0.2% | 4 | 3 |
| **gTask3** | 2 | 0.1% | 2 | 2 |
| **gTask0** | 1 | 0.1% | 1 | 1 |
| **gTask1** | 1 | 0.1% | 1 | 1 |

### Key Insight:
- **94% of records have NULL WorkstationDescription**
- Workstations are primarily populated when items are in active processing (WIP, REPAIR, HOLD statuses)

---

## 3. Status ↔ Workstation Relationship Matrix

### Critical Relationships:

| Status | Workstation | Count | Pattern |
|--------|-------------|-------|---------|
| **RECEIVED** | NULL | 1,567 | ✅ **Always NULL** - Receiving doesn't use workstations |
| **NEW** | NULL | 143 | ✅ **Always NULL** - New items not yet at workstations |
| **WIP** | Cosmetic | 24 | Active cosmetic work |
| **WIP** | gTest0 | 15 | Testing workstation |
| **WIP** | Close | 13 | Closing/finalizing work |
| **WIP** | Triage | 6 | Triage/assessment |
| **WIP** | Scrap | 4 | Scrapping process |
| **WIP** | gTask3 | 2 | Task-specific workstation |
| **WIP** | gTask0 | 1 | Task-specific workstation |
| **REPAIR** | Close | 12 | ✅ **Always "Close"** - Repair closing station |
| **HOLD** | Cosmetic | 11 | Cosmetic issues causing hold |
| **HOLD** | gTask5 | 5 | Task-specific hold |
| **HOLD** | Datawipe | 2 | Data wipe hold |
| **HOLD** | gTest0 | 2 | Testing hold |
| **HOLD** | Triage | 1 | Triage hold |
| **HOLD** | gTask1 | 1 | Task-specific hold |
| **HOLD** | Close | 1 | Close hold |
| **UNREPAIR** | Cosmetic | 3 | ✅ **Always "Cosmetic"** - Unrepairable cosmetic issues |
| **SCRAP** | Scrap | 1 | ✅ **Always "Scrap"** - Scrap workstation |

### Business Rules Inferred:
1. **RECEIVED & NEW statuses** → Always NULL WorkstationDescription
2. **REPAIR status** → Always "Close" WorkstationDescription
3. **UNREPAIR status** → Always "Cosmetic" WorkstationDescription
4. **SCRAP status** → Always "Scrap" WorkstationDescription
5. **WIP & HOLD statuses** → Can have various workstations (active processing)

---

## 4. Location Type Analysis

### Location Type Distribution by Status:

#### RECEIVED Status:
- **Put Away location**: 1,319 records (84% of RECEIVED)
- **ARB Location**: 248 records (16% of RECEIVED)

#### NEW Status:
- **Put Away location**: 73 records (51% of NEW)
- **ARB Location**: 70 records (49% of NEW)

#### Active Processing Statuses (WIP, HOLD, REPAIR):
- **Primarily Put Away locations** (most workstations are in Put Away locations)
- **Some ARB locations** for specific processes (e.g., REPAIR Close, UNREPAIR Cosmetic)

### Location Naming Patterns Observed:
From sample data, location numbers follow patterns:
- `Received.ARB.0.0.0` - Receiving location (RECEIVED status)
- `DISCREPANCY.ARB.UR.0.0` - Discrepancy handling (RECEIVED status)
- `Teardown.ARB.0.0.0` - Teardown process (RECEIVED status)
- `FINISHEDGOODS.ARB.BB.09.01A` - Finished goods storage (RECEIVED status)
- `WIP.10053.0.0.0` - Work in progress location (WIP status, various workstations)
- `FGI.10053.0.0.0` - Finished goods inventory (REPAIR status)
- `Staging.ARB.0.0.0` - Staging area (RECEIVED status)
- `InDemandGoodParts.ARB.0.0.0` - In-demand parts (NEW status)
- `Reimage.ARB.H0.0.0` - Reimaging process (HOLD status)
- `TEST.ARB.W1A.04.04B` - Test locations (NEW status)
- `TEST2.ARB.TTS.TTS.TTS` - Test locations (NEW status)

### Location Prefix to Status Mapping:
- **Received** prefix → RECEIVED status
- **DISCREPANCY** prefix → RECEIVED status
- **Teardown** prefix → RECEIVED status
- **FINISHEDGOODS** prefix → RECEIVED status
- **Staging** prefix → RECEIVED status
- **WIP** prefix → WIP status (active workstations)
- **FGI** prefix → REPAIR status
- **InDemandGoodParts** prefix → NEW status
- **Reimage** prefix → HOLD status
- **TEST** prefix → NEW status

---

## 5. Data Quality Observations

### NULL WorkstationDescription:
- **1,710 records (94%)** have NULL WorkstationDescription
- These are primarily RECEIVED (1,567) and NEW (143) statuses
- **This is expected behavior** - items not yet at workstations don't need workstation assignment

### Workstation Assignment Logic:
- Workstations are assigned when items enter active processing
- Different workstations handle different types of work:
  - **Cosmetic**: Cosmetic repairs/assessments
  - **Close**: Closing/finalizing processes (REPAIR, some WIP)
  - **gTest0, gTask0, gTask1, gTask3, gTask5**: Testing/task-specific workstations
  - **Triage**: Assessment/evaluation
  - **Scrap**: Scrapping process
  - **Datawipe**: Data wiping operations

---

## 6. Recommendations for Query Modifications

### Potential Enhancements:
1. **Add StatusDescription to output** - Currently missing from base query
2. **Add WorkstationDescription to output** - Currently missing from base query
3. **Create Status-based groupings** - Group by Warehouse Status for reporting
4. **Workstation-based filtering** - Filter by active workstations vs NULL
5. **Location pattern analysis** - Break down by location prefixes (Received, WIP, FGI, etc.)

### Query Logic Considerations:
- When WorkstationDescription is NULL → Item is likely in storage/receiving (not actively processed)
- When WorkstationDescription is populated → Item is actively being worked on
- Status + Workstation combination provides full workflow picture

---

## 7. Complete Location Structure Analysis (3-Level Breakdown)

### Location Structure Pattern:
**Format**: `[Level1_Prefix].[Level2].[Level3].[Additional].[Details]`

### Top Location Prefixes by Volume:
| Level1_Prefix | Record Count | Primary Status | Level2 Pattern | Level3 Pattern |
|---------------|--------------|----------------|---------------|---------------|
| **RAPENDING** | 627 | RECEIVED | SNP | 0 |
| **DGI** | 489 | RECEIVED | 10053 | 1, 0 |
| **Staging** | 82 | RECEIVED | ARB | 0 |
| **WIP** | 67 | WIP | 10053 | 0 |
| **Teardown** | 56 | RECEIVED | ARB | 0 |
| **FINISHEDGOODS** | 52+ | RECEIVED/NEW/REPAIR | ARB | BJ, 1, BK, BC, BB, BA, etc. |
| **DISCREPANCY** | 34+ | RECEIVED/NEW | ARB/SNP | UR, 0 |
| **Received** | 36 | RECEIVED | ARB | 0 |
| **RAAPPROVED** | 32+ | RECEIVED/NEW | SNP | 0, 1 |
| **FinishedGoods** | 34+ | RECEIVED/NEW/REPAIR | ARB | 0 |
| **LIQUIDATION** | 10+ | RECEIVED | SNP/10053 | 0 |
| **Reimage** | 6+ | HOLD/NEW | ARB | H0, 0 |
| **FGI** | 5+ | REPAIR/RECEIVED | 10053 | 0 |
| **BOXING** | 8+ | NEW/HOLD | ARB | 0, ENG |
| **RESEARCH** | 4+ | RECEIVED/NEW | ARB/SNP | 0 |

### Level2 Patterns:
- **ARB**: Most common, used across many location types
- **SNP**: Used for RAPENDING, RAAPPROVED, DISCREPANCY, LIQUIDATION, RESEARCH, RTV
- **10053**: Program ID, used for WIP, DGI, FGI, FUNCTIONAL, ShippedtoCustomer

### Level3 Patterns:
- **0**: Default/standard location (most common)
- **UR**: Unrepairable (DISCREPANCY locations)
- **H0**: Hold locations (Reimage, BROKER, BOXING, IntransittoMexico, etc.)
- **BJ, BB, BC, BK, BA, BF, BG, BL, BM, BP, FO, 1**: Finished goods sub-locations
- **K, D, W1A, TTS, TES**: Staging/TEST sub-locations
- **ARB**: Used in some FUNCTIONAL and Discrepancy locations
- **JRZ**: IntransittoMexico location
- **ENG**: Engineering-related locations

### Status Distribution by Location Prefix:
| Location Prefix | RECEIVED | NEW | WIP | HOLD | REPAIR | UNREPAIR | SCRAP |
|----------------|----------|-----|-----|------|--------|----------|-------|
| **RAPENDING** | ✅ 627 | ✅ 1 | | | | | |
| **DGI** | ✅ 489+6 | ✅ 1 | | | | | |
| **Staging** | ✅ 82 | ✅ 3 | | | | | |
| **WIP** | | | ✅ 67 | | | | |
| **Teardown** | ✅ 56 | ✅ 12 | | | | | ✅ 1 |
| **FINISHEDGOODS** | ✅ 52+3+2+1 | ✅ 6+3+2+1+1+1+1+1+1 | | | ✅ 3+2 | | |
| **DISCREPANCY** | ✅ 34+25+9+22+3 | ✅ 37+24 | | | | | |
| **FGI** | ✅ 2 | | | | ✅ 5 | | |
| **Reimage** | | ✅ 2 | | ✅ 6+2+1 | | | |
| **BOXING** | ✅ 1 | ✅ 8 | | ✅ 3 | | | |

### Key Insights:
1. **RAPENDING** is the largest location category (627 records) - RA Pending status
2. **DGI** locations are second largest (489 records) - DGI processing
3. **WIP** locations are the ONLY ones with WIP status (67 records)
4. **FINISHEDGOODS** can have multiple statuses (RECEIVED, NEW, REPAIR)
5. **DISCREPANCY** locations can be RECEIVED or NEW
6. **HOLD** status appears in various prefixes: Reimage, BROKER, BOXING, INTRANSITTOMEXICO, BOMFix, STAGING
7. **REPAIR** status primarily in FGI and FINISHEDGOODS locations
8. **Location structure**: `[Prefix].[ARB/SNP/10053].[SubCategory].[Additional].[Details]`

---

## 8. Warehouse (Level1_Prefix) Distribution (Non-WIP Focus)

### What “Warehouse” means for this project
- **Warehouse** is the **Level1 prefix** only: `UPPER(LEFT(PartLocationNo, CHARINDEX('.', PartLocationNo + '.') - 1))`
- This is independent of `StatusDescription`.
- **WIP classification**: We keep the WIP workstation-based mapping, but it keys off `Warehouse = 'WIP'` (not “status is WIP”).

### Latest warehouse summary (from investigative query)
| Warehouse | StatusDescription | Record_Count | Unique_Locations | Null_Workstation_Count |
|----------|-------------------|-------------:|-----------------:|-----------------------:|
| RAPENDING | RECEIVED | 630 | 3 | 630 |
| DGI | RECEIVED | 495 | 3 | 495 |
| FINISHEDGOODS | RECEIVED | 94 | 7 | 94 |
| DISCREPANCY | RECEIVED | 93 | 5 | 93 |
| STAGING | RECEIVED | 82 | 1 | 82 |
| DISCREPANCY | NEW | 61 | 2 | 61 |
| TEARDOWN | RECEIVED | 56 | 1 | 56 |
| RECEIVED | RECEIVED | 39 | 2 | 39 |
| RAAPPROVED | RECEIVED | 33 | 2 | 33 |
| FINISHEDGOODS | NEW | 23 | 14 | 23 |
| TEARDOWN | NEW | 12 | 1 | 12 |
| LIQUIDATION | RECEIVED | 11 | 2 | 11 |
| STAGING | NEW | 9 | 3 | 9 |
| REIMAGE | HOLD | 9 | 3 | 0 |
| BOXING | NEW | 8 | 1 | 8 |
| FUNCTIONAL | RECEIVED | 6 | 1 | 6 |
| FINISHEDGOODS | REPAIR | 5 | 2 | 0 |
| FGI | REPAIR | 5 | 1 | 0 |
| RESEARCH | RECEIVED | 4 | 1 | 4 |
| INTRANSITTOMEXICO | HOLD | 4 | 2 | 0 |
| RTV | RECEIVED | 4 | 1 | 4 |
| RAAPPROVED | NEW | 3 | 2 | 3 |
| FLOORSTOCK | NEW | 3 | 1 | 3 |
| RESEARCH | NEW | 3 | 1 | 3 |
| RECEIVED | NEW | 3 | 1 | 3 |
| BROKER | HOLD | 3 | 1 | 0 |
| BOXING | HOLD | 3 | 1 | 0 |
| TEST | NEW | 3 | 2 | 3 |
| SAN | RECEIVED | 3 | 1 | 3 |
| GENCOFGI | RECEIVED | 3 | 1 | 3 |
| SERVICESREPAIR | NEW | 2 | 1 | 2 |
| BOMFIX | HOLD | 2 | 1 | 0 |
| SHIPPEDTOCUSTOMER | RECEIVED | 2 | 1 | 2 |
| TESTWHS1 | RECEIVED | 2 | 1 | 2 |
| REIMAGE | NEW | 2 | 1 | 2 |
| SHIPPEDTOCUSTOMER | REPAIR | 2 | 1 | 0 |
| INTRANSITTOMEXICO | NEW | 2 | 1 | 2 |
| FGI | RECEIVED | 2 | 1 | 2 |
| GENCOEMR | RECEIVED | 1 | 1 | 1 |
| INTRANSITTOMEMPHIS | UNREPAIR | 1 | 1 | 0 |
| GENCOENGHOLD | RECEIVED | 1 | 1 | 1 |
| RAPENDING | NEW | 1 | 1 | 1 |
| STAGING | HOLD | 1 | 1 | 0 |
| INTRANSITTOMEXICO | RECEIVED | 1 | 1 | 1 |
| TEARDOWN | SCRAP | 1 | 1 | 0 |
| FUNCTIONAL | NEW | 1 | 1 | 1 |
| BOXING | RECEIVED | 1 | 1 | 1 |
| TAGTORNDOWN | RECEIVED | 1 | 1 | 1 |
| TEST2 | NEW | 1 | 1 | 1 |
| INDEMANDGOODPARTS | RECEIVED | 1 | 1 | 1 |
| INTRANSITTOMEMPHIS | HOLD | 1 | 1 | 0 |
| SHIPPEDTOCUSTOMER | NEW | 1 | 1 | 1 |
| SCRAP | UNREPAIR | 1 | 1 | 0 |
| SANPUTAWAY | RECEIVED | 1 | 1 | 1 |
| DGI | NEW | 1 | 1 | 1 |
| BROKER | UNREPAIR | 1 | 1 | 0 |
| BROKER | NEW | 1 | 1 | 1 |
| INDEMANDGOODPARTS | NEW | 1 | 1 | 1 |
| SCRAP | NEW | 1 | 1 | 1 |
| L2STAGING | RECEIVED | 1 | 1 | 1 |
| NODEMANDGOODPARTS | NEW | 1 | 1 | 1 |

---

## 9. Base Tables Behind `pls.vPartSerial` (View Lineage)

`pls.vPartSerial` is a view over these base tables (database `Plus`, schema `pls`):
- `Plus.pls.PartSerial` (main serial facts)
- `Plus.pls.PartLocation` (provides `PartLocationNo` via `LocationNo`)
- `Plus.pls.CodeStatus` (provides `StatusDescription`)
- `Plus.pls.CodeWorkStation` (provides `WorkstationDescription`)
- `Plus.pls.CodeConfiguration` (provides `ConfigurationDescription`)
- `Plus.pls.[User]` (provides `Username`)

### Important implication
Some **Warehouse prefixes can exist as locations** in `Plus.pls.PartLocation` even if they don’t appear (or barely appear) in `pls.vPartSerial`, because **no units are currently located there**.

Example from investigation:
- `INDEMANDBADPARTS`, `NODEMANDBADPARTS`, `SERVICESFINGOODS`, `INDEMANDGOODPARTS`, `NODEMANDGOODPARTS` all exist in `PartLocation`.
- But serials currently present (via `PartSerial` joined to `PartLocation`) were only:
  - `INDEMANDGOODPARTS`: `NEW` (1), `RECEIVED` (1)
  - `NODEMANDGOODPARTS`: `NEW` (1)

---

## 10. Classification Rules (Step 2: Non-WIP Warehouses)

These rules classify **anything NOT in `Warehouse='WIP'`** using `Warehouse` (Level1 prefix) + `StatusDescription` (and one rule also checks `.SNP.`).

| Warehouse | Status | W_Level | Mid_Level | High_Level | Extra Condition |
|----------|--------|---------|-----------|------------|----------------|
| RAPENDING | RECEIVED | RAPENDING | SNP RAPEN | SnP WIP | |
| REIMAGE | HOLD | Reimage | Reimage | ARB WIP | |
| INTRANSITTOMEXICO | HOLD | IntransittoMexico | REPAIR | ARB WIP | |
| TEARDOWN | RECEIVED | Teardown | TEARDOWN | ARB WIP | |
| ENGHOLD | RECEIVED | ENG Hold | HOLD | ARB Hold | |
| FINISHEDGOODS | REPAIR | FGI | FGI | ARB FGI | |
| STAGING | RECEIVED | Staging | WIP | ARB WIP | |
| MEXREPAIR | HOLD | MexRepair | REPAIR | ARB WIP | |
| INTRANSITTOMEMPHIS | HOLD | INTRANSITTOMEMPHIS | REPAIR | ARB WIP | |
| BOXING | HOLD | Boxing | WIP | ARB WIP | |
| RECEIVED | RECEIVED | SnP Recv | SNP Recv | SnP WIP | `PartLocationNo LIKE '%.SNP.%'` |

---

## 11. Classification Rules (Step 3: Additional Warehouses)

| Warehouse | Status | W_Level | Mid_Level | High_Level | Extra Condition |
|----------|--------|---------|-----------|------------|----------------|
| MEXREIMAGE | HOLD | MexReimage | REPAIR | ARB WIP | |
| MEXBOMFIX | HOLD | MexBomFix | REPAIR | ARB WIP | |
| RESEARCH | RECEIVED | Research | Research | ARB Hold | |
| LIQUIDATION | RECEIVED | Liquidation | SNP PenLiq | SnP Complete | |
| BOMFIX | HOLD | BomFIX | WIP | ARB WIP | |
| TAGTORNDOWN | RECEIVED | TagTorn Down | TagTornDown | ARB Complete | |
| SCRAP | (any) | Scrap | Scrap | ARB Complete | Status varies (often NEW/UNREPAIR); rule matches by Warehouse prefix |
| SAFETYCAPTURE | RECEIVED | Saftey Capture | WIP | ARB WIP | |
| FGI | REPAIR | FGI | FGI | ARB FGI | |
| GENCOFGI | RECEIVED | FGI | FGI | ARB FGI | |
| GENCOEMR | RECEIVED | MexRepair | REPAIR | ARB WIP | |
| SERVICESREPAIR | (any) | Teardown Part | Teardown Part | Teardown Part | Observed as NEW in rollups; rule matches by Warehouse prefix |

---

## 12. Classification Rules (Step 4: Additional Warehouses)

| Warehouse | Status | W_Level | Mid_Level | High_Level | Extra Condition |
|----------|--------|---------|-----------|------------|----------------|
| L2STAGING | RECEIVED | Saftey Capture | WIP | ARB WIP | |
| RAAPPROVED | RECEIVED | RAAPPROVED | SNP PenRTV | SNP WIP | |
| INDEMANDBADPARTS | RECEIVED | Teardown Part | Teardown Part | Teardown Part | |
| SERVICESFINGOODS | RECEIVED | Teardown Part | Teardown Part | Teardown Part | |
| INTRANSIITTOMEXICO | HOLD | IntransittoMexico | REPAIR | ARB WIP | Supports both `INTRANSIITTOMEXICO` + `INTRANSITTOMEXICO` |
| INDEMANDGOODPARTS | RECEIVED | Teardown Part | Teardown Part | Teardown Part | |
| NODEMANDGOODPARTS | RECEIVED | Teardown Part | Teardown Part | Teardown Part | |
| NODEMANDBADPARTS | RECEIVED | Teardown Part | Teardown Part | Teardown Part | |

---

## 13. Classification Rules (Step 5: DISCREPANCY (RECEIVED) Location-Based)

These rules apply when:
- `Warehouse = 'DISCREPANCY'` (Level1 prefix), and
- `StatusDescription = 'RECEIVED'`, and
- `PartLocationNo` contains `.ARB.` vs `.SNP.` and contains `.UR.` vs not.

| Warehouse | Status | Location criteria | W_Level | Mid_Level | High_Level |
|----------|--------|-------------------|---------|-----------|------------|
| DISCREPANCY | RECEIVED | contains `.ARB.` and `.UR.` | ARB UR | ARB UR | ARB Hold |
| DISCREPANCY | RECEIVED | contains `.SNP.` and `.UR.` | SnP UR | SnP UR | SNP Hold |
| DISCREPANCY | RECEIVED | contains `.ARB.` and **not** `.UR.` | ARB Research | ARB Research | ARB Hold |
| DISCREPANCY | RECEIVED | contains `.SNP.` and **not** `.UR.` | SnP Research | SnP Research | SNP Hold |

---

## 14. Classification Rules (Step 6: REIMAGE / MEXREPAIR Location Overrides)

These rules are **location-based overrides** and should be evaluated **before** the broader `REIMAGE` / `MEXREPAIR` rules.

| Warehouse | Criteria | W_Level | Mid_Level | High_Level |
|----------|-------------------|---------|-----------|------------|
| REIMAGE | `StatusDescription <> 'HOLD'` and `PartLocationNo` starts with `REIMAGE.ARB.ENG.REV.NPI` | Engineering Review | Reimage | ARB WIP |
| REIMAGE | `StatusDescription <> 'HOLD'` and (any other `REIMAGE.*`) | Engineering Review | Reimage | ARB WIP |
| MEXREPAIR | `PartLocationNo` contains `AWP` **OR** equals `INTRANSITTOMEXICO.ARB.0.0.0.1` | MexRepair AWP | AWP | ARB Hold |

---

## 15. Classification Rules (Step 7: BROKER (RECEIVED) Location-Based)

| Warehouse | Status | Location criteria | W_Level | Mid_Level | High_Level |
|----------|--------|-------------------|---------|-----------|------------|
| BROKER | RECEIVED | `PartLocationNo = 'BROKER.0.0.0'` (exact) | Broker | WIP | ARB WIP |
| (any) | RECEIVED | `PartLocationNo LIKE '%BROKER%'` (anywhere) | Broker FGI | Broker FGI | ARB Complete |

---

## 16. Classification Rules (Step 8: TEARDOWN PartNo `*-H` Override)

| Warehouse | Criteria | W_Level | Mid_Level | High_Level |
|----------|----------|---------|-----------|------------|
| TEARDOWN | `UPPER(PartNo) LIKE '%-H'` | Teardown Part | Teardown Part | Teardown Part |

---

## 17. Query Modification Recommendations

### Current Query Issues:
1. Uses `SELECT *` which includes StatusDescription and WorkstationDescription, but they're not explicitly shown
2. No explicit StatusDescription or WorkstationDescription in output
3. Location_Type logic only checks for `ARB.0.0.0` pattern, but many locations have different structures
4. Missing location prefix analysis which is critical for understanding workflow

### Recommended Enhancements:

#### Option 1: Add Status, Workstation, and Location Analysis (RECOMMENDED)
```sql
SELECT 
    *,
    StatusDescription AS Warehouse_Status,
    WorkstationDescription,
    LEFT(PartLocationNo, CHARINDEX('.', PartLocationNo + '.') - 1) AS Location_Prefix,
    CASE 
        WHEN CHARINDEX('.', PartLocationNo, CHARINDEX('.', PartLocationNo) + 1) > 0
        THEN SUBSTRING(PartLocationNo, 
            CHARINDEX('.', PartLocationNo) + 1, 
            CHARINDEX('.', PartLocationNo, CHARINDEX('.', PartLocationNo) + 1) - CHARINDEX('.', PartLocationNo) - 1)
        ELSE NULL
    END AS Location_Level2,
    'DELL - MEMPHIS' AS Location,
    -- ... rest of existing logic
```

#### Option 2: Enhanced Location Type with Prefix Categories
```sql
CASE 
    WHEN PartLocationNo LIKE 'RAPENDING.%' THEN 'RA Pending Location'
    WHEN PartLocationNo LIKE 'DGI.%' THEN 'DGI Location'
    WHEN PartLocationNo LIKE 'WIP.%' THEN 'WIP Location'
    WHEN PartLocationNo LIKE 'FGI.%' THEN 'FGI Location'
    WHEN PartLocationNo LIKE 'FINISHEDGOODS.%' THEN 'Finished Goods Location'
    WHEN PartLocationNo LIKE 'DISCREPANCY.%' THEN 'Discrepancy Location'
    WHEN PartLocationNo LIKE 'Received.%' THEN 'Receiving Location'
    WHEN PartLocationNo LIKE 'Teardown.%' THEN 'Teardown Location'
    WHEN PartLocationNo LIKE 'Staging.%' THEN 'Staging Location'
    WHEN PartLocationNo LIKE 'RAAPPROVED.%' THEN 'RA Approved Location'
    WHEN PartLocationNo LIKE 'LIQUIDATION.%' THEN 'Liquidation Location'
    WHEN PartLocationNo LIKE 'Reimage.%' THEN 'Reimage Location'
    WHEN PartLocationNo LIKE '%ARB.0.0.0%' THEN 'ARB Location'
    ELSE 'Put Away location'
END AS Location_Type
```

#### Option 3: Complete Location Breakdown
```sql
LEFT(PartLocationNo, CHARINDEX('.', PartLocationNo + '.') - 1) AS Location_Prefix,
CASE 
    WHEN PartLocationNo LIKE '%.ARB.%' THEN 'ARB'
    WHEN PartLocationNo LIKE '%.SNP.%' THEN 'SNP'
    WHEN PartLocationNo LIKE '%.10053.%' THEN 'Program 10053'
    ELSE 'Other'
END AS Location_Category
```

---

## 18. Questions for Further Investigation

1. **SLA by Status**: How do SLA rules differ by StatusDescription? (Should RECEIVED have same SLA as WIP?)
2. **Workstation Performance**: Which workstations have items outside SLA?
3. **Status Transitions**: What are the typical status progression paths?
4. **Location Type Impact**: Do ARB vs Put Away locations have different SLA requirements?
5. **Active vs Inactive**: Should we filter or highlight items with active workstations differently?

