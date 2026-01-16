# IDIAG Component Analysis - DAX Measures for PowerBI

## Overview
These DAX measures work with the `IDIAGFINAL.sql` query data. The query returns both Main Test and Subtest rows, with `RecordType` distinguishing between them.

**Key Fields Available:**
- `SubTestName` - Component test name (NULL for main tests)
- `SubTestResult` - 'PASSED' or 'FAILED' (NULL for main tests)
- `RecordType` - 'Main Test' or 'Subtest'
- `MachineNameNormalized` - 'IDIAGS' or 'MB-RESET'
- `TestDate_CDT` - Test date
- `PassFlag`, `FailFlag` - For main tests

---

## Calculated Columns (Create These First)

### 1. Component Category
```dax
Component Category = 
SWITCH(
    TRUE(),
    'Table'[SubTestName] = BLANK(), "N/A",
    CONTAINSSTRING('Table'[SubTestName], "KEYBOARD") || CONTAINSSTRING('Table'[SubTestName], "KBL"), "Input Device",
    CONTAINSSTRING('Table'[SubTestName], "TOUCHPAD") || CONTAINSSTRING('Table'[SubTestName], "TOUCHSCREEN"), "Input Device",
    CONTAINSSTRING('Table'[SubTestName], "FINGERPRINT") || CONTAINSSTRING('Table'[SubTestName], "CAMERA"), "Input Device",
    CONTAINSSTRING('Table'[SubTestName], "LIDSENSOR") || CONTAINSSTRING('Table'[SubTestName], "PROXIMITY") || CONTAINSSTRING('Table'[SubTestName], "ALS"), "Input Device",
    CONTAINSSTRING('Table'[SubTestName], "ACCELEROMETER") || CONTAINSSTRING('Table'[SubTestName], "GYROMETER"), "Input Device",
    CONTAINSSTRING('Table'[SubTestName], "DISPLAY") || CONTAINSSTRING('Table'[SubTestName], "VIDEO"), "Output Device",
    CONTAINSSTRING('Table'[SubTestName], "SOUND") || CONTAINSSTRING('Table'[SubTestName], "AUDIO"), "Output Device",
    CONTAINSSTRING('Table'[SubTestName], "USB") || CONTAINSSTRING('Table'[SubTestName], "RJ45") || CONTAINSSTRING('Table'[SubTestName], "VIDPORTS"), "Connectivity",
    CONTAINSSTRING('Table'[SubTestName], "BLUETOOTH") || CONTAINSSTRING('Table'[SubTestName], "WLAN") || CONTAINSSTRING('Table'[SubTestName], "NFC"), "Connectivity",
    CONTAINSSTRING('Table'[SubTestName], "SMARTCARD"), "Connectivity",
    CONTAINSSTRING('Table'[SubTestName], "BATTERY") || CONTAINSSTRING('Table'[SubTestName], "CHARGER"), "Power",
    CONTAINSSTRING('Table'[SubTestName], "CPU") || CONTAINSSTRING('Table'[SubTestName], "NPU"), "Processing",
    CONTAINSSTRING('Table'[SubTestName], "MEMORY") || CONTAINSSTRING('Table'[SubTestName], "STORAGE"), "Processing",
    CONTAINSSTRING('Table'[SubTestName], "FAN") || CONTAINSSTRING('Table'[SubTestName], "TPM"), "System Component",
    CONTAINSSTRING('Table'[SubTestName], "PCI") || CONTAINSSTRING('Table'[SubTestName], "MB_"), "System Component",
    CONTAINSSTRING('Table'[SubTestName], "CABLES"), "System Component",
    CONTAINSSTRING('Table'[SubTestName], "0TTT") || CONTAINSSTRING('Table'[SubTestName], "INVENTORY"), "Special/Unknown",
    "Other"
)
```

