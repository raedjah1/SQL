-- ===============================================
-- MEMPHIS ADT SITE - TIMING VERIFICATION QUERY
-- Items Scanned by Wednesday 2PM → Completed by Friday 2PM
-- ===============================================

/*
BUSINESS REQUIREMENT:
Anything scanned by Wednesday 2PM should be completed by Friday before 2 o'clock
This query verifies current compliance and calculates percentage performance
*/

-- Main Verification Query
WITH ADT_Timing_Analysis AS (
    -- Get ADT work orders with timing analysis
    SELECT 
        wh.ID as WorkOrderID,
        wh.CustomerReference,
        wh.PartNo,
        wh.SerialNo,
        wh.StatusDescription,
        wh.IsPass,
        wh.WorkstationDescription,
        wh.CreateDate as ScanDate,
        wh.LastActivityDate,
        wh.Username,
        
        -- Calculate scan day and time
        DATENAME(weekday, wh.CreateDate) as ScanDayOfWeek,
        DATEPART(hour, wh.CreateDate) as ScanHour,
        
        -- Determine if scanned by Wednesday 2PM
        CASE 
            WHEN DATENAME(weekday, wh.CreateDate) IN ('Monday', 'Tuesday') THEN 1
            WHEN DATENAME(weekday, wh.CreateDate) = 'Wednesday' AND DATEPART(hour, wh.CreateDate) <= 14 THEN 1
            ELSE 0
        END as ScannedByWednesday2PM,
        
        -- Calculate expected completion date (Friday 2PM of same week)
        DATEADD(day, 
            CASE DATENAME(weekday, wh.CreateDate)
                WHEN 'Monday' THEN 4
                WHEN 'Tuesday' THEN 3  
                WHEN 'Wednesday' THEN 2
                WHEN 'Thursday' THEN 1
                WHEN 'Friday' THEN 0
                WHEN 'Saturday' THEN 6
                WHEN 'Sunday' THEN 5
            END, 
            CAST(CAST(wh.CreateDate as DATE) as DATETIME) + CAST('14:00:00' as TIME)
        ) as ExpectedCompletionDate,
        
        -- Check if completed on time
        CASE 
            WHEN wh.StatusDescription = 'Close' AND wh.IsPass = 1 THEN
                CASE 
                    WHEN wh.LastActivityDate <= DATEADD(day, 
                        CASE DATENAME(weekday, wh.CreateDate)
                            WHEN 'Monday' THEN 4
                            WHEN 'Tuesday' THEN 3  
                            WHEN 'Wednesday' THEN 2
                            WHEN 'Thursday' THEN 1
                            WHEN 'Friday' THEN 0
                            WHEN 'Saturday' THEN 6
                            WHEN 'Sunday' THEN 5
                        END, 
                        CAST(CAST(wh.CreateDate as DATE) as DATETIME) + CAST('14:00:00' as TIME)
                    ) THEN 1
                    ELSE 0
                END
            ELSE 0
        END as CompletedOnTime,
        
        -- Calculate processing days
        DATEDIFF(hour, wh.CreateDate, COALESCE(wh.LastActivityDate, GETDATE())) / 24.0 as ProcessingDays,
        
        p.Name as ProgramName
        
    FROM pls.vWOHeader wh
    INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
    WHERE p.Site = 'MEMPHIS' 
    AND p.Name = 'ADT'  -- Focus on ADT program only
    AND wh.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
),

-- Summary Statistics
Timing_Summary AS (
    SELECT 
        COUNT(*) as TotalADTOrders,
        SUM(ScannedByWednesday2PM) as OrdersScannedByWed2PM,
        SUM(CASE WHEN ScannedByWednesday2PM = 1 AND CompletedOnTime = 1 THEN 1 ELSE 0 END) as CompletedOnTimeCount,
        SUM(CASE WHEN ScannedByWednesday2PM = 1 AND CompletedOnTime = 0 THEN 1 ELSE 0 END) as MissedDeadlineCount,
        
        -- Calculate percentage
        CASE 
            WHEN SUM(ScannedByWednesday2PM) > 0 THEN
                ROUND(
                    SUM(CASE WHEN ScannedByWednesday2PM = 1 AND CompletedOnTime = 1 THEN 1 ELSE 0 END) * 100.0 
                    / SUM(ScannedByWednesday2PM), 2
                )
            ELSE 0
        END as CompliancePercentage,
        
        AVG(CASE WHEN ScannedByWednesday2PM = 1 THEN ProcessingDays END) as AvgProcessingDays
    FROM ADT_Timing_Analysis
)

-- MAIN RESULTS
SELECT 
    '=== MEMPHIS ADT TIMING COMPLIANCE REPORT ===' as ReportSection,
    GETDATE() as ReportGeneratedDate
    
UNION ALL

