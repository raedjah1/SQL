# IDIAG Component Analysis - Single Page Dashboard Guide

## Page Name: **"IDIAG Component Analysis"**

---

## Layout Structure

```
┌─────────────────────────────────────────────────────────────┐
│  TOP ROW: KPI Cards (Summary Query)                         │
├─────────────────────────────────────────────────────────────┤
│  LEFT SIDE: Summary Visualizations (Summary Query)          │
│  RIGHT SIDE: Trend Visualizations (TimeSeries Query)         │
└─────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Build Instructions

### **STEP 1: Create the Page**
1. Right-click **Pages** → **New Page**
2. Rename to: **"IDIAG Component Analysis"**

---

### **STEP 2: Top Row - KPI Cards (Use Summary Query)**

#### Card 1: Total Component Tests
1. **Insert** → **Card**
2. **Data**: IDIAG Component Summary
3. **Field**: `TotalOccurrences`
4. **Format** → **Title**: "Total Component Tests"
5. **Format** → **Category label**: Off (cleaner look)

#### Card 2: Total Failures
1. **Insert** → **Card**
2. **Data**: IDIAG Component Summary
3. **Field**: `FailCount` (or `ErrorCount`)
4. **Format** → **Title**: "Total Failures"
5. **Format** → **Data colors**: Red

#### Card 3: Overall Pass Rate
1. **Insert** → **Card**
2. **Data**: IDIAG Component Summary
3. **Field**: `PassRate` (format as Percentage)
4. **Format** → **Title**: "Overall Pass Rate"
5. **Format** → **Data colors**: Green

#### Card 4: Components with Errors
1. **Insert** → **Card**
2. **Data**: IDIAG Component Summary
3. **Field**: `HasErrors` → Create measure: `Components with Errors = SUM('IDIAG Component Summary'[HasErrors])`
4. **Format** → **Title**: "Components with Errors"

**Arrange**: All 4 cards in a row at the top

---

### **STEP 3: Left Side - Summary Visualizations (Use Summary Query)**

#### Visualization 1: Top 10 Most Problematic Components
1. **Insert** → **Bar Chart** (Horizontal)
2. **Data**: IDIAG Component Summary
3. **Y-Axis**: `ComponentName`
4. **X-Axis**: `FailRate` (format as Percentage)
5. **Visualizations** → **Filters** → **Top N** → Top 10 by `FailRate`
6. **Format** → **Data colors**: Red gradient (darker = worse)
7. **Format** → **Title**: "Top 10 Most Problematic Components"
8. **Tooltip**: Add `ComponentDescription`, `TotalOccurrences`, `FailCount`

#### Visualization 2: Component Failure Heat Map
1. **Insert** → **Matrix**
2. **Data**: IDIAG Component Summary
3. **Rows**: `ComponentName` (Top 20 by `FailCount`)
4. **Values**: `FailRate` (format as Percentage)
5. **Format** → **Conditional formatting** → **Background color**:
   - Color scale: Green (0%) → Yellow (5%) → Red (10%+)
   - Show data bars
6. **Format** → **Title**: "Component Failure Rate Heat Map"
7. **Tooltip**: Add `ComponentDescription`, `TotalOccurrences`

#### Visualization 3: Component Category Breakdown
1. **Insert** → **Donut Chart**
2. **Data**: IDIAG Component Summary
3. **Legend**: `ComponentCategory`
4. **Values**: `TotalOccurrences`
5. **Format** → **Title**: "Tests by Component Category"
6. **Tooltip**: Category name, count, percentage

**Arrange**: Stack these 3 visuals vertically on the left side

---

### **STEP 4: Right Side - Trend Visualizations (Use TimeSeries Query)**

#### Visualization 4: Component Failure Trends Over Time
1. **Insert** → **Line Chart**
2. **Data**: IDIAG Component TimeSeries
3. **X-Axis**: `TestDate` (group by Week or Month)
4. **Y-Axis**: Create measure:
   ```
   Daily Fail Rate = DIVIDE(
       SUM('IDIAG Component TimeSeries'[FailCount]), 
       SUM('IDIAG Component TimeSeries'[TestCount]), 
       0
   )
   ```
   Format as Percentage
5. **Legend**: `ComponentName` (Top 10 by total failures)
6. **Format** → **Title**: "Component Failure Trends Over Time"
7. **Format** → **Legend**: Position at top

#### Visualization 5: Component Failure Heat Map (Time-Based)
1. **Insert** → **Matrix**
2. **Data**: IDIAG Component TimeSeries
3. **Rows**: `ComponentName` (Top 20 by total failures)
4. **Columns**: `TestDate` (group by Week)
5. **Values**: Same measure `Daily Fail Rate`
6. **Format** → **Conditional formatting** → **Background color**:
   - Color scale: Green (0%) → Yellow (5%) → Red (10%+)
7. **Format** → **Title**: "Component Failures Over Time (Heat Map)"
8. **Tooltip**: Date, Component, Test Count, Fail Count

#### Visualization 6: Daily Test Volume vs. Failure Rate
1. **Insert** → **Combo Chart** (Column + Line)
2. **Data**: IDIAG Component TimeSeries
3. **X-Axis**: `TestDate` (group by Day)
4. **Column Values**: `TestCount` (Total tests per day)
5. **Line Values**: Same measure `Daily Fail Rate`
6. **Format** → **Title**: "Daily Test Volume vs. Failure Rate"
7. **Format** → **Secondary Y-axis**: Show (for Fail Rate line)

**Arrange**: Stack these 3 visuals vertically on the right side

---

### **STEP 5: Bottom Section - Detailed Table (Use Summary Query)**

#### Visualization 7: Component Performance Table
1. **Insert** → **Table**
2. **Data**: IDIAG Component Summary
3. **Columns** (in order):
   - `ComponentName`
   - `ComponentCategory`
   - `TotalOccurrences`
   - `PassCount`
   - `FailCount` (or `ErrorCount`)
   - `PassRate` (format as Percentage)
   - `FailRate` (format as Percentage)
   - `ReliabilityCategory`
4. **Format** → **Conditional formatting**:
   - `FailRate` column → **Background color** → **Rules**:
     - Red if `FailRate >= 0.05` (5%)
     - Yellow if `FailRate >= 0.01` (1%)
     - Green if `FailRate = 0`
5. **Sort**: By `FailRate` (Descending) - worst first
6. **Format** → **Title**: "Component Performance Summary Table"
7. **Format** → **Search**: On (so users can search for components)

**Arrange**: Full width at the bottom

---

### **STEP 6: Add Slicers (Top of Page)**

#### Slicer 1: Machine Type
1. **Insert** → **Slicer**
2. **Field**: `MachineNameNormalized` (from Summary query)
3. **Format** → **Style**: Tiles
4. **Format** → **Title**: "Machine Type"

#### Slicer 2: Component Category
1. **Insert** → **Slicer**
2. **Field**: `ComponentCategory` (from Summary query)
3. **Format** → **Style**: Dropdown (multi-select)
4. **Format** → **Title**: "Component Category"

#### Slicer 3: Date Range (for TimeSeries visuals)
1. **Insert** → **Slicer**
2. **Field**: `TestDate` (from TimeSeries query)
3. **Format** → **Style**: Between
4. **Format** → **Title**: "Date Range"

#### Slicer 4: Reliability Filter
1. **Insert** → **Slicer**
2. **Field**: `ReliabilityCategory` (from Summary query)
3. **Format** → **Style**: Dropdown (multi-select)
4. **Format** → **Title**: "Reliability Status"

**Arrange**: All slicers in a row below the KPI cards

---

### **STEP 7: Format All Rate Fields as Percentages**

1. Go to **Model** view
2. Select **IDIAG Component Summary** table
3. Select `PassRate` field → **Format** → **Percentage** → 2 decimal places
4. Select `FailRate` field → **Format** → **Percentage** → 2 decimal places
5. Select `ErrorRate` field → **Format** → **Percentage** → 2 decimal places
6. Repeat for **IDIAG Component TimeSeries** table (if you create rate measures)

---

### **STEP 8: Enable Cross-Filtering**

1. Go to **Format** → **Edit interactions**
2. Click on each slicer
3. Set all visuals to **Filter** (not None)
4. This makes slicers affect all visuals on the page

---

### **STEP 9: Final Layout Arrangement**

```
┌─────────────────────────────────────────────────────────────┐
│  SLICERS (Machine, Category, Date Range, Reliability)      │
├─────────────────────────────────────────────────────────────┤
│  KPI CARDS (4 cards in a row)                               │
├──────────────────┬──────────────────────────────────────────┤
│                  │                                          │
│  LEFT SIDE:      │  RIGHT SIDE:                            │
│  - Top 10        │  - Failure Trends                       │
│    Problematic   │    (Line Chart)                         │
│  - Heat Map      │  - Time-Based                            │
│    (Matrix)      │    Heat Map                              │
│  - Category      │  - Daily Volume                          │
│    Breakdown     │    vs. Rate                              │
│                  │                                          │
├──────────────────┴──────────────────────────────────────────┤
│  DETAILED TABLE (Full width at bottom)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Tips

✅ **Format all rates as percentages** (Modeling → Format → Percentage)  
✅ **Use conditional formatting** to highlight problems (red = bad)  
✅ **Add tooltips** with `ComponentDescription` for context  
✅ **Enable cross-filtering** so slicers affect all visuals  
✅ **Sort tables** by `FailRate` descending (worst first)  
✅ **Use Top N filters** to focus on most problematic components  

---

## What This Page Shows

- **Top Section**: Key metrics at a glance (KPI cards)
- **Left Side**: Aggregated summary (which components are problematic)
- **Right Side**: Trends over time (are problems getting better/worse?)
- **Bottom**: Detailed table for drill-down analysis

All on one page, using both queries effectively!

