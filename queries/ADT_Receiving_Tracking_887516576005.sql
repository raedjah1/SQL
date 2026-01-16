-- ADT Receiving Report for Tracking Number: 887516576005
-- Shows all parts received for this specific tracking number

-- ============================================================================
-- Detailed View: All individual receiving transactions
-- ============================================================================
SELECT 
    dl.TrackingNo AS TrackingNumber,
    rec.CreateDate AS DateReceived,
    rec.PartNo,
    rec.SerialNo,
    rec.Qty AS QuantityReceived,
    rol.QtyToReceive AS QuantityExpected,
    rec.CustomerReference AS ASN,
    cpt.Description AS TransactionType,
    dl.ID AS DockLogID,
    rh.ID AS RMAHeaderID,
    rh.CustomerReference AS RMANumber,
    u.Username AS ReceivedBy
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
LEFT JOIN Plus.pls.ROLine rol ON rol.ID = rec.OrderLineID AND rol.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.[User] u ON u.ID = rec.UserID
WHERE rec.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND dl.TrackingNo = '887516576005'
ORDER BY rec.CreateDate DESC, rec.PartNo, rec.SerialNo;

-- ============================================================================
-- Summary by Part Number (Total quantities per part)
-- ============================================================================
SELECT 
    dl.TrackingNo AS TrackingNumber,
    rec.PartNo,
    MAX(rol.QtyToReceive) AS QuantityExpected,
    SUM(rec.Qty) AS TotalQuantityReceived,
    COUNT(DISTINCT rec.SerialNo) AS UniqueSerialCount,
    COUNT(*) AS TransactionCount,
    MIN(rec.CreateDate) AS FirstReceivedDate,
    MAX(rec.CreateDate) AS LastReceivedDate,
    rec.CustomerReference AS ASN,
    rh.ID AS RMAHeaderID
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
LEFT JOIN Plus.pls.ROLine rol ON rol.ID = rec.OrderLineID AND rol.ROHeaderID = rh.ID AND rol.PartNo = rec.PartNo
WHERE rec.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND dl.TrackingNo = '887516576005'
GROUP BY 
    dl.TrackingNo,
    rec.PartNo,
    rec.CustomerReference,
    rh.ID
ORDER BY rec.PartNo;

-- ============================================================================
-- Grand Total Summary
-- ============================================================================
SELECT 
    dl.TrackingNo AS TrackingNumber,
    COUNT(DISTINCT rec.PartNo) AS UniquePartCount,
    COUNT(DISTINCT rec.SerialNo) AS UniqueSerialCount,
    SUM(ISNULL(rol.QtyToReceive, 0)) AS TotalQuantityExpected,
    SUM(rec.Qty) AS TotalUnitsReceived,
    COUNT(*) AS TotalTransactions,
    MIN(rec.CreateDate) AS FirstReceivedDate,
    MAX(rec.CreateDate) AS LastReceivedDate,
    rec.CustomerReference AS ASN,
    rh.ID AS RMAHeaderID
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
LEFT JOIN Plus.pls.ROLine rol ON rol.ID = rec.OrderLineID AND rol.ROHeaderID = rh.ID AND rol.PartNo = rec.PartNo
WHERE rec.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND dl.TrackingNo = '887516576005'
GROUP BY 
    dl.TrackingNo,
    rec.CustomerReference,
    rh.ID;

