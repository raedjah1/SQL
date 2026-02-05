## `categorizations2.csv` findings (ProgramID 10053)

This file appears to be a “ground truth” export of desired categorization outputs:
- **Low Level** ≈ `W_Level`
- **Mid_Level** ≈ `Mid_Level`
- **High_Level** ≈ `High_Level`

### High-signal patterns (most rows)

- **FINISHEDGOODS + REPAIR**: `FGI / FGI / ARB FGI` (dominant)
- **REIMAGE + HOLD**: `Reimage / Reimage / ARB WIP` (dominant)
- **ENGHOLD + RECEIVED**: `ENG Hold / HOLD / ARB Hold` (dominant)
- **DISCREPANCY + RECEIVED**: `ARB Research / ARB Research / ARB Hold` (dominant)
- **MEXREPAIR + HOLD**: `MexRepair AWP / AWP / ARB Hold` (dominant)
- **TEARDOWN + RECEIVED**: `Teardown / TEARDOWN / ARB WIP` (dominant)

### Edge cases that are *not* consistently covered by the existing generalized rules

These showed up in the CSV and are good candidates for **small, targeted rules** (not location-by-location lists):

- **ENGHOLD (NEW/HOLD)**: `NPI / ENGR Hold / ARB Hold`
- **STAGING (HOLD/NEW/REPAIR/SCRAP)**: `Blowout / WIP / ARB WIP`
- **BROKER (HOLD)**: `Broker / WIP / ARB WIP`
- **TEARDOWN (NEW/HOLD/REPAIR/SCRAP)**: `Awaiting Teardown / Teardown / ARB WIP`
- **TAGTORNDOWN (HOLD/NEW/REPAIR)**: `Teardown Complete / TagTornDown / ARB Complete`
- **INTRANSITTOMEMPHIS (RECEIVED)**: `IntransittoMem / Repair / ARB WIP`
- **RESEARCH (NEW)** at `RESEARCH.ARB.0.0.0`: `ARB Research / ARB Research / ARB Hold`
- **LIQUIDATION (NEW)** at `LIQUIDATION.SNP.MAN.0.0`: `Awaiting Liq / SnP Liq / SnP Complete`
- **FINISHEDGOODS (NEW/RECEIVED)** at `FINISHEDGOODS.ARB.0.0.0`: `Awaiting Putaway / WIP / ARB WIP`
- **RECEIVED warehouse (NEW/RECEIVED)**: `Received / WIP / ARB WIP` (while preserving existing `SnP Recv` rule)

### Important note

`queries/partserialwithout.sql` already correctly handles many of the dominant patterns. The goal of using this CSV is to **add only the missing edge-case rules** with precise conditions (often exact `PartLocationNo` matches), without altering the existing logic for the majority of locations.


