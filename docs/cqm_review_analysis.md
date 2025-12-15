# CQM Review Query Analysis

## Query Purpose
The `rpt.CQMReview` view creates a quality control report for the DELL program (ProgramID = 10053) that combines:
1. **CQM (Customer Quality Management) Review** data from part serial attributes
2. **Test Results** from the DataWipeResult table (FICORE and SPECTRUMX testing)
3. **Received Date** from PartTransaction records

## Query Structure Analysis

### 1. **BaseData CTE** - Core Quality Data
```sql
FROM Plus.pls.PartSerial AS ps
JOIN Plus.pls.PartSerialAttribute AS oba ON oba.AttributeID = 1395
```
**Purpose**: Gets CQM review records filtered by AttributeID = 1395

**⚠️ Potential Issues:**
- **AttributeID 1395 vs 1394**: The comment says "swap if your CQM attribute is 1394" - need to verify which is correct
- **Hard-coded ProgramID = 10053**: This is correct for DELL Memphis program based on your memories
- Uses `oba.CreateDate` as CQMDate - makes sense

### 2. **AllTestResults CTE** - Testing Data
```sql
FROM redw.tia.DataWipeResult AS d
WHERE d.Program = 'DELL_MEM'
```
**Purpose**: Gets all data wipe results for DELL_MEM program

**⚠️ Potential Issues:**
- Filters by `Program = 'DELL_MEM'` - need to verify this is the correct program name in your database
- Joins with BaseData on SerialNumber - this should work if serial numbers match

### 3. **RankedResults CTE** - Most Recent Tests
```sql
ROW_NUMBER() OVER (
    PARTITION BY SerialNumber, TestArea, MachineName
    ORDER BY StartTime DESC, ID DESC
) AS RowNum
```
**Purpose**: Gets the most recent test result for each unique combination of serial, test area, and machine

**✅ This logic looks correct** - it properly ranks results and filters to RowNum = 1 later

### 4. **Final SELECT** - Combining Data

#### LEFT JOINs Strategy:
```sql
LEFT JOIN RankedResults AS ficMem  ON ... AND ficMem.RowNum = 1
LEFT JOIN RankedResults AS ficCore ON ... AND ficCore.RowNum = 1
LEFT JOIN RankedResults AS spc     ON ... AND spc.RowNum = 1
```

**⚠️ Potential Issues:**

1. **COALESCE Logic**:
   ```sql
   COALESCE(ficMem.Result, ficCore.Result) AS [Ficore Results]
   ```
   - This tries FICORE results from MEMPHIS test area first, then FICORE test area
   - Logic seems reasonable but depends on your testing structure

2. **TestArea and MachineName Filtering**:
   - Filters for `TestArea = 'MEMPHIS'` and `TestArea = 'FICORE'`
   - Uses `COLLATE Latin1_General_100_CI_AS` - suggests case-sensitivity issues might exist

3. **ReceivedDate OUTER APPLY**:
   ```sql
   WHERE rec.PartTransactionID IN (1, 47)
   ```
   - According to your codebase, PartTransactionID 1 = "RO-Receive" (repair order receiving)
   - PartTransactionID 47 = Unknown - need to verify what this represents

## Accuracy Assessment

### ✅ **What Looks Correct:**
1. Program filter (10053 = DELL Memphis) ✓
2. Ranking logic for most recent tests ✓
3. User attribution for CQM auditor ✓
4. Pass/Fail logic (CASE WHEN Value = 'PASS') ✓
5. NULL handling for warranty status (placeholder field) ✓

### ⚠️ **Potential Issues:**

1. **AttributeID**: Need to verify if 1395 or 1394 is correct for CQM data
   ```sql
   -- Check which attribute IDs exist for CQM
   SELECT DISTINCT AttributeID, AttributeName
   FROM Plus.pls.CodeAttribute
   WHERE AttributeName LIKE '%CQM%' OR AttributeID IN (1394, 1395);
   ```

2. **Program Name**: Verify 'DELL_MEM' is correct in DataWipeResult
   ```sql
   -- Check what programs exist
   SELECT DISTINCT Program FROM redw.tia.DataWipeResult;
   ```

3. **PartTransactionID 47**: Unknown transaction type
   ```sql
   -- Find what PartTransactionID 47 is
   SELECT * FROM Plus.pls.CodePartTransaction WHERE ID = 47;
   ```

4. **COLLATE Clauses**: Suggesting potential case-sensitivity issues
   ```sql
   -- Check if this is necessary
   -- Consider if TestArea values match exactly (case-sensitive?)
   ```

## Recommendations for Validation

### 1. Check CQM Attribute ID
```sql
SELECT psa.*, ca.AttributeName
FROM Plus.pls.PartSerialAttribute psa
JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
WHERE psa.AttributeID IN (1394, 1395)
  AND ps.ProgramID = 10053
LIMIT 10;
```

### 2. Verify Program Name
```sql
SELECT DISTINCT Program, COUNT(*) as RecordCount
FROM redw.tia.DataWipeResult
WHERE SerialNumber LIKE '2%'  -- Sample serials
GROUP BY Program
ORDER BY RecordCount DESC;
```

### 3. Verify Transaction Types
```sql
SELECT * FROM Plus.pls.CodePartTransaction WHERE ID IN (1, 47);
```

### 4. Test the Ranking Logic
```sql
-- Check if ranking is working correctly
SELECT SerialNumber, TestArea, MachineName, StartTime, Result, RowNum
FROM (
    SELECT
        SerialNumber,
        TestArea,
        MachineName,
        StartTime,
        Result,
        ID,
        ROW_NUMBER() OVER (
            PARTITION BY SerialNumber, TestArea, MachineName
            ORDER BY StartTime DESC, ID DESC
        ) AS RowNum
    FROM redw.tia.DataWipeResult
    WHERE Program = 'DELL_MEM'
      AND SerialNumber IN (SELECT TOP 10 SerialNo FROM Plus.pls.PartSerial WHERE ProgramID = 10053)
) ranked
WHERE RowNum <= 3
ORDER BY SerialNumber, TestArea, MachineName, RowNum;
```

## Summary

**Overall Assessment**: The query structure is **logically sound** but requires validation of:
1. AttributeID value (1395 vs 1394)
2. Program name ('DELL_MEM')
3. PartTransactionID 47 meaning
4. Test area names (case sensitivity)
5. Machine name values

The October 20-24 filter has been applied at all relevant points:
- CQMDate in BaseData
- StartTime in AllTestResults
- CreateDate in ReceivedDate OUTER APPLY

**Recommendation**: Run the validation queries above before using this view in production.


















