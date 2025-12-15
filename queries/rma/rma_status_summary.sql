-- ================================================
-- RMA STATUS Summary - Simple and Clean
-- Recreates the RMA STATUS table with OEM ACTION, Lines, QTY, TotalCost
-- ================================================

WITH RMAData AS (
    SELECT 
        rma.[Ticket Number] AS TicketNumber,
        rma.[part_code] AS PartCode,
        rma.[oem_action] AS OEMAction,
        rma.[EXT Cost] AS ExtendedCostFromRMA,
        -- Quantity: Use Quantity approved for shipment if available, otherwise get from PartTransaction
        COALESCE(
            CAST(rma.[Quantity approved for shipment] AS INT),
            (SELECT SUM(CAST(pt.Qty AS BIGINT))
             FROM Plus.pls.PartTransaction pt
             INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
             WHERE pt.PartNo = rma.[part_code]
               AND pt.ProgramID IN (10068, 10072)
               AND cpt.Description = 'RO-RECEIVE')
        ) AS Quantity,
        -- Cost: PartNoAttribute Cost or RMA Extended Cost fallback
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
        -- Get warranty status for "IW and waiting to submit to vendor" category
        COALESCE(
            (SELECT TOP 1 pna.Value
             FROM Plus.pls.PartNoAttribute pna
             INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
             WHERE pna.PartNo = rma.[part_code]
               AND ca.AttributeName = 'WARRANTY_STATUS'
             ORDER BY pna.LastActivityDate DESC),
            (SELECT TOP 1 psa.Value
             FROM Plus.pls.PartSerialAttribute psa
             INNER JOIN Plus.pls.PartSerial ps ON ps.ID = psa.PartSerialID
             INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
             WHERE ps.PartNo = rma.[part_code]
               AND ps.ProgramID IN (10068, 10072)
               AND ca.AttributeName = 'WARRANTY_STATUS'
             ORDER BY psa.LastActivityDate DESC)
        ) AS WarrantyStatus,
        rma.[request_timestamp] AS RequestTimestamp
    FROM [ClarityWarehouse].[rpt].[ADTReconextRMAData] rma
    WHERE rma.[part_code] IS NOT NULL
),
CategorizedData AS (
    SELECT 
        -- Enhanced OEM Action Category (includes "IW and waiting to submit to vendor")
        CASE 
            -- IW and waiting to submit to vendor: In warranty but no request yet
            WHEN (WarrantyStatus IN ('IN WARRANTY', 'IW', 'IN_WARRANTY') 
                  OR UPPER(LTRIM(RTRIM(COALESCE(WarrantyStatus, '')))) IN ('IN WARRANTY', 'IW', 'IN_WARRANTY'))
                 AND RequestTimestamp IS NULL
            THEN 'IW and waiting to submit to vendor'
            -- Use actual OEM Action if it exists
            WHEN OEMAction IS NOT NULL AND LTRIM(RTRIM(OEMAction)) != ''
            THEN OEMAction
            -- Default for records without OEM Action
            ELSE 'UNKNOWN'
        END AS OEMActionCategory,
        Quantity,
        Cost,
        Quantity * COALESCE(Cost, 0) AS TotalCost
    FROM RMAData
)
SELECT 
    OEMActionCategory AS [OEM ACTION],
    COUNT(*) AS Lines,
    SUM(Quantity) AS QTY,
    SUM(TotalCost) AS TotalCost
FROM CategorizedData
GROUP BY OEMActionCategory

UNION ALL

-- Total Row
SELECT 
    'TOTAL' AS [OEM ACTION],
    COUNT(*) AS Lines,
    SUM(Quantity) AS QTY,
    SUM(TotalCost) AS TotalCost
FROM CategorizedData

ORDER BY 
    CASE WHEN [OEM ACTION] = 'TOTAL' THEN 1 ELSE 0 END,
    [OEM ACTION];


