CREATE OR ALTER VIEW rpt.ADTECRDashboard AS
SELECT 
    BusinessDaysFromOrderCreateToShip AS DaysFromOrderCreateToShip,
    SOHeaderID,
    OrderLineID,
    CustomerReference,
    ThirdPartyReference,
    PartNo,
    SerialNo,
    QtyToShip AS Qty,
    QtyReserved,
    BizTalkID,
    BackOrderFlag,
    OrderCreateDate,
    ShipDate,
    HoursDifference,
    CalendarDays,
    COALESCE(Cost, 0) AS UnitCost,
    COALESCE(Cost, 0) * QtyToShip AS TotalCost,
    Status,
    IsShipped,
    TrackingNo,
    LocationNo,
    Category
FROM (
    SELECT 
        SOH.CreateDate AS OrderCreateDate,
        -- Ship Date: Use actual ship transaction date if available, otherwise use SOHeader LastActivityDate if shipped status
        CASE 
            WHEN pt.CreateDate IS NOT NULL THEN pt.CreateDate
            WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
            ELSE NULL
        END AS ShipDate,
        SOL.QtyToShip,
        SOL.QtyReserved,
        SOL.BizTalkID,
        SOL.PartNo,
        pt.SerialNo,
        SOH.ID AS SOHeaderID,
        SOL.ID AS OrderLineID,
        -- BackOrder Flag: Y if QtyToShip > QtyReserved, N otherwise
        CASE 
            WHEN (SOL.QtyToShip - SOL.QtyReserved) > 0 THEN 'Y'
            ELSE 'N'
        END AS BackOrderFlag,
        SOH.CustomerReference,
        SOH.ThirdPartyReference,
        cost.Cost,
        CS.Description AS Status,
        CASE WHEN SOL.StatusID = 18 OR pt.CreateDate IS NOT NULL THEN 1 ELSE 0 END AS IsShipped,
        SOSI.TrackingNo,
        pl_location.LocationNo,
        -- Category based on CustomerReference prefix
        CASE 
            WHEN SOH.CustomerReference LIKE '8%' THEN 'FWD'
            WHEN SOH.CustomerReference LIKE 'SP%' THEN 'Special Projects'
            ELSE 'Other'
        END AS Category,
        
        -- Calculate actual hours difference (to ship date or current time if not shipped)
        CASE 
            WHEN pt.CreateDate IS NOT NULL THEN DATEDIFF(HOUR, SOH.CreateDate, pt.CreateDate)
            WHEN SOL.StatusID = 18 THEN DATEDIFF(HOUR, SOH.CreateDate, SOH.LastActivityDate)
            ELSE DATEDIFF(HOUR, SOH.CreateDate, GETDATE()) -- Current time for unshipped orders
        END AS HoursDifference,
        
        -- Calculate calendar days
        CASE 
            WHEN pt.CreateDate IS NOT NULL THEN DATEDIFF(DAY, SOH.CreateDate, pt.CreateDate)
            WHEN SOL.StatusID = 18 THEN DATEDIFF(DAY, SOH.CreateDate, SOH.LastActivityDate)
            ELSE DATEDIFF(DAY, SOH.CreateDate, GETDATE()) -- Current date for unshipped orders
        END AS CalendarDays,
        
        -- Calculate business days (excluding weekends, only if >= 24 hours)
        CASE 
            WHEN CASE 
                WHEN pt.CreateDate IS NOT NULL THEN DATEDIFF(HOUR, SOH.CreateDate, pt.CreateDate)
                WHEN SOL.StatusID = 18 THEN DATEDIFF(HOUR, SOH.CreateDate, SOH.LastActivityDate)
                ELSE DATEDIFF(HOUR, SOH.CreateDate, GETDATE())
            END < 24 THEN 0  -- Less than 24 hours = 0 days
            ELSE (
                CASE 
                    WHEN pt.CreateDate IS NOT NULL THEN DATEDIFF(DAY, SOH.CreateDate, pt.CreateDate)
                    WHEN SOL.StatusID = 18 THEN DATEDIFF(DAY, SOH.CreateDate, SOH.LastActivityDate)
                    ELSE DATEDIFF(DAY, SOH.CreateDate, GETDATE())
                END
                - (CASE 
                    WHEN pt.CreateDate IS NOT NULL THEN DATEDIFF(WEEK, SOH.CreateDate, pt.CreateDate)
                    WHEN SOL.StatusID = 18 THEN DATEDIFF(WEEK, SOH.CreateDate, SOH.LastActivityDate)
                    ELSE DATEDIFF(WEEK, SOH.CreateDate, GETDATE())
                END * 2)  -- Subtract weekends
                - CASE WHEN DATEPART(WEEKDAY, SOH.CreateDate) = 7 THEN 1 ELSE 0 END  -- If start is Saturday
                - CASE WHEN DATEPART(WEEKDAY, CASE 
                    WHEN pt.CreateDate IS NOT NULL THEN pt.CreateDate
                    WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
                    ELSE GETDATE()
                END) = 1 THEN 1 ELSE 0 END   -- If end is Sunday
                + CASE WHEN DATEPART(WEEKDAY, SOH.CreateDate) = 1 THEN 1 ELSE 0 END  -- If start is Sunday, add back
                + CASE WHEN DATEPART(WEEKDAY, CASE 
                    WHEN pt.CreateDate IS NOT NULL THEN pt.CreateDate
                    WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
                    ELSE GETDATE()
                END) = 7 THEN 1 ELSE 0 END   -- If end is Saturday, add back
            )
        END AS BusinessDaysFromOrderCreateToShip
    
    FROM Plus.pls.SOHeader SOH
    INNER JOIN Plus.pls.SOLine SOL ON SOL.SOHeaderID = SOH.ID
    INNER JOIN Plus.pls.Program P ON P.ID = SOH.ProgramID
    INNER JOIN Plus.pls.CodeStatus CS ON CS.ID = SOH.StatusID
    INNER JOIN Plus.pls.[User] U ON U.ID = SOH.UserID
    
    -- LEFT JOIN to PartTransaction to get ship transactions (if they exist)
    LEFT JOIN Plus.pls.PartTransaction pt ON pt.OrderLineID = SOL.ID 
        AND pt.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'SO-SHIP')
    
    -- Get cost information
    LEFT JOIN (
        SELECT 
            pna.PartNo,
            MAX(CASE WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2)) ELSE NULL END) AS Cost
        FROM Plus.pls.PartNoAttribute pna
        INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
        WHERE ca.AttributeName = 'Cost'
        GROUP BY pna.PartNo
    ) cost ON cost.PartNo = SOL.PartNo
    
    -- Get tracking information
    LEFT JOIN Plus.pls.SOShipmentInfo SOSI ON SOH.ID = SOSI.SOHeaderID
    
    -- Get location information
    LEFT JOIN (
        SELECT DISTINCT
            sou.SOLineID,
            pl.LocationNo
        FROM Plus.pls.SOUnit sou
        INNER JOIN Plus.pls.PartLocation pl ON pl.ID = sou.FromLocationID
    ) pl_location ON pl_location.SOLineID = SOL.ID
    
    WHERE SOH.ProgramID IN (10068, 10072)
      AND (
          SOH.CustomerReference LIKE '8%' OR SOH.CustomerReference LIKE 'SP%'
      )
      AND CS.Description NOT LIKE '%CANCEL%'  -- Exclude canceled orders
) AS OrderData; 