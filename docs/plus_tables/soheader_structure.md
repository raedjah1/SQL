# SOHeader Table Structure

**Schema:** `Plus.pls.SOHeader`  
**Purpose:** Sales order header/master information

## Columns

| Column Name | Data Type | Nullable | Description |
|------------|-----------|----------|-------------|
| ID | int | NO | Primary Key (Order ID) |
| ProgramID | smallint | NO | Program identifier (10068 = ADT) |
| CustomerReference | varchar | YES | **Customer reference/ASN number** |
| ThirdPartyReference | varchar | YES | Third party reference |
| StatusID | smallint | NO | Order status (3=CANCELED, 7=NEW, 12=RESERVED, 13=PARTIALLYRESERVED, 18=SHIPPED) |
| AddressID | int | YES | Shipping address (FK to CodeAddressDetails) |
| CreateDate | datetime2 | NO | Order creation date |
| LastActivityDate | datetime2 | NO | Last activity timestamp |
| UserID | smallint | NO | User who created order |

## Key Relationships

- **ID** ← Referenced by `SOLine.SOHeaderID`
- **StatusID** → `Plus.pls.CodeStatus.ID`
- **AddressID** → `Plus.pls.CodeAddressDetails.AddressID`
- **ProgramID** → `Plus.pls.Program.ID`

## Common Status Values

- **3** = CANCELED
- **7** = NEW
- **12** = RESERVED
- **13** = PARTIALLYRESERVED
- **18** = SHIPPED

## Common Queries

### Search by customer reference
```sql
SELECT 
    soh.ID AS OrderID,
    soh.CustomerReference,
    soh.ThirdPartyReference,
    soh.StatusID,
    cs.Description AS Status,
    soh.CreateDate
FROM Plus.pls.SOHeader soh
    LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = soh.StatusID
WHERE soh.ProgramID = 10068
    AND soh.CustomerReference LIKE '%REFERENCE%';
```

### Get order with line items
```sql
SELECT 
    soh.ID AS OrderID,
    soh.CustomerReference,
    sol.PartNo,
    sol.QtyToShip,
    sol.QtyReserved
FROM Plus.pls.SOHeader soh
    INNER JOIN Plus.pls.SOLine sol ON sol.SOHeaderID = soh.ID
WHERE soh.ProgramID = 10068
    AND soh.ID = ORDER_ID;
```

## Notes

- **CustomerReference** is the main field for searching orders
- Join with SOLine to get part details
- Join with CodeAddressDetails to get shipping address

