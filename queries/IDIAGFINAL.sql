-- PowerBI-ready DETAIL dataset: Main tests + Subtests (UTC) + AttemptType per day
-- FIXED: Uses UNION to guarantee every test has exactly ONE main test row, even when subtests exist
-- Slicers: TestDate_CDT, SerialNumber, MachineNameNormalized, AttemptType_Day, RecordType, SubTestName/SubTestResult
-- NOTE: Field names include *_CDT for backward compatibility, but values are now UTC (no timezone conversion).

-- PART 1: Main Test rows (one per test, guaranteed)
SELECT
    t.TestDate_CDT,
    t.SerialNumber,
    t.PartNumber,
    t.MachineNameNormalized,
    t.AttemptType_Day,
    t.TotalAttempts_Day,
    'Main Test' AS RecordType,
    t.TestResult,
    CASE WHEN t.TestResult = 'PASS' THEN 1 ELSE 0 END AS PassFlag,
    CASE WHEN t.TestResult = 'FAIL' THEN 1 ELSE 0 END AS FailFlag,
    t.StartTime_CDT,
    t.EndTime_CDT,
    t.TestDurationSeconds,
    t.TestID,
    -- Subtest fields (NULL for main test rows)
    NULL AS SubTestName,
    NULL AS SubTestResult,
    NULL AS SubTestStartTime_CDT,
    NULL AS SubTestEndTime_CDT,
    NULL AS SubTestDurationSeconds,
    NULL AS SubTestID,
    NULL AS SubTestIDNumber,
    t.TestArea,
    t.CellNumber,
    t.OrderNumber
FROM (
    SELECT
        bt.*,
        COUNT(*) OVER (PARTITION BY bt.SerialNumber, bt.MachineNameNormalized, bt.TestDate_CDT) AS TotalAttempts_Day,
        CASE
            WHEN COUNT(*) OVER (PARTITION BY bt.SerialNumber, bt.MachineNameNormalized, bt.TestDate_CDT) = 1 THEN 'Only'
            WHEN ROW_NUMBER() OVER (
                    PARTITION BY bt.SerialNumber, bt.MachineNameNormalized, bt.TestDate_CDT
                    ORDER BY bt.EndTime_CDT ASC, bt.TestID ASC
                 ) = 1 THEN 'First'
            WHEN ROW_NUMBER() OVER (
                    PARTITION BY bt.SerialNumber, bt.MachineNameNormalized, bt.TestDate_CDT
                    ORDER BY bt.EndTime_CDT DESC, bt.TestID DESC
                 ) = 1 THEN 'Last'
            ELSE 'Middle'
        END AS AttemptType_Day
    FROM (
    SELECT 
        dwr.ID AS TestID,
        dwr.SerialNumber,
        ISNULL(ps.PartNo, dwr.PartNumber) AS PartNumber,
        dwr.MachineName,
            CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END AS MachineNameNormalized,
        dwr.Result AS TestResult,
        dwr.TestArea,
            dwr.CellNumber,
            dwr.OrderNumber,
            dwr.StartTime AS StartTime_CDT,
            dwr.EndTime AS EndTime_CDT,
            CAST(dwr.EndTime AS DATE) AS TestDate_CDT,
            DATEDIFF(SECOND, dwr.StartTime, dwr.EndTime) AS TestDurationSeconds
    FROM [redw].[tia].[DataWipeResult] AS dwr
    OUTER APPLY (
        SELECT TOP 1 ps.PartNo
        FROM Plus.pls.PartSerial ps
        WHERE ps.SerialNo = dwr.SerialNumber
          AND ps.ProgramID = 10053
        ORDER BY ps.ID DESC
    ) AS ps
        WHERE dwr.Contract = '10053'
        AND dwr.TestArea = 'MEMPHIS'
          AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
    ) bt
) t

    UNION ALL

-- PART 2: Subtest rows (one per subtest)
    SELECT 
    CAST(dwr.EndTime AS DATE) AS TestDate_CDT,
    dwr.SerialNumber,
    ISNULL(ps.PartNo, dwr.PartNumber) AS PartNumber,
    CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END AS MachineNameNormalized,
    -- Calculate AttemptType_Day for main test (needed for subtests too)
    CASE
        WHEN COUNT(*) OVER (PARTITION BY dwr.SerialNumber, 
            CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END,
            CAST(dwr.EndTime AS DATE)) = 1 THEN 'Only'
        WHEN ROW_NUMBER() OVER (
                PARTITION BY dwr.SerialNumber,
                    CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END,
                    CAST(dwr.EndTime AS DATE)
                ORDER BY dwr.EndTime ASC, dwr.ID ASC
             ) = 1 THEN 'First'
        WHEN ROW_NUMBER() OVER (
                PARTITION BY dwr.SerialNumber,
                    CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END,
                    CAST(dwr.EndTime AS DATE)
                ORDER BY dwr.EndTime DESC, dwr.ID DESC
             ) = 1 THEN 'Last'
        ELSE 'Middle'
    END AS AttemptType_Day,
    COUNT(*) OVER (PARTITION BY dwr.SerialNumber,
        CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END,
        CAST(dwr.EndTime AS DATE)) AS TotalAttempts_Day,
    'Subtest' AS RecordType,
    dwr.Result AS TestResult,
    CASE WHEN dwr.Result = 'PASS' THEN 1 ELSE 0 END AS PassFlag,
    CASE WHEN dwr.Result = 'FAIL' THEN 1 ELSE 0 END AS FailFlag,
    dwr.StartTime AS StartTime_CDT,
    dwr.EndTime AS EndTime_CDT,
    DATEDIFF(SECOND, dwr.StartTime, dwr.EndTime) AS TestDurationSeconds,
    dwr.ID AS TestID,
    stl.TestName AS SubTestName,
    stl.Result AS SubTestResult,
    stl.StartTime AS SubTestStartTime_CDT,
    stl.EndTime AS SubTestEndTime_CDT,
    DATEDIFF(SECOND, stl.StartTime, stl.EndTime) AS SubTestDurationSeconds,
    stl.ID AS SubTestID,
    stl.TestIDNumber AS SubTestIDNumber,
    dwr.TestArea,
    dwr.CellNumber,
    dwr.OrderNumber
FROM [redw].[tia].[DataWipeResult] AS dwr
INNER JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
OUTER APPLY (
    SELECT TOP 1 ps.PartNo
    FROM Plus.pls.PartSerial ps
    WHERE ps.SerialNo = dwr.SerialNumber
      AND ps.ProgramID = 10053
    ORDER BY ps.ID DESC
) AS ps
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')

-- PERFORMANCE NOTES:
-- Consider indexes on:
--   DataWipeResult: (Contract, TestArea, MachineName, StartTime) INCLUDE (SerialNumber, PartNumber, Result, EndTime, ID)
--   SubTestLogs: (MainTestID) INCLUDE (TestName, Result, StartTime, EndTime, TestIDNumber)