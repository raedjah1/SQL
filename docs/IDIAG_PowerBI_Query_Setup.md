# IDIAG Component Analysis - PowerBI Query Setup Guide

## Overview
Use **2 optimized SQL queries** (no WITH clauses) instead of DAX measures for better performance. These queries are pre-aggregated and optimized for PowerBI DirectQuery.

---

## Query 1: Time-Series Data
**File**: `queries/IDIAG_Component_TimeSeries_PowerBI.sql`

**Purpose**: Daily component statistics for trend analysis

**Returns**:
- `TestDate` - Date of test
- `MachineNameNormalized` - IDIAGS or MB-RESET
- `ComponentName` - Subtest name
- `MainTestResult` - PASS or FAIL
- `SubTestResult` - PASSED or FAILED
- `TestCount` - Number of tests
- `PassCount` - Number of passes
- `FailCount` - Number of failures
- `ErrorCount` - Alias for FailCount (for clarity)
- `HasErrors` - Flag: 1 = has errors, 0 = no errors (useful for filtering)

**Use For**:
- Line charts showing trends over time
- Heat maps (Component × Date)
- Daily breakdowns
- Time-based filtering

---

## Query 2: Summary Statistics
**File**: `queries/IDIAG_Component_Summary_PowerBI.sql`

**Purpose**: All-time aggregated component statistics

**Returns**:
- `MachineNameNormalized` - IDIAGS or MB-RESET
- `ComponentName` - Subtest name
- `TotalOccurrences` - Total number of tests
- `PassCount` - Total passes
- `FailCount` - Total failures
- `ErrorCount` - Alias for FailCount (for clarity)
- `HasErrors` - Flag: 1 = has errors, 0 = no errors (useful for filtering)
- `PassRate` - Pass rate as decimal (0.0 to 1.0) - PowerBI will format as percentage
- `FailRate` - Failure rate as decimal (0.0 to 1.0) - PowerBI will format as percentage
- `ErrorRate` - Alias for FailRate (for clarity)
- `ComponentCategory` - Pre-calculated category (Input Device, Output Device, etc.)
- `ComponentDescription` - Human-readable description
- `ReliabilityCategory` - Pre-calculated reliability flag
- `FrequencyCategory` - Pre-calculated frequency flag

**Use For**:
- Summary tables
- Top N visualizations
- Component comparison charts
- Summary cards
- Category breakdowns

---

## PowerBI Setup Instructions

### Step 1: Import Both Queries

1. Open PowerBI Desktop
2. **Get Data** → **SQL Server** (or your database)
3. **Import** or **DirectQuery** (recommend DirectQuery for live data)
4. Paste Query 1: `IDIAG_Component_TimeSeries_PowerBI.sql`
   - Name it: **"IDIAG Component TimeSeries"**
5. Repeat for Query 2: `IDIAG_Component_Summary_PowerBI.sql`
   - Name it: **"IDIAG Component Summary"**

### Step 2: Create Relationships (Optional)

If you want to link the two queries:
- **Relationship**: `ComponentName` in both tables
- **Cardinality**: Many-to-Many (or One-to-Many if you prefer)
- **Cross filter direction**: Both (or Single based on your needs)

---

## Visualization Examples

### 1. Summary Table (Use Query 2)
- **Visual**: Table
- **Data Source**: IDIAG Component Summary
- **Rows**: `ComponentName`
- **Values**: 
  - `TotalOccurrences`
  - `PassCount`
  - `FailCount` (or `ErrorCount`)
  - `PassRate`
  - `FailRate` (or `ErrorRate`)
  - `HasErrors` (for filtering/conditional formatting)
  - `ReliabilityCategory`
- **Sort by**: `TotalOccurrences` (Descending)

### 2. Top 10 Most Problematic (Use Query 2)
- **Visual**: Bar Chart
- **Data Source**: IDIAG Component Summary
- **Axis**: `ComponentName`
- **Values**: `FailRate` (or `ErrorRate` or `ErrorCount` for actual numbers)
- **Filter**: Top 10 by `FailRate`
- **Tooltip**: `ComponentDescription`

### 3. Top 10 Most Reliable (Use Query 2)
- **Visual**: Bar Chart
- **Data Source**: IDIAG Component Summary
- **Axis**: `ComponentName`
- **Values**: `PassRate` (or `PassCount` for actual numbers)
- **Filter**: Top 10 by `PassRate`
- **Tooltip**: `ComponentDescription`

### 4. Component Trends Over Time (Use Query 1)
- **Visual**: Line Chart
- **Data Source**: IDIAG Component TimeSeries
- **Axis**: `TestDate`
- **Values**: `PassCount` / `TestCount` (create measure: `PassRate = DIVIDE(SUM(PassCount), SUM(TestCount))`)
- **Legend**: `ComponentName` (or filter to specific component)
- **Slicer**: `ComponentName` (multi-select)

