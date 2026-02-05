SELECT
    rs.Description AS ASNStatus,
    rh.CustomerReference AS ASN,
    COALESCE(dl.TrackingNo, crst.TrackingNo) AS TrackingNo,
    br.Branch,
    rh.CreateDate AS ASNCreateDate,
    dl.CreateDate AS ASNDeliveryDate,
    lastROLine.CreateDate AS ASNProcessedDate,
    crst.Username AS UserID,

    -- Customer category based on ASN number (CustomerReference)
    CASE
        WHEN rh.CustomerReference LIKE 'X%'   THEN 'CDR'
        WHEN rh.CustomerReference LIKE 'EX%'  THEN 'Excess Centralization'
        WHEN rh.CustomerReference LIKE 'FSR%' THEN 'FSR'
        WHEN rh.CustomerReference LIKE 'SP%'  THEN 'Special Projects'
        ELSE 'Other'
    END AS CustomerCategory,

    -- Add calculated fields
    CAST(rh.CreateDate AS DATE) AS WorkDate,
    DATEDIFF(DAY, rh.CreateDate, GETDATE()) AS DaysSinceCreated,

    -- Days aged between Delivery and Processed
    CASE
        WHEN dl.CreateDate IS NULL THEN NULL
        ELSE biz.BusinessDays_DeliveryToEnd
    END AS DaysAged_DeliveryToProcessed,

    -- SLA columns (row-level): Due is Friday 5pm of delivery week if delivered by Wed 2pm,
    -- otherwise due is next Friday 5pm. Datetimes assumed CST (same assumption as your DAX).
    sla.SLA_DueDateTime,
    sla.SLA_CompliantFlag,

    -- Delivered but not processed yet (explicit flag/status)
    CASE
        WHEN dl.CreateDate IS NOT NULL AND lastROLine.CreateDate IS NULL THEN 'DELIVERED_NOT_PROCESSED_YET'
        ELSE 'OTHER'
    END AS DeliveredNotProcessedStatus,

    -- Flag rows to FILTER OUT: delivered + not processed + more than 2 days since delivery
    CASE
        WHEN dl.CreateDate IS NOT NULL
         AND lastROLine.CreateDate IS NULL
         AND biz.BusinessDays_DeliveryToEnd > 2
        THEN 1 ELSE 0
    END AS Exclude_DeliveredNotProcessed_Over2Days,

    -- Status classification
    CASE
        WHEN rs.Description = 'NEW' AND lastROLine.CreateDate IS NULL THEN 'STILL_OPEN'
        WHEN rs.Description = 'NEW' AND dl.CreateDate IS NOT NULL THEN 'DELIVERED_NOT_PROCESSED'
        ELSE 'UNKNOWN_STATUS'
    END AS DockStatus
FROM Plus.pls.ROHeader rh
JOIN Plus.pls.CodeStatus rs
    ON rs.ID = rh.StatusID

CROSS APPLY (
    SELECT TOP 1 crst1.ProgramID, crst1.TrackingNo, aus.Username
    FROM Plus.pls.CarrierResult crst1
    JOIN Plus.pls.[User] aus ON aus.ID = crst1.UserID
    WHERE crst1.OrderHeaderID = rh.ID
      AND crst1.ProgramID = rh.ProgramID
      AND crst1.OrderType = 'RO'
    ORDER BY crst1.ID DESC
) crst

OUTER APPLY (
    SELECT TOP 1 dlx.TrackingNo, dlx.CreateDate
    FROM Plus.pls.RODockLog dlx
    WHERE dlx.ROHeaderID = rh.ID
    ORDER BY dlx.ID DESC
) dl

OUTER APPLY (
    SELECT TOP 1 rl.CreateDate
    FROM Plus.pls.ROLine rl
    WHERE rl.ROHeaderID = rh.ID
    ORDER BY rl.ID DESC
) lastROLine

OUTER APPLY (
    SELECT TOP 1 rha.Value AS Branch
    FROM Plus.pls.ROHeaderAttribute rha
    JOIN Plus.pls.CodeAttribute att ON att.ID = rha.AttributeID
    WHERE rha.ROHeaderID = rh.ID
      AND att.AttributeName = 'SHIPFROMORG'
    ORDER BY rha.ID DESC
) br