SELECT 
    'COMPLIANCE SUMMARY' as ReportSection,
    CAST(CompliancePercentage as VARCHAR) + '% of ADT items scanned by Wed 2PM completed by Fri 2PM' as ReportGeneratedDate
FROM Timing_Summary

UNION ALL

SELECT 
    'VOLUME ANALYSIS' as ReportSection,
    CAST(TotalADTOrders as VARCHAR) + ' total ADT orders, ' + 
    CAST(OrdersScannedByWed2PM as VARCHAR) + ' scanned by Wed 2PM' as ReportGeneratedDate
FROM Timing_Summary

UNION ALL

SELECT 
    'PERFORMANCE BREAKDOWN' as ReportSection,
    CAST(CompletedOnTimeCount as VARCHAR) + ' completed on time, ' + 
    CAST(MissedDeadlineCount as VARCHAR) + ' missed Friday 2PM deadline' as ReportGeneratedDate
FROM Timing_Summary

UNION ALL

SELECT 
    'PROCESSING TIME' as ReportSection,
    CAST(ROUND(AvgProcessingDays, 1) as VARCHAR) + ' average days from scan to completion' as ReportGeneratedDate
FROM Timing_Summary;

-- DETAILED BREAKDOWN BY WEEK
SELECT 
    '=== WEEKLY BREAKDOWN ===' as WeeklyAnalysis,
    DATEPART(week, ScanDate) as WeekNumber,
    DATENAME(month, ScanDate) as Month,
    COUNT(*) as WeeklyOrders,
    SUM(ScannedByWednesday2PM) as ScannedByWed2PM,
    SUM(CompletedOnTime) as CompletedOnTime,
    CASE 
        WHEN SUM(ScannedByWednesday2PM) > 0 THEN
            ROUND(SUM(CompletedOnTime) * 100.0 / SUM(ScannedByWednesday2PM), 1)
        ELSE 0
    END as WeeklyComplianceRate
FROM ADT_Timing_Analysis
WHERE ScannedByWednesday2PM = 1
GROUP BY DATEPART(week, ScanDate), DATENAME(month, ScanDate)
ORDER BY WeekNumber DESC;

-- DETAILED ORDERS THAT MISSED DEADLINE
SELECT 
    '=== ORDERS MISSING FRIDAY 2PM DEADLINE ===' as MissedOrders,
    WorkOrderID,
    CustomerReference,
    PartNo,
    SerialNo,
    ScanDate,
    ExpectedCompletionDate,
    LastActivityDate,
    StatusDescription,
    ROUND(ProcessingDays, 1) as ActualProcessingDays,
    Username
FROM ADT_Timing_Analysis
WHERE ScannedByWednesday2PM = 1 
AND CompletedOnTime = 0
ORDER BY ScanDate DESC;

-- WORKSTATION PERFORMANCE ANALYSIS
SELECT 
    '=== WORKSTATION TIMING PERFORMANCE ===' as WorkstationAnalysis,
    WorkstationDescription,
    COUNT(*) as OrdersProcessed,
    SUM(ScannedByWednesday2PM) as WedScanned,
    SUM(CompletedOnTime) as OnTimeCompleted,
    CASE 
        WHEN SUM(ScannedByWednesday2PM) > 0 THEN
            ROUND(SUM(CompletedOnTime) * 100.0 / SUM(ScannedByWednesday2PM), 1)
        ELSE 0
    END as WorkstationComplianceRate,
    AVG(ProcessingDays) as AvgProcessingDays
FROM ADT_Timing_Analysis
WHERE ScannedByWednesday2PM = 1
AND WorkstationDescription IS NOT NULL
GROUP BY WorkstationDescription
ORDER BY WorkstationComplianceRate DESC;

-- USER PERFORMANCE ANALYSIS  
SELECT 
    '=== USER TIMING PERFORMANCE ===' as UserAnalysis,
    Username,
    COUNT(*) as OrdersHandled,
    SUM(ScannedByWednesday2PM) as WedScannedOrders,
    SUM(CompletedOnTime) as OnTimeCompletions,
    CASE 
        WHEN SUM(ScannedByWednesday2PM) > 0 THEN
            ROUND(SUM(CompletedOnTime) * 100.0 / SUM(ScannedByWednesday2PM), 1)
        ELSE 0
    END as UserComplianceRate,
    AVG(ProcessingDays) as AvgProcessingDays
FROM ADT_Timing_Analysis
WHERE ScannedByWednesday2PM = 1
AND Username IS NOT NULL
GROUP BY Username
ORDER BY UserComplianceRate DESC;

/*
INTERPRETATION GUIDE:
- CompliancePercentage: Overall % of Wed 2PM scanned items completed by Fri 2PM
- Orders missing deadline appear in detailed breakdown
- Workstation and user analysis shows performance bottlenecks
- Weekly trends show compliance patterns over time

EXPECTED RESULTS:
Based on Memphis intelligence showing ADT 100% pass rate, 
we expect high compliance but need verification of timing requirements.
*/
