-- GET ALL RMA RECORDS WITH OEM ACTIONS OTHER THAN 'Approved' OR 'Awaiting Approval'
-- Excludes: "Approved", "Aproved", "Awaiting Approval", "Awaiting Aproval", "Awaiting approval"
-- Includes: HOLD, Cancelled, Closed, and any other OEM actions
-- Includes vendor and cost from PartNoAttribute as fallback (like previous queries)
SELECT
    rma.[part_code] AS SKU,
    pn.Description AS PartDescription,
    -- Vendor: Use RMA table first, fallback to PartNoAttribute
    COALESCE(
        rma.[manufacturer],
        (SELECT TOP 1 pna_vendor.Value
         FROM Plus.pls.PartNoAttribute pna_vendor
         INNER JOIN Plus.pls.CodeAttribute ca_vendor ON ca_vendor.ID = pna_vendor.AttributeID
         WHERE pna_vendor.PartNo = rma.[part_code]
           AND (ca_vendor.AttributeName LIKE '%MANUFACTURER%'
                OR ca_vendor.AttributeName LIKE '%VENDOR%'
                OR ca_vendor.AttributeName LIKE '%SUPPLIER%'
                OR ca_vendor.AttributeName LIKE '%SUPPLIER_NAME%'
                OR ca_vendor.AttributeName LIKE '%SUPPLIER_NO%')
         ORDER BY CASE 
             WHEN ca_vendor.AttributeName LIKE '%SUPPLIER_NAME%' THEN 1
             WHEN ca_vendor.AttributeName LIKE '%VENDOR%' THEN 2
             WHEN ca_vendor.AttributeName LIKE '%MANUFACTURER%' THEN 3
             ELSE 4
         END)
    ) AS Vendor,
    -- Cost: Use RMA table first, fallback to PartNoAttribute
    COALESCE(
        rma.[Cost],
        (SELECT TOP 1 
            CASE 
                WHEN ISNUMERIC(pna_cost.Value) = 1 THEN CAST(pna_cost.Value AS DECIMAL(10,2))
                ELSE NULL
            END
         FROM Plus.pls.PartNoAttribute pna_cost
         INNER JOIN Plus.pls.CodeAttribute ca_cost ON ca_cost.ID = pna_cost.AttributeID
         WHERE pna_cost.PartNo = rma.[part_code]
           AND ca_cost.AttributeName = 'Cost'
         ORDER BY pna_cost.CreateDate DESC)
    ) AS Cost,
    rma.[Ticket Number] AS InternalReference,
    rma.[EXT Cost] AS ExtendedCost,
    rma.[Quantity approved for shipment] AS QuantityApprovedForShipment,
    rma.[Replacement],
    rma.[Credit/Replacement] AS Credit_Replacement,
    rma.[oem_action] AS OEMAction,
    rma.[oem_opinion for non-shipped] AS OEMOpinionForNonShipped,
    -- Date first received into RXT (earliest RO-RECEIVE transaction for this part) - DATE ONLY, NO TIME
    CAST((SELECT MIN(pt.CreateDate)
     FROM Plus.pls.PartTransaction pt
     INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
     WHERE pt.PartNo = rma.[part_code]
       AND pt.ProgramID = 10068
       AND cpt.Description = 'RO-RECEIVE') AS DATE) AS DateFirstReceivedIntoRXT,
    -- Total Quantity from RO-RECEIVE transactions for this part
    (SELECT SUM(pt.Qty)
     FROM Plus.pls.PartTransaction pt
     INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
     WHERE pt.PartNo = rma.[part_code]
       AND pt.ProgramID = 10068
       AND cpt.Description = 'RO-RECEIVE') AS TotalQuantity,
    rma.[request_timestamp] AS RequestTimestamp,
    rma.[rma_num_timestamp] AS RMANumTimestamp,
    rma.[reply_timestamp] AS ReplyTimestamp,
    rma.[Status]
FROM
    ClarityWarehouse.rpt.ADTReconextRMAData rma
LEFT JOIN
    Plus.pls.PartNo pn ON pn.PartNo = rma.[part_code]
WHERE
    rma.[oem_action] IS NOT NULL
    AND LTRIM(RTRIM(rma.[oem_action])) != ''
    AND UPPER(LTRIM(RTRIM(rma.[oem_action]))) NOT LIKE '%APROV%'
    AND UPPER(LTRIM(RTRIM(rma.[oem_action]))) NOT LIKE '%AWAITING%'
ORDER BY
    rma.[oem_action], rma.[part_code], rma.[request_timestamp];

