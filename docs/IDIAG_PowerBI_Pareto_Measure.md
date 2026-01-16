# IDIAG Component Analysis - Pareto Chart DAX Measure

## Cumulative Fail Percentage Measure

```dax
Cumulative Fail % = 
VAR CurrentComponent = SELECTEDVALUE('IDIAG Component Summary'[ComponentName])
VAR CurrentFailCount = SUM('IDIAG Component Summary'[FailCount])
VAR TotalFails = 
    CALCULATE(
        SUM('IDIAG Component Summary'[FailCount]),
        ALLSELECTED('IDIAG Component Summary'[ComponentName])
    )
VAR CumulativeFails = 
    CALCULATE(
        SUM('IDIAG Component Summary'[FailCount]),
        ALLSELECTED('IDIAG Component Summary'[ComponentName]),
        FILTER(
            ALLSELECTED('IDIAG Component Summary'[ComponentName]),
            SUM('IDIAG Component Summary'[FailCount]) >= CurrentFailCount
        )
    )
RETURN
    DIVIDE(CumulativeFails, TotalFails, 0)
```

## Alternative: Simpler Version (Based on FailCount)

```dax
Cumulative Fail % = 
VAR TotalFails = 
    CALCULATE(
        SUM('IDIAG Component Summary'[FailCount]),
        ALLSELECTED('IDIAG Component Summary'[ComponentName])
    )
VAR CumulativeFails = 
    CALCULATE(
        SUM('IDIAG Component Summary'[FailCount]),
        ALLSELECTED('IDIAG Component Summary'[ComponentName]),
        FILTER(
            ALLSELECTED('IDIAG Component Summary'[ComponentName]),
            SUM('IDIAG Component Summary'[FailCount]) >= 
            SUM('IDIAG Component Summary'[FailCount])
        )
    )
RETURN
    DIVIDE(CumulativeFails, TotalFails, 0) * 100
```

## Even Simpler: Use Built-in Pareto Visual

**PowerBI has a built-in Pareto chart visual!**

1. **Insert** → **Visualizations** → **Pareto chart**
2. **Category**: `ComponentName`
3. **Measure**: `FailCount` (or `ErrorCount`)
4. **Format** → **Percentage**: On
5. **Filter**: Top 10 by `FailCount`

This is the easiest way - no custom measures needed!

