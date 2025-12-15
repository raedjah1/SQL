-- ================================================
-- ADT RMA Data with Cost (PartNoAttribute Cost or RMA Extended Cost fallback)
-- ================================================

SELECT 
    rma.[part_code] AS PartCode,
    rma.[Ticket Number] AS TicketNumber,
    rma.[manufacturer] AS Manufacturer,
    -- Get Cost from PartNoAttribute
    (SELECT TOP 1 
        CASE 
            WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(18,2))
            ELSE NULL
        END
     FROM Plus.pls.PartNoAttribute pna
     INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
     WHERE pna.PartNo = rma.[part_code]
       AND ca.AttributeName = 'Cost'
     ORDER BY pna.LastActivityDate DESC) AS CostFromAttribute,
    -- Get Extended Cost from RMA data
    rma.[EXT Cost] AS ExtendedCostFromRMA,
    -- Final Cost: Use PartNoAttribute Cost if available, otherwise use RMA Extended Cost
    COALESCE(
        (SELECT TOP 1 
            CASE 
                WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(18,2))
                ELSE NULL
            END
         FROM Plus.pls.PartNoAttribute pna
         INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
         WHERE pna.PartNo = rma.[part_code]
           AND ca.AttributeName = 'Cost'
         ORDER BY pna.LastActivityDate DESC),
        rma.[EXT Cost]
    ) AS Cost,
    -- Indicate source
    CASE 
        WHEN (SELECT TOP 1 pna.Value
              FROM Plus.pls.PartNoAttribute pna
              INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
              WHERE pna.PartNo = rma.[part_code]
                AND ca.AttributeName = 'Cost'
              ORDER BY pna.LastActivityDate DESC) IS NOT NULL
             AND ISNUMERIC((SELECT TOP 1 pna.Value
                           FROM Plus.pls.PartNoAttribute pna
                           INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
                           WHERE pna.PartNo = rma.[part_code]
                             AND ca.AttributeName = 'Cost'
                           ORDER BY pna.LastActivityDate DESC)) = 1
        THEN 'PartNoAttribute'
        ELSE 'RMA Extended Cost'
    END AS CostSource,
    rma.[oem_action] AS OEMAction,
    rma.[Entry Date] AS EntryDate,
    rma.[request_timestamp] AS RequestTimestamp,
    rma.[rma_num_timestamp] AS RMANumTimestamp,
    rma.[reply_timestamp] AS ReplyTimestamp,
    rma.[Shipped_date] AS ShippedDate,
    rma.[Status] AS Status
FROM [ClarityWarehouse].[rpt].[ADTReconextRMAData] rma
WHERE rma.[part_code] IS NOT NULL
ORDER BY rma.[Entry Date] DESC;


