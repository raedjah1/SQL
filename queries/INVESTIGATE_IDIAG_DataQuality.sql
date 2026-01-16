-- INVESTIGATIVE QUERY 5: Data quality and completeness
-- Purpose: Understand data gaps and quality issues

-- 5.1: How complete is the PartNumber field?
SELECT 
    MachineName,
    COUNT(*) AS TotalTests,
    SUM(CASE WHEN PartNumber IS NULL OR PartNumber = '' THEN 1 ELSE 0 END) AS MissingPartNumber,
    SUM(CASE WHEN PartNumber IS NOT NULL AND PartNumber != '' THEN 1 ELSE 0 END) AS HasPartNumber,
    SUM(CASE WHEN PartNumber IS NOT NULL AND PartNumber != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS PctWithPartNumber
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND EndTime >= DATEADD(DAY, -30, GETDATE())
GROUP BY MachineName;

-- 5.2: How many tests have subtests vs no subtests?
SELECT 
    dwr.MachineName,
    dwr.Result,
    COUNT(DISTINCT dwr.ID) AS MainTestCount,
    COUNT(DISTINCT stl.MainTestID) AS TestsWithSubtests,
    COUNT(DISTINCT dwr.ID) - COUNT(DISTINCT stl.MainTestID) AS TestsWithoutSubtests
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.EndTime >= DATEADD(DAY, -30, GETDATE())
GROUP BY dwr.MachineName, dwr.Result;

-- 5.3: Are there any unusual or unexpected values?
SELECT 
    'MachineName' AS FieldName,
    MachineName AS FieldValue,
    COUNT(*) AS Count
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND MachineName NOT IN ('IDIAGS', 'IDIAGS-MB-RESET')
GROUP BY MachineName

UNION ALL

SELECT 
    'Result' AS FieldName,
    Result AS FieldValue,
    COUNT(*) AS Count
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
GROUP BY Result

UNION ALL

SELECT 
    'SubTestResult' AS FieldName,
    stl.Result AS FieldValue,
    COUNT(*) AS Count
FROM [redw].[tia].[SubTestLogs] AS stl
INNER JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.ID = stl.MainTestID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
GROUP BY stl.Result

ORDER BY FieldName, Count DESC;

-- 5.4: What's the time gap between tests? Are there missing tests?
SELECT 
    SerialNumber,
    MachineName,
    StartTime,
    EndTime,
    Result,
    LAG(EndTime) OVER (PARTITION BY SerialNumber, MachineName ORDER BY StartTime) AS PreviousTestEnd,
    DATEDIFF(MINUTE, LAG(EndTime) OVER (PARTITION BY SerialNumber, MachineName ORDER BY StartTime), StartTime) AS MinutesSinceLastTest
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND SerialNumber IN (
      SELECT SerialNumber
      FROM [redw].[tia].[DataWipeResult]
      WHERE Contract = '10053'
        AND TestArea = 'MEMPHIS'
        AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
      GROUP BY SerialNumber
      HAVING COUNT(*) > 1
  )
ORDER BY SerialNumber, MachineName, StartTime;

