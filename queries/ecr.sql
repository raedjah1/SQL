CREATE OR ALTER     VIEW rpt.ADTECRDashboard AS
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
        
        -- SLA Days From Order Create To Ship (3pm cutoff encoded here)
        -- Rule:
        -- - Created BEFORE 3pm -> must ship same day (anything next day counts as 1+ late)
        -- - Created AT/AFTER 3pm -> must ship next business day BY 3pm (missed cutoff counts as 1 day late)
        -- We keep the same weekend-exclusion style when counting late days (DATEDIFF(day/week) with Sat/Sun adjustments).
        -- Ship datetime (or GETDATE() if not shipped yet)
        CASE
                    WHEN (
                        CASE
                            WHEN MAX(pt.CreateDate) IS NOT NULL THEN MAX(pt.CreateDate)
                            WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
                            ELSE GETDATE()
                        END
                    ) <=
                    -- Due datetime
                    CASE
                        WHEN CAST(SOH.CreateDate AS TIME) < '15:00:00' THEN
                            -- Due = same day end-of-day
                            DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(CAST(SOH.CreateDate AS DATE) AS DATETIME2(0))))
                        ELSE
                            -- Due = next business day @ 3pm (Fri->Mon, Sat->Mon, Sun->Mon)
                            DATEADD(
                                HOUR,
                                15,
                                CAST(
                                    CASE
                                        WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 6 THEN DATEADD(DAY, 3, CAST(SOH.CreateDate AS DATE)) -- Friday
                                        WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 7 THEN DATEADD(DAY, 2, CAST(SOH.CreateDate AS DATE)) -- Saturday
                                        WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 1 THEN DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE)) -- Sunday
                                        ELSE DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE)) -- Mon-Thu
                                    END AS DATETIME2(0)
                                )
                            )
                    END
            THEN 0
            ELSE
                -- Late: count business-day lateness from due date to ship date.
                CASE
                        -- If shipped on the due DATE but after due TIME (only possible for after-2pm rule), count as 1 day late
                        WHEN CAST(
                                CASE
                                    WHEN MAX(pt.CreateDate) IS NOT NULL THEN MAX(pt.CreateDate)
                                    WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
                                    ELSE GETDATE()
                                END AS DATE
                            )
                            =
                            CASE
                                WHEN CAST(SOH.CreateDate AS TIME) < '15:00:00' THEN CAST(SOH.CreateDate AS DATE)
                                ELSE
                                    CASE
                                        WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 6 THEN DATEADD(DAY, 3, CAST(SOH.CreateDate AS DATE))
                                        WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 7 THEN DATEADD(DAY, 2, CAST(SOH.CreateDate AS DATE))
                                        WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 1 THEN DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))
                                        ELSE DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))
                                    END
                            END
                            AND CAST(
                                CASE
                                    WHEN MAX(pt.CreateDate) IS NOT NULL THEN MAX(pt.CreateDate)
                                    WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
                                    ELSE GETDATE()
                                END AS TIME
                            ) >
                            CASE
                                WHEN CAST(SOH.CreateDate AS TIME) < '15:00:00' THEN '23:59:59'
                                ELSE '15:00:00'
                            END
                        THEN 1
                        ELSE
                            -- Business day difference between DueDate and ShipDate (dates only), excluding weekends
                            (
                                DATEDIFF(
                                    DAY,
                                    CASE
                                        WHEN CAST(SOH.CreateDate AS TIME) < '15:00:00' THEN CAST(SOH.CreateDate AS DATE)
                                        ELSE
                                            CASE
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 6 THEN DATEADD(DAY, 3, CAST(SOH.CreateDate AS DATE))
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 7 THEN DATEADD(DAY, 2, CAST(SOH.CreateDate AS DATE))
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 1 THEN DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))
                                                ELSE DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))
                                            END
                                    END,
                                    CAST(
                                        CASE
                                            WHEN MAX(pt.CreateDate) IS NOT NULL THEN MAX(pt.CreateDate)
                                            WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
                                            ELSE GETDATE()
                                        END AS DATE
                                    )
                                )
                                - (DATEDIFF(
                                    WEEK,
                                    CASE
                                        WHEN CAST(SOH.CreateDate AS TIME) < '15:00:00' THEN CAST(SOH.CreateDate AS DATE)
                                        ELSE
                                            CASE
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 6 THEN DATEADD(DAY, 3, CAST(SOH.CreateDate AS DATE))
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 7 THEN DATEADD(DAY, 2, CAST(SOH.CreateDate AS DATE))
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 1 THEN DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))
                                                ELSE DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))
                                            END
                                    END,
                                    CAST(
                                        CASE
                                            WHEN MAX(pt.CreateDate) IS NOT NULL THEN MAX(pt.CreateDate)
                                            WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
                                            ELSE GETDATE()
                                        END AS DATE
                                    )
                                ) * 2)
                                - CASE WHEN DATEPART(WEEKDAY,
                                    CASE
                                        WHEN CAST(SOH.CreateDate AS TIME) < '15:00:00' THEN CAST(SOH.CreateDate AS DATE)
                                        ELSE
                                            CASE
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 6 THEN DATEADD(DAY, 3, CAST(SOH.CreateDate AS DATE))
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 7 THEN DATEADD(DAY, 2, CAST(SOH.CreateDate AS DATE))
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 1 THEN DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))
                                                ELSE DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))
                                            END
                                    END
                                ) = 7 THEN 1 ELSE 0 END
                                - CASE WHEN DATEPART(WEEKDAY,
                                    CAST(
                                        CASE
                                            WHEN MAX(pt.CreateDate) IS NOT NULL THEN MAX(pt.CreateDate)
                                            WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
                                            ELSE GETDATE()
                                        END AS DATE
                                    )
                                ) = 1 THEN 1 ELSE 0 END
                                + CASE WHEN DATEPART(WEEKDAY,
                                    CASE
                                        WHEN CAST(SOH.CreateDate AS TIME) < '15:00:00' THEN CAST(SOH.CreateDate AS DATE)
                                        ELSE
                                            CASE
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 6 THEN DATEADD(DAY, 3, CAST(SOH.CreateDate AS DATE))
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 7 THEN DATEADD(DAY, 2, CAST(SOH.CreateDate AS DATE))
                                                WHEN DATEPART(WEEKDAY, CAST(SOH.CreateDate AS DATE)) = 1 THEN DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))
                                                ELSE DATEADD(DAY, 1, CAST(SOH.CreateDate AS DATE))
                                            END
                                    END
                                ) = 1 THEN 1 ELSE 0 END
                                + CASE WHEN DATEPART(WEEKDAY,
                                    CAST(
                                        CASE
                                            WHEN MAX(pt.CreateDate) IS NOT NULL THEN MAX(pt.CreateDate)
                                            WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate
                                            ELSE GETDATE()
                                        END AS DATE
                                    )
                                ) = 7 THEN 1 ELSE 0 END
                            )
                END
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