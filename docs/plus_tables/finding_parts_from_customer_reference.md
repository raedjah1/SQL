# Finding Parts from Customer Reference

**Purpose:** How to find part numbers associated with a customer reference across different tables

## Method 1: From SOHeader (Sales Orders)

### Simple Query
```sql
SELECT 
    soh.CustomerReference,
    sol.PartNo,
    sol.QtyToShip AS RequestedQty,
    sol.QtyReserved AS ShippedQty
FROM 
    Plus.pls.SOHeader soh
    INNER JOIN Plus.pls.SOLine sol ON sol.SOHeaderID = soh.ID
WHERE 
    soh.ProgramID = 10068  -- ADT
    AND soh.CustomerReference = 'CUSTOMER_REFERENCE';
```

### With Details
```sql
SELECT 
    soh.ID AS OrderID,
    soh.CustomerReference,
    sol.PartNo,
    sol.QtyToShip AS RequestedQty,
    sol.QtyReserved AS ReservedQty,
    sol.ConfigurationID,
    cc.Description AS Configuration,
    soh.StatusID,
    cs.Description AS Status,
    soh.CreateDate
FROM 
    Plus.pls.SOHeader soh
    INNER JOIN Plus.pls.SOLine sol ON sol.SOHeaderID = soh.ID
    LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = soh.StatusID
    LEFT JOIN Plus.pls.CodeConfiguration cc ON cc.ID = sol.ConfigurationID
WHERE 
    soh.ProgramID = 10068
    AND soh.CustomerReference = 'CUSTOMER_REFERENCE';
```

## Method 2: From ROHeader (Return Orders)

### Simple Query
```sql
SELECT 
    rh.CustomerReference,
    rol.PartNo
FROM 
    Plus.pls.ROHeader rh
    INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
WHERE 
    rh.ProgramID = 10068  -- ADT
    AND rh.CustomerReference = 'CUSTOMER_REFERENCE';
```

## Method 3: From PartTransaction

### Simple Query
```sql
SELECT 
    pt.CustomerReference,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty,
    cpt.Description AS TransactionType,
    pt.CreateDate
FROM 
    Plus.pls.PartTransaction pt
    LEFT JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE 
    pt.ProgramID = 10068  -- ADT
    AND pt.CustomerReference = 'CUSTOMER_REFERENCE'
ORDER BY pt.CreateDate DESC;
```

**Note:** PartTransaction may have NULL PartNo for certain transaction types (like SO-CANCEL). In that case, use OrderHeaderID to link back to the order.

## Method 4: When PartTransaction PartNo is NULL (Canceled Orders)

If PartTransaction shows NULL PartNo (e.g., SO-CANCEL transactions), use OrderHeaderID to find the parts:

```sql
-- Step 1: Get the OrderHeaderID from PartTransaction
SELECT 
    pt.ID AS TransactionID,
    pt.CustomerReference,
    pt.OrderHeaderID,
    pt.OrderType,
    cpt.Description AS TransactionType
FROM 
    Plus.pls.PartTransaction pt
    LEFT JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE 
    pt.ProgramID = 10068
    AND pt.CustomerReference = 'CUSTOMER_REFERENCE'
    AND pt.PartNo IS NULL;

-- Step 2: Use OrderHeaderID to get parts from SOHeader/SOLine
SELECT 
    soh.ID AS OrderID,
    soh.CustomerReference,
    sol.PartNo,
    sol.QtyToShip AS RequestedQty,
    sol.QtyReserved AS ReservedQty,
    soh.StatusID,
    cs.Description AS Status
FROM 
    Plus.pls.SOHeader soh
    INNER JOIN Plus.pls.SOLine sol ON sol.SOHeaderID = soh.ID
    LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = soh.StatusID
WHERE 
    soh.ProgramID = 10068
    AND soh.ID = ORDER_HEADER_ID;  -- Use the OrderHeaderID from Step 1
```

## Complete Investigation Query

For a complete picture of a customer reference:

```sql
-- Get parts from all sources
SELECT 
    'SOHeader' AS Source,
    soh.CustomerReference,
    sol.PartNo,
    sol.QtyToShip AS Qty,
    soh.CreateDate
FROM Plus.pls.SOHeader soh
INNER JOIN Plus.pls.SOLine sol ON sol.SOHeaderID = soh.ID
WHERE soh.ProgramID = 10068 AND soh.CustomerReference = 'CUSTOMER_REFERENCE'

UNION ALL

SELECT 
    'ROHeader' AS Source,
    rh.CustomerReference,
    rol.PartNo,
    NULL AS Qty,
    rh.CreateDate
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
WHERE rh.ProgramID = 10068 AND rh.CustomerReference = 'CUSTOMER_REFERENCE'

UNION ALL

SELECT 
    'PartTransaction' AS Source,
    pt.CustomerReference,
    pt.PartNo,
    pt.Qty,
    pt.CreateDate
FROM Plus.pls.PartTransaction pt
WHERE pt.ProgramID = 10068 
    AND pt.CustomerReference = 'CUSTOMER_REFERENCE'
    AND pt.PartNo IS NOT NULL

ORDER BY CreateDate DESC;
```

## Key Relationships

- **SOHeader.ID** ← `SOLine.SOHeaderID` (one order has many lines/parts)
- **ROHeader.ID** ← `ROLine.ROHeaderID` (one return order has many lines/parts)
- **PartTransaction.OrderHeaderID** → `SOHeader.ID` (links transaction to order)
- **PartTransaction.OrderLineID** → `SOLine.ID` (links transaction to specific line)

## Common Scenarios

### Scenario 1: Find parts for active order
Use **SOHeader/SOLine** - most reliable source

### Scenario 2: Find parts for return order
Use **ROHeader/ROLine**

### Scenario 3: Find parts from transaction history
Use **PartTransaction** - shows all movements

### Scenario 4: PartTransaction shows NULL PartNo
Use **OrderHeaderID** to link back to **SOHeader/SOLine** to get the actual parts

## Notes

- Always filter by `ProgramID = 10068` for ADT
- PartTransaction may have NULL PartNo for cancel transactions - use OrderHeaderID
- SOLine has `QtyToShip` (requested) and `QtyReserved` (shipped/reserved)
- Check multiple sources to get complete picture


