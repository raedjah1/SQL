-- Find customer references and check if they were shipped
-- Customer References: 1028622756, 1028622757, 1028622758
SELECT 
    'SOHeader' AS SourceTable,
    soh.ID AS OrderID,
    soh.CustomerReference,
    soh.ProgramID,
    cs.Description AS Status,
    soh.CreateDate,
    soh.LastActivityDate,
    -- Check if shipped
    CASE 
        WHEN cs.Description = 'SHIPPED' THEN 'YES - Status = SHIPPED'
        ELSE 'NO - Status = ' + cs.Description
    END AS ShippedStatus,
    -- Shipping info
    sos.TrackingNo,
    sos.Carrier,
    sos.ShipmentDate,
    -- Line items
    sol.PartNo,
    sol.QtyToShip,
    sol.QtyReserved AS QtyShipped,
    -- Shipped units
    su.SerialNo AS ShippedSerialNo,
    su.CreateDate AS ShippedDate,
    -- Check for SO-SHIP transactions
    CASE 
        WHEN pt_ship.ID IS NOT NULL THEN 'YES - Has SO-SHIP Transaction'
        ELSE 'NO - No SO-SHIP Transaction'
    END AS HasShipTransaction
FROM Plus.pls.SOHeader soh
    LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = soh.StatusID
    LEFT JOIN Plus.pls.SOLine sol ON sol.SOHeaderID = soh.ID
    LEFT JOIN Plus.pls.SOShipmentInfo sos ON sos.SOHeaderID = soh.ID
    LEFT JOIN Plus.pls.SOUnit su ON su.SOShipmentInfoID = sos.ID
    -- Check for SO-SHIP transactions in PartTransaction
    LEFT JOIN (
        SELECT DISTINCT pt.CustomerReference, pt.ID
        FROM Plus.pls.PartTransaction pt
        INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
        WHERE pt.CustomerReference IN ('1028622756', '1028622757', '1028622758')
            AND pt.ProgramID = 10053
            AND cpt.Description = 'SO-SHIP'
    ) pt_ship ON pt_ship.CustomerReference = soh.CustomerReference
WHERE soh.CustomerReference IN ('1028622756', '1028622757', '1028622758')
    AND soh.ProgramID = 10053  -- Dell program (based on Picklist.sql)
ORDER BY soh.CustomerReference, soh.CreateDate DESC, sol.PartNo;

-- ================================================
-- ALSO CHECK PartTransaction for shipping transactions
-- ================================================
SELECT 
    'PartTransaction' AS SourceTable,
    pt.CustomerReference,
    pt.SerialNo,
    pt.PartNo,
    cpt.Description AS TransactionType,
    pt.CreateDate AS TransactionDate,
    pt.Location,
    pt.ToLocation,
    u.Username AS TransactionUser
FROM Plus.pls.PartTransaction pt
    INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    LEFT JOIN Plus.pls.[User] u ON u.ID = pt.UserID
WHERE pt.CustomerReference IN ('1028622756', '1028622757', '1028622758')
    AND pt.ProgramID = 10053
    AND cpt.Description IN ('SO-SHIP', 'SO-CSCLOSE', 'SO-CLOSE')
ORDER BY pt.CustomerReference, pt.CreateDate DESC;

