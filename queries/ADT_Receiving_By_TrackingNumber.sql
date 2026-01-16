-- ADT Receiving Report by Tracking Number
-- Shows all parts received for each tracking number with quantities
-- ProgramID = 10068 (ADT)

SELECT 
    dl.TrackingNo AS TrackingNumber,
    rec.CreateDate AS DateReceived,
    rec.PartNo,
    rec.SerialNo,
    rec.Qty AS QuantityReceived,
    rec.CustomerReference AS ASN,
    cpt.Description AS TransactionType,
    dl.ID AS DockLogID,
    rh.ID AS RMAHeaderID,
    rh.CustomerReference AS RMANumber,
    u.Username AS ReceivedBy,
    rec.LocationNo AS ReceivingLocation
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
LEFT JOIN Plus.pls.[User] u ON u.ID = rec.UserID
WHERE rec.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND dl.TrackingNo IS NOT NULL
ORDER BY dl.TrackingNo, rec.CreateDate DESC, rec.PartNo;

-- ============================================================================
-- Summary by Tracking Number (Total quantities per part)
-- ============================================================================
SELECT 
    dl.TrackingNo AS TrackingNumber,
    MIN(rec.CreateDate) AS FirstReceivedDate,
    MAX(rec.CreateDate) AS LastReceivedDate,
    rec.PartNo,
    SUM(rec.Qty) AS TotalQuantityReceived,
    COUNT(DISTINCT rec.SerialNo) AS UniqueSerialCount,
    COUNT(*) AS TransactionCount,
    rec.CustomerReference AS ASN,
    rh.ID AS RMAHeaderID
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
WHERE rec.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND dl.TrackingNo IS NOT NULL
GROUP BY 
    dl.TrackingNo,
    rec.PartNo,
    rec.CustomerReference,
    rh.ID
ORDER BY dl.TrackingNo, rec.PartNo;

-- ============================================================================
-- Grand Total by Tracking Number (All parts combined)
-- ============================================================================
SELECT 
    dl.TrackingNo AS TrackingNumber,
    MIN(rec.CreateDate) AS FirstReceivedDate,
    MAX(rec.CreateDate) AS LastReceivedDate,
    COUNT(DISTINCT rec.PartNo) AS UniquePartCount,
    COUNT(DISTINCT rec.SerialNo) AS UniqueSerialCount,
    SUM(rec.Qty) AS TotalUnitsReceived,
    COUNT(*) AS TotalTransactions,
    rec.CustomerReference AS ASN,
    rh.ID AS RMAHeaderID
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
WHERE rec.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND dl.TrackingNo IS NOT NULL
GROUP BY 
    dl.TrackingNo,
    rec.CustomerReference,
    rh.ID
ORDER BY dl.TrackingNo;

