-- ================================================
-- ALL OEM ACTION CATEGORIES: Request to Reply aging
-- EMAIL = "waiting to be submitted by vendor"
-- All other categories remain as-is
-- ================================================

WITH RequestToReplyAging AS (
    SELECT 
        -- Supplier: SUPPLIER_NO or Manufacturer fallback
        COALESCE(
            (SELECT TOP 1 pna.Value
             FROM Plus.pls.PartNoAttribute pna
             INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
             WHERE pna.PartNo = rma.[part_code]
               AND ca.AttributeName = 'SUPPLIER_NO'
             ORDER BY pna.LastActivityDate DESC),
            rma.[manufacturer]
        ) AS Supplier,
        rma.[Ticket Number],
        rma.[rma_number],
        rma.[part_code],
        rma.[requested _qty],
        rma.[Entry Date] AS EntryDate,
        rma.[request_timestamp] AS RequestDate,
        rma.[reply_timestamp] AS ReplyDate,
        rma.[rma_num_timestamp] AS ApprovalDate,
        rma.[Shipped_date] AS ShipDate,
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
        ) AS DollarAmount,
        rma.[oem_action],
        rma.[Status],
        -- Categorize OEM Action: EMAIL = "waiting to be submitted by vendor"
        CASE 
            WHEN rma.[oem_action] = 'EMAIL' THEN 'Waiting to be submitted to vendor'
            WHEN rma.[oem_action] IS NOT NULL AND LTRIM(RTRIM(rma.[oem_action])) != '' THEN rma.[oem_action]
            ELSE 'UNKNOWN'
        END AS OEMActionCategory,
        -- Calculate business days from Request to Reply (excluding weekends, >= 24 hours)
        CASE 
            WHEN rma.[request_timestamp] IS NOT NULL AND rma.[reply_timestamp] IS NOT NULL THEN
                CASE 
                    WHEN DATEDIFF(HOUR, rma.[request_timestamp], rma.[reply_timestamp]) < 24 THEN 0
                    ELSE (
                        -- Total calendar days
                        DATEDIFF(DAY, rma.[request_timestamp], rma.[reply_timestamp])
                        -- Subtract 2 days for each complete week
                        - (DATEDIFF(WEEK, rma.[request_timestamp], rma.[reply_timestamp]) * 2)
                        -- Adjust for partial weekends at start
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 7 THEN 1  -- If start is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 1 THEN 1    -- If start is Sunday, subtract 1
                            ELSE 0
                          END
                        -- Adjust for partial weekends at end
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[reply_timestamp]) = 7 THEN 1     -- If end is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[reply_timestamp]) = 1 THEN 1      -- If end is Sunday, subtract 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromRequestToReply,
        -- Calculate business days from Entry Date to Request (Request SLA - 5 business day target)
        CASE 
            WHEN rma.[Entry Date] IS NOT NULL AND rma.[request_timestamp] IS NOT NULL THEN
                CASE 
                    WHEN DATEDIFF(HOUR, rma.[Entry Date], rma.[request_timestamp]) < 24 THEN 0
                    ELSE (
                        -- Total calendar days
                        DATEDIFF(DAY, rma.[Entry Date], rma.[request_timestamp])
                        -- Subtract 2 days for each complete week
                        - (DATEDIFF(WEEK, rma.[Entry Date], rma.[request_timestamp]) * 2)
                        -- Adjust for partial weekends at start
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 7 THEN 1  -- If start is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 1 THEN 1    -- If start is Sunday, subtract 1
                            ELSE 0
                          END
                        -- Adjust for partial weekends at end
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 7 THEN 1     -- If end is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 1 THEN 1      -- If end is Sunday, subtract 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromEntryToRequest,
        -- Calculate business days from Approval to Ship (Approval-to-Ship SLA - 5 business day target)
        CASE 
            WHEN rma.[rma_num_timestamp] IS NOT NULL AND rma.[Shipped_date] IS NOT NULL THEN
                CASE 
                    WHEN DATEDIFF(HOUR, rma.[rma_num_timestamp], rma.[Shipped_date]) < 24 THEN 0
                    ELSE (
                        -- Total calendar days
                        DATEDIFF(DAY, rma.[rma_num_timestamp], rma.[Shipped_date])
                        -- Subtract 2 days for each complete week
                        - (DATEDIFF(WEEK, rma.[rma_num_timestamp], rma.[Shipped_date]) * 2)
                        -- Adjust for partial weekends at start
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 7 THEN 1  -- If start is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 1 THEN 1    -- If start is Sunday, subtract 1
                            ELSE 0
                          END
                        -- Adjust for partial weekends at end
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 7 THEN 1     -- If end is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 1 THEN 1      -- If end is Sunday, subtract 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromApprovalToShip
    FROM [ClarityWarehouse].[rpt].[ADTReconextRMAData] rma
    WHERE rma.[part_code] IS NOT NULL
)

-- ============================================
-- SUMMARY BY SUPPLIER AND OEM ACTION CATEGORY
-- ============================================
SELECT 
    Supplier,
    OEMActionCategory,
    COUNT(*) AS TotalRecords,
    COUNT(CASE WHEN ReplyDate IS NOT NULL THEN 1 END) AS TotalWithReply,
    COUNT(CASE WHEN BusinessDaysFromRequestToReply <= 5 THEN 1 END) AS RespondedWithin5Days,
    COUNT(CASE WHEN BusinessDaysFromRequestToReply > 5 THEN 1 END) AS RespondedAfter5Days,
    CAST(COUNT(CASE WHEN BusinessDaysFromRequestToReply <= 5 THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN ReplyDate IS NOT NULL THEN 1 END), 0) AS DECIMAL(10,2)) AS PercentRespondedWithin5Days,
    CAST(COUNT(CASE WHEN BusinessDaysFromRequestToReply > 5 THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN ReplyDate IS NOT NULL THEN 1 END), 0) AS DECIMAL(10,2)) AS PercentRespondedAfter5Days,
    SUM(DollarAmount) AS TotalDollarAmount,
    SUM(CASE WHEN BusinessDaysFromRequestToReply <= 5 THEN DollarAmount ELSE 0 END) AS DollarAmountWithin5Days,
    SUM(CASE WHEN BusinessDaysFromRequestToReply > 5 THEN DollarAmount ELSE 0 END) AS DollarAmountAfter5Days
