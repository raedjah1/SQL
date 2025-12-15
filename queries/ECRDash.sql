-- Detailed underlying data for each business day from order to ship
-- Starting with day 1, showing all transaction details

SELECT 
    BusinessDaysFromOrderCreateToShip AS DaysFromOrderCreateToShip,
    SOHeaderID,
    OrderLineID,
    CustomerReference,
    ThirdPartyReference,
    PartNo,
    SerialNo,
    Qty,
    OrderCreateDate,
    ShipDate,
    HoursDifference,
    CalendarDays,
    COALESCE(Cost, 0) AS UnitCost,
    COALESCE(Cost, 0) * Qty AS TotalCost,
    HasBackOrder,
    BackOrderedQty
FROM (
    SELECT 
        soh.CreateDate AS OrderCreateDate,
        pt.CreateDate AS ShipDate,
        pt.Qty,
        pt.PartNo,
        pt.SerialNo,
        soh.ID AS SOHeaderID,
        pt.OrderLineID,
        soh.CustomerReference,
        soh.ThirdPartyReference,
        cost.Cost,
        -- Calculate actual hours difference
        DATEDIFF(HOUR, soh.CreateDate, pt.CreateDate) AS HoursDifference,
        -- Calculate calendar days
        DATEDIFF(DAY, soh.CreateDate, pt.CreateDate) AS CalendarDays,
        -- Calculate business days (excluding weekends, only if >= 24 hours)
        CASE 
            WHEN DATEDIFF(HOUR, soh.CreateDate, pt.CreateDate) < 24 THEN 0  -- Less than 24 hours = 0 days
            ELSE (
                DATEDIFF(DAY, soh.CreateDate, pt.CreateDate)
                - (DATEDIFF(WEEK, soh.CreateDate, pt.CreateDate) * 2)  -- Subtract weekends
                - CASE WHEN DATEPART(WEEKDAY, soh.CreateDate) = 7 THEN 1 ELSE 0 END  -- If start is Saturday
                - CASE WHEN DATEPART(WEEKDAY, pt.CreateDate) = 1 THEN 1 ELSE 0 END   -- If end is Sunday
                + CASE WHEN DATEPART(WEEKDAY, soh.CreateDate) = 1 THEN 1 ELSE 0 END  -- If start is Sunday, add back
                + CASE WHEN DATEPART(WEEKDAY, pt.CreateDate) = 7 THEN 1 ELSE 0 END   -- If end is Saturday, add back
            )
        END AS BusinessDaysFromOrderCreateToShip,
        -- Back order flag: 1 if order line still has back orders, 0 if fully shipped
        CASE WHEN sol.QtyToShip > sol.QtyReserved THEN 1 ELSE 0 END AS HasBackOrder,
        -- Back ordered quantity remaining for this order line
        CASE WHEN sol.QtyToShip > sol.QtyReserved THEN sol.QtyToShip - sol.QtyReserved ELSE 0 END AS BackOrderedQty
    FROM Plus.pls.PartTransaction pt
    INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    INNER JOIN Plus.pls.SOHeader soh ON soh.ID = pt.OrderHeaderID
    INNER JOIN Plus.pls.SOLine sol ON sol.ID = pt.OrderLineID
    LEFT JOIN (
        SELECT 
            pna.PartNo,
            MAX(CASE WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2)) ELSE NULL END) AS Cost
        FROM Plus.pls.PartNoAttribute pna
        INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
        WHERE ca.AttributeName = 'Cost'
        GROUP BY pna.PartNo
    ) cost ON cost.PartNo = pt.PartNo
    WHERE pt.ProgramID IN (10068, 10072)
      AND cpt.Description = 'SO-SHIP'
      AND (
          soh.CustomerReference LIKE '8%' 
          OR soh.ThirdPartyReference LIKE '8%'
          OR pt.SerialNo LIKE 'EXADT%'
      )
) AS BusinessDaysCalculation