### 2. Component Description
```dax
Component Description = 
SWITCH(
    'Table'[SubTestName],
    "TEST_STATUS_BATTERY", "Battery health and functionality",
    "TEST_STATUS_BLUETOOTH", "Bluetooth connectivity",
    "TEST_STATUS_CABLES", "Cable connections",
    "TEST_STATUS_CAMERA", "Camera functionality",
    "TEST_STATUS_CHARGER_WATTS", "Charger/power adapter",
    "TEST_STATUS_CPU_PRIME95", "CPU stress test (Prime95)",
    "TEST_STATUS_CPU_STRESS", "CPU stress test",
    "TEST_STATUS_DISPLAY", "Display/screen functionality",
    "TEST_STATUS_FAN", "Cooling fan",
    "TEST_STATUS_FINGERPRINT", "Fingerprint reader",
    "TEST_STATUS_KBL", "Keyboard backlight",
    "TEST_STATUS_KEYBOARD", "Keyboard functionality",
    "TEST_STATUS_LIDSENSOR", "Lid sensor",
    "TEST_STATUS_MEMORY_STRESS", "Memory stress test",
    "TEST_STATUS_NFC", "NFC functionality",
    "TEST_STATUS_NPU_STRESS", "NPU (Neural Processing Unit) stress test",
    "TEST_STATUS_PCI", "PCI component",
    "TEST_STATUS_RJ45", "Ethernet port",
    "TEST_STATUS_SMARTCARD", "Smart card reader",
    "TEST_STATUS_SOUND_OUT", "Audio output",
    "TEST_STATUS_STORAGE_STRESS", "Storage stress test",
    "TEST_STATUS_TOUCHPAD", "Touchpad",
    "TEST_STATUS_TOUCHSCREEN", "Touchscreen",
    "TEST_STATUS_TPM", "Trusted Platform Module",
    "TEST_STATUS_USB", "USB ports",
    "TEST_STATUS_VIDEO_STRESS", "Video stress test",
    "TEST_STATUS_VIDPORTS", "Video ports",
    "TEST_STATUS_WLAN", "Wireless LAN (WiFi)",
    "TEST_STATUS_MB_HW_MSR", "Motherboard hardware MSR",
    "TEST_STATUS_0TTT", "Unknown test (0TTT)",
    "TEST_STATUS_INVENTORY", "Inventory check",
    "TEST_STATUS_PROXIMITY_SENSOR", "Proximity sensor",
    "TEST_STATUS_ALS", "Ambient light sensor",
    "TEST_STATUS_ACCELEROMETER", "Accelerometer",
    "TEST_STATUS_GYROMETER", "Gyrometer",
    "TEST_STATUS_AFX", "AFX component",
    "TEST_STATUS_HEADSET", "Headset functionality",
    "TEST_STATUS_AUDIO_LOOPBACK", "Audio loopback test",
    "TEST_STATUS_SOUND_IN", "Audio input",
    "TEST_STATUS_Overall_FPT_BIOS", "Overall FPT BIOS test",
    BLANK()
)
```

### 3. Subtest Result Numeric (for easier calculations)
```dax
SubTestResultNumeric = 
IF(
    'Table'[RecordType] = "Subtest",
    SWITCH(
        'Table'[SubTestResult],
        "PASSED", 1,
        "FAILED", 0,
        BLANK()
    ),
    BLANK()
)
```

---

## Base Measures (Component Statistics)

### 1. Total Component Tests
```dax
Total Component Tests = 
CALCULATE(
    COUNTROWS('Table'),
    'Table'[RecordType] = "Subtest",
    NOT(ISBLANK('Table'[SubTestName]))
)
```

### 2. Component Pass Count
```dax
Component Pass Count = 
CALCULATE(
    COUNTROWS('Table'),
    'Table'[RecordType] = "Subtest",
    'Table'[SubTestResult] = "PASSED"
)
```

### 3. Component Fail Count
```dax
Component Fail Count = 
CALCULATE(
    COUNTROWS('Table'),
    'Table'[RecordType] = "Subtest",
    'Table'[SubTestResult] = "FAILED"
)
```

### 4. Component Pass Rate
```dax
Component Pass Rate = 
DIVIDE(
    [Component Pass Count],
    [Total Component Tests],
    0
) * 100
```

### 5. Component Fail Rate
```dax
Component Fail Rate = 
DIVIDE(
    [Component Fail Count],
    [Total Component Tests],
    0
) * 100
```

---

## Component-Specific Measures (Filter by SubTestName)

### 6. Component Tests by Name
```dax
Component Tests by Name = 
VAR SelectedComponent = SELECTEDVALUE('Table'[SubTestName])
RETURN
CALCULATE(
    COUNTROWS('Table'),
    'Table'[RecordType] = "Subtest",
    'Table'[SubTestName] = SelectedComponent
)
```

