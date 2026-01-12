# IDIAG Data Source Documentation

## Overview
This document provides information about the IDIAG data source tables and available columns for querying IDIAG test results.

---

## Data Source Tables

### Primary Tables
- **`[redw].[tia].[DataWipeResult]`** - Main test result records
- **`[redw].[tia].[SubTestLogs]`** - Individual subtest details (linked via MainTestID = DataWipeResult.ID)

---

## DataWipeResult Table Structure

### Table: `[redw].[tia].[DataWipeResult]`

| Column Name | Data Type | Max Length | Precision | Scale | Is Nullable | Default | Position |
|------------|-----------|------------|-----------|-------|-------------|---------|----------|
| ID | int | NULL | 10 | 0 | NO | NULL | 1 |
| SerialNumber | varchar | 8000 | NULL | NULL | YES | NULL | 2 |
| PartNumber | varchar | 8000 | NULL | NULL | YES | NULL | 3 |
| StartTime | datetime2 | NULL | NULL | NULL | NO | NULL | 4 |
| EndTime | datetime2 | NULL | NULL | NULL | NO | NULL | 5 |
| MachineName | varchar | 8000 | NULL | NULL | YES | NULL | 6 |
| Result | varchar | 8000 | NULL | NULL | YES | NULL | 7 |
| TestArea | varchar | 8000 | NULL | NULL | YES | NULL | 8 |
| CellNumber | varchar | 8000 | NULL | NULL | YES | NULL | 9 |
| Program | varchar | 8000 | NULL | NULL | YES | NULL | 10 |
| MiscInfo | varchar | 8000 | NULL | NULL | YES | NULL | 11 |
| MACAddress | varchar | 8000 | NULL | NULL | YES | NULL | 12 |
| Msg | varchar | 8000 | NULL | NULL | YES | NULL | 13 |
| AsOf | datetime2 | NULL | NULL | NULL | NO | NULL | 14 |
| Exported | bit | NULL | NULL | NULL | NO | NULL | 15 |
| LastModifiedBy | varchar | 8000 | NULL | NULL | YES | NULL | 16 |
| LastModifiedOn | datetime2 | NULL | NULL | NULL | YES | NULL | 17 |
| Username | varchar | 8000 | NULL | NULL | YES | NULL | 18 |
| OrderNumber | varchar | 8000 | NULL | NULL | YES | NULL | 19 |
| UploadTime | datetime2 | NULL | NULL | NULL | YES | NULL | 20 |
| Contract | varchar | 8000 | NULL | NULL | YES | NULL | 21 |
| FileReference | varchar | 8000 | NULL | NULL | YES | NULL | 22 |
| FailureReference | varchar | 8000 | NULL | NULL | YES | NULL | 23 |
| FailureNumber | varchar | 8000 | NULL | NULL | YES | NULL | 24 |
| ErrItem | varchar | 8000 | NULL | NULL | YES | NULL | 25 |
| TestAreaOrig | varchar | 8000 | NULL | NULL | YES | NULL | 26 |
| BatteryHealthGrade | varchar | 8000 | NULL | NULL | YES | NULL | 27 |
| LogFileStatus | varchar | 8000 | NULL | NULL | YES | NULL | 28 |

### Key Fields for IDIAG

#### Always Populated & Useful Fields:
- **ID** - Primary key, used to link to SubTestLogs
- **SerialNumber** - Serial number of the unit being tested (100% populated)
- **StartTime** - When the test started (always present)
- **EndTime** - When the test completed (always present)
- **MachineName** - Test machine name (use 'IDIAGS' for IDIAG tests)
- **Result** - Main test result (PASS/FAIL) - Values: PASS (3049), FAIL (1686)
- **TestArea** - Test area (use 'MEMPHIS' for IDIAG tests)
- **Program** - Program identifier (Value: 'DELL_MEM')
- **Contract** - Contract number (Value: '10053')
- **AsOf** - Timestamp when record was created
- **Exported** - Export flag (bit field)
- **LastModifiedBy** - User who last modified (Value: 'usengprod_funapp')
- **LastModifiedOn** - Last modification timestamp
- **UploadTime** - When test was uploaded

#### Fields Present But Typically Empty:
- **PartNumber** - Part number (technically populated but often empty string)
- **MiscInfo** - Additional test information (often empty)
- **MACAddress** - MAC address of the device (often empty)
- **Msg** - Message field (often empty)
- **FileReference** - File reference (often empty)
- **FailureReference** - Failure reference (often empty)
- **FailureNumber** - Failure number (often empty)
- **ErrItem** - Error item (often empty)
- **BatteryHealthGrade** - Battery health assessment (NULL or empty)
- **LogFileStatus** - Status of the log file (NULL)
- **CellNumber** - Cell number (often empty)
- **Username** - Username (often empty)
- **OrderNumber** - Order number (often empty)
- **TestAreaOrig** - Original test area (often empty)

### Data Statistics (Based on Exploration)
- **Total Records**: 4,735 IDIAG test records
- **Result Distribution**: 
  - PASS: 3,049 records (64.4%)
  - FAIL: 1,686 records (35.6%)
- **Date Range**: October 13, 2025 to January 7, 2026
- **All records have**: SerialNumber, StartTime, EndTime, Result, MachineName, TestArea, Program, Contract

---

## Exploration Queries

### Query 1: Explore DataWipeResult Table Structure
```sql
-- Get detailed column information
SELECT 
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    c.NUMERIC_PRECISION AS Precision,
    c.NUMERIC_SCALE AS Scale,
    c.IS_NULLABLE,
    c.COLUMN_DEFAULT,
    c.ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_SCHEMA = 'tia'
    AND c.TABLE_NAME = 'DataWipeResult'
ORDER BY c.ORDINAL_POSITION;
```

