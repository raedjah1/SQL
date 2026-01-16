-- INVESTIGATIVE QUERY: Data Quality Issues and Anomalies
-- Purpose: Find data quality problems, inconsistencies, and anomalies

-- ============================================================================
-- 1. INCONSISTENT DATA - Tests that don't make sense
-- ============================================================================

-- 1.1: Tests with zero or negative duration
SELECT 
    ID,
    SerialNumber,
    MachineName,
    Result,
    StartTime,
    EndTime,
    DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
    CASE 
        WHEN EndTime < StartTime THEN 'End Before Start'
        WHEN DATEDIFF(SECOND, StartTime, EndTime) = 0 THEN 'Zero Duration'
        WHEN DATEDIFF(SECOND, StartTime, EndTime) < 0 THEN 'Negative Duration'
        ELSE 'OK'
    END AS IssueType
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND (
      EndTime < StartTime
      OR DATEDIFF(SECOND, StartTime, EndTime) <= 0
  )
ORDER BY StartTime DESC;

-- 1.2: Tests with extremely long durations (possible data errors)
SELECT 
    ID,
    SerialNumber,
    MachineName,
    Result,
    StartTime,
    EndTime,
    DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
    DATEDIFF(HOUR, StartTime, EndTime) AS DurationHours,
    DATEDIFF(DAY, StartTime, EndTime) AS DurationDays
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND DATEDIFF(HOUR, StartTime, EndTime) > 48  -- More than 2 days
ORDER BY DurationHours DESC;

-- 1.3: Tests with extremely short durations (possible incomplete tests)
SELECT 
    ID,
    SerialNumber,
    MachineName,
    Result,
    StartTime,
    EndTime,
    DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
    COUNT(stl.ID) AS SubtestCount
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND DATEDIFF(SECOND, dwr.StartTime, dwr.EndTime) < 10  -- Less than 10 seconds
GROUP BY dwr.ID, dwr.SerialNumber, dwr.MachineName, dwr.Result, dwr.StartTime, dwr.EndTime
ORDER BY DurationSeconds ASC;

-- ============================================================================
-- 2. LOGICAL INCONSISTENCIES - Results that don't match
-- ============================================================================

-- 2.1: Main test PASS but has FAILED subtests
SELECT 
    dwr.ID AS TestID,
    dwr.SerialNumber,
    dwr.MachineName,
    dwr.Result AS MainResult,
    COUNT(stl.ID) AS TotalSubtests,
    SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) AS PassedSubtests,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FailedSubtests,
    STRING_AGG(stl.TestName, ', ') WITHIN GROUP (ORDER BY stl.TestName) AS FailedSubtestNames
FROM [redw].[tia].[DataWipeResult] AS dwr
INNER JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.Result = 'PASS'
  AND stl.Result = 'FAILED'
GROUP BY dwr.ID, dwr.SerialNumber, dwr.MachineName, dwr.Result
ORDER BY FailedSubtests DESC;

-- 2.2: Main test FAIL but all subtests PASSED
SELECT 
    dwr.ID AS TestID,
    dwr.SerialNumber,
    dwr.MachineName,
    dwr.Result AS MainResult,
    COUNT(stl.ID) AS TotalSubtests,
    SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) AS PassedSubtests,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FailedSubtests
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.Result = 'FAIL'
GROUP BY dwr.ID, dwr.SerialNumber, dwr.MachineName, dwr.Result
HAVING SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) = 0
   OR COUNT(stl.ID) = 0  -- No subtests at all
ORDER BY dwr.StartTime DESC;

-- 2.3: Tests with no subtests (should all tests have subtests?)
SELECT 
    MachineName,
    Result,
    COUNT(*) AS TestCount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS PctOfTotal
FROM [redw].[tia].[DataWipeResult] AS dwr
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND NOT EXISTS (
      SELECT 1 
      FROM [redw].[tia].[SubTestLogs] AS stl 
      WHERE stl.MainTestID = dwr.ID
  )
GROUP BY MachineName, Result
ORDER BY TestCount DESC;

-- ============================================================================
-- 3. DUPLICATE OR SUSPICIOUS PATTERNS
-- ============================================================================

-- 3.1: Same SerialNumber tested multiple times in very short time window
SELECT 
    SerialNumber,
    MachineName,
    COUNT(*) AS TestCount,
    MIN(StartTime) AS FirstTest,
    MAX(StartTime) AS LastTest,
    DATEDIFF(MINUTE, MIN(StartTime), MAX(StartTime)) AS MinutesBetween,
    STRING_AGG(CAST(Result AS VARCHAR), ', ') WITHIN GROUP (ORDER BY StartTime) AS Results
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND SerialNumber IS NOT NULL
  AND SerialNumber != ''
  AND StartTime >= DATEADD(DAY, -7, GETDATE())
GROUP BY SerialNumber, MachineName
HAVING COUNT(*) > 1
   AND DATEDIFF(MINUTE, MIN(StartTime), MAX(StartTime)) < 5  -- Multiple tests within 5 minutes
ORDER BY MinutesBetween ASC, TestCount DESC;

