# PartQty Table Structure

**Schema:** `Plus.pls.PartQty`  
**Purpose:** Tracks part quantities at specific locations

## Columns

| Column Name | Data Type | Nullable | Description |
|------------|-----------|----------|-------------|
| ID | int | NO | Primary Key |
| ProgramID | smallint | NO | Program identifier (10068 = ADT) |
| LocationID | int | NO | Foreign Key to PartLocation.ID |
| ConfigurationID | smallint | NO | Configuration (1 = Good, 2 = Bad) |
| PartNo | varchar(8000) | NO | Part number |
| PalletBoxNo | varchar(8000) | NO | Pallet/Box number |
| LotNo | varchar(8000) | NO | Lot number |
| AvailableQty | int | NO | **Available quantity at this location** |
| UserID | smallint | NO | User who created record |
| CreateDate | datetime2 | NO | Record creation date |
| LastActivityDate | datetime2 | NO | Last update date |

## Key Relationships

- **LocationID** → `Plus.pls.PartLocation.ID`
- **ConfigurationID** → `Plus.pls.CodeConfiguration.ID`
- **ProgramID** → `Plus.pls.Program.ID`

## Common Queries

### Get available stock for a part
```sql
SELECT 
    pq.PartNo,
    pq.ConfigurationID,
    SUM(pq.AvailableQty) AS TotalAvailable
FROM Plus.pls.PartQty pq
WHERE pq.ProgramID = 10068
    AND pq.PartNo = 'PART_NUMBER'
GROUP BY pq.PartNo, pq.ConfigurationID;
```

### Get stock with location details
```sql
SELECT 
    pq.PartNo,
    pq.AvailableQty,
    pl.LocationNo,
    pl.Warehouse,
    pl.Bin
FROM Plus.pls.PartQty pq
    LEFT JOIN Plus.pls.PartLocation pl ON pl.ID = pq.LocationID
WHERE pq.ProgramID = 10068
    AND pq.PartNo = 'PART_NUMBER';
```

## Notes

- **AvailableQty** is the key field for checking stock levels
- Join with PartLocation to get location details
- Group by ConfigurationID to separate Good vs Bad parts

