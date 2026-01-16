-- Investigate blank ComponentCategory values in IDIAG data
-- Purpose: Find out what rows have NULL/blank SubTestName

-- Check what RecordTypes have blank SubTestName
SELECT 
    'Main Test vs Subtest' AS InvestigationType,
    CASE WHEN stl.TestName IS NULL THEN 'NULL SubTestName' ELSE 'Has SubTestName' END AS SubTestNameStatus,
    CASE 
        WHEN stl.MainTestID IS NOT NULL THEN 'Subtest'
        ELSE 'Main Test'
    END AS RecordType,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT dwr.SerialNumber) AS UniqueSerials,
    COUNT(DISTINCT dwr.ID) AS UniqueTests
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
GROUP BY 
    CASE WHEN stl.TestName IS NULL THEN 'NULL SubTestName' ELSE 'Has SubTestName' END,
    CASE 
        WHEN stl.MainTestID IS NOT NULL THEN 'Subtest'
        ELSE 'Main Test'
    END

UNION ALL

-- Check if there are any SubTestName values that are empty strings
SELECT 
    'Empty String Check' AS InvestigationType,
    CASE 
        WHEN stl.TestName IS NULL THEN 'NULL'
        WHEN stl.TestName = '' THEN 'Empty String'
        ELSE 'Has Value'
    END AS SubTestNameStatus,
    'Subtest' AS RecordType,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT dwr.SerialNumber) AS UniqueSerials,
    COUNT(DISTINCT dwr.ID) AS UniqueTests
FROM [redw].[tia].[DataWipeResult] AS dwr
INNER JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
GROUP BY 
    CASE 
        WHEN stl.TestName IS NULL THEN 'NULL'
        WHEN stl.TestName = '' THEN 'Empty String'
        ELSE 'Has Value'
    END

-- Show sample rows with NULL SubTestName
SELECT TOP 20
    'Sample NULL Rows' AS InvestigationType,
    dwr.ID AS TestID,
    dwr.SerialNumber,
    dwr.MachineName,
    dwr.Result AS MainTestResult,
    stl.ID AS SubTestID,
    stl.TestName AS SubTestName,
    stl.Result AS SubTestResult,
    CASE 
        WHEN stl.MainTestID IS NOT NULL THEN 'Subtest'
        ELSE 'Main Test'
    END AS RecordType
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND (stl.TestName IS NULL OR stl.TestName = '')
ORDER BY dwr.EndTime DESC;