-- Business-days aging between DeliveryDate and ProcessedDate (or Today if not processed)
-- Using proven pattern from ecrdashboards.sql
OUTER APPLY (
    SELECT
        CASE
            WHEN dl.CreateDate IS NULL THEN NULL
            -- First check: If total hours < 24, return 0 days
            WHEN (DATEDIFF(MINUTE, dl.CreateDate, COALESCE(lastROLine.CreateDate, GETDATE())) / 60.0) < 24.0 THEN 0
            ELSE (
                DATEDIFF(DAY, dl.CreateDate, COALESCE(lastROLine.CreateDate, GETDATE()))
                - (DATEDIFF(WEEK, dl.CreateDate, COALESCE(lastROLine.CreateDate, GETDATE())) * 2)  -- Subtract weekends
                - CASE WHEN DATEPART(WEEKDAY, dl.CreateDate) = 7 THEN 1 ELSE 0 END  -- If start is Saturday
                - CASE WHEN DATEPART(WEEKDAY, COALESCE(lastROLine.CreateDate, GETDATE())) = 1 THEN 1 ELSE 0 END  -- If end is Sunday
                + CASE WHEN DATEPART(WEEKDAY, dl.CreateDate) = 1 THEN 1 ELSE 0 END  -- If start is Sunday, add back
                + CASE WHEN DATEPART(WEEKDAY, COALESCE(lastROLine.CreateDate, GETDATE())) = 7 THEN 1 ELSE 0 END  -- If end is Saturday, add back
            )
        END AS BusinessDays_DeliveryToEnd
) biz

-- SLA due date + compliance flag (row-level)
OUTER APPLY (
    SELECT
        -- Monday of the delivery week, independent of @@DATEFIRST
        CASE
            WHEN dl.CreateDate IS NULL THEN NULL
            ELSE
                CASE
                    WHEN COALESCE(lastROLine.CreateDate, GETDATE())
                        <= CASE
                               WHEN dl.CreateDate
                                    <= DATEADD(HOUR, 14, DATEADD(DAY, 2,
                                           DATEADD(DAY, -(DATEDIFF(DAY, '19000101', CONVERT(DATE, dl.CreateDate)) % 7),
                                               CONVERT(DATE, dl.CreateDate)
                                           )))
                               THEN DATEADD(HOUR, 17, DATEADD(DAY, 4,
                                           DATEADD(DAY, -(DATEDIFF(DAY, '19000101', CONVERT(DATE, dl.CreateDate)) % 7),
                                               CONVERT(DATE, dl.CreateDate)
                                           )))
                               ELSE DATEADD(DAY, 7, DATEADD(HOUR, 17, DATEADD(DAY, 4,
                                           DATEADD(DAY, -(DATEDIFF(DAY, '19000101', CONVERT(DATE, dl.CreateDate)) % 7),
                                               CONVERT(DATE, dl.CreateDate)
                                           ))))
                           END
                    THEN 1 ELSE 0
                END
        END AS SLA_CompliantFlag,

        CASE
            WHEN dl.CreateDate IS NULL THEN NULL
            ELSE
                CASE
                    WHEN dl.CreateDate
                         <= DATEADD(HOUR, 14, DATEADD(DAY, 2,
                                DATEADD(DAY, -(DATEDIFF(DAY, '19000101', CONVERT(DATE, dl.CreateDate)) % 7),
                                    CONVERT(DATE, dl.CreateDate)
                                )))
                    THEN DATEADD(HOUR, 17, DATEADD(DAY, 4,
                                DATEADD(DAY, -(DATEDIFF(DAY, '19000101', CONVERT(DATE, dl.CreateDate)) % 7),
                                    CONVERT(DATE, dl.CreateDate)
                                )))
                    ELSE DATEADD(DAY, 7, DATEADD(HOUR, 17, DATEADD(DAY, 4,
                                DATEADD(DAY, -(DATEDIFF(DAY, '19000101', CONVERT(DATE, dl.CreateDate)) % 7),
                                    CONVERT(DATE, dl.CreateDate)
                                ))))
                END
        END AS SLA_DueDateTime
) sla

WHERE rs.Description = 'NEW'
  AND rh.ProgramID = 10068;