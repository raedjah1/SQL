-- Investigate where Warehouse should come from for GIT orders
-- Purpose: GIT orders show blank Warehouse, need to find the correct source

-- ============================================================================
-- 1. Check if GIT orders have SERVICETAG (current warehouse source)
-- ============================================================================
SELECT 
    'GIT Orders - SERVICETAG Check' AS InvestigationType,
    sh.CustomerReference,
    sl.PartNo,
    COUNT(DISTINCT sla.Value) AS ServiceTagCount,
    MAX(CASE WHEN cla.AttributeName = 'SERVICETAG' THEN sla.Value END) AS SampleServiceTag,
    CASE 
        WHEN MAX(CASE WHEN cla.AttributeName = 'SERVICETAG' THEN sla.Value END) IS NOT NULL 
        THEN 'Has SERVICETAG' 
        ELSE 'NO SERVICETAG' 
    END AS ServiceTagStatus
FROM Plus.pls.SOHeader sh
INNER JOIN Plus.pls.SOLine sl ON sl.SOHeaderID = sh.ID
LEFT JOIN Plus.pls.SOLineAttribute sla ON sla.SOLineID = sl.ID
LEFT JOIN Plus.pls.CodeAttribute cla ON cla.ID = sla.AttributeID AND cla.AttributeName = 'SERVICETAG'
WHERE sh.ProgramID = 10053
  AND sh.CustomerReference LIKE 'GIT%'
  AND sh.StatusID NOT IN (SELECT ID FROM Plus.pls.CodeStatus WHERE Description IN ('CANCELED', 'SHIPPED'))
GROUP BY sh.CustomerReference, sl.PartNo
ORDER BY ServiceTagStatus, sh.CustomerReference
-- LIMIT to first 20 for quick check
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;

-- ============================================================================
-- 2. Check Warehouse from PartLocation via PartQty (not via SerialNumber)
-- ============================================================================
SELECT 
    'GIT Orders - Warehouse via PartQty->PartLocation' AS InvestigationType,
    sh.CustomerReference,
    sl.PartNo,
    loc.Warehouse AS WarehouseFromPartLocation,
    loc.LocationNo,
    SUM(pq.AvailableQty) AS TotalAvailableQty,
    COUNT(DISTINCT loc.ID) AS LocationCount
FROM Plus.pls.SOHeader sh
INNER JOIN Plus.pls.SOLine sl ON sl.SOHeaderID = sh.ID
LEFT JOIN Plus.pls.PartQty pq ON pq.PartNo = sl.PartNo AND pq.ProgramID = 10053
LEFT JOIN Plus.pls.PartLocation loc ON loc.ID = pq.LocationID
WHERE sh.ProgramID = 10053
  AND sh.CustomerReference LIKE 'GIT%'
  AND sh.StatusID NOT IN (SELECT ID FROM Plus.pls.CodeStatus WHERE Description IN ('CANCELED', 'SHIPPED'))
GROUP BY sh.CustomerReference, sl.PartNo, loc.Warehouse, loc.LocationNo
ORDER BY sh.CustomerReference, sl.PartNo
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;

-- ============================================================================
-- 3. Check Warehouse from PartQty joined to PartLocation
-- ============================================================================
SELECT 
    'GIT Orders - Warehouse via PartQty->PartLocation' AS InvestigationType,
    sh.CustomerReference,
    sl.PartNo,
    loc.Warehouse AS WarehouseFromPartQty,
    loc.LocationNo,
    SUM(pq.AvailableQty) AS TotalAvailableQty,
    COUNT(DISTINCT loc.ID) AS LocationCount
FROM Plus.pls.SOHeader sh
INNER JOIN Plus.pls.SOLine sl ON sl.SOHeaderID = sh.ID
LEFT JOIN Plus.pls.PartQty pq ON pq.PartNo = sl.PartNo AND pq.ProgramID = 10053
LEFT JOIN Plus.pls.PartLocation loc ON loc.ID = pq.LocationID
WHERE sh.ProgramID = 10053
  AND sh.CustomerReference LIKE 'GIT%'
  AND sh.StatusID NOT IN (SELECT ID FROM Plus.pls.CodeStatus WHERE Description IN ('CANCELED', 'SHIPPED'))
GROUP BY sh.CustomerReference, sl.PartNo, loc.Warehouse, loc.LocationNo
ORDER BY sh.CustomerReference, sl.PartNo
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;

-- ============================================================================
-- 4. Check Warehouse from PartNoAttribute
-- ============================================================================
SELECT 
    'GIT Orders - Warehouse Attribute' AS InvestigationType,
    sh.CustomerReference,
    sl.PartNo,
    pna.Value AS WarehouseFromAttribute,
    ca.AttributeName
FROM Plus.pls.SOHeader sh
INNER JOIN Plus.pls.SOLine sl ON sl.SOHeaderID = sh.ID
LEFT JOIN Plus.pls.PartNoAttribute pna ON pna.PartNo = sl.PartNo AND pna.ProgramID = 10053
LEFT JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
WHERE sh.ProgramID = 10053
  AND sh.CustomerReference LIKE 'GIT%'
  AND sh.StatusID NOT IN (SELECT ID FROM Plus.pls.CodeStatus WHERE Description IN ('CANCELED', 'SHIPPED'))
  AND (
      ca.AttributeName LIKE '%WAREHOUSE%'
      OR ca.AttributeName LIKE '%WH%'
      OR ca.AttributeName LIKE '%LOCATION%'
  )
