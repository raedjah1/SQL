-- ================================================
-- INVESTIGATE MISSING FIELDS FOR RECEIPT REPORT
-- ================================================
-- Purpose: Find Total Units and Dept fields for ADTReceiptReport
-- ================================================

-- ================================================
-- 1. INVESTIGATE TOTAL UNITS - ROLine quantities
-- ================================================

-- Check ROLine table structure for quantity fields
SELECT TOP 10
    rol.ID,
    rol.ROHeaderID,
    rol.PartNo,
    rol.QtyToReceive,
    rol.QtyReceived,
    rol.StatusID,
    rol.CreateDate,
    rol.LastActivityDate
FROM PLUS.pls.ROLine rol
WHERE rol.ROHeaderID IN (
    SELECT TOP 5 rh.ID 
    FROM PLUS.pls.ROHeader rh 
    WHERE rh.ProgramID IN (10068, 10072)
    ORDER BY rh.CreateDate DESC
)
ORDER BY rol.CreateDate DESC;

-- ================================================
-- 2. INVESTIGATE DEPARTMENT ATTRIBUTES
-- ================================================

-- Find all available attributes in CodeAddressDetailsAttribute
SELECT DISTINCT
    ca.AttributeName,
    COUNT(*) as UsageCount,
    MIN(cada.Value) as SampleValue1,
    MAX(cada.Value) as SampleValue2
FROM PLUS.pls.CodeAddressDetailsAttribute cada
JOIN PLUS.pls.CodeAttribute ca ON cada.AttributeID = ca.ID
WHERE ca.AttributeName LIKE '%DEPT%'
   OR ca.AttributeName LIKE '%DEPARTMENT%'
   OR ca.AttributeName LIKE '%DIVISION%'
   OR ca.AttributeName LIKE '%ORG%'
   OR ca.AttributeName LIKE '%ORGANIZATION%'
GROUP BY ca.AttributeName
ORDER BY UsageCount DESC;

-- ================================================
-- 3. INVESTIGATE ALL ADDRESS ATTRIBUTES
-- ================================================

-- Get all available address attributes
SELECT DISTINCT
    ca.AttributeName,
    COUNT(*) as UsageCount
FROM PLUS.pls.CodeAddressDetailsAttribute cada
JOIN PLUS.pls.CodeAttribute ca ON cada.AttributeID = ca.ID
GROUP BY ca.AttributeName
ORDER BY UsageCount DESC;

-- ================================================
-- 4. INVESTIGATE ROHeader quantities
-- ================================================

-- Check if ROHeader has quantity fields
SELECT TOP 10
    rh.ID,
    rh.CustomerReference,
    rh.CreateDate,
    rh.StatusID,
    rh.AddressID,
    -- Check for any quantity-related fields
    rh.*
FROM PLUS.pls.ROHeader rh
WHERE rh.ProgramID IN (10068, 10072)
ORDER BY rh.CreateDate DESC;

-- ================================================
-- 5. INVESTIGATE PartTransaction quantities
-- ================================================

-- Check PartTransaction for quantity information
SELECT TOP 10
    pt.ID,
    pt.CustomerReference,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty,
    pt.CreateDate,
    pt.PartTransactionID,
    cpt.Description as TransactionType
FROM PLUS.pls.PartTransaction pt
JOIN PLUS.pls.CodePartTransaction cpt ON pt.PartTransactionID = cpt.ID
WHERE pt.ProgramID IN (10068, 10072)
  AND cpt.Description = 'RO-RECEIVE'
ORDER BY pt.CreateDate DESC;

-- ================================================
-- 6. INVESTIGATE ROUnit quantities
-- ================================================

-- Check ROUnit for quantity information
SELECT TOP 10
    ru.ID,
    ru.ROLineID,
    ru.SerialNo,
    ru.Qty,
    ru.CreateDate,
    ru.StatusID
FROM PLUS.pls.ROUnit ru
WHERE ru.ROLineID IN (
    SELECT TOP 5 rol.ID 
    FROM PLUS.pls.ROLine rol
    WHERE rol.ROHeaderID IN (
        SELECT TOP 3 rh.ID 
        FROM PLUS.pls.ROHeader rh 
        WHERE rh.ProgramID IN (10068, 10072)
        ORDER BY rh.CreateDate DESC
    )
)
ORDER BY ru.CreateDate DESC;

-- ================================================
-- 7. SAMPLE DATA FOR TESTING
-- ================================================

-- Get sample data to test the receipt report structure
SELECT TOP 5
    rec.CustomerReference as ASN,
    rec.PartNo,
    rec.SerialNo,
    rec.Qty,
    rec.CreateDate,
    rh.ID as ROHeaderID,
    rh.AddressID,
    adt.Name as AddressName,
    adt.City,
    adt.State
FROM PLUS.pls.PartTransaction rec
JOIN PLUS.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
JOIN PLUS.pls.CodeAddress adr ON adr.ID = rh.AddressID
JOIN PLUS.pls.CodeAddressDetails adt ON adt.AddressID = adr.ID
WHERE rec.ProgramID IN (10068, 10072)
  AND rec.PartTransactionID = 1
ORDER BY rec.CreateDate DESC;

