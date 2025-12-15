-- =====================================================
-- INVESTIGATE DOCK LOG TRANSACTION ID CONNECTIONS
-- =====================================================
-- Check what RODockLog transaction fields connect to

-- FIRST: Look at RODockLog structure and key fields
SELECT TOP 5 
    dl.ID as DockLogID,
    dl.TransactionID,  -- This might be the key!
    dl.ROID,
    dl.PartTransactionID,  -- This could link to PartTransaction
    dl.CreateDate,
    dl.ProgramID,
    dla.AttributeID,
    dla.[Value] as SerialNumber
FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
WHERE dl.ProgramID = 10053
ORDER BY dl.CreateDate DESC;

-- OPTION A: If PartTransactionID exists, check PartTransaction connection
SELECT TOP 10
    dl.ID as DockLogID,
    dla.[Value] as SerialNumber,
    dl.CreateDate as DockLogDate,
    
    -- PART TRANSACTION INFO (if PartTransactionID exists)
    pt.ID as PartTransactionID,
    pt.CreateDate as TransactionDate,
    pt.Qty,
    pt.PartNo,
    pt.SerialNo as PT_SerialNo,
    pt.CustomerReference,
    cpt.Description as TransactionType,
    u.Username as Operator

FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
    LEFT JOIN Plus.pls.PartTransaction pt ON pt.ID = dl.PartTransactionID  -- Check if this field exists
    LEFT JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    LEFT JOIN Plus.pls.[User] u ON u.ID = pt.UserID
WHERE dl.ProgramID = 10053
ORDER BY dl.CreateDate DESC;

-- OPTION B: If TransactionID exists, check what it connects to
SELECT TOP 10
    dl.ID as DockLogID,
    dl.TransactionID,
    dla.[Value] as SerialNumber,
    dl.CreateDate as DockLogDate,
    
    -- CHECK DIFFERENT TRANSACTION CONNECTIONS
    pt1.CreateDate as PT_CreateDate,
    pt1.Qty as PT_Qty,
    pt1.PartNo as PT_PartNo,
    cpt1.Description as PT_Type,
    u1.Username as PT_Operator

FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
    LEFT JOIN Plus.pls.PartTransaction pt1 ON pt1.ID = dl.TransactionID  -- Try TransactionID
    LEFT JOIN Plus.pls.CodePartTransaction cpt1 ON cpt1.ID = pt1.PartTransactionID
    LEFT JOIN Plus.pls.[User] u1 ON u1.ID = pt1.UserID
WHERE dl.ProgramID = 10053
ORDER BY dl.CreateDate DESC;

-- OPTION C: Check ROHeader connection (if ROID exists)
SELECT TOP 10
    dl.ID as DockLogID,
    dl.ROID,
    dla.[Value] as SerialNumber,
    dl.CreateDate as DockLogDate,
    
    -- RO HEADER INFO
    roh.ID as ROHeaderID,
    roh.CreateDate as ROCreateDate,
    roh.CustomerReference as RO_CustomerRef,
    roh.ReceivedDate,
    roh.ReceivedQty

FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
    LEFT JOIN Plus.pls.ROHeader roh ON roh.ID = dl.ROID  -- Check if ROID connects to ROHeader
WHERE dl.ProgramID = 10053
ORDER BY dl.CreateDate DESC;






