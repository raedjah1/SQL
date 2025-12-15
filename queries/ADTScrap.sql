CREATE OR ALTER VIEW [rpt].[ADTScrap] AS

SELECT
    ps.SerialNo,
    ps.PartNo,
    pl.LocationNo,
    pl.Warehouse,
    ps.CreateDate AS ScrapDate,
    CAST(ps.CreateDate AS DATE) AS ScrapDateOnly,
    
    -- Get CustomerReference from most recent transaction (used for shipping lookup)
    pt_ref.CustomerReference,
    
    -- Shipped status: Check if there's a SO-SHIP transaction or shipment info
    CASE 
        WHEN pt_ship.ID IS NOT NULL OR ship_info.TrackingNumber IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS Shipped,
    
    -- Get shipping info if available
    ship_info.TrackingNumber,
    ship_info.Carrier,
     
    ps.ProgramID,
    ps.LastActivityDate

FROM Plus.pls.PartSerial ps
INNER JOIN Plus.pls.PartLocation pl ON pl.ID = ps.LocationID

-- ✅ OPTIMIZED: Get CustomerReference once via OUTER APPLY
OUTER APPLY (
    SELECT TOP 1 pt.CustomerReference
    FROM Plus.pls.PartTransaction pt
    WHERE pt.SerialNo = ps.SerialNo
      AND pt.ProgramID = 10068
      AND pt.CustomerReference IS NOT NULL
    ORDER BY pt.CreateDate DESC
) pt_ref

-- ✅ OPTIMIZED: Check for SO-SHIP transaction once
OUTER APPLY (
    SELECT TOP 1 pt.ID
    FROM Plus.pls.PartTransaction pt
    INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    WHERE pt.SerialNo = ps.SerialNo
      AND pt.ProgramID = 10068
      AND cpt.Description = 'SO-SHIP'
) pt_ship

-- ✅ OPTIMIZED: Get shipping info once via OUTER APPLY
OUTER APPLY (
    SELECT TOP 1 
        sos.TrackingNo AS TrackingNumber,
        sos.Carrier
    FROM Plus.pls.SOHeader sh
    INNER JOIN Plus.pls.SOShipmentInfo sos ON sos.SOHeaderID = sh.ID
    WHERE sh.CustomerReference = pt_ref.CustomerReference
      AND sh.ProgramID = 10068
      AND sos.TrackingNo IS NOT NULL
    ORDER BY sos.ShipmentDate DESC
) ship_info

WHERE ps.ProgramID = 10068
  AND pl.LocationNo LIKE 'SCRAP.%'
  -- ✅ OPTIMIZED: 7-day date filter (last 7 days)
  AND (ps.CreateDate >= DATEADD(DAY, -7, GETDATE()) 
       OR ps.LastActivityDate >= DATEADD(DAY, -7, GETDATE()))

