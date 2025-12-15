CREATE OR ALTER   VIEW rpt.ADTECRDashboard AS
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
            WHEN MAX(pt.CreateDate) IS NOT NULL THEN MAX(pt.CreateDate)
            WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
            ELSE NULL
        END AS ShipDate,
        SOL.QtyToShip,
        SOL.QtyReserved,
        SOL.BizTalkID,
        SOL.PartNo,
        MAX(pt.SerialNo) AS SerialNo,
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
        CASE WHEN SOL.StatusID = 18 OR MAX(pt.CreateDate) IS NOT NULL THEN 1 ELSE 0 END AS IsShipped,
        MAX(SOSI.TrackingNo) AS TrackingNo,
        MAX(pl_location.LocationNo) AS LocationNo,
        -- Category based on CustomerReference prefix
        CASE 
            WHEN SOH.CustomerReference LIKE '8%' THEN 'FWD'
            WHEN SOH.CustomerReference LIKE 'SP%' THEN 'Special Projects'
            ELSE 'Other'
        END AS Category,
        
        -- Calculate actual hours difference (to ship date or current time if not shipped)
        CASE 
            WHEN MAX(pt.CreateDate) IS NOT NULL THEN DATEDIFF(HOUR, SOH.CreateDate, MAX(pt.CreateDate))
            WHEN SOL.StatusID = 18 THEN DATEDIFF(HOUR, SOH.CreateDate, SOH.LastActivityDate)
            ELSE DATEDIFF(HOUR, SOH.CreateDate, GETDATE()) -- Current time for unshipped orders
        END AS HoursDifference,
        
        -- Calculate calendar days
        CASE 
            WHEN MAX(pt.CreateDate) IS NOT NULL THEN DATEDIFF(DAY, SOH.CreateDate, MAX(pt.CreateDate))
            WHEN SOL.StatusID = 18 THEN DATEDIFF(DAY, SOH.CreateDate, SOH.LastActivityDate)
            ELSE DATEDIFF(DAY, SOH.CreateDate, GETDATE()) -- Current date for unshipped orders
        END AS CalendarDays,
        
        -- Calculate business days (excluding weekends, only if >= 24 business hours)
        -- Business hours = total hours minus weekend hours (Saturday 00:00 to Sunday 23:59:59)
        CASE 
            WHEN (
                -- Calculate business hours: total hours minus weekend hours
                CASE 
                    WHEN MAX(pt.CreateDate) IS NOT NULL THEN 
                        DATEDIFF(HOUR, SOH.CreateDate, MAX(pt.CreateDate))
                        - (DATEDIFF(WEEK, SOH.CreateDate, MAX(pt.CreateDate)) * 48)  -- Subtract 48 hours per weekend
                        - CASE WHEN DATEPART(WEEKDAY, SOH.CreateDate) = 7 THEN 
                            DATEDIFF(HOUR, SOH.CreateDate, DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))) 
                          ELSE 0 END  -- Subtract Saturday hours if starts on Saturday
                        - CASE WHEN DATEPART(WEEKDAY, MAX(pt.CreateDate)) = 1 THEN 
                            DATEDIFF(HOUR, CAST(MAX(pt.CreateDate) AS DATE), MAX(pt.CreateDate)) 
                          ELSE 0 END  -- Subtract Sunday hours if ends on Sunday
                    WHEN SOL.StatusID = 18 THEN 
                        DATEDIFF(HOUR, SOH.CreateDate, SOH.LastActivityDate)
                        - (DATEDIFF(WEEK, SOH.CreateDate, SOH.LastActivityDate) * 48)
                        - CASE WHEN DATEPART(WEEKDAY, SOH.CreateDate) = 7 THEN 
                            DATEDIFF(HOUR, SOH.CreateDate, DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))) 
                          ELSE 0 END
                        - CASE WHEN DATEPART(WEEKDAY, SOH.LastActivityDate) = 1 THEN 
                            DATEDIFF(HOUR, CAST(SOH.LastActivityDate AS DATE), SOH.LastActivityDate) 
                          ELSE 0 END
                    ELSE 
                        DATEDIFF(HOUR, SOH.CreateDate, GETDATE())
                        - (DATEDIFF(WEEK, SOH.CreateDate, GETDATE()) * 48)
                        - CASE WHEN DATEPART(WEEKDAY, SOH.CreateDate) = 7 THEN 
                            DATEDIFF(HOUR, SOH.CreateDate, DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))) 
                          ELSE 0 END
                        - CASE WHEN DATEPART(WEEKDAY, GETDATE()) = 1 THEN 
                            DATEDIFF(HOUR, CAST(GETDATE() AS DATE), GETDATE()) 
                          ELSE 0 END
                END
            ) < 24 THEN 0  -- Less than 24 business hours = 0 days
            ELSE (
                CASE 
                    WHEN MAX(pt.CreateDate) IS NOT NULL THEN DATEDIFF(DAY, SOH.CreateDate, MAX(pt.CreateDate))
                    WHEN SOL.StatusID = 18 THEN DATEDIFF(DAY, SOH.CreateDate, SOH.LastActivityDate)
                    ELSE DATEDIFF(DAY, SOH.CreateDate, GETDATE())
                END
                - (CASE 
                    WHEN MAX(pt.CreateDate) IS NOT NULL THEN DATEDIFF(WEEK, SOH.CreateDate, MAX(pt.CreateDate))
                    WHEN SOL.StatusID = 18 THEN DATEDIFF(WEEK, SOH.CreateDate, SOH.LastActivityDate)
                    ELSE DATEDIFF(WEEK, SOH.CreateDate, GETDATE())
                END * 2)  -- Subtract weekends
                - CASE WHEN DATEPART(WEEKDAY, SOH.CreateDate) = 7 THEN 1 ELSE 0 END  -- If start is Saturday
                - CASE WHEN DATEPART(WEEKDAY, CASE 
                    WHEN MAX(pt.CreateDate) IS NOT NULL THEN MAX(pt.CreateDate)
                    WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
                    ELSE GETDATE()
                END) = 1 THEN 1 ELSE 0 END   -- If end is Sunday
                + CASE WHEN DATEPART(WEEKDAY, SOH.CreateDate) = 1 THEN 1 ELSE 0 END  -- If start is Sunday, add back
                + CASE WHEN DATEPART(WEEKDAY, CASE 
                    WHEN MAX(pt.CreateDate) IS NOT NULL THEN MAX(pt.CreateDate)
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
    GROUP BY 
        SOH.ID,
        SOL.ID,
        SOH.CreateDate,
        SOL.QtyToShip,
        SOL.QtyReserved,
        SOL.BizTalkID,
        SOL.PartNo,
        SOL.StatusID,
        SOH.LastActivityDate,
        SOH.CustomerReference,
        SOH.ThirdPartyReference,
        CS.Description,
        cost.Cost
) AS OrderData; 