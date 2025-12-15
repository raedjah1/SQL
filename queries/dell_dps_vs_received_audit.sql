-- ================================================
-- DELL DPS vs Received Quantity Audit Report
-- ================================================
-- Purpose: Compare expected quantity (DPS) vs received quantity to audit
--          employee receiving accuracy and identify partial refund issues
-- Program: DELL (ProgramID: 10053)
-- Use Case: Identify cases where customer returned multiple items but only
--           some were received (e.g., 2 printers returned, only 1 received)
-- Example: Customer Reference RXTSP250910092038, Tracking 791907810771
--          Expected 2 items, only 1 received = partial refund issue
--
-- USAGE:
--   - By default, shows ONLY discrepancies (UNDER RECEIVED and OVER RECEIVED)
--   - To see ALL orders including matches, comment out line 120
--   - To search for specific tracking: Add "AND dl.TrackingNo = '791907810771'"
--   - To search for specific CustomerReference: Add "AND rh.CustomerReference = 'RXTSP250910092038'"
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
    rol.PartNo AS PartNo,  -- Keep part number for reference
    
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
    
    -- Discrepancy Status (for filtering)
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
    cad.Name AS OrgName

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
  AND rol.QtyToReceive > 0  -- Only show lines with expected quantity
  
  -- Filter for discrepancies only - shows UNDER RECEIVED and OVER RECEIVED cases
  -- Comment out this line to see ALL orders (including matches)
  AND CAST(rol.QtyToReceive AS BIGINT) <> CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT)

ORDER BY 
    -- Prioritize UNDER RECEIVED cases first (most critical for refund issues)
    CASE 
        WHEN CAST(rol.QtyToReceive AS BIGINT) > CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) THEN 1
        ELSE 2
    END,
    rh.CustomerReference,
    COALESCE(dl.TrackingNo, crst.TrackingNo, 'N/A'),  -- Group by tracking number
    rol.PartNo,
    rh.CreateDate DESC;

-- ================================================
-- SUMMARY: Total Discrepancies by Status
-- ================================================
SELECT 
    CASE 
        WHEN CAST(rol.QtyToReceive AS BIGINT) > CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) THEN 'UNDER RECEIVED'
        WHEN CAST(rol.QtyToReceive AS BIGINT) < CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) THEN 'OVER RECEIVED'
        ELSE 'MATCH'
    END AS ReceiptStatus,
    COUNT(*) AS OrderLineCount,
    SUM(CAST(rol.QtyToReceive AS BIGINT)) AS TotalExpected,
    SUM(CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT)) AS TotalReceived,
    SUM(CAST(rol.QtyToReceive AS BIGINT) - CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT)) AS TotalDifference

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID

OUTER APPLY (
    SELECT SUM(CAST(pt.Qty AS BIGINT)) AS ActualReceived
    FROM Plus.pls.PartTransaction pt
    INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    WHERE pt.OrderHeaderID = rh.ID
      AND pt.OrderLineID = rol.ID
      AND pt.ProgramID = rh.ProgramID
      AND cpt.Description = 'RO-RECEIVE'
) AS ReceivedQty

WHERE rh.ProgramID = 10053
  AND rol.QtyToReceive > 0

GROUP BY 
    CASE 
        WHEN CAST(rol.QtyToReceive AS BIGINT) > CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) THEN 'UNDER RECEIVED'
        WHEN CAST(rol.QtyToReceive AS BIGINT) < CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) THEN 'OVER RECEIVED'
        ELSE 'MATCH'
    END

ORDER BY 
    MIN(CASE 
        WHEN CAST(rol.QtyToReceive AS BIGINT) > CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) THEN 1
        WHEN CAST(rol.QtyToReceive AS BIGINT) < CAST(COALESCE(ReceivedQty.ActualReceived, 0) AS BIGINT) THEN 2
        ELSE 3
    END);

