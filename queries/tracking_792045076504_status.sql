-- Check if tracking number 792045076504 was dock logged and then received
SELECT
    dl.TrackingNo,
    dl.CreateDate AS DockLogDate,
    rh.CustomerReference AS ASN,
    CASE WHEN COUNT(pt.ID) > 0 THEN 'YES' ELSE 'NO' END AS WasReceived,
    COUNT(pt.ID) AS ReceiptCount,
    SUM(pt.Qty) AS TotalQtyReceived,
    MIN(pt.CreateDate) AS FirstReceiveDate,
    MAX(pt.CreateDate) AS LastReceiveDate
FROM Plus.pls.RODockLog dl
JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
LEFT JOIN Plus.pls.PartTransaction pt 
    ON pt.OrderHeaderID = rh.ID
    AND pt.ProgramID = 10068
LEFT JOIN Plus.pls.CodePartTransaction cpt 
    ON cpt.ID = pt.PartTransactionID
    AND cpt.Description = 'RO-RECEIVE'
WHERE dl.TrackingNo = '792045076504'
  AND rh.ProgramID = 10068
GROUP BY dl.TrackingNo, dl.CreateDate, rh.CustomerReference;

