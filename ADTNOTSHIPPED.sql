-- Received but NOT Shipped Yet
-- Shows: SKU, CR, SN, Qty Received (per serial), Total Received (per part), Total Shipped (per part), Qty Remaining (per part)
-- Filtered by PartNo attribute DISPOSITION = 'CR Program' (case insensitive)
-- NOTE: Receipts are per serial, Ships are aggregated by PartNo - math must match correctly

WITH Received AS (
     -- Get all receives (from ADTRECEIEVE logic) - ALL TIME - Individual serials
     SELECT 
     rec.CustomerReference AS ASN,
     rec.PartNo,
     rec.SerialNo,
     rec.Qty AS QtyReceived,
     rec.ProgramID

     FROM Plus.pls.PartTransaction AS rec
     JOIN Plus.pls.CodePartTransaction AS rcd ON rcd.ID = rec.PartTransactionID AND rcd.Description = 'RO-RECEIVE'
     JOIN Plus.pls.RODockLog AS dl ON dl.ID = rec.RODockLogID
     INNER JOIN Plus.pls.PartNoAttribute pna ON pna.PartNo = rec.PartNo AND pna.ProgramID = rec.ProgramID
     INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID 
         AND UPPER(LTRIM(RTRIM(ca.AttributeName))) = 'DISPOSITION'
         AND UPPER(LTRIM(RTRIM(pna.Value))) = 'CR PROGRAM'

     WHERE rec.ProgramID IN (10068, 10072) 
      AND rec.PartTransactionID = 1
     ),
ReceivedByPart AS (
     -- Aggregate received quantities by PartNo (to match shipped aggregation)
     SELECT 
     PartNo,
     ProgramID,
     SUM(QtyReceived) AS TotalQtyReceived
     FROM Received
     GROUP BY PartNo, ProgramID
     ),
Shipped AS (
     -- Get all ships (from ADTSHIP logic) - ALL TIME - Aggregated by PartNo
     SELECT 
     SOL.PartNo,
     SOH.ProgramID,
     SUM(CAST(SOL.QtyReserved AS BIGINT)) AS TotalQtyShipped

     FROM Plus.pls.SOHeader SOH 
     INNER JOIN Plus.pls.SOLine SOL ON SOL.SOHeaderID = SOH.ID
     WHERE SOH.ProgramID = 10068
       AND SOH.CustomerReference LIKE 'REY%'
     GROUP BY SOL.PartNo, SOH.ProgramID
     ),
RemainingByPart AS (
     -- Calculate remaining quantity per part
     SELECT 
     rec.PartNo,
     rec.ProgramID,
     rec.TotalQtyReceived,
     ISNULL(ship.TotalQtyShipped, 0) AS TotalQtyShipped,
     rec.TotalQtyReceived - ISNULL(ship.TotalQtyShipped, 0) AS QtyRemaining
     FROM ReceivedByPart rec
     LEFT JOIN Shipped ship ON ship.PartNo = rec.PartNo AND ship.ProgramID = rec.ProgramID
     WHERE rec.TotalQtyReceived - ISNULL(ship.TotalQtyShipped, 0) > 0  -- Only parts with remaining quantity
     )

SELECT 
    rec.PartNo AS SKU,
    rec.ASN AS CR,
    rec.SerialNo AS SN,
    rec.QtyReceived,
    rem.TotalQtyReceived,
    rem.TotalQtyShipped,
    rem.QtyRemaining,
    rec.ProgramID AS Program
FROM Received rec
INNER JOIN RemainingByPart rem ON rem.PartNo = rec.PartNo AND rem.ProgramID = rec.ProgramID
ORDER BY rec.ASN, rec.PartNo, rec.SerialNo;