### 7. Component Pass Count by Name
```dax
Component Pass Count by Name = 
VAR SelectedComponent = SELECTEDVALUE('Table'[SubTestName])
RETURN
CALCULATE(
    COUNTROWS('Table'),
    'Table'[RecordType] = "Subtest",
    'Table'[SubTestName] = SelectedComponent,
    'Table'[SubTestResult] = "PASSED"
)
```

### 8. Component Fail Count by Name
```dax
Component Fail Count by Name = 
VAR SelectedComponent = SELECTEDVALUE('Table'[SubTestName])
RETURN
CALCULATE(
    COUNTROWS('Table'),
    'Table'[RecordType] = "Subtest",
    'Table'[SubTestName] = SelectedComponent,
    'Table'[SubTestResult] = "FAILED"
)
```

### 9. Component Pass Rate by Name
```dax
Component Pass Rate by Name = 
DIVIDE(
    [Component Pass Count by Name],
    [Component Tests by Name],
    0
) * 100
```

---

## Ranking Measures

### 10. Component Rank by Occurrences
```dax
Component Rank by Occurrences = 
IF(
    HASONEVALUE('Table'[SubTestName]),
    RANKX(
        ALL('Table'[SubTestName]),
        [Total Component Tests],
        ,
        DESC,
        DENSE
    ),
    BLANK()
)
```

### 11. Component Rank by Failure Rate
```dax
Component Rank by Failure Rate = 
IF(
    HASONEVALUE('Table'[SubTestName]),
    RANKX(
        ALL('Table'[SubTestName]),
        [Component Fail Rate],
        ,
        DESC,
        DENSE
    ),
    BLANK()
)
```

### 12. Component Rank by Pass Rate
```dax
Component Rank by Pass Rate = 
IF(
    HASONEVALUE('Table'[SubTestName]),
    RANKX(
        ALL('Table'[SubTestName]),
        [Component Pass Rate],
        ,
        DESC,
        DENSE
    ),
    BLANK()
)
```

---

## Category Measures (By Component Category)

### 13. Tests by Category
```dax
Tests by Category = 
CALCULATE(
    [Total Component Tests],
    ALL('Table'[SubTestName])
)
```

### 14. Pass Rate by Category
```dax
Pass Rate by Category = 
CALCULATE(
    [Component Pass Rate],
    ALL('Table'[SubTestName])
)
```

### 15. Fail Rate by Category
```dax
Fail Rate by Category = 
CALCULATE(
    [Component Fail Rate],
    ALL('Table'[SubTestName])
)
```

---

## Reliability Flags

### 16. Reliability Category
```dax
Reliability Category = 
VAR FailRate = [Component Fail Rate]
VAR TotalTests = [Total Component Tests]
RETURN
SWITCH(
    TRUE(),
    TotalTests = 0, "No Data",
    [Component Fail Count] = 0 && TotalTests > 100, "Perfect (Zero Failures)",
    FailRate = 100, "Always Fails",
    FailRate >= 50, "High Failure Rate (≥50%)",
    FailRate >= 10, "Moderate Failure Rate (10-50%)",
    FailRate >= 1, "Low Failure Rate (1-10%)",
    FailRate > 0, "Minimal Failures (<1%)",
    "Perfect (No Failures)"
)
```

### 17. Frequency Category
```dax
Frequency Category = 
VAR TotalTests = [Total Component Tests]
RETURN
SWITCH(
    TRUE(),
    TotalTests >= 5000, "Very Common (5000+)",
    TotalTests >= 3000, "Common (3000-5000)",
    TotalTests >= 1000, "Moderate (1000-3000)",
    TotalTests >= 100, "Less Common (100-1000)",
    TotalTests > 0, "Rare (<100)",
    "No Data"
)
```

---

## Time-Based Measures (Trends)

### 18. Daily Component Tests
```dax
Daily Component Tests = 
CALCULATE(
    [Total Component Tests],
    ALL('Table'[TestDate_CDT])
)
```

### 19. Daily Component Pass Rate
```dax
Daily Component Pass Rate = 
CALCULATE(
    [Component Pass Rate],
    ALL('Table'[TestDate_CDT])
)
```

