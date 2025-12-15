-- ================================================
-- SLA Compliance Summary for FSR ASNs
-- Week of 11/10 to 11/16, 2025 (based on ASNCreateDate)
-- 
-- SLA Rules (matching DAX calculation):
-- 1. Only ASNs that were RECEIVED (have ASNDeliveryDate) are included in compliance calculation
-- 2. If received by 2pm Wednesday: Must be processed by Friday 5pm same week
-- 3. If received after 2pm Wednesday: Must be processed by Friday 5pm next week
-- 4. Compliance = (ASNs processed on time) / (ASNs received)
-- 5. For unprocessed ASNs, uses GETDATE() (current time) to determine compliance
-- 6. Weekday calculation: Monday=1, Tuesday=2, ..., Sunday=7 (matching DAX WEEKDAY(date, 2))
-- ================================================

WITH SLACalculation AS (
    SELECT 
        ASN,
        Branch,
        ASNStatus,
        ASNCreateDate,
        ASNDeliveryDate,
        ASNProcessedDate,
        -- Total units received for this ASN (from PartTransaction RO-RECEIVE)
        (SELECT SUM(CAST(pt.Qty AS BIGINT))
         FROM Plus.pls.PartTransaction pt
         INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
         WHERE pt.CustomerReference = ar.ASN
           AND pt.ProgramID IN (10068, 10072)
           AND cpt.Description = 'RO-RECEIVE') AS TotalUnitsReceived,
        -- Calculate weekday in DAX format (Monday=1, Tuesday=2, ..., Sunday=7)
        -- SQL Server: Sunday=1, Monday=2, ..., Saturday=7
        -- Convert: CASE WHEN SQL weekday = 1 (Sunday) THEN 7 ELSE SQL weekday - 1 END
        CASE 
            WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
            ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
        END AS DeliveryWeekday_DAX,
        -- Calculate Monday of delivery week (matching DAX: wkStartMon = dDate - (WEEKDAY(d, 2) - 1))
        DATEADD(DAY, -(
            CASE 
                WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
            END - 1
        ), CAST(ASNDeliveryDate AS DATE)) AS DeliveryWeekMonday,
        -- Calculate Wednesday 2:00 PM cutoff of delivery week (matching DAX: Wed1400 = wkStartMon + 2 + TIME(14, 0, 0))
        DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(
            CASE 
                WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
            END - 1
        ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2)) AS Wednesday2PM,
        -- Calculate Friday 5:00 PM of delivery week (matching DAX: Fri1700 = wkStartMon + 4 + TIME(17, 0, 0))
        DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(
            CASE 
                WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
            END - 1
        ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2)) AS Friday5PM_SameWeek,
        -- Calculate Friday 5:00 PM of next week (matching DAX: Fri1700 + 7)
        DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(
            CASE 
                WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
            END - 1
        ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2)) AS Friday5PM_NextWeek,
        -- Determine due date based on delivery time (matching DAX logic)
        -- If received by Wednesday 2pm: Due Friday 5pm same week
        -- If received after Wednesday 2pm: Due Friday 5pm next week (add 7 days)
        CASE 
            WHEN ASNDeliveryDate IS NOT NULL THEN
                CASE 
                    WHEN ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(
                        CASE 
                            WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                            ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
                        END - 1
                    ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(
                        CASE 
                            WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                            ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
                        END - 1
                    ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    ELSE DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(
                        CASE 
                            WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                            ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
                        END - 1
                    ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                END
            ELSE NULL
        END AS DueDateTime,
        -- Use processed date or current date if blank (matching DAX: p = COALESCE(ASNProcessedDate, __now))
        COALESCE(ASNProcessedDate, GETDATE()) AS EffectiveProcessedDate,
        -- Compliance check (matching DAX logic exactly)
        -- Only for ASNs that were RECEIVED (have ASNDeliveryDate)
        -- Uses GETDATE() for unprocessed ASNs to determine compliance
        -- Compliant = 1 if processed (or current time) <= due date
        -- Non-Compliant = 0 if processed (or current time) > due date
        -- NULL if not yet received (excluded from compliance calculation)
        CASE 
            WHEN ASNDeliveryDate IS NULL THEN NULL  -- Not received yet, exclude from compliance
            WHEN COALESCE(ASNProcessedDate, GETDATE()) <= 
                CASE 
                    WHEN ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(
                        CASE 
                            WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                            ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
                        END - 1
                    ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(
                        CASE 
                            WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                            ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
                        END - 1
                    ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    ELSE DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(
                        CASE 
                            WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                            ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
                        END - 1
                    ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                END
            THEN 1  -- Compliant
            ELSE 0  -- Non-Compliant
        END AS IsCompliant,
        -- Hours from due date (negative = early, positive = late)
        -- Uses EffectiveProcessedDate (COALESCE with GETDATE()) to match DAX
        CASE 
            WHEN ASNDeliveryDate IS NOT NULL THEN
                DATEDIFF(HOUR, 
                    CASE 
                        WHEN ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(
                            CASE 
                                WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                                ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
                            END - 1
                        ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                        THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(
                            CASE 
                                WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                                ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
                            END - 1
                        ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                        ELSE DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(
                            CASE 
                                WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                                ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
                            END - 1
                        ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    END,
                    COALESCE(ASNProcessedDate, GETDATE())
                )
            ELSE NULL
        END AS HoursFromDueDate,
        -- Indicate if received before/after Wednesday 2pm cutoff
        CASE 
            WHEN ASNDeliveryDate IS NULL THEN NULL
            WHEN ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(
                CASE 
                    WHEN DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) = 1 THEN 7
                    ELSE DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 1
                END - 1
            ), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
            THEN 'Received by Wed 2pm (Due: Fri 5pm same week)'
            ELSE 'Received after Wed 2pm (Due: Fri 5pm next week)'
        END AS ReceiptCategory
    FROM [rpt].[ADTASNReport] ar
    WHERE CAST(ar.ASNCreateDate AS DATE) >= '2025-11-10'
      AND CAST(ar.ASNCreateDate AS DATE) <= '2025-11-16'
      AND ar.ASN LIKE 'FSR%'
)
SELECT * FROM (
    -- Summary
    SELECT 
        'SUMMARY' AS ReportType,
        NULL AS ASN,
        NULL AS ASNStatus,
        NULL AS ASNCreateDate,
        NULL AS ASNDeliveryDate,
        NULL AS ASNProcessedDate,
        NULL AS DueDateTime,
        NULL AS EffectiveProcessedDate,
        NULL AS IsCompliant,
        NULL AS HoursFromDueDate,
        NULL AS DeliveryWeekMonday,
        NULL AS Wednesday2PM,
        NULL AS Friday5PM_SameWeek,
        NULL AS Friday5PM_NextWeek,
        NULL AS ReceiptCategory,
        NULL AS DeliveryWeekday_DAX,
        NULL AS TotalUnitsReceived,
        COUNT(*) AS TotalASNs,
        SUM(TotalUnitsReceived) AS TotalUnitsReceived_All,
        COUNT(CASE WHEN ASNDeliveryDate IS NOT NULL THEN 1 END) AS ASNsReceived,
        COUNT(CASE WHEN ASNDeliveryDate IS NULL THEN 1 END) AS ASNsNotYetReceived,
        COUNT(CASE WHEN ASNDeliveryDate IS NOT NULL AND ASNProcessedDate IS NOT NULL THEN 1 END) AS ASNsReceivedAndProcessed,
        COUNT(CASE WHEN ASNProcessedDate IS NULL AND ASNDeliveryDate IS NOT NULL THEN 1 END) AS ReceivedButNotProcessed,
        COUNT(CASE WHEN IsCompliant = 1 THEN 1 END) AS CompliantASNs,
        COUNT(CASE WHEN IsCompliant = 0 THEN 1 END) AS NonCompliantASNs,
        COUNT(CASE WHEN IsCompliant IS NULL THEN 1 END) AS CannotCalculateSLA,
        -- Compliance percentage: (Compliant ASNs) / (ASNs Received)
        -- Matches DAX calculation: includes unprocessed ASNs (uses GETDATE() for them)
        -- Only ASNs with delivery date are included in compliance calculation
        CAST(COUNT(CASE WHEN IsCompliant = 1 THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN ASNDeliveryDate IS NOT NULL THEN 1 END), 0) AS DECIMAL(10,2)) AS SLACompliancePercentage,
        COUNT(CASE WHEN CAST(ASNCreateDate AS DATE) = '2025-11-10' THEN 1 END) AS CreatedOnMonday,
        COUNT(CASE WHEN CAST(ASNCreateDate AS DATE) = '2025-11-11' THEN 1 END) AS CreatedOnTuesday,
        COUNT(CASE WHEN CAST(ASNCreateDate AS DATE) = '2025-11-12' THEN 1 END) AS CreatedOnWednesday,
        COUNT(CASE WHEN CAST(ASNCreateDate AS DATE) = '2025-11-13' THEN 1 END) AS CreatedOnThursday,
        COUNT(CASE WHEN CAST(ASNCreateDate AS DATE) = '2025-11-14' THEN 1 END) AS CreatedOnFriday,
        COUNT(CASE WHEN CAST(ASNCreateDate AS DATE) = '2025-11-15' THEN 1 END) AS CreatedOnSaturday,
        COUNT(CASE WHEN CAST(ASNCreateDate AS DATE) = '2025-11-16' THEN 1 END) AS CreatedOnSunday
    FROM SLACalculation

    UNION ALL

    -- Detailed breakdown
    SELECT 
        'DETAIL' AS ReportType,
        ASN,
        ASNStatus,
        ASNCreateDate,
        ASNDeliveryDate,
        ASNProcessedDate,
        DueDateTime,
        EffectiveProcessedDate,
        IsCompliant,
        HoursFromDueDate,
        DeliveryWeekMonday,
        Wednesday2PM,
        Friday5PM_SameWeek,
        Friday5PM_NextWeek,
        ReceiptCategory,
        DeliveryWeekday_DAX,
        TotalUnitsReceived,
        NULL AS TotalASNs,
        NULL AS TotalUnitsReceived_All,
        NULL AS ASNsReceived,
        NULL AS ASNsNotYetReceived,
        NULL AS ASNsReceivedAndProcessed,
        NULL AS ReceivedButNotProcessed,
        NULL AS CompliantASNs,
        NULL AS NonCompliantASNs,
        NULL AS CannotCalculateSLA,
        NULL AS SLACompliancePercentage,
        NULL AS CreatedOnMonday,
        NULL AS CreatedOnTuesday,
        NULL AS CreatedOnWednesday,
        NULL AS CreatedOnThursday,
        NULL AS CreatedOnFriday,
        NULL AS CreatedOnSaturday,
        NULL AS CreatedOnSunday
    FROM SLACalculation
) CombinedResults
ORDER BY 
    CASE WHEN ReportType = 'SUMMARY' THEN 0 ELSE 1 END,
    CASE WHEN IsCompliant IS NULL THEN 1 ELSE 0 END,
    IsCompliant DESC,
    ASNDeliveryDate,
    ASN;

-- ================================================
-- Detailed Breakdown by Compliance Category
-- ================================================

WITH SLACalculation AS (
    SELECT 
        ASN,
        Branch,
        ASNStatus,
        ASNCreateDate,
        ASNDeliveryDate,
        ASNProcessedDate,
        -- Determine due date based on delivery time
        CASE 
            WHEN ASNDeliveryDate IS NOT NULL AND ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
            THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
            WHEN ASNDeliveryDate IS NOT NULL
            THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
            ELSE NULL
        END AS DueDateTime,
        -- Compliance check
        CASE 
            WHEN ASNDeliveryDate IS NULL THEN NULL
            WHEN COALESCE(ASNProcessedDate, GETDATE()) <= 
                CASE 
                    WHEN ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    ELSE DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                END
            THEN 1
            ELSE 0
        END AS IsCompliant,
        -- Hours from due date
        CASE 
            WHEN ASNDeliveryDate IS NOT NULL AND ASNProcessedDate IS NOT NULL THEN
                DATEDIFF(HOUR, 
                    CASE 
                        WHEN ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                        THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                        ELSE DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    END,
                    ASNProcessedDate
                )
            ELSE NULL
        END AS HoursFromDueDate
    FROM [rpt].[ADTASNReport]
    WHERE CAST(ASNCreateDate AS DATE) >= '2025-11-10'
      AND CAST(ASNCreateDate AS DATE) <= '2025-11-16'
      AND ASN LIKE 'FSR%'
)
SELECT 
    ComplianceCategory,
    Count,
    PercentageOfTotal,
    AvgHoursFromDueDate,
    MinHoursFromDueDate,
    MaxHoursFromDueDate
FROM (
    SELECT 
        CASE 
            WHEN ASNDeliveryDate IS NULL THEN 'No Delivery Date'
            WHEN IsCompliant = 1 THEN 'Compliant'
            WHEN IsCompliant = 0 THEN 'Non-Compliant'
            ELSE 'Cannot Calculate'
        END AS ComplianceCategory,
        COUNT(*) AS Count,
        CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM SLACalculation) AS DECIMAL(10,2)) AS PercentageOfTotal,
        -- Average hours from due date
        AVG(HoursFromDueDate) AS AvgHoursFromDueDate,
        MIN(HoursFromDueDate) AS MinHoursFromDueDate,
        MAX(HoursFromDueDate) AS MaxHoursFromDueDate
    FROM SLACalculation
    GROUP BY 
        CASE 
            WHEN ASNDeliveryDate IS NULL THEN 'No Delivery Date'
            WHEN IsCompliant = 1 THEN 'Compliant'
            WHEN IsCompliant = 0 THEN 'Non-Compliant'
            ELSE 'Cannot Calculate'
        END
) CategorySummary
ORDER BY 
    CASE 
        WHEN ComplianceCategory = 'Compliant' THEN 1
        WHEN ComplianceCategory = 'Non-Compliant' THEN 2
        WHEN ComplianceCategory = 'No Delivery Date' THEN 3
        ELSE 4
    END;

-- ================================================
-- Non-Compliant ASNs Detail (shows why they failed)
-- ================================================

WITH SLACalculation AS (
    SELECT 
        ASN,
        Branch,
        ASNStatus,
        ASNCreateDate,
        ASNDeliveryDate,
        ASNProcessedDate,
        -- Determine due date based on delivery time
        CASE 
            WHEN ASNDeliveryDate IS NOT NULL AND ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
            THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
            WHEN ASNDeliveryDate IS NOT NULL
            THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
            ELSE NULL
        END AS DueDateTime,
        -- Compliance check
        CASE 
            WHEN ASNDeliveryDate IS NULL THEN NULL
            WHEN COALESCE(ASNProcessedDate, GETDATE()) <= 
                CASE 
                    WHEN ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    ELSE DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                END
            THEN 1
            ELSE 0
        END AS IsCompliant,
        -- Hours from due date
        CASE 
            WHEN ASNDeliveryDate IS NOT NULL AND ASNProcessedDate IS NOT NULL THEN
                DATEDIFF(HOUR, 
                    CASE 
                        WHEN ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                        THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                        ELSE DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    END,
                    ASNProcessedDate
                )
            ELSE NULL
        END AS HoursFromDueDate,
        -- Days late
        CASE 
            WHEN ASNDeliveryDate IS NOT NULL AND ASNProcessedDate IS NOT NULL THEN
                CAST(DATEDIFF(HOUR, 
                    CASE 
                        WHEN ASNDeliveryDate <= DATEADD(HOUR, 14, CAST(DATEADD(DAY, 2, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                        THEN DATEADD(HOUR, 17, CAST(DATEADD(DAY, 4, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                        ELSE DATEADD(HOUR, 17, CAST(DATEADD(DAY, 11, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(ASNDeliveryDate AS DATE)) - 2), CAST(ASNDeliveryDate AS DATE))) AS DATETIME2))
                    END,
                    ASNProcessedDate
                ) / 24.0 AS DECIMAL(10,2))
            ELSE NULL
        END AS DaysLate
    FROM [rpt].[ADTASNReport]
    WHERE CAST(ASNCreateDate AS DATE) >= '2025-11-10'
      AND CAST(ASNCreateDate AS DATE) <= '2025-11-16'
      AND ASN LIKE 'FSR%'
)
SELECT 
    ASN,
    Branch,
    ASNStatus,
    ASNCreateDate,
    ASNDeliveryDate,
    ASNProcessedDate,
    DueDateTime,
    HoursFromDueDate,
    DaysLate,
    CASE 
        WHEN ASNProcessedDate IS NULL THEN 'Not Yet Processed'
        WHEN HoursFromDueDate > 0 THEN CONCAT('Late by ', CAST(DaysLate AS VARCHAR), ' days (', CAST(HoursFromDueDate AS VARCHAR), ' hours)')
        ELSE 'On Time'
    END AS StatusDescription
FROM SLACalculation
WHERE IsCompliant = 0  -- Only non-compliant
ORDER BY HoursFromDueDate DESC;

