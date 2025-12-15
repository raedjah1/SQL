# PartTransaction Table Structure

**Schema:** `Plus.pls.PartTransaction`  
**Purpose:** Tracks all part movements and transactions

## Columns

| Column Name | Data Type | Nullable | Description |
|------------|-----------|----------|-------------|
| ID | int | NO | Primary Key |
| ProgramID | smallint | NO | Program identifier (10068 = ADT) |
| CustomerReference | varchar | YES | Customer reference/ASN number |
| PartNo | varchar | NO | Part number |
| SerialNo | varchar | YES | Serial number |
| Qty | int | NO | Transaction quantity |
| PartTransactionID | smallint | NO | Transaction type (FK to CodePartTransaction) |
| LocationNo | varchar | YES | Location involved in transaction |
| CreateDate | datetime2 | NO | Transaction date |
| UserID | smallint | NO | User who created transaction |

## Key Relationships

- **PartTransactionID** → `Plus.pls.CodePartTransaction.ID`
- **ProgramID** → `Plus.pls.Program.ID`

## Common Transaction Types

- RO-RECEIVE (Return Order Receive)
- SO-SHIP (Sales Order Ship)
- TRANSFER
- ADJUSTMENT
- etc.

## Common Queries

### Search by customer reference
```sql
SELECT 
    pt.CustomerReference,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty,
    cpt.Description AS TransactionType,
    pt.CreateDate
FROM Plus.pls.PartTransaction pt
    LEFT JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE pt.ProgramID = 10068
    AND pt.CustomerReference LIKE '%REFERENCE%';
```

### Search by serial number
```sql
SELECT 
    pt.SerialNo,
    pt.PartNo,
    pt.CustomerReference,
    cpt.Description AS TransactionType,
    pt.CreateDate
FROM Plus.pls.PartTransaction pt
    LEFT JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE pt.ProgramID = 10068
    AND pt.SerialNo LIKE '%SERIAL%';
```

## Notes

- **CustomerReference** can contain ASN numbers, order references, etc.
- **SerialNo** can be searched for specific serialized parts
- Use this table to track part history and movements