ORDER BY sh.CustomerReference, sl.PartNo
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;

-- ============================================================================
-- 5. Check Warehouse from SOHeaderAttribute or SOLineAttribute
-- ============================================================================
SELECT 
    'GIT Orders - Warehouse from Order Attributes' AS InvestigationType,
    sh.CustomerReference,
    sl.PartNo,
    CASE 
        WHEN sha_attr.SOHeaderID IS NOT NULL THEN 'SOHeaderAttribute'
        WHEN sla_attr.SOLineID IS NOT NULL THEN 'SOLineAttribute'
    END AS AttributeSource,
    CASE 
        WHEN sha_attr.SOHeaderID IS NOT NULL THEN sha_attr.Value
        WHEN sla_attr.SOLineID IS NOT NULL THEN sla_attr.Value
    END AS WarehouseValue,
    ca_attr.AttributeName
FROM Plus.pls.SOHeader sh
INNER JOIN Plus.pls.SOLine sl ON sl.SOHeaderID = sh.ID
LEFT JOIN Plus.pls.SOHeaderAttribute sha_attr ON sha_attr.SOHeaderID = sh.ID
LEFT JOIN Plus.pls.CodeAttribute ca_attr_header ON ca_attr_header.ID = sha_attr.AttributeID
LEFT JOIN Plus.pls.SOLineAttribute sla_attr ON sla_attr.SOLineID = sl.ID
LEFT JOIN Plus.pls.CodeAttribute ca_attr ON ca_attr.ID = sla_attr.AttributeID
WHERE sh.ProgramID = 10053
  AND sh.CustomerReference LIKE 'GIT%'
  AND sh.StatusID NOT IN (SELECT ID FROM Plus.pls.CodeStatus WHERE Description IN ('CANCELED', 'SHIPPED'))
  AND (
      (ca_attr_header.AttributeName LIKE '%WAREHOUSE%' OR ca_attr_header.AttributeName LIKE '%WH%')
      OR
      (ca_attr.AttributeName LIKE '%WAREHOUSE%' OR ca_attr.AttributeName LIKE '%WH%')
  )
ORDER BY sh.CustomerReference, sl.PartNo
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;

-- ============================================================================
-- 6. Compare: Non-GIT orders (that have warehouse) vs GIT orders
-- ============================================================================
SELECT 
    'Comparison: Non-GIT vs GIT' AS InvestigationType,
    CASE WHEN sh.CustomerReference LIKE 'GIT%' THEN 'GIT' ELSE 'Non-GIT' END AS OrderType,
    COUNT(DISTINCT sh.ID) AS OrderCount,
    COUNT(DISTINCT sl.ID) AS LineCount,
    COUNT(DISTINCT CASE WHEN loc.Warehouse IS NOT NULL THEN sl.ID END) AS LinesWithWarehouse,
    COUNT(DISTINCT CASE WHEN loc.Warehouse IS NULL THEN sl.ID END) AS LinesWithoutWarehouse,
    COUNT(DISTINCT CASE WHEN sla.Value IS NOT NULL AND cla.AttributeName = 'SERVICETAG' THEN sl.ID END) AS LinesWithServiceTag
FROM Plus.pls.SOHeader sh
INNER JOIN Plus.pls.SOLine sl ON sl.SOHeaderID = sh.ID
LEFT JOIN Plus.pls.SOLineAttribute sla ON sla.SOLineID = sl.ID
LEFT JOIN Plus.pls.CodeAttribute cla ON cla.ID = sla.AttributeID AND cla.AttributeName = 'SERVICETAG'
LEFT JOIN Plus.pls.PartSerial ps ON ps.SerialNo = sla.Value
LEFT JOIN Plus.pls.PartLocation loc ON loc.ID = ps.LocationID
WHERE sh.ProgramID = 10053
  AND sh.StatusID NOT IN (SELECT ID FROM Plus.pls.CodeStatus WHERE Description IN ('CANCELED', 'SHIPPED'))
GROUP BY CASE WHEN sh.CustomerReference LIKE 'GIT%' THEN 'GIT' ELSE 'Non-GIT' END;

-- ============================================================================
-- 7. Check if GIT orders have PartNo that exists in PartQty->PartLocation
-- ============================================================================
SELECT 
    'GIT Orders - PartNo in PartQty->PartLocation' AS InvestigationType,
    sh.CustomerReference,
    sl.PartNo,
    loc.Warehouse,
    loc.LocationNo,
    SUM(pq.AvailableQty) AS TotalAvailableQty,
    COUNT(DISTINCT loc.ID) AS MatchingLocations
FROM Plus.pls.SOHeader sh
INNER JOIN Plus.pls.SOLine sl ON sl.SOHeaderID = sh.ID
INNER JOIN Plus.pls.PartQty pq ON pq.PartNo = sl.PartNo AND pq.ProgramID = 10053
INNER JOIN Plus.pls.PartLocation loc ON loc.ID = pq.LocationID
WHERE sh.ProgramID = 10053
  AND sh.CustomerReference LIKE 'GIT%'
  AND sh.StatusID NOT IN (SELECT ID FROM Plus.pls.CodeStatus WHERE Description IN ('CANCELED', 'SHIPPED'))
GROUP BY sh.CustomerReference, sl.PartNo, loc.Warehouse, loc.LocationNo
ORDER BY sh.CustomerReference, sl.PartNo
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;

