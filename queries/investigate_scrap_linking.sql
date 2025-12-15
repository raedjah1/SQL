-- ============================================
-- INVESTIGATE SCRAP LINKING FOR EX RETURN ORDERS
-- ============================================
-- Goal: Find how WO-SCRAP transactions relate back to EX return orders

-- ============================================
-- 1. WHAT'S IN WO-SCRAP CustomerReference?
-- ============================================
-- See what CustomerReference values exist in WO-SCRAP for ADT
SELECT TOP 50
    pt.CustomerReference,
    pt.PartNo,
    pt.SerialNo,
    pt.LocationID,
    pt.ToLocationID,
    pt.CreateDate,
    pt.Username,
    pt.Reason
FROM [PLUS].pls.PartTransaction pt
INNER JOIN [PLUS].pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE cpt.Description = 'WO-SCRAP'
  AND pt.ProgramID = 10068
  AND pt.CreateDate >= DATEADD(MONTH, -3, GETDATE())
ORDER BY pt.CreateDate DESC;

-- ============================================
-- 2. WHAT ARE THE EX RETURN ORDERS?
-- ============================================
-- See what EX orders exist
SELECT TOP 50
    ro.CustomerReference,
    ro.CreateDate,
    ro.StatusID,
    cs.Description as Status,
    rol.PartNo,
    rol.QtyToReceive,
    rol.QtyReceived
FROM [PLUS].pls.ROHeader ro
JOIN [PLUS].pls.ROLine rol ON ro.ID = rol.ROHeaderID
LEFT JOIN [PLUS].pls.CodeStatus cs ON rol.StatusID = cs.ID
WHERE ro.CustomerReference LIKE 'EX%'
  AND ro.ProgramID = 10068
ORDER BY ro.CreateDate DESC;

-- ============================================
-- 3. FIND ALL TRANSACTIONS FOR A SPECIFIC EX ORDER
-- ============================================
-- Pick an EX order and see ALL transactions related to it
-- Replace 'EX2506275' with an actual EX number from query #2
DECLARE @ExNumber VARCHAR(50) = 'EX%' -- Use wildcard or specific number

SELECT 
    pt.ID,
    pt.CustomerReference,
    cpt.Description as TransactionType,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty,
    pt.LocationID,
    pt.ToLocationID,
    pt.CreateDate,
    pt.Username,
    pt.Reason
FROM [PLUS].pls.PartTransaction pt
INNER JOIN [PLUS].pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE pt.ProgramID = 10068
  AND pt.CreateDate >= DATEADD(MONTH, -3, GETDATE())
  AND (
    pt.CustomerReference LIKE @ExNumber
    OR pt.Reason LIKE '%' + @ExNumber + '%'
    OR pt.SerialNo IN (
        -- Find serials that were RO-RECEIVEd with this EX number
        SELECT DISTINCT pt2.SerialNo
        FROM [PLUS].pls.PartTransaction pt2
        INNER JOIN [PLUS].pls.CodePartTransaction cpt2 ON cpt2.ID = pt2.PartTransactionID
        WHERE cpt2.Description = 'RO-RECEIVE'
          AND pt2.CustomerReference LIKE @ExNumber
          AND pt2.ProgramID = 10068
    )
  )
ORDER BY pt.CreateDate, cpt.Description;

-- ============================================
-- 4. FIND SCRAP BY SERIAL NUMBER TRACKING
-- ============================================
-- See if we can link scrap through serial numbers
SELECT 
    receive.CustomerReference as EX_Number,
    receive.PartNo,
    receive.SerialNo,
    receive.CreateDate as Received_Date,
    scrap.CreateDate as Scrapped_Date,
    scrap.Reason as Scrap_Reason,
    scrap.Username as Scrapped_By
FROM (
    -- All RO-RECEIVE transactions with EX numbers
    SELECT 
        pt.CustomerReference,
        pt.PartNo,
        pt.SerialNo,
        pt.CreateDate
    FROM [PLUS].pls.PartTransaction pt
    INNER JOIN [PLUS].pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    WHERE cpt.Description = 'RO-RECEIVE'
      AND pt.CustomerReference LIKE 'EX%'
      AND pt.ProgramID = 10068
      AND pt.CreateDate >= DATEADD(MONTH, -3, GETDATE())
) receive
LEFT JOIN (
    -- All WO-SCRAP transactions
    SELECT 
        pt.PartNo,
        pt.SerialNo,
        pt.CreateDate,
        pt.Reason,
        pt.Username
    FROM [PLUS].pls.PartTransaction pt
    INNER JOIN [PLUS].pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    WHERE cpt.Description = 'WO-SCRAP'
      AND pt.ProgramID = 10068
      AND pt.CreateDate >= DATEADD(MONTH, -3, GETDATE())
) scrap ON receive.SerialNo = scrap.SerialNo
    AND receive.PartNo = scrap.PartNo
    AND scrap.CreateDate > receive.CreateDate
ORDER BY receive.CustomerReference, receive.PartNo;

-- ============================================
-- 5. CHECK IF SCRAP USES LOCATION TRACKING
-- ============================================
-- See if scrap happens in a specific location tied to EX orders
SELECT 
    pt.LocationID,
    pt.ToLocationID,
    cpt.Description as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as DistinctParts
FROM [PLUS].pls.PartTransaction pt
INNER JOIN [PLUS].pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE cpt.Description IN ('RO-RECEIVE', 'WO-SCRAP')
  AND pt.ProgramID = 10068
  AND pt.CreateDate >= DATEADD(MONTH, -3, GETDATE())
GROUP BY pt.LocationID, pt.ToLocationID, cpt.Description
ORDER BY cpt.Description, TransactionCount DESC;

-- ============================================
-- 6. FIND COMMON LINKING PATTERN
-- ============================================
-- Check if there's a common field pattern
SELECT TOP 100
    ro.CustomerReference as EX_Reference,
    pt.CustomerReference as Transaction_Reference,
    cpt.Description as TransactionType,
    pt.PartNo,
    pt.SerialNo,
    pt.CreateDate,
    CASE 
        WHEN pt.CustomerReference = ro.CustomerReference THEN 'MATCH: CustomerReference'
        WHEN pt.SerialNo IN (
            SELECT pt2.SerialNo 
            FROM [PLUS].pls.PartTransaction pt2 
            WHERE pt2.CustomerReference = ro.CustomerReference
        ) THEN 'MATCH: SerialNo'
        WHEN pt.Reason LIKE '%' + ro.CustomerReference + '%' THEN 'MATCH: Reason field'
        ELSE 'NO MATCH'
    END as LinkType
FROM [PLUS].pls.ROHeader ro
JOIN [PLUS].pls.ROLine rol ON ro.ID = rol.ROHeaderID
CROSS APPLY (
    SELECT TOP 5 pt.*, cpt.Description
    FROM [PLUS].pls.PartTransaction pt
    INNER JOIN [PLUS].pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    WHERE pt.PartNo = rol.PartNo
      AND cpt.Description = 'WO-SCRAP'
      AND pt.ProgramID = 10068
      AND pt.CreateDate >= ro.CreateDate
    ORDER BY pt.CreateDate
) pt (ID, ProgramID, PartTransactionID, PartNo, SerialNo, Qty, LocationID, ToLocationID, 
      CreateDate, Username, Reason, CustomerReference, Description)
WHERE ro.CustomerReference LIKE 'EX%'
  AND ro.ProgramID = 10068
  AND ro.CreateDate >= DATEADD(MONTH, -3, GETDATE())
ORDER BY ro.CustomerReference;

















