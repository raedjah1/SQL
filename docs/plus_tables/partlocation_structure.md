# PartLocation Table Structure

**Schema:** `Plus.pls.PartLocation`  
**Purpose:** Defines physical warehouse locations

## Columns

| Column Name | Data Type | Nullable | Description |
|------------|-----------|----------|-------------|
| ID | int | NO | Primary Key (used by PartQty.LocationID) |
| ProgramID | smallint | NO | Program identifier |
| LocationNo | varchar(8000) | NO | **Full location identifier** |
| Warehouse | varchar(8000) | NO | Warehouse name (FGI, SCRAP, RESERVE, etc.) |
| Bin | varchar(8000) | NO | Bin identifier |
| Building | varchar(8000) | NO | Building identifier |
| Bay | varchar(8000) | NO | Bay identifier |
| Row | varchar(8000) | NO | Row identifier |
| Tier | varchar(8000) | NO | Tier identifier |
| StatusID | smallint | NO | Location status |
| LocationGroupID | smallint | NO | Location group |
| Width | smallint | NO | Location width |
| Height | smallint | NO | Location height |
| Length | smallint | NO | Location length |
| Volume | smallint | NO | Location volume |
| PickOrder | smallint | NO | Picking order |
| UserID | smallint | NO | User who created |
| CreateDate | datetime2 | NO | Creation date |
| LastActivityDate | datetime2 | NO | Last update date |

## Key Relationships

- **ID** ← Referenced by `PartQty.LocationID`
- **StatusID** → `Plus.pls.CodeStatus.ID`
- **LocationGroupID** → `Plus.pls.CodeLocationGroup.ID`

## Common Warehouse Values

- **FGI** = Finished Goods Inventory (pickable)
- **SCRAP** = Scrap location (NOT pickable)
- **RESERVE** = Reserve location
- **STAGE** = Staging area

## Common Queries

### Get location details for a part
```sql
SELECT 
    pl.LocationNo,
    pl.Warehouse,
    pl.Bin,
    pl.Building,
    pl.Bay,
    pl.Row,
    pl.Tier,
    pq.AvailableQty
FROM Plus.pls.PartQty pq
    LEFT JOIN Plus.pls.PartLocation pl ON pl.ID = pq.LocationID
WHERE pq.ProgramID = 10068
    AND pq.PartNo = 'PART_NUMBER';
```

## Notes

- **LocationNo** is the full location identifier (e.g., "FGI.ADT.ZF.12.06B")
- **Warehouse** determines if location is pickable (SCRAP = not pickable)
- Join with PartQty using `pl.ID = pq.LocationID`

