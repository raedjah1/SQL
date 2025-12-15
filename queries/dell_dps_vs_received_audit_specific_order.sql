-- ================================================
-- DELL DPS vs Received - SPECIFIC ORDER QUERY
-- ================================================
-- Purpose: Query for specific order to audit receiving discrepancies
-- Example Order: 
--   CustomerReference: RXTSP250910092038
--   Tracking: 791907810771
--   Issue: Expected 2 items, only 1 received (partial refund processed)
-- ================================================

SELECT 
    -- Column order matching your example format
    rh.CustomerReference AS FusionDetail,
    
    -- Service Tag (if available from attributes, show #N/A if not found)
    COALESCE(
        (SELECT TOP 1 rua.Value 
         FROM Plus.pls.ROUnit ru2
         INNER JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru2.ID
         INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = rua.AttributeID
         WHERE ru2.ROLineID = rol.ID 
           AND ca.AttributeName = 'SERVICETAG'
         ORDER BY rua.ID DESC),
        '#N/A'
    ) AS ServiceTag,
    
    -- Part Information
    COALESCE(pn.Description, rol.PartNo) AS Item,
    rol.PartNo AS PartNo,
    
    -- Tracking Information
    COALESCE(dl.TrackingNo, crst.TrackingNo, 'N/A') AS Tracking,
    
    -- Dock Logged Date (formatted as in example: 8/27/2025)
    CASE 
        WHEN dl.CreateDate IS NOT NULL 
        THEN FORMAT(dl.CreateDate, 'M/d/yyyy')
        ELSE NULL
    END AS DockLogged,
    
    -- Quantity Information - DPS (Expected quantity from ROLine)
    CAST(rol.QtyToReceive AS BIGINT) AS DPS,
    
    -- Actual Received Quantity from PartTransaction (RO-RECEIVE)
    CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) AS Received,
    
    -- Discrepancy Calculation
    CAST(rol.QtyToReceive AS BIGINT) - CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) AS QtyDifference,
    
    -- Discrepancy Status
    CASE 
        WHEN CAST(rol.QtyToReceive AS BIGINT) > CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) THEN 'UNDER RECEIVED'
        WHEN CAST(rol.QtyToReceive AS BIGINT) < CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) THEN 'OVER RECEIVED'
        ELSE 'MATCH'
    END AS ReceiptStatus,
    
    -- Additional fields for audit context
    rh.ID AS ROHeaderID,
    rol.ID AS ROLineID,
    cs.Description AS ASNStatus,
    rh.CreateDate AS OrderCreateDate,
    rh.LastActivityDate AS LastActivityDate,
    
    -- Return Type
    (SELECT TOP 1 rha.Value 
     FROM Plus.pls.ROHeaderAttribute rha
     INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = rha.AttributeID
     WHERE rha.ROHeaderID = rh.ID 
       AND ca.AttributeName = 'RETURNTYPE'
     ORDER BY rha.ID DESC) AS ReturnType,
    
    -- User who created the order
    u.Username AS CreatedBy,
    
    -- Address Information
    cad.Name AS OrgName,
    cad.Address1,
    cad.City,
    cad.State,
    cad.Zip

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
INNER JOIN Plus.pls.CodeStatus cs ON cs.ID = rh.StatusID
LEFT JOIN Plus.pls.PartNo pn ON pn.PartNo = rol.PartNo
LEFT JOIN Plus.pls.[User] u ON u.ID = rh.UserID
LEFT JOIN Plus.pls.CodeAddressDetails cad ON cad.AddressID = rh.AddressID AND cad.AddressType = 'ShipTo'

-- Get tracking number from RODockLog (preferred) or CarrierResult
OUTER APPLY (
    SELECT TOP 1 dlx.TrackingNo, dlx.CreateDate
    FROM Plus.pls.RODockLog dlx 
    WHERE dlx.ROHeaderID = rh.ID 
    ORDER BY dlx.ID DESC
) AS dl

OUTER APPLY (
    SELECT TOP 1 crst1.TrackingNo
    FROM Plus.pls.CarrierResult crst1 
    WHERE crst1.OrderHeaderID = rh.ID 
      AND crst1.ProgramID = rh.ProgramID 
      AND crst1.OrderType = 'RO' 
    ORDER BY crst1.ID DESC
) AS crst

-- Calculate actual received quantity from PartTransaction (RO-RECEIVE)
OUTER APPLY (
    SELECT SUM(CAST(pt.Qty AS BIGINT)) AS ActualReceived
    FROM Plus.pls.PartTransaction pt
    INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    WHERE pt.OrderHeaderID = rh.ID
      AND pt.OrderLineID = rol.ID
      AND pt.ProgramID = rh.ProgramID
      AND cpt.Description = 'RO-RECEIVE'
) AS ReceivedQty

WHERE rh.ProgramID = 10053  -- DELL program
  AND rol.QtyToReceive > 0
  
  -- Filter for specific order - use CustomerReference OR Tracking number
  AND (
      rh.CustomerReference = 'RXTSP250910092038'
      OR COALESCE(dl.TrackingNo, crst.TrackingNo) = '791907810771'
      OR rh.ID = 214703739  -- If DPS value is actually the ROHeaderID
  )

ORDER BY 
    rh.CustomerReference,
    rol.PartNo,
    rh.CreateDate DESC;

-- ================================================
-- DETAILED BREAKDOWN: Show all PartTransactions for this order
-- ================================================
SELECT 
    'PART TRANSACTION DETAIL' AS ReportSection,
    rh.CustomerReference AS FusionDetail,
    rh.ID AS ROHeaderID,
    rol.ID AS ROLineID,
    rol.PartNo,
    pn.Description AS ItemDescription,
    pt.SerialNo,
    pt.Qty AS TransactionQty,
    cpt.Description AS TransactionType,
    pt.CreateDate AS TransactionDate,
    pt.Username AS TransactionUser,
    COALESCE(dl.TrackingNo, crst.TrackingNo, 'N/A') AS Tracking

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
INNER JOIN Plus.pls.PartTransaction pt ON pt.OrderHeaderID = rh.ID AND pt.OrderLineID = rol.ID
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
LEFT JOIN Plus.pls.PartNo pn ON pn.PartNo = rol.PartNo

OUTER APPLY (
    SELECT TOP 1 dlx.TrackingNo
    FROM Plus.pls.RODockLog dlx 
    WHERE dlx.ROHeaderID = rh.ID 
    ORDER BY dlx.ID DESC
) AS dl

OUTER APPLY (
    SELECT TOP 1 crst1.TrackingNo
    FROM Plus.pls.CarrierResult crst1 
    WHERE crst1.OrderHeaderID = rh.ID 
      AND crst1.ProgramID = rh.ProgramID 
      AND crst1.OrderType = 'RO' 
    ORDER BY crst1.ID DESC
) AS crst

WHERE rh.ProgramID = 10053
  AND (
      rh.CustomerReference = 'RXTSP250910092038'
      OR COALESCE(dl.TrackingNo, crst.TrackingNo) = '791907810771'
      OR rh.ID = 214703739
  )

ORDER BY 
    pt.CreateDate DESC,
    cpt.Description;











