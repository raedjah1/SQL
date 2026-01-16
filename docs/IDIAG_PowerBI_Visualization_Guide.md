# IDIAG Component Analysis - PowerBI Visualization Guide

## Best Visualizations for Instant Understanding

---

## 🎯 **PAGE 1: Executive Summary Dashboard**

### 1. **KPI Cards (Top of Page)**
**Visual Type**: Card
**Data Source**: IDIAG Component Summary
**Measures**:
- `Total Component Tests` = SUM(TotalOccurrences)
- `Overall Pass Rate` = AVERAGE(PassRate)
- `Total Failures` = SUM(FailCount)
- `Most Problematic Component` = TOP 1 by FailRate

**Why**: Instant high-level metrics

---

### 2. **Top 10 Most Problematic Components**
**Visual Type**: **Clustered Bar Chart** (Horizontal)
**Data Source**: IDIAG Component Summary
- **Y-Axis**: `ComponentName` (Top 10 by FailRate)
- **X-Axis**: `FailRate` (%)
- **Color**: Red gradient (darker = worse)
- **Tooltip**: `ComponentDescription`, `TotalOccurrences`, `FailCount`
- **Sort**: Descending by FailRate

**Why**: Immediately shows which components fail most often

---

### 3. **Component Failure Heat Map**
**Visual Type**: **Matrix** with Conditional Formatting
**Data Source**: IDIAG Component Summary
- **Rows**: `ComponentName` (Top 20 by FailCount)
- **Values**: `FailRate` (%)
- **Conditional Formatting**: 
  - Color scale: Green (0%) → Yellow (5%) → Red (10%+)
  - Data bars: Show relative failure rates
- **Tooltip**: `ComponentDescription`, `TotalOccurrences`

**Why**: Color-coded matrix makes problem areas obvious

---

### 4. **Component Category Breakdown**
**Visual Type**: **Donut Chart**
**Data Source**: IDIAG Component Summary
- **Legend**: `ComponentCategory`
- **Values**: `TotalOccurrences`
- **Tooltip**: Category name, count, percentage

**Why**: Shows which categories are tested most

---

### 5. **Reliability Distribution**
**Visual Type**: **Stacked Bar Chart** (Horizontal)
**Data Source**: IDIAG Component Summary
- **Axis**: `ComponentCategory`
- **Legend**: `ReliabilityCategory`
- **Values**: `TotalOccurrences`
- **Sort**: By total occurrences (descending)

**Why**: Shows reliability by category at a glance

---

## 📊 **PAGE 2: Component Detail Analysis**

### 6. **Component Performance Table**
**Visual Type**: **Table** with Conditional Formatting
**Data Source**: IDIAG Component Summary
**Columns**:
- `ComponentName` (with tooltip = `ComponentDescription`)
- `ComponentCategory`
- `TotalOccurrences` (Data bars)
- `PassCount` (Green background if > 95%)
- `FailCount` (Red background if > 0)
- `PassRate` (Color scale: Red < 95%, Yellow 95-99%, Green ≥ 99%)
- `FailRate` (Color scale: Green = 0%, Yellow < 5%, Red ≥ 5%)
- `ReliabilityCategory` (Icons: ✅ Perfect, ⚠️ Moderate, ❌ High Failure)

**Sort**: By `FailRate` (Descending) - worst first
**Filter**: Show all or Top 50

**Why**: Comprehensive view with color coding for instant problem identification

---

### 7. **Component Comparison Scatter Plot**
**Visual Type**: **Scatter Chart**
**Data Source**: IDIAG Component Summary
- **X-Axis**: `TotalOccurrences` (log scale)
- **Y-Axis**: `FailRate` (%)
- **Size**: `FailCount` (bigger bubble = more failures)
- **Color**: `ComponentCategory`
- **Tooltip**: `ComponentName`, `ComponentDescription`, `TotalOccurrences`, `FailCount`, `FailRate`

**Why**: Shows volume vs. failure rate - components in top-right are most problematic

---

### 8. **Perfect vs. Problematic Components**
**Visual Type**: **Two Column Charts Side-by-Side**
**Left Chart**: "Perfect Components (Zero Failures)"
- **Visual Type**: Bar Chart
- **Data Source**: IDIAG Component Summary
- **Filter**: `FailCount = 0` AND `TotalOccurrences > 100`
- **Axis**: `ComponentName`
- **Values**: `TotalOccurrences`
- **Sort**: Descending

**Right Chart**: "Most Problematic Components"
- **Visual Type**: Bar Chart
- **Data Source**: IDIAG Component Summary
- **Filter**: `FailRate >= 1%` OR `FailCount > 50`
- **Axis**: `ComponentName`
- **Values**: `FailRate`
- **Sort**: Descending

**Why**: Side-by-side comparison highlights both good and bad

---

## 📈 **PAGE 3: Trend Analysis**

### 9. **Component Failure Trends Over Time**
**Visual Type**: **Line Chart** (Multi-line)
**Data Source**: IDIAG Component TimeSeries
- **Axis**: `TestDate` (grouped by Week or Month)
- **Values**: Create measure: `Daily Fail Rate = DIVIDE(SUM(FailCount), SUM(TestCount), 0) * 100`
- **Legend**: `ComponentName` (Top 10 by total failures)
- **Slicer**: `ComponentName` (multi-select)
- **Tooltip**: Date, Component, Test Count, Fail Count, Fail Rate

**Why**: Shows if problems are getting better or worse over time

---

