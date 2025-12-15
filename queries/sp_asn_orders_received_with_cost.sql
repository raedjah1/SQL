-- ================================================
-- Total orders received (ECR) - SP ASN with quantity and dollar amount breakdown
-- ================================================

-- Detailed breakdown by ASN
SELECT 
    rh.CustomerReference AS EXASN,
    COUNT(DISTINCT rh.ID) AS TotalOrdersReceived,
    SUM(CAST(pt.Qty AS BIGINT)) AS TotalQtyReceived,
    -- Get cost per part and calculate total cost
    SUM(CAST(pt.Qty AS BIGINT) * CAST(COALESCE(cost.Cost, 0) AS DECIMAL(18,2))) AS TotalCost,
    COUNT(CASE WHEN cost.Cost > 0 THEN 1 END) AS PartsWithCost,
    COUNT(CASE WHEN cost.Cost IS NULL OR cost.Cost = 0 THEN 1 END) AS PartsWithoutCost
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
INNER JOIN Plus.pls.ROHeader rh ON rh.ID = pt.OrderHeaderID
LEFT JOIN (
    SELECT 
        pna.PartNo,
        MAX(CASE WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(18,2)) ELSE 0 END) AS Cost
    FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE ca.AttributeName = 'Cost'
    GROUP BY pna.PartNo
) cost ON cost.PartNo = pt.PartNo
WHERE pt.ProgramID IN (10068, 10072)
  AND pt.PartTransactionID = 1
  AND cpt.Description = 'RO-RECEIVE'
  AND rh.CustomerReference LIKE 'SP%'
GROUP BY rh.CustomerReference
ORDER BY rh.CustomerReference;

-- Summary totals
SELECT 
    COUNT(DISTINCT rh.ID) AS TotalOrdersReceived,
    COUNT(DISTINCT rh.CustomerReference) AS TotalSPASNs,
    SUM(CAST(pt.Qty AS BIGINT)) AS TotalQtyReceived,
    -- Total dollar amount
    SUM(CAST(pt.Qty AS BIGINT) * CAST(COALESCE(cost.Cost, 0) AS DECIMAL(18,2))) AS TotalCost,
    COUNT(CASE WHEN cost.Cost > 0 THEN 1 END) AS PartsWithCost,
    COUNT(CASE WHEN cost.Cost IS NULL OR cost.Cost = 0 THEN 1 END) AS PartsWithoutCost,
    -- Average cost per unit
    CASE 
        WHEN SUM(CAST(pt.Qty AS BIGINT)) > 0 
        THEN SUM(CAST(pt.Qty AS BIGINT) * CAST(COALESCE(cost.Cost, 0) AS DECIMAL(18,2))) / SUM(CAST(pt.Qty AS BIGINT))
        ELSE 0
    END AS AvgCostPerUnit
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
INNER JOIN Plus.pls.ROHeader rh ON rh.ID = pt.OrderHeaderID
LEFT JOIN (
    SELECT 
        pna.PartNo,
        MAX(CASE WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(18,2)) ELSE 0 END) AS Cost
    FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE ca.AttributeName = 'Cost'
    GROUP BY pna.PartNo
) cost ON cost.PartNo = pt.PartNo
WHERE pt.ProgramID IN (10068, 10072)
  AND pt.PartTransactionID = 1
  AND cpt.Description = 'RO-RECEIVE'
  AND rh.CustomerReference LIKE 'SP%';


