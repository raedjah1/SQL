-- Check if tracking number 792045076504 was fully received
-- Compares expected quantity (from ROLine) vs received quantity (from PartTransaction RO-RECEIVE)

SELECT
    dl.TrackingNo,
    rh.CustomerReference AS ASN,
    rh.ID AS ROHeaderID,
    rh.StatusID,
    cs.Description AS Status,
    
    -- Expected quantities from ROLine
    COUNT(DISTINCT rl.ID) AS ExpectedLineCount,
    SUM(rl.Qty) AS ExpectedTotalQty,
    
    -- Received quantities from PartTransaction
    COUNT(DISTINCT pt.ID) AS ReceiptTransactionCount,
    SUM(pt.Qty) AS ReceivedTotalQty,
    
    -- Comparison
    CASE 
        WHEN SUM(rl.Qty) IS NULL THEN 'NO ORDER LINES FOUND'
        WHEN SUM(pt.Qty) IS NULL THEN 'NOT RECEIVED'
        WHEN SUM(pt.Qty) >= SUM(rl.Qty) THEN 'FULLY RECEIVED'
        ELSE 'PARTIALLY RECEIVED'
    END AS ReceiptStatus,
    
    -- Difference
    SUM(rl.Qty) - COALESCE(SUM(pt.Qty), 0) AS QtyRemaining,
    
    -- Dates
    MIN(dl.CreateDate) AS FirstDockLogDate,
    MIN(pt.CreateDate) AS FirstReceiveDate,
    MAX(pt.CreateDate) AS LastReceiveDate,
    lastROLine.CreateDate AS ASNProcessedDate

FROM Plus.pls.RODockLog dl
JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
JOIN Plus.pls.CodeStatus cs ON cs.ID = rh.StatusID
LEFT JOIN Plus.pls.ROLine rl ON rl.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.PartTransaction pt 
    ON pt.OrderHeaderID = rh.ID
    AND pt.ProgramID = 10068
LEFT JOIN Plus.pls.CodePartTransaction cpt 
    ON cpt.ID = pt.PartTransactionID
    AND cpt.Description = 'RO-RECEIVE'
OUTER APPLY (
    SELECT TOP 1 rl_last.CreateDate
    FROM Plus.pls.ROLine rl_last
    WHERE rl_last.ROHeaderID = rh.ID
    ORDER BY rl_last.ID DESC
) lastROLine
WHERE dl.TrackingNo = '792045076504'
  AND rh.ProgramID = 10068
GROUP BY dl.TrackingNo, rh.CustomerReference, rh.ID, rh.StatusID, cs.Description, lastROLine.CreateDate
ORDER BY FirstDockLogDate;