### 10. **Component Failure Heat Map (Time-Based)**
**Visual Type**: **Matrix** with Conditional Formatting
**Data Source**: IDIAG Component TimeSeries
- **Rows**: `ComponentName` (Top 20 by total failures)
- **Columns**: `TestDate` (grouped by Week)
- **Values**: Create measure: `Fail Rate = DIVIDE(SUM(FailCount), SUM(TestCount), 0) * 100`
- **Conditional Formatting**: 
  - Color scale: Green (0%) → Yellow (5%) → Red (10%+)
  - Show data bars
- **Tooltip**: Date, Component, Test Count, Fail Count

**Why**: Shows failure patterns over time - dark red cells = problem periods

---

### 11. **Daily Test Volume vs. Failure Rate**
**Visual Type**: **Combo Chart** (Column + Line)
**Data Source**: IDIAG Component TimeSeries
- **X-Axis**: `TestDate` (grouped by Day)
- **Column Values**: `TestCount` (Total tests per day)
- **Line Values**: Create measure: `Daily Fail Rate = DIVIDE(SUM(FailCount), SUM(TestCount), 0) * 100`
- **Slicer**: `ComponentName` (single select for specific component)

**Why**: Shows if failure rate correlates with test volume

---

## 🔍 **PAGE 4: Machine Comparison**

### 12. **IDIAGS vs. MB-RESET Comparison**
**Visual Type**: **Clustered Column Chart**
**Data Source**: IDIAG Component Summary
- **Axis**: `ComponentName` (Top 15 by total occurrences)
- **Legend**: `MachineNameNormalized` (IDIAGS vs. MB-RESET)
- **Values**: `FailRate` (%)
- **Tooltip**: Machine, Component, Test Count, Fail Rate

**Why**: Shows which machine type has more problems per component

---

### 13. **Machine Performance by Category**
**Visual Type**: **100% Stacked Bar Chart**
**Data Source**: IDIAG Component Summary
- **Axis**: `ComponentCategory`
- **Legend**: `MachineNameNormalized`
- **Values**: `TotalOccurrences`
- **Tooltip**: Category, Machine, Count, Percentage

**Why**: Shows test distribution by machine type and category

---

## 🎨 **Visualization Best Practices**

### Color Coding Standards
- **Green**: Good (Pass Rate ≥ 99%, Fail Rate = 0%)
- **Yellow**: Warning (Pass Rate 95-99%, Fail Rate 1-5%)
- **Red**: Problem (Pass Rate < 95%, Fail Rate > 5%)
- **Dark Red**: Critical (Fail Rate > 10%)

### Icons to Use
- ✅ Perfect/Zero Failures
- ⚠️ Moderate Issues
- ❌ High Failure Rate
- 📊 Needs Attention

### Tooltip Best Practices
Always include in tooltips:
- Component name
- Component description
- Total occurrences
- Pass/Fail counts
- Pass/Fail rates
- Date (if time-based)

---

## 📋 **Recommended Dashboard Layout**

### **Page 1: Executive Summary** (Landing Page)
1. KPI Cards (4 cards across top)
2. Top 10 Most Problematic (Large bar chart)
3. Component Failure Heat Map (Matrix)
4. Component Category Breakdown (Donut chart)
5. Reliability Distribution (Stacked bar)

### **Page 2: Component Details**
1. Component Performance Table (Full width)
2. Component Comparison Scatter Plot
3. Perfect vs. Problematic (Side-by-side)

### **Page 3: Trends**
1. Component Failure Trends (Line chart - full width)
2. Component Failure Heat Map Time-Based (Matrix - full width)
3. Daily Test Volume vs. Failure Rate (Combo chart)

### **Page 4: Machine Comparison**
1. IDIAGS vs. MB-RESET Comparison (Column chart)
2. Machine Performance by Category (Stacked bar)

---

## 🎯 **Key Visualizations for Instant Problem Identification**

### **#1 Priority: Top 10 Most Problematic Components**
- **Why**: Immediately shows what's broken
- **Visual**: Horizontal bar chart
- **Color**: Red gradient
- **Placement**: Top of dashboard

### **#2 Priority: Component Failure Heat Map**
- **Why**: Color-coded matrix makes problems obvious
- **Visual**: Matrix with conditional formatting
- **Color**: Green → Yellow → Red
- **Placement**: Center of dashboard

### **#3 Priority: Component Performance Table**
- **Why**: Comprehensive view with all details
- **Visual**: Table with conditional formatting
- **Sort**: Worst failures first
- **Placement**: Full page for detailed analysis

### **#4 Priority: Failure Trends Over Time**
- **Why**: Shows if problems are getting better/worse
- **Visual**: Multi-line chart
- **Focus**: Top 10 problematic components
- **Placement**: Trend analysis page

---

## 💡 **Pro Tips**

1. **Use Slicers**: Add slicers for Date Range, Component Category, Machine Type
2. **Cross-filtering**: Enable cross-filtering so clicking one visual filters others
3. **Bookmarks**: Create bookmarks for common views (e.g., "Show Only Failures")
4. **Drill-through**: Set up drill-through from summary to detail pages
5. **Mobile Layout**: Create mobile-optimized layout for on-the-go viewing
6. **Export**: Add export buttons for reports
7. **Alerts**: Set up alerts for components with Fail Rate > 10%

---

## 🚨 **Alert Thresholds**

Create measures for alerts:
- **Critical**: Fail Rate > 10%
- **Warning**: Fail Rate > 5%
- **Info**: Fail Rate > 1%

Use these in conditional formatting and KPI cards.

