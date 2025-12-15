CREATE OR ALTER         VIEW rpt.ADTRMA AS

SELECT 
    Supplier,
    OEMActionCategory,
    [Ticket Number],
    [rma_number],
    [part_code],
    [requested _qty],
    EntryDate,
    RequestDate,
    ReplyDate,
    ApprovalDate,
    ShipDate,
    ShipFlag,
    CreditReplacement,
    CreditReplacementDate,
    BusinessDaysFromRequestToReply AS DaysFromRequestToReply,
    BusinessDaysFromEntryToRequest AS DaysFromEntryToRequest,
    BusinessDaysFromApprovalToShip AS DaysFromApprovalToShip,
    BusinessDaysFromShipToCredit AS DaysFromShipToCredit,
    -- Exact Calendar Days Aging Columns
    RequestAgingDays,
    ResponseAgingDays,
    ApprovalAgingDays,
    CreditAgingDays,
    DollarAmount,
    TotalDollarAmount,
    TotalDollarAmountFormatted,
    [oem_action] AS OriginalOEMAction,
    [Status]
FROM (
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
        -- Ship Flag: Y if shipped, N if not shipped
        CASE 
            WHEN rma.[Shipped_date] IS NOT NULL THEN 'Y'
            ELSE 'N'
        END AS ShipFlag,
        rma.[Credit/Replacement] AS CreditReplacement,
        rma.[CreditReplacementDate] AS CreditReplacementDate,
        -- Cost: PartNoAttribute Cost or RMA Extended Cost fallback (calculated once via OUTER APPLY)
        COALESCE(cost_attr.AttributeCost, rma.[EXT Cost]) AS DollarAmount,
        -- Total Dollar Amount: Quantity * Dollar Amount (reuse DollarAmount calculation)
        CAST(rma.[requested _qty] AS DECIMAL(18,2)) * COALESCE(cost_attr.AttributeCost, rma.[EXT Cost]) AS TotalDollarAmount,
        -- Formatted Total Dollar Amount with $ sign (reuse DollarAmount calculation)
        FORMAT(
            CAST(rma.[requested _qty] AS DECIMAL(18,2)) * COALESCE(cost_attr.AttributeCost, rma.[EXT Cost]),
            'C'
        ) AS TotalDollarAmountFormatted,
        rma.[oem_action],
        rma.[Status],
        -- Categorize OEM Action: Validation rules first, then original logic
        CASE 
            -- Validation: If CreditReplacement has an actual numeric value, it's CLOSED (highest priority)
            WHEN rma.[Credit/Replacement] IS NOT NULL 
                 AND ISNUMERIC(rma.[Credit/Replacement]) = 1 
                 AND CAST(rma.[Credit/Replacement] AS DECIMAL(18,2)) > 0 THEN 'CLOSED'
            -- Validation: If Approval Date exists but current category would be Pending Request, it's APPROVED
            WHEN rma.[rma_num_timestamp] IS NOT NULL AND rma.[oem_action] = 'EMAIL' THEN 'APPROVED'
            -- Validation: If Request Date exists and oem_action is EMAIL, it's AWAITING OEM DISPOSITION
            WHEN rma.[request_timestamp] IS NOT NULL AND rma.[oem_action] = 'EMAIL' THEN 'AWAITING OEM DISPOSITION'
            -- Validation: If Reply Date exists (and no Approval Date) and oem_action is EMAIL, it's AWAITING OEM DISPOSITION
            WHEN rma.[reply_timestamp] IS NOT NULL 
                 AND rma.[rma_num_timestamp] IS NULL 
                 AND rma.[oem_action] = 'EMAIL' THEN 'AWAITING OEM DISPOSITION'
            -- Original logic: EMAIL = "waiting to be submitted by vendor"
            WHEN rma.[oem_action] = 'EMAIL' THEN 'Pending Request'
            -- Validation: If Approval Date exists and oem_action is NOT DECLINED, it's APPROVED
            WHEN rma.[rma_num_timestamp] IS NOT NULL 
                 AND rma.[oem_action] != 'DECLINED' 
                 AND rma.[oem_action] IS NOT NULL THEN 'APPROVED'
            -- Validation: Any oem_action that is AWAITING APPROVAL becomes AWAITING OEM DISPOSITION
            WHEN rma.[oem_action] = 'AWAITING APPROVAL' THEN 'AWAITING OEM DISPOSITION'
            -- Validation: Any oem_action starting with HOLD becomes HOLD
            WHEN rma.[oem_action] LIKE 'HOLD%' THEN 'HOLD'
            WHEN rma.[oem_action] IS NOT NULL AND LTRIM(RTRIM(rma.[oem_action])) != '' THEN rma.[oem_action]
            ELSE ''
        END AS OEMActionCategory,
        -- Calculate business days from Request to Reply (use GETDATE() if reply is NULL)
        CASE 
            WHEN rma.[request_timestamp] IS NOT NULL THEN
                CASE 
                    -- Business hours: total hours minus weekend hours
                    WHEN (
                        DATEDIFF(HOUR, rma.[request_timestamp], COALESCE(rma.[reply_timestamp], GETDATE()))
                        - (DATEDIFF(WEEK, rma.[request_timestamp], COALESCE(rma.[reply_timestamp], GETDATE())) * 48)
                        - CASE WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 7 THEN 
                            DATEDIFF(HOUR, rma.[request_timestamp], DATEADD(DAY, 1, CAST(rma.[request_timestamp] AS DATE))) 
                          ELSE 0 END
                        - CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[reply_timestamp], GETDATE())) = 1 THEN 
                            DATEDIFF(HOUR, CAST(COALESCE(rma.[reply_timestamp], GETDATE()) AS DATE), COALESCE(rma.[reply_timestamp], GETDATE())) 
                          ELSE 0 END
                    ) < 24 THEN 0
                    ELSE (
                        DATEDIFF(DAY, rma.[request_timestamp], COALESCE(rma.[reply_timestamp], GETDATE()))
                        - (DATEDIFF(WEEK, rma.[request_timestamp], COALESCE(rma.[reply_timestamp], GETDATE())) * 2)
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 7 THEN 1
                            WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 1 THEN 1
                            ELSE 0
                          END
                        - CASE 
                            WHEN DATEPART(WEEKDAY, COALESCE(rma.[reply_timestamp], GETDATE())) = 7 THEN 1
                            WHEN DATEPART(WEEKDAY, COALESCE(rma.[reply_timestamp], GETDATE())) = 1 THEN 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromRequestToReply,
        -- Calculate business days from Entry Date to Request (Request SLA - 5 business day target)
        -- Use GETDATE() if request_timestamp is NULL
        CASE 
            WHEN rma.[Entry Date] IS NOT NULL THEN
                CASE 
                    -- Business hours: total hours minus weekend hours
                    WHEN (
                        DATEDIFF(HOUR, rma.[Entry Date], COALESCE(rma.[request_timestamp], GETDATE()))
                        - (DATEDIFF(WEEK, rma.[Entry Date], COALESCE(rma.[request_timestamp], GETDATE())) * 48)
                        - CASE WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 7 THEN 
                            DATEDIFF(HOUR, rma.[Entry Date], DATEADD(DAY, 1, CAST(rma.[Entry Date] AS DATE))) 
                          ELSE 0 END
                        - CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[request_timestamp], GETDATE())) = 1 THEN 
                            DATEDIFF(HOUR, CAST(COALESCE(rma.[request_timestamp], GETDATE()) AS DATE), COALESCE(rma.[request_timestamp], GETDATE())) 
                          ELSE 0 END
                    ) < 24 THEN 0
                    ELSE (
                        -- Total calendar days
                        DATEDIFF(DAY, rma.[Entry Date], COALESCE(rma.[request_timestamp], GETDATE()))
                        -- Subtract 2 days for each complete week
                        - (DATEDIFF(WEEK, rma.[Entry Date], COALESCE(rma.[request_timestamp], GETDATE())) * 2)
                        -- Adjust for partial weekends at start
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 7 THEN 1  -- If start is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 1 THEN 1    -- If start is Sunday, subtract 1
                            ELSE 0
                          END
                        -- Adjust for partial weekends at end
                        - CASE 
                            WHEN DATEPART(WEEKDAY, COALESCE(rma.[request_timestamp], GETDATE())) = 7 THEN 1     -- If end is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, COALESCE(rma.[request_timestamp], GETDATE())) = 1 THEN 1      -- If end is Sunday, subtract 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromEntryToRequest,
        -- Calculate business days from Approval to Ship (Approval-to-Ship SLA - 5 business day target)
        -- Use GETDATE() if Shipped_date is NULL
        CASE 
            WHEN rma.[rma_num_timestamp] IS NOT NULL THEN
                CASE 
                    -- Business hours: total hours minus weekend hours
                    WHEN (
                        DATEDIFF(HOUR, rma.[rma_num_timestamp], COALESCE(rma.[Shipped_date], GETDATE()))
                        - (DATEDIFF(WEEK, rma.[rma_num_timestamp], COALESCE(rma.[Shipped_date], GETDATE())) * 48)
                        - CASE WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 7 THEN 
                            DATEDIFF(HOUR, rma.[rma_num_timestamp], DATEADD(DAY, 1, CAST(rma.[rma_num_timestamp] AS DATE))) 
                          ELSE 0 END
                        - CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[Shipped_date], GETDATE())) = 1 THEN 
                            DATEDIFF(HOUR, CAST(COALESCE(rma.[Shipped_date], GETDATE()) AS DATE), COALESCE(rma.[Shipped_date], GETDATE())) 
                          ELSE 0 END
                    ) < 24 THEN 0
                    ELSE (
                        -- Total calendar days
                        DATEDIFF(DAY, rma.[rma_num_timestamp], COALESCE(rma.[Shipped_date], GETDATE()))
                        -- Subtract 2 days for each complete week
                        - (DATEDIFF(WEEK, rma.[rma_num_timestamp], COALESCE(rma.[Shipped_date], GETDATE())) * 2)
                        -- Adjust for partial weekends at start
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 7 THEN 1  -- If start is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 1 THEN 1    -- If start is Sunday, subtract 1
                            ELSE 0
                          END
                        -- Adjust for partial weekends at end
                        - CASE 
                            WHEN DATEPART(WEEKDAY, COALESCE(rma.[Shipped_date], GETDATE())) = 7 THEN 1     -- If end is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, COALESCE(rma.[Shipped_date], GETDATE())) = 1 THEN 1      -- If end is Sunday, subtract 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromApprovalToShip,
        -- Calculate business days from Ship to Credit/Replacement (Credit SLA - 30 business day target)
        -- Use GETDATE() if CreditReplacementDate is NULL
        CASE 
            WHEN rma.[Shipped_date] IS NOT NULL THEN
                CASE 
                    -- Business hours: total hours minus weekend hours
                    WHEN (
                        DATEDIFF(HOUR, rma.[Shipped_date], COALESCE(rma.[CreditReplacementDate], GETDATE()))
                        - (DATEDIFF(WEEK, rma.[Shipped_date], COALESCE(rma.[CreditReplacementDate], GETDATE())) * 48)
                        - CASE WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 7 THEN 
                            DATEDIFF(HOUR, rma.[Shipped_date], DATEADD(DAY, 1, CAST(rma.[Shipped_date] AS DATE))) 
                          ELSE 0 END
                        - CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[CreditReplacementDate], GETDATE())) = 1 THEN 
                            DATEDIFF(HOUR, CAST(COALESCE(rma.[CreditReplacementDate], GETDATE()) AS DATE), COALESCE(rma.[CreditReplacementDate], GETDATE())) 
                          ELSE 0 END
                    ) < 24 THEN 0
                    ELSE (
                        -- Total calendar days
                        DATEDIFF(DAY, rma.[Shipped_date], COALESCE(rma.[CreditReplacementDate], GETDATE()))
                        -- Subtract 2 days for each complete week
                        - (DATEDIFF(WEEK, rma.[Shipped_date], COALESCE(rma.[CreditReplacementDate], GETDATE())) * 2)
                        -- Adjust for partial weekends at start
                        - CASE 
                            WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 7 THEN 1  -- If start is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 1 THEN 1    -- If start is Sunday, subtract 1
                            ELSE 0
                          END
                        -- Adjust for partial weekends at end
                        - CASE 
                            WHEN DATEPART(WEEKDAY, COALESCE(rma.[CreditReplacementDate], GETDATE())) = 7 THEN 1     -- If end is Saturday, subtract 1
                            WHEN DATEPART(WEEKDAY, COALESCE(rma.[CreditReplacementDate], GETDATE())) = 1 THEN 1      -- If end is Sunday, subtract 1
                            ELSE 0
                          END
                    )
                END
            ELSE NULL
        END AS BusinessDaysFromShipToCredit,
        -- REQUEST AGING: Business days from Entry Date to Request Date (or current date if no request)
        CASE 
            WHEN rma.[Entry Date] IS NOT NULL THEN 
                DATEDIFF(DAY, rma.[Entry Date], COALESCE(rma.[request_timestamp], GETDATE()))
                - (DATEDIFF(WEEK, rma.[Entry Date], COALESCE(rma.[request_timestamp], GETDATE())) * 2)
                - CASE WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 7 THEN 1 ELSE 0 END
                - CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[request_timestamp], GETDATE())) = 1 THEN 1 ELSE 0 END
                + CASE WHEN DATEPART(WEEKDAY, rma.[Entry Date]) = 1 THEN 1 ELSE 0 END
                + CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[request_timestamp], GETDATE())) = 7 THEN 1 ELSE 0 END
            ELSE NULL
        END AS RequestAgingDays,
        -- RESPONSE AGING: Business days from Request Date to Reply Date (or current date if no reply)
        CASE 
            WHEN rma.[request_timestamp] IS NOT NULL THEN 
                DATEDIFF(DAY, rma.[request_timestamp], COALESCE(rma.[reply_timestamp], GETDATE()))
                - (DATEDIFF(WEEK, rma.[request_timestamp], COALESCE(rma.[reply_timestamp], GETDATE())) * 2)
                - CASE WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 7 THEN 1 ELSE 0 END
                - CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[reply_timestamp], GETDATE())) = 1 THEN 1 ELSE 0 END
                + CASE WHEN DATEPART(WEEKDAY, rma.[request_timestamp]) = 1 THEN 1 ELSE 0 END
                + CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[reply_timestamp], GETDATE())) = 7 THEN 1 ELSE 0 END
            ELSE NULL
        END AS ResponseAgingDays,
        -- APPROVAL AGING: Business days from Approval Date to Ship Date (or current date if not shipped)
        CASE 
            WHEN rma.[rma_num_timestamp] IS NOT NULL THEN 
                DATEDIFF(DAY, rma.[rma_num_timestamp], COALESCE(rma.[Shipped_date], GETDATE()))
                - (DATEDIFF(WEEK, rma.[rma_num_timestamp], COALESCE(rma.[Shipped_date], GETDATE())) * 2)
                - CASE WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 7 THEN 1 ELSE 0 END
                - CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[Shipped_date], GETDATE())) = 1 THEN 1 ELSE 0 END
                + CASE WHEN DATEPART(WEEKDAY, rma.[rma_num_timestamp]) = 1 THEN 1 ELSE 0 END
                + CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[Shipped_date], GETDATE())) = 7 THEN 1 ELSE 0 END
            ELSE NULL
        END AS ApprovalAgingDays,
        -- CREDIT AGING: Business days from Ship Date to Credit/Replacement Date (or current date if no credit)
        CASE 
            WHEN rma.[Shipped_date] IS NOT NULL THEN 
                DATEDIFF(DAY, rma.[Shipped_date], COALESCE(rma.[CreditReplacementDate], GETDATE()))
                - (DATEDIFF(WEEK, rma.[Shipped_date], COALESCE(rma.[CreditReplacementDate], GETDATE())) * 2)
                - CASE WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 7 THEN 1 ELSE 0 END
                - CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[CreditReplacementDate], GETDATE())) = 1 THEN 1 ELSE 0 END
                + CASE WHEN DATEPART(WEEKDAY, rma.[Shipped_date]) = 1 THEN 1 ELSE 0 END
                + CASE WHEN DATEPART(WEEKDAY, COALESCE(rma.[CreditReplacementDate], GETDATE())) = 7 THEN 1 ELSE 0 END
            ELSE NULL
        END AS CreditAgingDays
    FROM [ClarityWarehouse].[rpt].[ADTReconextRMAData] rma
    OUTER APPLY (
        SELECT TOP 1 
            CASE 
                WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(18,2))
                ELSE NULL
            END AS AttributeCost
        FROM Plus.pls.PartNoAttribute pna
        INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
        WHERE pna.PartNo = rma.[part_code]
          AND ca.AttributeName = 'Cost'
        ORDER BY pna.LastActivityDate DESC
    ) cost_attr
    WHERE rma.[part_code] IS NOT NULL
) AS RequestToReplyAging

