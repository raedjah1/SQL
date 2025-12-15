-- ===============================================
-- MEMPHIS ADT - TIMING VERIFICATION
-- Items received between Wednesday to Wednesday should be done by Friday 2PM
-- ===============================================

-- BUSINESS RULE VERIFICATION:
-- Anything received from Wednesday to the following Wednesday should be completed by Friday before 2 o'clock

SELECT 
    'ADT TIMING COMPLIANCE CHECK' as CheckType,
    COUNT(*) as TotalRecentOrders,
    
    -- Orders received between Wednesday to Wednesday (weekly cycle)
    SUM(CASE 
        WHEN DATENAME(weekday, wh.CreateDate) IN ('Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday') 
        THEN 1 ELSE 0 
    END) as OrdersInWeeklyCycle,
    
    -- Completed orders that met Friday 2PM deadline (next Friday after receipt)
    SUM(CASE 
        WHEN wh.StatusDescription = 'Close' 
        AND wh.IsPass = 1
        AND wh.LastActivityDate <= DATEADD(hour, 14, 
            DATEADD(day, 
                CASE DATENAME(weekday, wh.CreateDate)
                    WHEN 'Wednesday' THEN 2  -- Wed -> Fri (2 days)
                    WHEN 'Thursday' THEN 1   -- Thu -> Fri (1 day)
                    WHEN 'Friday' THEN 7     -- Fri -> Next Fri (7 days)
                    WHEN 'Saturday' THEN 6   -- Sat -> Next Fri (6 days)
                    WHEN 'Sunday' THEN 5     -- Sun -> Next Fri (5 days)
                    WHEN 'Monday' THEN 4     -- Mon -> Next Fri (4 days)
                    WHEN 'Tuesday' THEN 3    -- Tue -> Next Fri (3 days)
                END, 
                CAST(wh.CreateDate as DATE)
            )
        )
        THEN 1 ELSE 0 
    END) as CompletedOnTime,
    
    -- Calculate compliance percentage (completed on time / total orders in cycle)
    CASE 
        WHEN SUM(CASE 
            WHEN DATENAME(weekday, wh.CreateDate) IN ('Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday') 
            THEN 1 ELSE 0 
        END) > 0 THEN
            ROUND(
                SUM(CASE 
                    WHEN wh.StatusDescription = 'Close' 
                    AND wh.IsPass = 1
                    AND wh.LastActivityDate <= DATEADD(hour, 14, 
                        DATEADD(day, 
                            CASE DATENAME(weekday, wh.CreateDate)
                                WHEN 'Wednesday' THEN 2
                                WHEN 'Thursday' THEN 1
                                WHEN 'Friday' THEN 7
                                WHEN 'Saturday' THEN 6
                                WHEN 'Sunday' THEN 5
                                WHEN 'Monday' THEN 4
                                WHEN 'Tuesday' THEN 3
                            END, 
                            CAST(wh.CreateDate as DATE)
                        )
                    )
                    THEN 1 ELSE 0 
                END) * 100.0 / 
                SUM(CASE 
                    WHEN DATENAME(weekday, wh.CreateDate) IN ('Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday') 
                    THEN 1 ELSE 0 
                END), 2
            )
        ELSE 0
    END as CompliancePercentage,
    
    GETDATE() as CheckDateTime

FROM pls.vWOHeader wh
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS' 
AND p.Name = 'ADT'
AND wh.CreateDate >= DATEADD(month, -1, GETDATE());  -- Last month only

-- Show recent orders that missed the deadline
SELECT TOP 10
    'RECENT MISSED DEADLINES' as OrderType,
    wh.CustomerReference,
    wh.PartNo,
    wh.SerialNo,
    wh.CreateDate as ScanDate,
    DATENAME(weekday, wh.CreateDate) as ScanDay,
    DATEPART(hour, wh.CreateDate) as ScanHour,
    wh.LastActivityDate as CompletionDate,
    wh.StatusDescription,
    wh.IsPass,
    DATEDIFF(hour, wh.CreateDate, wh.LastActivityDate) / 24.0 as ProcessingDays,
    wh.Username

FROM pls.vWOHeader wh
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS' 
AND p.Name = 'ADT'
AND wh.CreateDate >= DATEADD(month, -1, GETDATE())
AND DATENAME(weekday, wh.CreateDate) IN ('Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday')
AND (wh.StatusDescription != 'Close' 
     OR wh.IsPass != 1 
     OR wh.LastActivityDate > DATEADD(hour, 14, 
         DATEADD(day, 
             CASE DATENAME(weekday, wh.CreateDate)
                 WHEN 'Wednesday' THEN 2
                 WHEN 'Thursday' THEN 1
                 WHEN 'Friday' THEN 7
                 WHEN 'Saturday' THEN 6
                 WHEN 'Sunday' THEN 5
                 WHEN 'Monday' THEN 4
                 WHEN 'Tuesday' THEN 3
             END, 
             CAST(wh.CreateDate as DATE)
         )
     ))
ORDER BY wh.CreateDate DESC;