FROM RequestToReplyAging
GROUP BY Supplier, OEMActionCategory
ORDER BY Supplier, OEMActionCategory;

-- ============================================
-- OVERALL SUMMARY BY OEM ACTION CATEGORY
-- ============================================
WITH RequestToReplyAging AS (
    SELECT 
        -- Supplier: SUPPLIER_NO or Manufacturer fallback
        COALESCE(
            (SELECT TOP 1 pna.Value
             FROM Plus.pls.PartNoAttribute pna
             INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
             WHERE pna.PartNo = rma.[part_code]
               AND ca.AttributeName = 'SUPPLIER_NO'
             ORDER BY pna.LastActivityDate DESC),
            rma.[manufacturer]
        ) AS Supplier,
        rma.[Ticket Number],
        rma.[rma_number],
        rma.[part_code],
        rma.[requested _qty],
        rma.[Entry Date] AS EntryDate,
        rma.[request_timestamp] AS RequestDate,
        rma.[reply_timestamp] AS ReplyDate,
        rma.[rma_num_timestamp] AS ApprovalDate,
        rma.[Shipped_date] AS ShipDate,
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
        ) AS DollarAmount,
        rma.[oem_action],
        rma.[Status],
        -- Categorize OEM Action: EMAIL = "waiting to be submitted by vendor"
        CASE 
            WHEN rma.[oem_action] = 'EMAIL' THEN 'Waiting to be submitted to vendor'
            WHEN rma.[oem_action] IS NOT NULL AND LTRIM(RTRIM(rma.[oem_action])) != '' THEN rma.[oem_action]
            ELSE 'UNKNOWN'
        END AS OEMActionCategory,
        -- Calculate business days from Request to Reply
        CASE 
            WHEN rma.[request_timestamp] IS NOT NULL AND rma.[reply_timestamp] IS NOT NULL THEN
                CASE 
                    WHEN DATEDIFF(HOUR, rma.[request_timestamp], rma.[reply_timestamp]) < 24 THEN 0
                    ELSE (
                        DATEDIFF(DAY, rma.[request_timestamp], rma.[reply_timestamp])
                        - (DATEDIFF(WEEK, rma.[request_timestamp], rma.[reply_timestamp]) * 2)
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 7 THEN 1
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 1 THEN 1
                            ELSE 0
                          END
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[reply_timestamp]) = 7 THEN 1
                            WHEN DATEPART(WEEKDAY, rma.[reply_timestamp]) = 1 THEN 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromRequestToReply,
        -- Calculate business days from Entry Date to Request (Request SLA - 5 business day target)
        CASE 
            WHEN rma.[Entry Date] IS NOT NULL AND rma.[request_timestamp] IS NOT NULL THEN
                CASE 
                    WHEN DATEDIFF(HOUR, rma.[Entry Date], rma.[request_timestamp]) < 24 THEN 0
                    ELSE (
                        -- Total calendar days
                        DATEDIFF(DAY, rma.[Entry Date], rma.[request_timestamp])
                        -- Subtract 2 days for each complete week
                        - (DATEDIFF(WEEK, rma.[Entry Date], rma.[request_timestamp]) * 2)
                        -- Adjust for partial weekends at start
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 7 THEN 1  -- If start is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 1 THEN 1    -- If start is Sunday, subtract 1
                            ELSE 0
                          END
                        -- Adjust for partial weekends at end
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 7 THEN 1     -- If end is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 1 THEN 1      -- If end is Sunday, subtract 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromEntryToRequest,
        -- Calculate business days from Approval to Ship (Approval-to-Ship SLA - 5 business day target)
        CASE 
            WHEN rma.[rma_num_timestamp] IS NOT NULL AND rma.[Shipped_date] IS NOT NULL THEN
                CASE 
                    WHEN DATEDIFF(HOUR, rma.[rma_num_timestamp], rma.[Shipped_date]) < 24 THEN 0
                    ELSE (
                        -- Total calendar days
                        DATEDIFF(DAY, rma.[rma_num_timestamp], rma.[Shipped_date])
                        -- Subtract 2 days for each complete week
                        - (DATEDIFF(WEEK, rma.[rma_num_timestamp], rma.[Shipped_date]) * 2)
                        -- Adjust for partial weekends at start
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 7 THEN 1  -- If start is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 1 THEN 1    -- If start is Sunday, subtract 1
                            ELSE 0
                          END
                        -- Adjust for partial weekends at end
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 7 THEN 1     -- If end is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 1 THEN 1      -- If end is Sunday, subtract 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromApprovalToShip
    FROM [ClarityWarehouse].[rpt].[ADTReconextRMAData] rma
    WHERE rma.[part_code] IS NOT NULL
)
SELECT 
    OEMActionCategory AS Category,
    COUNT(*) AS TotalRecords,
    COUNT(CASE WHEN ReplyDate IS NOT NULL THEN 1 END) AS TotalWithReply,
    COUNT(CASE WHEN BusinessDaysFromRequestToReply <= 5 THEN 1 END) AS RespondedWithin5Days,
    COUNT(CASE WHEN BusinessDaysFromRequestToReply > 5 THEN 1 END) AS RespondedAfter5Days,
    CAST(COUNT(CASE WHEN BusinessDaysFromRequestToReply <= 5 THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN ReplyDate IS NOT NULL THEN 1 END), 0) AS DECIMAL(10,2)) AS PercentRespondedWithin5Days,
    CAST(COUNT(CASE WHEN BusinessDaysFromRequestToReply > 5 THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN ReplyDate IS NOT NULL THEN 1 END), 0) AS DECIMAL(10,2)) AS PercentRespondedAfter5Days,
    SUM(DollarAmount) AS TotalDollarAmount,
    SUM(CASE WHEN BusinessDaysFromRequestToReply <= 5 THEN DollarAmount ELSE 0 END) AS DollarAmountWithin5Days,
    SUM(CASE WHEN BusinessDaysFromRequestToReply > 5 THEN DollarAmount ELSE 0 END) AS DollarAmountAfter5Days
