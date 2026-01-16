-- INVESTIGATIVE QUERY 1: What is IDIAG? Explore the data structure
-- Purpose: Understand what IDIAG actually is by examining the raw data

-- 1.1: What are all the unique MachineName values?
SELECT DISTINCT 
    MachineName,
    COUNT(*) AS TestCount,
    MIN(StartTime) AS FirstTest,
    MAX(StartTime) AS LastTest
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
GROUP BY MachineName
ORDER BY TestCount DESC;

-- 1.2: What does "IDIAGS" vs "IDIAGS-MB-RESET" actually test?
SELECT 
    MachineName,
    Result,
    COUNT(*) AS Count,
    AVG(DATEDIFF(SECOND, StartTime, EndTime)) AS AvgDurationSeconds
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
GROUP BY MachineName, Result
ORDER BY MachineName, Result;

-- 1.3: What are all the unique subtest names? (What components are tested?)
SELECT DISTINCT 
    stl.TestName,
    COUNT(*) AS OccurrenceCount,
    SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FailCount
FROM [redw].[tia].[SubTestLogs] AS stl
INNER JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.ID = stl.MainTestID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
GROUP BY stl.TestName
ORDER BY OccurrenceCount DESC;

-- 1.4: What other fields in DataWipeResult might tell us what IDIAG is?
SELECT TOP 100
    ID,
    SerialNumber,
    PartNumber,
    MachineName,
    Result,
    TestArea,
    Program,
    Contract,
    MiscInfo,
    MACAddress,
    Msg,
    FileReference,
    FailureReference,
    FailureNumber,
    ErrItem,
    BatteryHealthGrade,
    LogFileStatus,
    Username,
    OrderNumber
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
ORDER BY StartTime DESC;

