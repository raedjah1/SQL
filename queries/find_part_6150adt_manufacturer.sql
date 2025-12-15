-- ============================================
-- FIND PART 6150ADT AND LINK TO MANUFACTURER
-- ============================================
-- Quick investigation query for ADT part 6150ADT
-- ADT ProgramID = 10068
-- ============================================

-- ============================================
-- 1. FIND PART 6150ADT IN PART MASTER
-- ============================================
SELECT 
    'PART_MASTER' AS InfoType,
    pn.PartNo,
    pn.Description,
    pn.PartType,
    pn.Status,
    pn.PrimaryCommodityID,
    pn.SecondaryCommodityID,
    pn.CreateDate,
    pn.LastActivityDate
FROM Plus.pls.PartNo pn
WHERE pn.PartNo = '6150ADT';

-- ============================================
-- 2. FIND MANUFACTURER ATTRIBUTE FOR 6150ADT
-- ============================================
SELECT 
    'MANUFACTURER_ATTRIBUTE' AS InfoType,
    pna.PartNo,
    ca.AttributeName,
    pna.Value AS Manufacturer,
    pna.CreateDate
FROM Plus.pls.PartNoAttribute pna
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
WHERE pna.PartNo = '6150ADT'
  AND (ca.AttributeName LIKE '%MANUFACTURER%' 
       OR ca.AttributeName LIKE '%MAKER%'
       OR ca.AttributeName LIKE '%VENDOR%'
       OR ca.AttributeName LIKE '%SUPPLIER%');

-- ============================================
-- 3. FIND ALL ATTRIBUTES FOR 6150ADT
-- ============================================
SELECT 
    'ALL_ATTRIBUTES' AS InfoType,
    pna.PartNo,
    ca.AttributeName,
    pna.Value,
    pna.CreateDate
FROM Plus.pls.PartNoAttribute pna
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
WHERE pna.PartNo = '6150ADT'
ORDER BY ca.AttributeName;

-- ============================================
-- 4. FIND WHERE 6150ADT IS LOCATED (ADT ONLY)
-- ============================================
SELECT 
    'PART_LOCATIONS' AS InfoType,
    pl.PartNo,
    pl.LocationNo,
    pl.Warehouse,
    pl.QtyOnHand,
    pl.ProgramID,
    p.Name AS ProgramName,
    pl.CreateDate,
    pl.LastActivityDate
FROM Plus.pls.PartLocation pl
INNER JOIN Plus.pls.Program p ON p.ID = pl.ProgramID
WHERE pl.PartNo = '6150ADT'
  AND pl.ProgramID = 10068  -- ADT Program
ORDER BY pl.QtyOnHand DESC;

-- ============================================
-- 5. FIND SERIAL NUMBERS FOR 6150ADT (ADT ONLY)
-- ============================================
SELECT TOP 20
    'PART_SERIALS' AS InfoType,
    ps.PartNo,
    ps.SerialNo,
    ps.ProgramID,
    pl.LocationNo,
    pl.Warehouse,
    cs.Description AS Status,
    ps.CreateDate,
    ps.LastActivityDate
FROM Plus.pls.PartSerial ps
INNER JOIN Plus.pls.PartLocation pl ON pl.ID = ps.LocationID
INNER JOIN Plus.pls.CodeStatus cs ON cs.ID = ps.StatusID
WHERE ps.PartNo = '6150ADT'
  AND ps.ProgramID = 10068  -- ADT Program
ORDER BY ps.CreateDate DESC;

-- ============================================
-- 6. FIND WORK ORDERS FOR 6150ADT (ADT ONLY)
-- ============================================
SELECT TOP 20
    'WORK_ORDERS' AS InfoType,
    wo.ID AS WorkOrderID,
    wo.PartNo,
    wo.SerialNo,
    wo.CustomerReference,
    wo.ProgramID,
    p.Name AS ProgramName,
    cs.Description AS Status,
    wo.CreateDate,
    wo.LastActivityDate
FROM Plus.pls.WOHeader wo
INNER JOIN Plus.pls.Program p ON p.ID = wo.ProgramID
INNER JOIN Plus.pls.CodeStatus cs ON cs.ID = wo.StatusID
WHERE wo.PartNo = '6150ADT'
  AND wo.ProgramID = 10068  -- ADT Program
ORDER BY wo.CreateDate DESC;

-- ============================================
-- 7. FIND TRANSACTIONS FOR 6150ADT (ADT ONLY)
-- ============================================
SELECT TOP 20
    'PART_TRANSACTIONS' AS InfoType,
    pt.PartNo,
    pt.SerialNo,
    cpt.Description AS TransactionType,
    pt.Location,
    pt.ToLocation,
    pt.Qty,
    u.Username,
    pt.CreateDate
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
INNER JOIN Plus.pls.[User] u ON u.ID = pt.UserID
WHERE pt.PartNo = '6150ADT'
  AND pt.ProgramID = 10068  -- ADT Program
ORDER BY pt.CreateDate DESC;

-- ============================================
-- 8. CHECK ALL AVAILABLE ATTRIBUTE NAMES
-- ============================================
-- This helps identify if manufacturer is stored under a different name
SELECT DISTINCT
    'AVAILABLE_ATTRIBUTES' AS InfoType,
    ca.AttributeName
FROM Plus.pls.CodeAttribute ca
WHERE ca.AttributeName LIKE '%MAN%'
   OR ca.AttributeName LIKE '%MAKE%'
   OR ca.AttributeName LIKE '%VEND%'
   OR ca.AttributeName LIKE '%SUPP%'
   OR ca.AttributeName LIKE '%BRAND%'
ORDER BY ca.AttributeName;














