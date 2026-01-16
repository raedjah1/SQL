-- Find all transactions related to a specific serial number, ASN, RMA, or tracking number
-- Use this query to trace the complete transaction history for a specific unit or order

-- ============================================================================
-- ALL TRANSACTIONS RELATED TO SPECIFIC IDENTIFIERS
-- ============================================================================
-- Replace the values below with your specific identifiers:
--   @SerialNo: EXADT01062026163944720172608342
--   @ASN: EX2506388
--   @RMAHeaderID: 5666031
--   @TrackingNumber: 887396457970
--   @DockLogID: 4472075
--   @PartNo: 5828V

SELECT 
    pt.CreateDate AS TransactionDate,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty AS QuantityMoved,
    cpt.Description AS TransactionType,
    pt.CustomerReference AS ASN,
    u.Username AS MovedBy,
    pt.OrderHeaderID AS RMAHeaderID,
    rh.CustomerReference AS RMANumber,
    dl.TrackingNo AS TrackingNumber,
    pt.RODockLogID AS DockLogID,
    pt.Location AS FromLocation,
    pt.ToLocation AS ToLocation,
    pt.PalletBoxNo,
    pt.ToPalletBoxNo,
    pt.LotNo,
    pt.Reason AS TransactionReason,
    pt.ProgramID,
    -- Current status information
    ps_current.LocationID AS CurrentLocationID,
    pl_current.LocationNo AS CurrentLocation,
    pl_current.Warehouse AS CurrentWarehouse,
    pq_current.AvailableQty AS CurrentAvailableQty,
    cc_current.Description AS CurrentConfiguration
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
LEFT JOIN Plus.pls.[User] u ON u.ID = pt.UserID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = pt.OrderHeaderID AND pt.OrderType = 'RO'
LEFT JOIN Plus.pls.RODockLog dl ON dl.ID = pt.RODockLogID
-- Current location/status
LEFT JOIN Plus.pls.PartSerial ps_current ON ps_current.SerialNo = pt.SerialNo 
    AND ps_current.ProgramID = pt.ProgramID
LEFT JOIN Plus.pls.PartLocation pl_current ON pl_current.ID = ps_current.LocationID
LEFT JOIN Plus.pls.PartQty pq_current ON pq_current.PartNo = pt.PartNo 
    AND pq_current.ProgramID = pt.ProgramID
    AND pq_current.LocationID = ps_current.LocationID
LEFT JOIN Plus.pls.CodeConfiguration cc_current ON cc_current.ID = pq_current.ConfigurationID
WHERE pt.ProgramID = 10068  -- ADT program
  AND (
    -- Match by Serial Number
    pt.SerialNo = 'EXADT01062026163944720172608342'
    -- Match by ASN/CustomerReference
    OR pt.CustomerReference = 'EX2506388'
    -- Match by RMA Header ID
    OR pt.OrderHeaderID = 5666031
    -- Match by Tracking Number (via DockLog)
    OR EXISTS (
        SELECT 1 
        FROM Plus.pls.RODockLog dl_check 
        WHERE dl_check.ID = pt.RODockLogID 
          AND dl_check.TrackingNo = '887396457970'
    )
    -- Match by DockLog ID
    OR pt.RODockLogID = 4472075
    -- Match by Part Number + ASN (to catch all parts in same order)
    OR (pt.PartNo = '5828V' AND pt.CustomerReference = 'EX2506388')
  )
ORDER BY pt.CreateDate DESC, pt.SerialNo, pt.PartNo;

-- ============================================================================
-- SUMMARY: Transaction count by type and user
-- ============================================================================
SELECT 
    cpt.Description AS TransactionType,
    u.Username AS MovedBy,
    COUNT(*) AS TransactionCount,
    SUM(pt.Qty) AS TotalQuantityMoved,
    MIN(pt.CreateDate) AS FirstTransaction,
    MAX(pt.CreateDate) AS LastTransaction
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
LEFT JOIN Plus.pls.[User] u ON u.ID = pt.UserID
WHERE pt.ProgramID = 10068
  AND (
    pt.SerialNo = 'EXADT01062026163944720172608342'
    OR pt.CustomerReference = 'EX2506388'
    OR pt.OrderHeaderID = 5666031
    OR EXISTS (
        SELECT 1 
        FROM Plus.pls.RODockLog dl_check 
        WHERE dl_check.ID = pt.RODockLogID 
          AND dl_check.TrackingNo = '887396457970'
    )
    OR pt.RODockLogID = 4472075
    OR (pt.PartNo = '5828V' AND pt.CustomerReference = 'EX2506388')
  )
GROUP BY cpt.Description, u.Username
ORDER BY TransactionCount DESC, TransactionType;