### Query 2: Sample IDIAG Records with All Columns
```sql
-- See sample data with all available columns
SELECT TOP 10
    dwr.*
FROM [redw].[tia].[DataWipeResult] AS dwr
WHERE dwr.MachineName = 'IDIAGS'
    AND dwr.TestArea = 'MEMPHIS'
ORDER BY dwr.ID DESC;
```

### Query 3: Explore Distinct Values for Key Fields
```sql
-- See what values exist in key fields
SELECT 
    'Program' AS FieldName,
    Program AS FieldValue,
    COUNT(*) AS Count
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS'
GROUP BY Program

UNION ALL

SELECT 
    'Result',
    Result,
    COUNT(*)
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS'
GROUP BY Result

UNION ALL

SELECT 
    'BatteryHealthGrade',
    BatteryHealthGrade,
    COUNT(*)
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS'
GROUP BY BatteryHealthGrade

UNION ALL

SELECT 
    'LogFileStatus',
    LogFileStatus,
    COUNT(*)
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS'
GROUP BY LogFileStatus

ORDER BY FieldName, Count DESC;
```

### Query 4: Date Range and Volume Analysis
```sql
-- Understand the data volume and date ranges
SELECT 
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT SerialNumber) AS UniqueSerialNumbers,
    COUNT(DISTINCT PartNumber) AS UniquePartNumbers,
    MIN(StartTime) AS EarliestTest,
    MAX(StartTime) AS LatestTest,
    MIN(EndTime) AS EarliestEndTime,
    MAX(EndTime) AS LatestEndTime,
    AVG(DATEDIFF(SECOND, StartTime, EndTime)) AS AvgTestDurationSeconds
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS';
```

### Query 5: Explore Additional Fields (MiscInfo, Msg, etc.)
```sql
-- See what's in the MiscInfo, Msg, and other text fields
SELECT TOP 20
    SerialNumber,
    Result,
    MiscInfo,
    Msg,
    FileReference,
    FailureReference,
    FailureNumber,
    ErrItem,
    BatteryHealthGrade,
    LogFileStatus
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS'
    AND (
        MiscInfo IS NOT NULL 
        OR Msg IS NOT NULL 
        OR FileReference IS NOT NULL
        OR FailureReference IS NOT NULL
        OR BatteryHealthGrade IS NOT NULL
    )
ORDER BY ID DESC;
```

### Query 6: Complete IDIAG Record with All Fields
```sql
-- Get a complete record showing all available data
SELECT TOP 1
    dwr.*,
    COUNT(stl.ID) AS SubTestCount
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.MachineName = 'IDIAGS'
    AND dwr.TestArea = 'MEMPHIS'
GROUP BY 
    dwr.ID,
    dwr.SerialNumber,
    dwr.PartNumber,
    dwr.StartTime,
    dwr.EndTime,
    dwr.MachineName,
    dwr.Result,
    dwr.TestArea,
    dwr.CellNumber,
    dwr.Program,
    dwr.MiscInfo,
    dwr.MACAddress,
    dwr.Msg,
    dwr.AsOf,
    dwr.Exported,
    dwr.LastModifiedBy,
    dwr.LastModifiedOn,
    dwr.Username,
    dwr.OrderNumber,
    dwr.UploadTime,
    dwr.Contract,
    dwr.FileReference,
    dwr.FailureReference,
    dwr.FailureNumber,
    dwr.ErrItem,
    dwr.TestAreaOrig,
    dwr.BatteryHealthGrade,
    dwr.LogFileStatus
ORDER BY dwr.ID DESC;
```

### Query 7: Check for NULL Patterns
```sql
-- See which fields are commonly populated vs NULL
SELECT 
    'SerialNumber' AS FieldName,
    SUM(CASE WHEN SerialNumber IS NULL THEN 1 ELSE 0 END) AS NullCount,
    SUM(CASE WHEN SerialNumber IS NOT NULL THEN 1 ELSE 0 END) AS NotNullCount
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS'

UNION ALL

SELECT 
    'PartNumber',
    SUM(CASE WHEN PartNumber IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN PartNumber IS NOT NULL THEN 1 ELSE 0 END)
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS'

UNION ALL

SELECT 
    'MiscInfo',
    SUM(CASE WHEN MiscInfo IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN MiscInfo IS NOT NULL THEN 1 ELSE 0 END)
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS'

UNION ALL

SELECT 
    'BatteryHealthGrade',
    SUM(CASE WHEN BatteryHealthGrade IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN BatteryHealthGrade IS NOT NULL THEN 1 ELSE 0 END)
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS'

UNION ALL

SELECT 
    'MACAddress',
    SUM(CASE WHEN MACAddress IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN MACAddress IS NOT NULL THEN 1 ELSE 0 END)
FROM [redw].[tia].[DataWipeResult]
WHERE MachineName = 'IDIAGS'
    AND TestArea = 'MEMPHIS';
```

---

## Related Files
- `queries/idiag.sql` - Main IDIAG query
- `IDIAG_Test_Result_Requirements.md` - Requirements document

---

## Notes
- **MachineName** = 'IDIAGS' for IDIAG tests
- **TestArea** = 'MEMPHIS' for IDIAG tests
- Always use the latest test result: `WHERE dwr.ID = (SELECT MAX(ID) FROM ... WHERE SerialNumber = @SerialNumber)`
- Link to SubTestLogs using: `stl.MainTestID = dwr.ID`

