-- ============================================
-- QUICK FIND: PART 6150ADT MANUFACTURER (ADT ONLY)
-- ============================================
-- Single query for quick investigation in chat
-- ADT ProgramID = 10068
-- ============================================

SELECT 
    pn.PartNo,
    pn.Description,
    pn.Status,
    -- Manufacturer from attributes
    (SELECT TOP 1 pna.Value 
     FROM Plus.pls.PartNoAttribute pna
     INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
     WHERE pna.PartNo = pn.PartNo
       AND (ca.AttributeName LIKE '%MANUFACTURER%' 
            OR ca.AttributeName LIKE '%MAKER%'
            OR ca.AttributeName LIKE '%VENDOR%'
            OR ca.AttributeName LIKE '%SUPPLIER%')
     ORDER BY ca.AttributeName) AS Manufacturer,
    -- Current locations
    (SELECT COUNT(*) FROM Plus.pls.PartLocation pl 
     WHERE pl.PartNo = pn.PartNo AND pl.ProgramID = 10068) AS LocationCount,
    (SELECT SUM(pl.QtyOnHand) FROM Plus.pls.PartLocation pl 
     WHERE pl.PartNo = pn.PartNo AND pl.ProgramID = 10068) AS TotalQtyOnHand,
    -- Recent activity
    (SELECT TOP 1 pl.LocationNo FROM Plus.pls.PartLocation pl 
     WHERE pl.PartNo = pn.PartNo AND pl.ProgramID = 10068 
     ORDER BY pl.LastActivityDate DESC) AS MostRecentLocation,
    pn.CreateDate,
    pn.LastActivityDate
FROM Plus.pls.PartNo pn
WHERE pn.PartNo = '6150ADT';

-- ============================================
-- ALTERNATIVE: If manufacturer is in description
-- ============================================
-- Uncomment below if manufacturer info is in part description
/*
SELECT 
    PartNo,
    Description,
    -- Extract manufacturer from description if pattern exists
    CASE 
        WHEN Description LIKE '%2GIG%' THEN '2GIG'
        WHEN Description LIKE '%Honeywell%' THEN 'Honeywell'
        WHEN Description LIKE '%ADT%' THEN 'ADT'
        ELSE 'See Description'
    END AS Manufacturer_FromDescription,
    Status
FROM Plus.pls.PartNo
WHERE PartNo = '6150ADT';
*/














