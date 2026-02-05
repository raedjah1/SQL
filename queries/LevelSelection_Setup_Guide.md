# Power BI Level Selection Toggle Setup

## Step 1: Create the Parameter Table

1. In Power BI Desktop, go to **Modeling** tab
2. Click **New Table**
3. Paste this DAX code:

```DAX
LevelSelection = 
DATATABLE(
    "Level", STRING,
    "ColumnName", STRING,
    {
        {"High Level", "High_Level"},
        {"Mid Level", "Mid_Level"},
        {"Low Level", "W_Level"}
    }
)
```

4. Press Enter to create the table

## Step 2: Create the Measure

1. Go to **Modeling** tab
2. Click **New Measure**
3. Name it: `Selected Level Count`
4. Paste this DAX (replace `'YourTableName'` with your actual table name):

```DAX
Selected Level Count = 
VAR SelectedColumn = SELECTEDVALUE(LevelSelection[ColumnName])
RETURN
    SWITCH(
        SelectedColumn,
        "High_Level", 
            CALCULATE(
                COUNTROWS('YourTableName'),
                ALLEXCEPT('YourTableName', 'YourTableName'[High_Level])
            ),
        "Mid_Level",
            CALCULATE(
                COUNTROWS('YourTableName'),
                ALLEXCEPT('YourTableName', 'YourTableName'[Mid_Level])
            ),
        "W_Level",
            CALCULATE(
                COUNTROWS('YourTableName'),
                ALLEXCEPT('YourTableName', 'YourTableName'[W_Level])
            ),
        COUNTROWS('YourTableName')
    )
```

## Step 3: Set Up Your Bar Chart

1. **Add a Slicer:**
   - Insert → Slicer
   - Drag `LevelSelection[Level]` to the slicer
   - Format it as a dropdown or buttons

2. **Configure Your Bar Chart:**
   - X-axis: Use the measure `Selected Level Count` OR use a calculated column based on selection
   - Y-axis: Your count/measure
   - OR use the selected level column directly on the axis

## Alternative: Direct Column Selection

If you want to use the actual level values on the axis (not counts), create this measure:

```DAX
Selected Level = 
VAR SelectedColumn = SELECTEDVALUE(LevelSelection[ColumnName])
RETURN
    SWITCH(
        SelectedColumn,
        "High_Level", SELECTEDVALUE('YourTableName'[High_Level]),
        "Mid_Level", SELECTEDVALUE('YourTableName'[Mid_Level]),
        "W_Level", SELECTEDVALUE('YourTableName'[W_Level]),
        SELECTEDVALUE('YourTableName'[High_Level])
    )
```

Then use `Selected Level` as the axis in your bar chart.

## Notes

- Replace `'YourTableName'` with your actual table name (likely something like `partserialwithout` or similar)
- The slicer will show: "High Level", "Mid Level", "Low Level"
- When you select one, the chart will automatically switch to show that level