-- 3.2: Tests with identical timestamps (possible duplicates)
SELECT 
    StartTime,
    EndTime,
    MachineName,
    Result,
    COUNT(*) AS DuplicateCount,
    STRING_AGG(CAST(ID AS VARCHAR), ', ') AS TestIDs,
    STRING_AGG(SerialNumber, ', ') AS SerialNumbers
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
GROUP BY StartTime, EndTime, MachineName, Result
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;

-- 3.3: SerialNumbers that appear in both IDIAGS and IDIAGS-MB-RESET
SELECT 
    SerialNumber,
    SUM(CASE WHEN MachineName = 'IDIAGS' THEN 1 ELSE 0 END) AS IDIAGSCount,
    SUM(CASE WHEN MachineName = 'IDIAGS-MB-RESET' THEN 1 ELSE 0 END) AS MBResetCount,
    MIN(StartTime) AS FirstTest,
    MAX(StartTime) AS LastTest,
    DATEDIFF(HOUR, MIN(StartTime), MAX(StartTime)) AS HoursBetween
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND SerialNumber IS NOT NULL
  AND SerialNumber != ''
GROUP BY SerialNumber
HAVING SUM(CASE WHEN MachineName = 'IDIAGS' THEN 1 ELSE 0 END) > 0
   AND SUM(CASE WHEN MachineName = 'IDIAGS-MB-RESET' THEN 1 ELSE 0 END) > 0
ORDER BY HoursBetween ASC;

-- ============================================================================
-- 4. UNUSUAL VALUES - Things that stand out
-- ============================================================================

-- 4.1: What are the unusual subtest results? (Not PASSED or FAILED)
SELECT 
    stl.Result,
    COUNT(*) AS Count,
    COUNT(DISTINCT stl.MainTestID) AS UniqueTests,
    STRING_AGG(DISTINCT stl.TestName, ', ') AS TestNames
FROM [redw].[tia].[SubTestLogs] AS stl
INNER JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.ID = stl.MainTestID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND stl.Result NOT IN ('PASSED', 'FAILED')
GROUP BY stl.Result
ORDER BY Count DESC;

-- 4.2: What are the unusual main test results? (Not PASS or FAIL)
SELECT 
    Result,
    COUNT(*) AS Count,
    MIN(StartTime) AS FirstSeen,
    MAX(StartTime) AS LastSeen
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND Result NOT IN ('PASS', 'FAIL')
GROUP BY Result
ORDER BY Count DESC;

-- 4.3: Tests with unusual subtest counts (too many or too few)
SELECT 
    MachineName,
    Result,
    COUNT(DISTINCT dwr.ID) AS TestCount,
    AVG(SubtestCount) AS AvgSubtests,
    MIN(SubtestCount) AS MinSubtests,
    MAX(SubtestCount) AS MaxSubtests,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SubtestCount) OVER (PARTITION BY MachineName, Result) AS MedianSubtests
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN (
    SELECT MainTestID, COUNT(*) AS SubtestCount
    FROM [redw].[tia].[SubTestLogs]
    GROUP BY MainTestID
) AS st ON st.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
GROUP BY MachineName, Result;

-- Find tests with unusually high subtest counts
SELECT TOP 20
    dwr.ID AS TestID,
    dwr.SerialNumber,
    dwr.MachineName,
    dwr.Result,
    COUNT(stl.ID) AS SubtestCount
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
GROUP BY dwr.ID, dwr.SerialNumber, dwr.MachineName, dwr.Result
HAVING COUNT(stl.ID) > 50  -- More than 50 subtests (unusual)
ORDER BY SubtestCount DESC;

-- ============================================================================
-- 5. MISSING RELATIONSHIPS - Data that should link but doesn't
-- ============================================================================

-- 5.1: Tests with SerialNumbers that don't exist in PartSerial
SELECT 
    dwr.ID AS TestID,
    dwr.SerialNumber,
    dwr.PartNumber,
    dwr.MachineName,
    dwr.Result,
    dwr.StartTime,
    ps.ID AS PartSerialID
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN Plus.pls.PartSerial AS ps ON ps.SerialNumber = dwr.SerialNumber AND ps.ProgramID = 10053
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.SerialNumber IS NOT NULL
  AND dwr.SerialNumber != ''
  AND ps.ID IS NULL  -- SerialNumber not found in PartSerial
  AND dwr.StartTime >= DATEADD(DAY, -30, GETDATE())
ORDER BY dwr.StartTime DESC;

-- 5.2: Tests where PartNumber doesn't match PartSerial.PartNo
SELECT 
    dwr.ID AS TestID,
    dwr.SerialNumber,
    dwr.PartNumber AS TestPartNumber,
    ps.PartNo AS PartSerialPartNumber,
    dwr.MachineName,
    dwr.Result
FROM [redw].[tia].[DataWipeResult] AS dwr
INNER JOIN Plus.pls.PartSerial AS ps ON ps.SerialNumber = dwr.SerialNumber AND ps.ProgramID = 10053
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.SerialNumber IS NOT NULL
  AND dwr.SerialNumber != ''
  AND dwr.PartNumber IS NOT NULL
  AND dwr.PartNumber != ''
  AND dwr.PartNumber != ps.PartNo
  AND dwr.StartTime >= DATEADD(DAY, -30, GETDATE())
ORDER BY dwr.StartTime DESC;

