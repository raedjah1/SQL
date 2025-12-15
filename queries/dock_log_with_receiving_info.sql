-- =====================================================
-- DOCK LOG WITH RECEIVING INFORMATION
-- =====================================================
-- Adds receipt date, qty received, etc. to dock logged units

-- OPTION 1: Via Part Transaction (Receiving Events)
SELECT TOP 10 
    dla.AttributeID, 
    dla.[Value] as SerialNumber,
    dl.*,
    
    -- RECEIVING INFORMATION
    pt_receive.CreateDate as ReceiptDate,
    pt_receive.Qty as QtyReceived,
    pt_receive.PartNo as ReceivedPartNo,
    pt_receive.CustomerReference as ReceiptReference,
    cpt_receive.Description as ReceiveTransactionType,
    u_receive.Username as ReceivedByOperator

FROM Plus.pls.RODockLog dl

    LEFT JOIN Plus.pls.RODockLogAttribute dla
        ON dla.RODockLogID = dl.ID
        AND dla.AttributeID = 627  -- Serial Number attribute

    -- JOIN TO RECEIVING TRANSACTIONS
    LEFT JOIN Plus.pls.PartTransaction pt_receive
        ON pt_receive.SerialNo = dla.[Value]  -- Match by serial number
        AND pt_receive.ProgramID = dl.ProgramID

    LEFT JOIN Plus.pls.CodePartTransaction cpt_receive
        ON cpt_receive.ID = pt_receive.PartTransactionID
        AND cpt_receive.Description IN ('RO-RECEIVE', 'RECEIVE', 'ASN-RECEIVE')  -- Receiving codes

    LEFT JOIN Plus.pls.[User] u_receive
        ON u_receive.ID = pt_receive.UserID

WHERE dl.ProgramID = 10053
ORDER BY dl.CreateDate DESC, pt_receive.CreateDate DESC;






