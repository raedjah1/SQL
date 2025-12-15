# ROHeader Table Structure

**Schema:** `Plus.pls.ROHeader`  
**Purpose:** Return order header/master information

## Columns

| Column Name | Data Type | Nullable | Description |
|------------|-----------|----------|-------------|
| ID | int | NO | Primary Key (RO Order ID) |
| ProgramID | smallint | NO | Program identifier (10068 = ADT) |
| CustomerReference | varchar | YES | **Customer reference/ASN number** |
| StatusID | smallint | NO | Order status |
| AddressID | int | YES | Shipping address |
| CreateDate | datetime2 | NO | Order creation date |
| LastActivityDate | datetime2 | NO | Last activity timestamp |
| UserID | smallint | NO | User who created order |

## Key Relationships

- **ID** ← Referenced by `ROLine.ROHeaderID`
- **StatusID** → `Plus.pls.CodeStatus.ID`
- **AddressID** → `Plus.pls.CodeAddressDetails.AddressID`
- **ProgramID** → `Plus.pls.Program.ID`

## Common Queries

### Search by customer reference
```sql
SELECT 
    rh.ID AS OrderID,
    rh.CustomerReference,
    rh.StatusID,
    cs.Description AS Status,
    rh.CreateDate
FROM Plus.pls.ROHeader rh
    LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = rh.StatusID
WHERE rh.ProgramID = 10068
    AND rh.CustomerReference LIKE '%REFERENCE%';
```

### Get RO with line items
```sql
SELECT 
    rh.ID AS OrderID,
    rh.CustomerReference,
    rol.PartNo
FROM Plus.pls.ROHeader rh
    INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
WHERE rh.ProgramID = 10068
    AND rh.ID = ORDER_ID;
```

## Notes

- Similar structure to SOHeader but for return orders
- **CustomerReference** is the main search field
- Join with ROLine to get part details

