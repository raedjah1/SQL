-- ================================================
-- ADT RMA Data with Supplier (SUPPLIER_NO or Manufacturer fallback)
-- ================================================

SELECT 
    rma.[part_code] AS PartCode,
    rma.[Ticket Number] AS TicketNumber,
    rma.[manufacturer] AS RMAManufacturer,
    -- Get SUPPLIER_NO from PartNoAttribute
    (SELECT TOP 1 pna.Value
     FROM Plus.pls.PartNoAttribute pna
     INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
     WHERE pna.PartNo = rma.[part_code]
       AND ca.AttributeName = 'SUPPLIER_NO'
     ORDER BY pna.LastActivityDate DESC) AS SupplierNo,
    -- Final Supplier: Use SUPPLIER_NO if available, otherwise use manufacturer
    COALESCE(
        (SELECT TOP 1 pna.Value
         FROM Plus.pls.PartNoAttribute pna
         INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
         WHERE pna.PartNo = rma.[part_code]
           AND ca.AttributeName = 'SUPPLIER_NO'
         ORDER BY pna.LastActivityDate DESC),
        rma.[manufacturer]
    ) AS Supplier,
    -- Indicate source
    CASE 
        WHEN (SELECT TOP 1 pna.Value
              FROM Plus.pls.PartNoAttribute pna
              INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
              WHERE pna.PartNo = rma.[part_code]
                AND ca.AttributeName = 'SUPPLIER_NO'
              ORDER BY pna.LastActivityDate DESC) IS NOT NULL
        THEN 'SUPPLIER_NO'
        ELSE 'Manufacturer'
    END AS SupplierSource,
    rma.[oem_action] AS OEMAction,
    rma.[EXT Cost] AS ExtendedCost,
    rma.[Entry Date] AS EntryDate,
    rma.[request_timestamp] AS RequestTimestamp,
    rma.[rma_num_timestamp] AS RMANumTimestamp,
    rma.[reply_timestamp] AS ReplyTimestamp,
    rma.[Shipped_date] AS ShippedDate,
    rma.[Status] AS Status
FROM [ClarityWarehouse].[rpt].[ADTReconextRMAData] rma
WHERE rma.[part_code] IS NOT NULL
ORDER BY rma.[Entry Date] DESC;


