-- =====================================================
-- ALTERNATIVE APPROACHES FOR RECEIVING INFO
-- =====================================================

-- OPTION 2: Via RO Header (if receiving tracked at RO level)
SELECT TOP 10 
    dla.AttributeID, 
    dla.[Value] as SerialNumber,
    dl.*,
    
    -- RECEIVING FROM RO HEADER
    roh.ReceiveDate,
    roh.ReceivedQty,
    roh.CustomerReference,
    roh.CreateDate as ROCreateDate

FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
    LEFT JOIN Plus.pls.ROHeader roh ON roh.ID = dl.ROID  -- If ROID exists on dock log

WHERE dl.ProgramID = 10053;

-- OPTION 3: Via ASN/Receipt Tables (if separate receiving system)
SELECT TOP 10 
    dla.AttributeID, 
    dla.[Value] as SerialNumber,
    dl.*,
    
    -- ASN/RECEIPT INFORMATION  
    asn.ReceiveDate,
    asn.QtyReceived,
    asn.ASNNumber,
    asn.TrackingNumber

FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
    LEFT JOIN Plus.pls.ASN asn ON asn.SerialNumber = dla.[Value]  -- If ASN table exists

WHERE dl.ProgramID = 10053;

-- OPTION 4: Find Latest Receiving Transaction Per Serial
WITH LatestReceiving AS (
    SELECT 
        pt.SerialNo,
        pt.CreateDate as ReceiptDate,
        pt.Qty as QtyReceived,
        pt.PartNo,
        pt.CustomerReference,
        u.Username as ReceivedBy,
        ROW_NUMBER() OVER (PARTITION BY pt.SerialNo ORDER BY pt.CreateDate DESC) as rn
    FROM Plus.pls.PartTransaction pt
    JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    JOIN Plus.pls.[User] u ON u.ID = pt.UserID
    WHERE cpt.Description IN ('RO-RECEIVE', 'RECEIVE', 'ASN-RECEIVE')
      AND pt.ProgramID = 10053
)

SELECT TOP 10 
    dla.AttributeID, 
    dla.[Value] as SerialNumber,
    dl.*,
    
    -- LATEST RECEIVING INFO
    lr.ReceiptDate,
    lr.QtyReceived,
    lr.PartNo as ReceivedPartNo,
    lr.CustomerReference as ReceiptReference,
    lr.ReceivedBy

FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
    LEFT JOIN LatestReceiving lr ON lr.SerialNo = dla.[Value] AND lr.rn = 1

WHERE dl.ProgramID = 10053
ORDER BY dl.CreateDate DESC;






