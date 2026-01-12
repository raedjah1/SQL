-- Summary: Unique PartNos with Received/Shipped/Remaining totals
-- Shows: SKU, Total Received, Total Shipped, Qty Remaining
-- Filtered by PartNo attribute DISPOSITION = 'CR Program' (case insensitive)

WITH Received AS (
     -- Get all receives (from ADTRECEIEVE logic) - ALL TIME - Individual serials
     SELECT 
     rec.PartNo,
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
     -- Aggregate received quantities by PartNo
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
     )

SELECT 
    rec.PartNo AS SKU,
    rec.ProgramID AS Program,
    rec.TotalQtyReceived,
    ISNULL(ship.TotalQtyShipped, 0) AS TotalQtyShipped,
    rec.TotalQtyReceived - ISNULL(ship.TotalQtyShipped, 0) AS QtyRemaining
FROM ReceivedByPart rec
LEFT JOIN Shipped ship ON ship.PartNo = rec.PartNo AND ship.ProgramID = rec.ProgramID
WHERE rec.TotalQtyReceived - ISNULL(ship.TotalQtyShipped, 0) > 0  -- Only parts with remaining quantity
ORDER BY rec.PartNo;

