-- =====================================================
-- INVESTIGATE PART TRANSACTION CODES (CODE 1 = RECEIPT)
-- =====================================================

-- Check what PartTransactionID codes exist and their meanings
SELECT 
    cpt.ID as PartTransactionID,
    cpt.Code,
    cpt.Description,
    COUNT(*) as TransactionCount
FROM Plus.pls.CodePartTransaction cpt
    LEFT JOIN Plus.pls.PartTransaction pt ON pt.PartTransactionID = cpt.ID
WHERE pt.ProgramID = 10053
GROUP BY cpt.ID, cpt.Code, cpt.Description
ORDER BY cpt.ID;

-- Test your exact query to see what it returns
SELECT TOP 10
    dla.AttributeID,
    dla.[Value] as SerialNumber,
    dl.CreateDate as DockLogDate,
    dl.ID as DockLogID,
    pt.Qty AS ReceivedQty,
    pt.CreateDate AS ReceiptDate,
    pt.PartNo,
    pt.CustomerReference,
    cpt.Description as TransactionType
FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
    LEFT JOIN Plus.pls.PartTransaction pt ON pt.RODockLogID = dl.ID 
                                          AND pt.ProgramID = dl.ProgramID 
                                          AND pt.PartTransactionID = 1  -- receipt txn
    LEFT JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE dl.ProgramID = 10053 
  AND dla.AttributeID = 627
ORDER BY dl.CreateDate DESC;

-- Check if there are other transaction types for same dock log entries
SELECT TOP 10
    dla.[Value] as SerialNumber,
    dl.ID as DockLogID,
    pt.PartTransactionID,
    cpt.Description as TransactionType,
    pt.CreateDate,
    pt.Qty
FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
    LEFT JOIN Plus.pls.PartTransaction pt ON pt.RODockLogID = dl.ID AND pt.ProgramID = dl.ProgramID
    LEFT JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE dl.ProgramID = 10053 
  AND dla.AttributeID = 627
  AND pt.PartTransactionID IS NOT NULL
ORDER BY dla.[Value], pt.CreateDate;

-- See what Code 1 actually says in the lookup table
SELECT 
    ID,
    Code, 
    Description,
    CodeType
FROM Plus.pls.CodePartTransaction 
WHERE ID = 1;






