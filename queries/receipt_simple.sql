SELECT
    pt.CustomerReference AS ASN,
    dl.TrackingNo AS TrackingNumber,
    u.Username,
    pt.Qty,
    pt.PartNo
FROM Plus.pls.PartTransaction pt
JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
JOIN Plus.pls.[User] u ON u.ID = pt.UserID
LEFT JOIN Plus.pls.RODockLog dl ON dl.ID = pt.RODockLogID
WHERE pt.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE';

