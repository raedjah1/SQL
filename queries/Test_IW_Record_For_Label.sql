-- ============================================
-- TEST QUERY: Get IW (In Warranty) Record for ZPL Label Testing
-- ============================================
-- Purpose: Find a record with IW warranty status to test vendor display on label
-- ============================================

SELECT TOP 10
    rec."Date Received",
    rec."Tracking Number",
    rec.ASN,
    rec."Part No",
    rec."Serial No",
    rec."Dock Log ID",
    rec."Warranty Status",
    -- Vendor/Supplier from PartNoAttribute
    (SELECT TOP 1 pna.Value
     FROM pls.PartNoAttribute pna
     INNER JOIN pls.CodeAttribute ca ON ca.ID = pna.AttributeID
     WHERE pna.ProgramID = rec.ProgramID
       AND pna.PartNo = rec."Part No"
       AND ca.AttributeName = 'SUPPLIER_NO'
     ORDER BY pna.LastActivityDate DESC) AS "Vendor/Supplier",
    rec.ProgramID,
    rec.RMANumber
FROM rpt.ADTReceiptReport rec
WHERE rec.ProgramID = 10068
    -- Filter for IW records only
    AND rec."Warranty Status" = 'IW'
    -- Ensure vendor exists
    AND EXISTS (
        SELECT 1
        FROM pls.PartNoAttribute pna
        INNER JOIN pls.CodeAttribute ca ON ca.ID = pna.AttributeID
        WHERE pna.ProgramID = rec.ProgramID
          AND pna.PartNo = rec."Part No"
          AND ca.AttributeName = 'SUPPLIER_NO'
    )
ORDER BY rec."Date Received" DESC;

