-- Back Orders by SKU (EX Orders Only)
-- Shows quantity ordered vs shipped, back ordered quantity, dates, and cost
-- Includes both summary by SKU and detailed order line breakdown

-- ================================================
-- SUMMARY BY SKU (Aggregated)
-- ================================================
SELECT 
    sol.PartNo AS SKU,
    COUNT(DISTINCT soh.ID) AS NumberOfOrders,
    COUNT(DISTINCT CASE WHEN soh.StatusID = 3 THEN soh.ID END) AS CancelledOrders,
    SUM(sol.QtyToShip) AS TotalQtyOrdered,
    SUM(sol.QtyReserved) AS TotalQtyShipped,
    SUM(sol.QtyToShip) - SUM(sol.QtyReserved) AS Difference,
    COUNT(CASE WHEN sol.QtyToShip > sol.QtyReserved THEN 1 END) AS BackOrderedLines,
    MIN(soh.CreateDate) AS OldestOrderDate,
    MAX(soh.CreateDate) AS NewestOrderDate,
    MAX(soh.LastActivityDate) AS LastActivityDate,
    SUM(COALESCE(cost.Cost, 0) * (sol.QtyToShip - sol.QtyReserved)) AS TotalBackOrderedCost
FROM Plus.pls.SOHeader soh
INNER JOIN Plus.pls.SOLine sol ON sol.SOHeaderID = soh.ID
LEFT JOIN (
    SELECT 
        pna.PartNo,
        MAX(CASE WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2)) ELSE NULL END) AS Cost
    FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE ca.AttributeName = 'Cost'
    GROUP BY pna.PartNo
) cost ON cost.PartNo = sol.PartNo
WHERE soh.ProgramID IN (10068, 10072)  -- ADT programs
    AND soh.StatusID != 3  -- Exclude cancelled orders
    AND (
        soh.CustomerReference LIKE '8%'  -- EX orders by customer reference
        OR soh.ThirdPartyReference LIKE '8%'  -- Or third party reference
    )
    AND sol.QtyToShip > sol.QtyReserved  -- Only show back ordered items
    -- Date filters (uncomment and adjust as needed)
    -- AND soh.CreateDate >= '2025-01-01'  -- Filter by order creation date
    -- AND soh.CreateDate <= '2025-12-31'
    -- AND soh.LastActivityDate >= '2025-01-01'  -- Filter by last activity date
GROUP BY sol.PartNo
HAVING SUM(sol.QtyToShip) > SUM(sol.QtyReserved)  -- Only SKUs with back orders
ORDER BY Difference DESC, SKU;

-- ================================================
-- DETAILED ORDER LINES (Individual back ordered lines)
-- ================================================
SELECT 
    soh.ID AS OrderID,
    soh.CustomerReference,
    soh.ThirdPartyReference,
    soh.CreateDate AS OrderCreateDate,
    soh.LastActivityDate AS OrderLastActivityDate,
    cs.Description AS OrderStatus,
    sol.PartNo AS SKU,
    sol.QtyToShip AS QtyOrdered,
    sol.QtyReserved AS QtyShipped,
    sol.QtyToShip - sol.QtyReserved AS BackOrderedQty,
    COALESCE(cost.Cost, 0) AS UnitCost,
    COALESCE(cost.Cost, 0) * (sol.QtyToShip - sol.QtyReserved) AS BackOrderedCost,
    sol.CreateDate AS LineCreateDate,
    sol.LastActivityDate AS LineLastActivityDate,
    DATEDIFF(DAY, soh.CreateDate, GETDATE()) AS DaysSinceOrderCreated,
    DATEDIFF(DAY, sol.CreateDate, GETDATE()) AS DaysSinceLineCreated
FROM Plus.pls.SOHeader soh
INNER JOIN Plus.pls.SOLine sol ON sol.SOHeaderID = soh.ID
INNER JOIN Plus.pls.CodeStatus cs ON cs.ID = soh.StatusID
LEFT JOIN (
    SELECT 
        pna.PartNo,
        MAX(CASE WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2)) ELSE NULL END) AS Cost
    FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE ca.AttributeName = 'Cost'
    GROUP BY pna.PartNo
) cost ON cost.PartNo = sol.PartNo
WHERE soh.ProgramID IN (10068, 10072)  -- ADT programs
    AND soh.StatusID != 3  -- Exclude cancelled orders
    AND (
        soh.CustomerReference LIKE '8%'  -- EX orders by customer reference
        OR soh.ThirdPartyReference LIKE '8%'  -- Or third party reference
    )
    AND sol.QtyToShip > sol.QtyReserved  -- Only show back ordered items
    -- Date filters (uncomment and adjust as needed)
    -- AND soh.CreateDate >= '2025-01-01'  -- Filter by order creation date
    -- AND soh.CreateDate <= '2025-12-31'
    -- AND soh.LastActivityDate >= '2025-01-01'  -- Filter by last activity date
ORDER BY soh.CreateDate DESC, sol.PartNo;

