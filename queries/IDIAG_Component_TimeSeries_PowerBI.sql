-- PowerBI Direct Query: IDIAG Component Time-Series Analysis
-- Purpose: Daily component statistics for trend analysis
-- No WITH clauses - simple SELECT for PowerBI DirectQuery

SELECT 
    CAST(dwr.EndTime AS DATE) AS TestDate,
    CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END AS MachineNameNormalized,
    stl.TestName AS ComponentName,
    dwr.Result AS MainTestResult,
    stl.Result AS SubTestResult,
    COUNT(*) AS TestCount,
    SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FailCount,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS ErrorCount,  -- Alias for clarity
    CASE WHEN SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) > 0 THEN 1 ELSE 0 END AS HasErrors  -- Flag: 1 = has errors, 0 = no errors
FROM [redw].[tia].[DataWipeResult] AS dwr
INNER JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
GROUP BY 
    CAST(dwr.EndTime AS DATE),
    CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END,
    stl.TestName,
    dwr.Result,
    stl.Result;

