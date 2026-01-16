-- INVESTIGATIVE QUERY 3: What do the subtests actually test? Patterns and failures
-- Purpose: Understand component-level testing and failure patterns

-- 3.1: Which subtests fail most often?
SELECT 
    stl.TestName,
    COUNT(*) AS TotalTests,
    SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FailCount,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS FailRate
FROM [redw].[tia].[SubTestLogs] AS stl
INNER JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.ID = stl.MainTestID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
GROUP BY stl.TestName
ORDER BY FailCount DESC, FailRate DESC;

-- 3.2: When a main test FAILS, which subtests typically fail?
SELECT 
    stl.TestName AS FailedSubtest,
    COUNT(*) AS FailureCount,
    COUNT(DISTINCT stl.MainTestID) AS UniqueTestsWithThisFailure
FROM [redw].[tia].[SubTestLogs] AS stl
INNER JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.ID = stl.MainTestID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.Result = 'FAIL'
  AND stl.Result = 'FAILED'
GROUP BY stl.TestName
ORDER BY FailureCount DESC;

-- 3.3: How many subtests does a typical test have?
SELECT 
    dwr.MachineName,
    dwr.Result,
    COUNT(DISTINCT stl.MainTestID) AS TestCount,
    AVG(SubtestCount) AS AvgSubtestsPerTest,
    MIN(SubtestCount) AS MinSubtests,
    MAX(SubtestCount) AS MaxSubtests
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN (
    SELECT 
        MainTestID,
        COUNT(*) AS SubtestCount
    FROM [redw].[tia].[SubTestLogs]
    GROUP BY MainTestID
) AS st ON st.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.EndTime >= DATEADD(DAY, -30, GETDATE())
GROUP BY dwr.MachineName, dwr.Result;

-- 3.4: What's the relationship between main test result and subtest results?
-- Do all subtests pass when main test passes?
SELECT 
    dwr.Result AS MainResult,
    COUNT(DISTINCT dwr.ID) AS MainTestCount,
    SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) AS SubtestPassCount,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS SubtestFailCount,
    SUM(CASE WHEN stl.Result IS NULL THEN 1 ELSE 0 END) AS NoSubtestsCount
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.EndTime >= DATEADD(DAY, -30, GETDATE())
GROUP BY dwr.Result;