### 20. Component Tests This Week
```dax
Component Tests This Week = 
CALCULATE(
    [Total Component Tests],
    DATESBETWEEN(
        'Table'[TestDate_CDT],
        TODAY() - 7,
        TODAY()
    )
)
```

### 21. Component Tests This Month
```dax
Component Tests This Month = 
CALCULATE(
    [Total Component Tests],
    DATESBETWEEN(
        'Table'[TestDate_CDT],
        EOMONTH(TODAY(), -1) + 1,
        TODAY()
    )
)
```

---

## Machine Type Measures

### 22. Component Tests by Machine
```dax
Component Tests by Machine = 
CALCULATE(
    [Total Component Tests],
    ALL('Table'[MachineNameNormalized])
)
```

### 23. Component Pass Rate by Machine
```dax
Component Pass Rate by Machine = 
CALCULATE(
    [Component Pass Rate],
    ALL('Table'[MachineNameNormalized])
)
```

---

## Top N Measures (For Visualizations)

### 24. Top 10 Components by Occurrences
```dax
Top 10 Components by Occurrences = 
VAR TopComponents = 
    TOPN(
        10,
        ALL('Table'[SubTestName]),
        [Total Component Tests],
        DESC
    )
RETURN
CALCULATE(
    [Total Component Tests],
    TopComponents
)
```

### 25. Top 10 Components by Failure Rate
```dax
Top 10 Components by Failure Rate = 
VAR TopComponents = 
    TOPN(
        10,
        ALL('Table'[SubTestName]),
        [Component Fail Rate],
        DESC
    )
RETURN
CALCULATE(
    [Component Fail Rate],
    TopComponents
)
```

### 26. Top 10 Most Reliable Components
```dax
Top 10 Most Reliable Components = 
VAR TopComponents = 
    TOPN(
        10,
        ALL('Table'[SubTestName]),
        [Component Pass Rate],
        DESC
    )
RETURN
CALCULATE(
    [Component Pass Rate],
    TopComponents
)
```

---

## Usage Instructions

### Step 1: Create Calculated Columns
1. Go to **Modeling** tab → **New Column**
2. Create the three calculated columns listed above:
   - `Component Category`
   - `Component Description`
   - `SubTestResultNumeric`

### Step 2: Create Measures
1. Go to **Modeling** tab → **New Measure**
2. Create all the measures listed above
3. Organize them in a measure folder called "IDIAG Component Analysis"

### Step 3: Create Visualizations

#### Summary Table
- **Visual**: Table
- **Rows**: `SubTestName`
- **Values**: 
  - `Total Component Tests`
  - `Component Pass Count`
  - `Component Fail Count`
  - `Component Pass Rate`
  - `Component Fail Rate`
  - `Reliability Category`
- **Sort by**: `Total Component Tests` (Descending)

#### Top 10 Most Problematic
- **Visual**: Bar Chart
- **Axis**: `SubTestName`
- **Values**: `Component Fail Rate`
- **Filter**: Top 10 by `Component Fail Rate`

#### Top 10 Most Reliable
- **Visual**: Bar Chart
- **Axis**: `SubTestName`
- **Values**: `Component Pass Rate`
- **Filter**: Top 10 by `Component Pass Rate`

#### Component Trends Over Time
- **Visual**: Line Chart
- **Axis**: `TestDate_CDT`
- **Values**: `Daily Component Pass Rate`
- **Legend**: `SubTestName` (or `Component Category`)

#### Component Category Breakdown
- **Visual**: Donut Chart
- **Legend**: `Component Category`
- **Values**: `Tests by Category`

#### Heat Map
- **Visual**: Matrix
- **Rows**: `SubTestName`
- **Columns**: `TestDate_CDT`
- **Values**: `Component Pass Rate`
- **Conditional Formatting**: Color scale (green = high pass rate, red = low pass rate)

---

## Notes

- All measures filter to `RecordType = "Subtest"` to exclude main test rows
- Measures work with slicers on `TestDate_CDT`, `MachineNameNormalized`, `SubTestName`, etc.
- Use `Component Description` column for tooltips
- Use `Component Category` for grouping and filtering
- Rankings update automatically based on current filter context