### 5. Component Category Breakdown (Use Query 2)
- **Visual**: Donut Chart
- **Data Source**: IDIAG Component Summary
- **Legend**: `ComponentCategory`
- **Values**: `TotalOccurrences`
- **Tooltip**: `ComponentDescription`

### 6. Heat Map (Use Query 1)
- **Visual**: Matrix
- **Data Source**: IDIAG Component TimeSeries
- **Rows**: `ComponentName`
- **Columns**: `TestDate` (grouped by week/month)
- **Values**: Create measure: `PassRate = DIVIDE(SUM(PassCount), SUM(TestCount), 0)`
- **Format**: Set to Percentage in PowerBI (Format → Percentage)
- **Conditional Formatting**: Color scale (green = high pass rate, red = low pass rate)

### 7. Component Comparison (Use Query 2)
- **Visual**: Scatter Chart
- **Data Source**: IDIAG Component Summary
- **X-Axis**: `TotalOccurrences`
- **Y-Axis**: `FailRate`
- **Size**: `FailCount`
- **Legend**: `ComponentCategory`
- **Tooltip**: `ComponentName`, `ComponentDescription`

### 8. Reliability Distribution (Use Query 2)
- **Visual**: Stacked Bar Chart
- **Data Source**: IDIAG Component Summary
- **Axis**: `ComponentCategory`
- **Legend**: `ReliabilityCategory`
- **Values**: `TotalOccurrences`

---

## Important: Formatting Rates as Percentages

**Both queries return rates as decimals (0.0 to 1.0), not percentages.**

To display as percentages in PowerBI:
1. Select the field (e.g., `PassRate` or `FailRate`)
2. Go to **Modeling** tab → **Format**
3. Select **Percentage** format
4. Choose decimal places (e.g., 2 decimal places = 99.50%)

**Example**: 
- Value in database: `0.9950` (decimal)
- Displayed in PowerBI: `99.50%` (percentage)

This is the standard PowerBI approach and allows for proper formatting and calculations.

---

## Simple Measures (If Needed)

If you need additional calculations, create these simple measures:

### Pass Rate (for Query 1)
```dax
Pass Rate = DIVIDE(SUM('IDIAG Component TimeSeries'[PassCount]), SUM('IDIAG Component TimeSeries'[TestCount]), 0)
```
**Note**: Returns decimal (0.0 to 1.0). Format as percentage in PowerBI (Format → Percentage).

### Fail Rate (for Query 1)
```dax
Fail Rate = DIVIDE(SUM('IDIAG Component TimeSeries'[FailCount]), SUM('IDIAG Component TimeSeries'[TestCount]), 0)
```
**Note**: Returns decimal (0.0 to 1.0). Format as percentage in PowerBI (Format → Percentage).

### Total Tests (for Query 1)
```dax
Total Tests = SUM('IDIAG Component TimeSeries'[TestCount])
```

---

## Performance Tips

1. **Use DirectQuery** for live data (updates automatically)
2. **Use Import** if you need better performance and can refresh periodically
3. **Filter early**: Add date filters in PowerBI slicers to reduce data volume
4. **Index suggestions** (for database admin):
   - `DataWipeResult`: (Contract, TestArea, MachineName, EndTime) INCLUDE (Result, ID)
   - `SubTestLogs`: (MainTestID) INCLUDE (TestName, Result)

---

## Advantages Over DAX Measures

✅ **Pre-aggregated**: Calculations done in SQL (faster)  
✅ **Simpler**: No complex DAX formulas  
✅ **Better performance**: SQL Server does the heavy lifting  
✅ **Easier to maintain**: All logic in SQL queries  
✅ **DirectQuery friendly**: Works with DirectQuery mode  
✅ **No WITH clauses**: Compatible with PowerBI DirectQuery  

---

## When to Use Each Query

| Use Case | Query to Use |
|----------|-------------|
| Summary tables | Query 2 (Summary) |
| Top N lists | Query 2 (Summary) |
| Category breakdowns | Query 2 (Summary) |
| Trends over time | Query 1 (TimeSeries) |
| Daily/weekly analysis | Query 1 (TimeSeries) |
| Heat maps | Query 1 (TimeSeries) |
| Component comparison | Query 2 (Summary) |
| Reliability analysis | Query 2 (Summary) |

---

## Next Steps

1. Import both queries into PowerBI
2. Create relationships if needed
3. Build visualizations using the examples above
4. Add slicers for filtering (Date, Component, Machine Type, etc.)
5. Create a dashboard with multiple pages

