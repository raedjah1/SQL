# GCF/BizTalk Structure Documentation

## Overview

**GCF (Good Case Fail)** - Pre-test inspection failures from BizTalk integration system.

## Source Table

**Table:** `Biztalk.dbo.Outmessage_hdr`  
**Schema:** `Biztalk.dbo`  
**Purpose:** Stores GCF error messages from BizTalk integration

## Key Fields

| Field Name | Data Type | Description | Notes |
|------------|-----------|-------------|-------|
| `Outmessage_Hdr_Id` | Primary Key | Unique record identifier | |
| `Customer_order_No` | varchar | **Work Order number** | Main identifier for tracking |
| `Message_Type` | varchar | GCF Version | Values: `'DellARB-GCF_V4'`, `'DellARB-GCF_V3'` |
| `Processed` | char(1) | Pass/Fail indicator | `'F'` = FAIL, `'T'` = PASS |
| `Message` | varchar | **Error description** | Used for categorization |
| `C01` | varchar | Error Code | Sometimes contains category code (e.g., 'OPP') |
| `C20` | varchar | Additional Notes | Extra context/notes |
| `Insert_Date` | datetime | Error timestamp | Used for date filtering and deduplication |
| `Source` | varchar | Source system | Always `'Plus'` |
| `Contract` | varchar | Program identifier | Always `'10053'` (DELL program) |

## Standard Query Filters

```sql
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND obm.Processed = 'F'  -- FAIL only
```

## Deduplication Logic

**Problem:** Same work order can have multiple GCF errors on the same date  
**Solution:** Keep only the **latest timestamp** per work order per date

```sql
ROW_NUMBER() OVER (
    PARTITION BY obm.Customer_order_No, CAST(obm.Insert_Date AS DATE) 
    ORDER BY obm.Insert_Date DESC
) AS rn
```

Then filter: `WHERE rn = 1`

**Why:** Prevents double-counting when the same work order has multiple error messages on the same day.

## Fail Categories (12 Total)

Categorization is done via `CASE` statement on the `Message` field using pattern matching:

1. **Root Element Missing**
   - Pattern: `Message = 'Root element is missing.'`

2. **CCN**
   - Pattern: `Message LIKE '%List of possible elements expected: ''CCN''%'`
   - Or: `Message LIKE '%invalid child element ''NON-REPLACEMENT''%'`

3. **Invalid Service Tag**
   - Pattern: `Message LIKE '%Service tag is invalid%'`
   - Or: `Message LIKE '%Service tag%invalid%'`

4. **DPK Status**
   - Pattern: `Message LIKE '%DPK Status attribute not configured%'`

5. **API/Time Out**
   - Patterns: `%HTTP status%`, `%Unauthorized%`, `%timeout%`, `%Time Out%`, `%401%`, `%403%`, `%500%`

6. **DPK Quantity**
   - Patterns: `%DPK%Quantity%`, `%DPK%quantity%`, `%quantity%DPK%`

7. **DPK Deviation**
   - Patterns: `%DPK%Deviation%`, `%DPK%deviation%`, `%deviation%DPK%`

8. **Missing Processor/Too Many Processors**
   - Patterns: `%Processor%`, `%processor%`, `%Missing Processor%`, `%Too Many Processors%`

9. **Linux OS**
   - Patterns: `%Linux%`, `%linux%`

10. **Unsupported Parts**
    - Patterns: `%Unsupported%`, `%unsupported%`, `%not supported%`

11. **OPP**
    - Pattern: `C01 = 'OPP'` OR `Message LIKE '%OPP%'`

12. **Other**
    - Catch-all for uncategorized errors

## Common Query Patterns

### Basic Deduplicated Query
```sql
WITH RankedGCF AS (
    SELECT 
        CAST(obm.Insert_Date AS DATE) AS GCF_Date,
        obm.Customer_order_No AS Work_Order,
        obm.Message_Type AS GCF_Version,
        obm.Processed,
        obm.Message AS Error_Description,
        obm.C01 AS Error_Code,
        obm.C20 AS Additional_Notes,
        obm.Insert_Date AS Error_Timestamp,
        obm.Outmessage_Hdr_Id,
        ROW_NUMBER() OVER (
            PARTITION BY obm.Customer_order_No, CAST(obm.Insert_Date AS DATE) 
            ORDER BY obm.Insert_Date DESC
        ) AS rn
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Processed = 'F'
)
SELECT *
FROM RankedGCF
WHERE rn = 1
ORDER BY Error_Timestamp DESC;
```

### Summary by Category
```sql
SELECT 
    Test_Date,
    Fail_Category,
    COUNT(*) AS Error_Count,
    COUNT(DISTINCT Work_Order) AS Unique_Work_Orders,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Test_Date) AS DECIMAL(5,2)) AS Percent_Of_Total
FROM (
    -- Categorization logic here
) AS RankedGCF
WHERE rn = 1
GROUP BY Test_Date, Fail_Category
ORDER BY Test_Date DESC, Error_Count DESC;
```

## Business Context

- **GCF = Good Case Fail**: Pre-test inspection failures
- **Purpose**: Identify work orders that fail pre-test inspection before actual testing
- **Program**: DELL (Contract 10053)
- **Integration**: BizTalk integration between Plus system and DELL systems
- **Use Case**: Track and categorize pre-test failures to identify patterns and improve processes

## Related Files

- `queries/gcf_errors_deduplicated.sql` - Basic deduplicated query
- `queries/gcf_errors_with_categorization.sql` - Full categorization logic
- `queries/gcf_opp_investigation.sql` - OPP category investigation

