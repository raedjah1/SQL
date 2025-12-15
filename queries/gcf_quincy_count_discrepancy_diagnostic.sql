-- ============================================================================
-- DIAGNOSTIC: Why View and Query counts differ
-- ============================================================================
-- This query helps identify which records are counted differently
-- ============================================================================

-- Check time zone conversion differences
SELECT 
    'Time Zone Conversion Comparison' AS [Check],
    COUNT(*) AS [TotalRecords],
    -- Count records where view date != query date
    SUM(CASE 
        WHEN CAST(arl.createDate AS DATE) != CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) 
        THEN 1 
        ELSE 0 
    END) AS [DateMismatchCount]
FROM rpt.AgentRepairLog arl
INNER JOIN ClarityWarehouse.agentlogs.repair r
    ON r.serialNo = arl.serialNo
    AND r.createDate = CAST(arl.createDate AT TIME ZONE 'Eastern Standard Time' AT TIME ZONE 'UTC' AS DATETIME2)
    AND r.programID = arl.programID
    AND r.agentName = arl.agentName
WHERE arl.programID = 10053
    AND arl.agentName = 'quincy'
    AND CAST(arl.createDate AS DATE) >= '2025-11-08';

-- Show records where dates differ
SELECT 
    r.serialNo,
    r.createDate AS [RawCreateDate_UTC],
    CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATETIME2) AS [View_Date_EST],
    CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) AS [View_DateOnly],
    DATEADD(HOUR, -6, r.createDate) AS [Query_Date_CST],
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Query_DateOnly],
    CASE 
        WHEN CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) != CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
        THEN 'DIFFERENT'
        ELSE 'SAME'
    END AS [DateMatch]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.debug = 0
    AND CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) >= '2025-11-08'
    AND CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) != CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
ORDER BY r.createDate DESC;

-- Summary by date showing the discrepancy
SELECT 
    CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) AS [View_Date],
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Query_Date],
    COUNT(*) AS [RecordsWithDateMismatch]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.debug = 0
    AND CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) >= '2025-11-08'
    AND CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) != CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
GROUP BY 
    CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE),
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
ORDER BY [View_Date] DESC, [Query_Date] DESC;


