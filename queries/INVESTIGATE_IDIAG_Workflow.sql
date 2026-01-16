-- INVESTIGATIVE QUERY 2: What is the workflow? How do units flow through IDIAG?
-- Purpose: Understand the business process and routing

-- 2.1: Do units get tested multiple times? What's the retest pattern?
SELECT 
    SerialNumber,
    MachineName,
    COUNT(*) AS TestAttempts,
    MIN(StartTime) AS FirstTest,
    MAX(StartTime) AS LastTest,
    DATEDIFF(HOUR, MIN(StartTime), MAX(StartTime)) AS HoursBetweenFirstAndLast,
    SUM(CASE WHEN Result = 'PASS' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN Result = 'FAIL' THEN 1 ELSE 0 END) AS FailCount
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
GROUP BY SerialNumber, MachineName
HAVING COUNT(*) > 1
ORDER BY TestAttempts DESC, SerialNumber;

-- 2.2: What happens AFTER IDIAG? Where do units go?
-- Check if there's a relationship with PartTransaction or PartSerial location
SELECT TOP 50
    dwr.SerialNumber,
    dwr.MachineName,
    dwr.Result AS IDIAGResult,
    dwr.EndTime AS IDIAGEndTime,
    ps.PartNo,
    ps.LocationID,
    pl.LocationNo,
    pl.Warehouse
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN Plus.pls.PartSerial AS ps ON ps.SerialNumber = dwr.SerialNumber AND ps.ProgramID = 10053
LEFT JOIN Plus.pls.PartLocation AS pl ON pl.ID = ps.LocationID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.EndTime >= DATEADD(DAY, -7, GETDATE()) -- Last 7 days
ORDER BY dwr.EndTime DESC;

-- 2.3: Is there a relationship between IDIAG results and teardown?
-- Check if failed IDIAG tests lead to teardown
SELECT 
    dwr.Result AS IDIAGResult,
    COUNT(*) AS TestCount,
    SUM(CASE WHEN pl.Warehouse = 'Teardown' THEN 1 ELSE 0 END) AS WentToTeardown,
    SUM(CASE WHEN pl.Warehouse = 'Teardown' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS PctToTeardown
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN Plus.pls.PartSerial AS ps ON ps.SerialNumber = dwr.SerialNumber AND ps.ProgramID = 10053
LEFT JOIN Plus.pls.PartLocation AS pl ON pl.ID = ps.LocationID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.EndTime >= DATEADD(DAY, -30, GETDATE()) -- Last 30 days
GROUP BY dwr.Result;

-- 2.4: What's the typical test duration? Fast vs slow tests?
SELECT 
    MachineName,
    Result,
    AVG(DATEDIFF(SECOND, StartTime, EndTime)) AS AvgDurationSeconds,
    MIN(DATEDIFF(SECOND, StartTime, EndTime)) AS MinDurationSeconds,
    MAX(DATEDIFF(SECOND, StartTime, EndTime)) AS MaxDurationSeconds,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DATEDIFF(SECOND, StartTime, EndTime)) OVER (PARTITION BY MachineName, Result) AS MedianDurationSeconds
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND EndTime >= DATEADD(DAY, -30, GETDATE());