FROM RequestToReplyAging
GROUP BY OEMActionCategory
ORDER BY OEMActionCategory;

-- ============================================
-- DETAILED RECORDS FOR ALL CATEGORIES
-- ============================================
WITH RequestToReplyAging AS (
    SELECT 
        -- Supplier: SUPPLIER_NO or Manufacturer fallback
        COALESCE(
            (SELECT TOP 1 pna.Value
             FROM Plus.pls.PartNoAttribute pna
             INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
             WHERE pna.PartNo = rma.[part_code]
               AND ca.AttributeName = 'SUPPLIER_NO'
             ORDER BY pna.LastActivityDate DESC),
            rma.[manufacturer]
        ) AS Supplier,
        rma.[Ticket Number],
        rma.[rma_number],
        rma.[part_code],
        rma.[requested _qty],
        rma.[Entry Date] AS EntryDate,
        rma.[request_timestamp] AS RequestDate,
        rma.[reply_timestamp] AS ReplyDate,
        rma.[rma_num_timestamp] AS ApprovalDate,
        rma.[Shipped_date] AS ShipDate,
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
        ) AS DollarAmount,
        rma.[oem_action],
        rma.[Status],
        -- Categorize OEM Action: EMAIL = "waiting to be submitted by vendor"
        CASE 
            WHEN rma.[oem_action] = 'EMAIL' THEN 'Waiting to be submitted to vendor'
            WHEN rma.[oem_action] IS NOT NULL AND LTRIM(RTRIM(rma.[oem_action])) != '' THEN rma.[oem_action]
            ELSE 'UNKNOWN'
        END AS OEMActionCategory,
        -- Calculate business days from Request to Reply
        CASE 
            WHEN rma.[request_timestamp] IS NOT NULL AND rma.[reply_timestamp] IS NOT NULL THEN
                CASE 
                    WHEN DATEDIFF(HOUR, rma.[request_timestamp], rma.[reply_timestamp]) < 24 THEN 0
                    ELSE (
                        DATEDIFF(DAY, rma.[request_timestamp], rma.[reply_timestamp])
                        - (DATEDIFF(WEEK, rma.[request_timestamp], rma.[reply_timestamp]) * 2)
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 7 THEN 1
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 1 THEN 1
                            ELSE 0
                          END
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[reply_timestamp]) = 7 THEN 1
                            WHEN DATEPART(WEEKDAY, rma.[reply_timestamp]) = 1 THEN 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromRequestToReply,
        -- Calculate business days from Entry Date to Request (Request SLA - 5 business day target)
        CASE 
            WHEN rma.[Entry Date] IS NOT NULL AND rma.[request_timestamp] IS NOT NULL THEN
                CASE 
                    WHEN DATEDIFF(HOUR, rma.[Entry Date], rma.[request_timestamp]) < 24 THEN 0
                    ELSE (
                        -- Total calendar days
                        DATEDIFF(DAY, rma.[Entry Date], rma.[request_timestamp])
                        -- Subtract 2 days for each complete week
                        - (DATEDIFF(WEEK, rma.[Entry Date], rma.[request_timestamp]) * 2)
                        -- Adjust for partial weekends at start
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 7 THEN 1  -- If start is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 1 THEN 1    -- If start is Sunday, subtract 1
                            ELSE 0
                          END
                        -- Adjust for partial weekends at end
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 7 THEN 1     -- If end is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 1 THEN 1      -- If end is Sunday, subtract 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromEntryToRequest,
        -- Calculate business days from Approval to Ship (Approval-to-Ship SLA - 5 business day target)
        CASE 
            WHEN rma.[rma_num_timestamp] IS NOT NULL AND rma.[Shipped_date] IS NOT NULL THEN
                CASE 
                    WHEN DATEDIFF(HOUR, rma.[rma_num_timestamp], rma.[Shipped_date]) < 24 THEN 0
                    ELSE (
                        -- Total calendar days
                        DATEDIFF(DAY, rma.[rma_num_timestamp], rma.[Shipped_date])
                        -- Subtract 2 days for each complete week
                        - (DATEDIFF(WEEK, rma.[rma_num_timestamp], rma.[Shipped_date]) * 2)
                        -- Adjust for partial weekends at start
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 7 THEN 1  -- If start is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 1 THEN 1    -- If start is Sunday, subtract 1
                            ELSE 0
                          END
                        -- Adjust for partial weekends at end
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 7 THEN 1     -- If end is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 1 THEN 1      -- If end is Sunday, subtract 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromApprovalToShip
    FROM [ClarityWarehouse].[rpt].[ADTReconextRMAData] rma
    WHERE rma.[part_code] IS NOT NULL
)
SELECT 
    Supplier,
    OEMActionCategory,
    [Ticket Number],
    [rma_number],
    [part_code],
    [requested _qty],
    RequestDate,
    ReplyDate,
    ApprovalDate,
    ShipDate,
    BusinessDaysFromRequestToReply AS DaysFromRequestToReply,
    BusinessDaysFromEntryToRequest AS DaysFromEntryToRequest,
    BusinessDaysFromApprovalToShip AS DaysFromApprovalToShip,
    DollarAmount,
    [oem_action] AS OriginalOEMAction,
    [Status],
    CASE 
        WHEN BusinessDaysFromRequestToReply <= 5 THEN 'Within 5 Days'
        WHEN BusinessDaysFromRequestToReply > 5 THEN 'After 5 Days'
        ELSE 'No Reply'
    END AS ResponseCategory
FROM RequestToReplyAging
ORDER BY Supplier, OEMActionCategory, BusinessDaysFromRequestToReply DESC, RequestDate DESC;

