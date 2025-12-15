# Process Category Mapping for Efficiency Analysis

## Purpose
Map Vpart.sql `Category` field to `Process_Thresholds` for efficiency calculations.

## Process Thresholds Available:
- **Receiving** (Green: 15, Yellow: 8)
- **Receiving to Staging** (Green: 15, Yellow: 8)
- **Blow Out** (Green: 16, Yellow: 8)
- **Harvest** (Green: 40, Yellow: 20)
- **Putaway** (Green: 35, Yellow: 17)
- **Pallet Consolidation** (Green: 20, Yellow: 10)
- **Pick** (Green: 30, Yellow: 15)
- **Ship** (Green: 27, Yellow: 14)
- **QA** (Green: 65, Yellow: 32)
- **Boxing** (Green: 10, Yellow: 8)
- **BOM Fix** (Green: 10, Yellow: 8)
- **Discrepancy** (Green: 9, Yellow: 7)
- **Engineering into Hold** (Green: 7, Yellow: 5)
- **Engineering out** (Green: 7, Yellow: 5)
- **Add Part Adjustments** (Green: 8, Yellow: 6)
- **Pallet** (Green: 25, Yellow: 13)

## Category → Process Mappings:

### 1. RECEIVING
**Process:** "Receiving"  
**Categories from Vpart.sql:**
- 'ARB Receiving'
- 'ARB Receiving - Raw Goods'
- 'ARB Receiving - Finished Goods'
- 'ARB Receiving - SaN'
- 'ARB Receiving - Safety Capture'
- 'ARB Receiving - Discrepancy'
- 'ARB Receiving - Staging'

**Rule:** `Category LIKE '%ARB Receiving%'` → "Receiving"

### 2. SNP RECEIVING
**Process:** "Receiving"  
**Categories from Vpart.sql:**
- 'SNP Receiving'
- 'SNP Receiving - Liquidation'
- 'SNP Receiving - Crossdock'
- 'SNP Receiving - Discrepancy'
- 'SNP Receiving - Rapending'

**Rule:** `Category LIKE '%SNP Receiving%'` → "Receiving"

### 3. PUTAWAY
**Process:** "Putaway"  
**Categories from Vpart.sql:**
- 'Put Away - Finished Goods'
- 'Put Away - Finished Goods Correction'
- 'Put Away - Raw Goods'
- 'Put Away - EngHold'
- 'Put Away - Discrepancy'
- 'Put Away - Discrepancy Consolidation'
- 'Put Away - Raw Goods Consolidation'
- 'Put Away - Finished Goods Consolidation'
- 'Put Away - EngHold Consolidation'
- 'Put Away - EngRev Consolidation'
- 'Put Away - RAPENDING Consolidation'
- 'Put Away - Harvest Parts'
- 'Put Away - SCRAP Consolidation'
- 'Put Away - REIMAGE Consolidation'
- 'Put Away - SNP'
- 'Put Away - In Progress'

**Rule:** `Category LIKE '%Put Away%'` → "Putaway"
**Thresholds:** Green: 35/hour, Yellow: 17/hour

### 4. BLOWOUT
**Process:** "Blow Out"  
**Rule:** `Category LIKE '%Blowout%'` → "Blow Out"
**Thresholds:** Green: 16/hour, Yellow: 8/hour

### 5. PICKING
**Process:** "Pick"  
**Rule:** `Category LIKE '%Picking%'` → "Pick"
**Thresholds:** Green: 30/hour, Yellow: 15/hour

### 6. SHIPPING
**Process:** "Ship"  
**Rule:** `Category LIKE '%Shipping%'` → "Ship"
**Thresholds:** Green: 27/hour, Yellow: 14/hour

### 7. HARVESTING
**Process:** "Harvest"  
**Rule:** `Category LIKE '%Harvesting%'` → "Harvest"
**Thresholds:** Green: 40/hour, Yellow: 20/hour

### 8. BOXING
**Process:** "Boxing"  
**Rule:** `Category LIKE '%Boxing%'` → "Boxing"
**Thresholds:** Green: 10/hour, Yellow: 8/hour

### 9. ENGINEERING HOLD
**Process:** "Engineering into Hold"  
**Rule:** `Category LIKE '%Engineering Hold%'` → "Engineering into Hold"
**Thresholds:** Green: 7/hour, Yellow: 5/hour

### 10. ENGINEERING OUT
**Process:** "Engineering out"  
**Rule:** `Category LIKE '%Engineering Review%'` → "Engineering out"
**Thresholds:** Green: 7/hour, Yellow: 5/hour

### 11. PALLET
**Process:** "Pallet"  
**Rule:** `Category LIKE '%Pallet%'` → "Pallet"
**Thresholds:** Green: 25/hour, Yellow: 13/hour

### 12. DISCREPANCY
**Process:** "Discrepancy"  
**Rule:** `Category LIKE '%Discrepancy%'` → "Discrepancy"
**Thresholds:** Green: 9/hour, Yellow: 7/hour

---

## Next Categories to Map:
[ ] Picking categories  
[ ] Shipping categories
[ ] Other categories

## Notes:
- Start with ARB Receiving mapping
- Build up systematically
- Some categories may not have direct threshold matches
