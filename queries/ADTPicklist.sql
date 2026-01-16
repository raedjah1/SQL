-- ADT Pick List Query (ProgramID = 10068)
SELECT 
    -- Drop Date (from SOLine)
    CAST(sl.CreateDate AS DATE) AS DropDate,
    
    -- Ship Date (NULL for pick list - orders not shipped yet)
    NULL AS ShipDate,
    
    -- Ship Order
    sh.CustomerReference AS ShipOrder,
    
    -- Part Number2
    sl.PartNo AS PartNumber2,
    
    -- From Loc w/ on Hand Qty (FGI locations where parts are picked FROM)
    MAX(loc.LocationNo + ' - [' + CAST(pq.AvailableQty AS VARCHAR) + ']') AS FromLoc_w_OnHandQty,
    
    -- To Location (from CodeAddressDetails - actual location name)
    ISNULL(cad.Name, CAST(sh.AddressID AS VARCHAR)) AS ToLocation,
    
    -- Ship Qty
    sl.QtyToShip AS ShipQty,
    
    -- Serial Number (SERVICETAG attribute or PartSerial.SerialNo)
    COALESCE(
        MAX(CASE WHEN cla.AttributeName = 'SERVICETAG' THEN sla.Value END),
        MAX(ps.SerialNo)
    ) AS SerialNumber,
    
    -- FedEx Tracking
    MAX(sos.TrackingNo) AS FedExTracking,
    
    -- Ship ID
    CAST(sh.ID AS VARCHAR) AS ShipID,
    
    -- Packing Slip (PICK_SLIP attribute)
    MAX(CASE WHEN cha.AttributeName = 'PICK_SLIP' THEN sha.Value END) AS PackingSlip,
    
    -- Status Description (Header Status)
    cs.Description AS StatusDescription,
    
    -- Comment
    NULL AS Comment
    
FROM pls.SOHeader sh
JOIN pls.SOLine sl ON sh.ID = sl.SOHeaderID
JOIN pls.CodeStatus cs ON cs.ID = sh.StatusID
JOIN pls.CodeStatus cs_line ON cs_line.ID = sl.StatusID
LEFT JOIN pls.SOLineAttribute sla ON sl.ID = sla.SOLineID
LEFT JOIN pls.CodeAttribute cla ON cla.ID = sla.AttributeID AND cla.AttributeName = 'SERVICETAG'
LEFT JOIN pls.PartSerial ps ON ps.SOHeaderID = sh.ID 
    AND ps.PartNo = sl.PartNo 
    AND ps.ProgramID = 10068
LEFT JOIN pls.PartQty pq ON pq.PartNo = sl.PartNo 
    AND pq.ProgramID = 10068
    AND pq.AvailableQty > 0
LEFT JOIN pls.PartLocation loc ON loc.ID = pq.LocationID
    AND loc.LocationNo LIKE 'FGI%'
    AND loc.StatusID = (SELECT ID FROM pls.CodeStatus WHERE Description = 'ACTIVE')
    AND (
        loc.Bay LIKE '%Z%' 
        OR loc.LocationNo LIKE 'FGI.ADT.Z%'  -- Z locations like FGI.ADT.ZD.04.06E
        OR loc.LocationNo LIKE 'FGI.10068%'  -- ✅ Include FGI.10068 locations (like FGI.10068.0.0.0)
    )
LEFT JOIN Plus.pls.CodeAddressDetails cad ON cad.AddressID = sh.AddressID
    AND cad.AddressType = 'ShipTo'
LEFT JOIN Plus.pls.SOShipmentInfo sos ON sos.SOHeaderID = sh.ID
LEFT JOIN pls.SOHeaderAttribute sha ON sh.ID = sha.SOHeaderID
LEFT JOIN pls.CodeAttribute cha ON cha.ID = sha.AttributeID AND cha.AttributeName = 'PICK_SLIP'
WHERE sh.ProgramID = 10068
  AND sh.CustomerReference LIKE '8%'
  AND cs.Description NOT IN ('CANCELED', 'SHIPPED')
  AND cs_line.Description NOT IN ('SHIPPED', 'CANCELED')
GROUP BY 
    sl.CreateDate,
    sh.CustomerReference, 
    sl.PartNo, 
    sh.AddressID,
    cad.Name,
    sl.QtyToShip, 
    sh.ID,
    cs.Description  -- ✅ Added cs.Description to GROUP BY
