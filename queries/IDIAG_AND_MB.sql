-- Comprehensive IDIAG and MB-RESET Test Results Query
-- Includes all test data and subtest details for dashboard building
-- MachineName: 'IDIAGS' = IDIAG tests, 'IDIAGS-MB-RESET' = MB-RESET tests
--
-- WHAT THIS QUERY RETURNS:
-- - One row per subtest (tests with multiple subtests = multiple rows)
-- - Tests without subtests still appear (LEFT JOIN, subtest columns will be NULL)
-- - All datetime fields are converted to CDT (Central Daylight Time)
-- - Includes calculated fields: TestSequenceNumber (1 = latest), TotalAttempts, AttemptType (First/Last/Middle)
-- - Includes subtest grouping: SubTestSequenceNumber, TotalSubTestsPerTest, SubTestPosition
--
-- USAGE NOTES:
-- 1. This query returns ALL test results with their subtests
-- 2. To get only the LATEST test per serial number, add: WHERE TestSequenceNumber = 1
-- 3. To get only main tests (no subtests), change LEFT JOIN to INNER JOIN and remove subtest columns
-- 4. MachineNameNormalized converts 'IDIAGS-MB-RESET' to 'MB-RESET' for easier filtering
-- 5. Contract = '10053' (varchar field, must use quotes)
--
-- DASHBOARD BUILDING TIPS:
-- - Use TestSequenceNumber = 1 to get latest test per serial
-- - Use AttemptType = 'First' to get first test attempt per serial
-- - Use AttemptType = 'Last' to get last test attempt per serial
-- - Use AttemptType = 'Middle' to get retest attempts (not first or last)
-- - Use TotalAttempts to see how many times a serial was tested
-- - Use TestResultNumeric for easy pass/fail calculations (1=Pass, 0=Fail)
-- - Use TestDate, TestYear, TestMonth for date-based filtering
-- - Group by MachineNameNormalized to separate IDIAG vs MB-RESET
-- - Filter by SubTestResult to analyze specific subtest failures
--
-- IDENTIFYING SUBTESTS FOR THE SAME TEST:
-- - All rows with the same TestID belong to the same test
-- - SubTestMainTestID should match TestID (they link together)
-- - Use SubTestSequenceNumber to see order of subtests (1, 2, 3, etc.)
-- - Use TotalSubTestsPerTest to see how many subtests a test has
-- - Use SubTestPosition to identify First/Last/Middle/Only subtest
-- - Group by TestID to see all subtests for one test together

SELECT 
    -- Main Test Information
    dwr.ID AS TestID,
    dwr.SerialNumber,
    dwr.PartNumber,
    -- Convert times to CDT (Central Daylight Time)
    dwr.StartTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS StartTime_CDT,
    dwr.EndTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS EndTime_CDT,
    dwr.MachineName,
    -- Normalize MachineName: IDIAGS-MB-RESET → MB-RESET
    CASE 
        WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET'
        ELSE dwr.MachineName
    END AS MachineNameNormalized,
    dwr.Result AS TestResult,
    dwr.TestArea,
    dwr.CellNumber,
    dwr.Program,
    dwr.Contract,
    
    -- Test Duration (calculated from original UTC times)
    DATEDIFF(SECOND, dwr.StartTime, dwr.EndTime) AS TestDurationSeconds,
    DATEDIFF(MINUTE, dwr.StartTime, dwr.EndTime) AS TestDurationMinutes,
    
    -- Additional Test Fields
    dwr.MiscInfo,
    dwr.MACAddress,
    dwr.Msg,
    dwr.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS AsOf_CDT,
    dwr.Exported,
    dwr.LastModifiedBy,
    dwr.LastModifiedOn AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS LastModifiedOn_CDT,
    dwr.Username,
    dwr.OrderNumber,
    dwr.UploadTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS UploadTime_CDT,
    dwr.FileReference,
    dwr.FailureReference,
    dwr.FailureNumber,
    dwr.ErrItem,
    dwr.TestAreaOrig,
    dwr.BatteryHealthGrade,
    dwr.LogFileStatus,
    
    -- Subtest Information (from SubTestLogs)
    -- Actual SubTestLogs columns: ID, MainTestID, TestIDNumber, TestName, TestDesc, StartTime, EndTime, Result, ErrorMessage, ResultMessage, param, resultunit
    stl.ID AS SubTestID,
    stl.MainTestID AS SubTestMainTestID,
    stl.TestIDNumber AS SubTestIDNumber,
    stl.TestName AS SubTestName,
    stl.TestDesc AS SubTestDescription,
    -- Convert subtest times to CDT
    stl.StartTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS SubTestStartTime_CDT,
    stl.EndTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS SubTestEndTime_CDT,
    -- Calculate subtest duration from StartTime and EndTime (using original UTC times)
    DATEDIFF(SECOND, stl.StartTime, stl.EndTime) AS SubTestDurationSeconds,
    stl.Result AS SubTestResult,
    stl.ErrorMessage AS SubTestErrorMessage,
    stl.ResultMessage AS SubTestResultMessage,
    stl.param AS SubTestParam,
    stl.resultunit AS SubTestResultUnit,
    
    -- Subtest Grouping Indicators (to identify which subtests belong to same test)
    -- Subtest sequence number within the test (1, 2, 3, etc.)
    ROW_NUMBER() OVER (
        PARTITION BY dwr.ID
        ORDER BY stl.TestIDNumber ASC, stl.StartTime ASC
    ) AS SubTestSequenceNumber,
    
    -- Total number of subtests for this test
    COUNT(stl.ID) OVER (
        PARTITION BY dwr.ID
    ) AS TotalSubTestsPerTest,
    
    -- Subtest position indicator (First, Last, or Middle)
    CASE 
        WHEN COUNT(stl.ID) OVER (PARTITION BY dwr.ID) = 1 THEN 'Only'
        WHEN ROW_NUMBER() OVER (
            PARTITION BY dwr.ID
            ORDER BY stl.TestIDNumber ASC, stl.StartTime ASC
        ) = 1 THEN 'First'
        WHEN ROW_NUMBER() OVER (
            PARTITION BY dwr.ID
            ORDER BY stl.TestIDNumber DESC, stl.StartTime DESC
        ) = 1 THEN 'Last'
        ELSE 'Middle'
    END AS SubTestPosition,
    
    -- Calculated Fields for Dashboard
    CASE 
        WHEN dwr.Result = 'PASS' THEN 1 
        WHEN dwr.Result = 'FAIL' THEN 0 
        ELSE NULL 
    END AS TestResultNumeric,  -- 1 = Pass, 0 = Fail, NULL = Unknown
    
    CASE 
        WHEN stl.Result = 'PASSED' THEN 1 
        WHEN stl.Result = 'FAILED' THEN 0 
        ELSE NULL 
    END AS SubTestResultNumeric,  -- 1 = Passed, 0 = Failed, NULL = Unknown
    
    -- Date/Time Fields for Filtering (in CDT)
    CAST(dwr.StartTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE) AS TestDate_CDT,
    CAST(dwr.StartTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS TIME) AS TestTime_CDT,
    DATEPART(YEAR, dwr.StartTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time') AS TestYear,
    DATEPART(MONTH, dwr.StartTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time') AS TestMonth,
    DATEPART(DAY, dwr.StartTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time') AS TestDay,
    DATEPART(HOUR, dwr.StartTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time') AS TestHour,
    DATENAME(WEEKDAY, dwr.StartTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time') AS TestDayOfWeek,
    
    -- Test Sequence Indicators
    -- Latest Test Indicator (using ROW_NUMBER for latest per serial)
    ROW_NUMBER() OVER (
        PARTITION BY dwr.SerialNumber, 
                     CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END
        ORDER BY dwr.EndTime DESC, dwr.ID DESC
    ) AS TestSequenceNumber,
    
    -- First Test Indicator (1 = first attempt, ordered by EndTime ASC)
    ROW_NUMBER() OVER (
        PARTITION BY dwr.SerialNumber, 
                     CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END
        ORDER BY dwr.EndTime ASC, dwr.ID ASC
    ) AS FirstAttemptSequence,
    
    -- Total number of attempts per serial/machine
    COUNT(*) OVER (
        PARTITION BY dwr.SerialNumber, 
                     CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END
    ) AS TotalAttempts,
    
    -- Attempt Type Flag: First, Last, or Middle
    CASE 
        WHEN ROW_NUMBER() OVER (
            PARTITION BY dwr.SerialNumber, 
                         CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END
            ORDER BY dwr.EndTime ASC, dwr.ID ASC
        ) = 1 THEN 'First'
        WHEN ROW_NUMBER() OVER (
            PARTITION BY dwr.SerialNumber, 
                         CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END
            ORDER BY dwr.EndTime DESC, dwr.ID DESC
        ) = 1 THEN 'Last'
        ELSE 'Middle'
    END AS AttemptType

FROM [redw].[tia].[DataWipeResult] AS dwr
    -- LEFT JOIN to include main tests even if no subtests exist
    LEFT JOIN [redw].[tia].[SubTestLogs] AS stl 
        ON stl.MainTestID = dwr.ID

WHERE dwr.Contract = '10053'  -- Contract filter (varchar, must use quotes)
    AND (
        dwr.MachineName = 'IDIAGS' 
        OR dwr.MachineName = 'IDIAGS-MB-RESET'
    )
    AND dwr.TestArea = 'MEMPHIS'

ORDER BY 
    dwr.SerialNumber,
    CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END,
    dwr.EndTime DESC,  -- Using original UTC for sorting (consistent ordering)
    dwr.ID DESC,
    stl.TestIDNumber ASC,  -- Order subtests by TestIDNumber (if NULL, will sort first)
    stl.StartTime ASC;  -- Secondary sort by start time (using original UTC)

-- ============================================================================
-- ALTERNATIVE: Get only LATEST test per serial number (wrap above query):
-- ============================================================================
/*
SELECT * FROM (
    -- [Insert the query above here]
) AS AllTests
WHERE TestSequenceNumber = 1
ORDER BY SerialNumber, MachineNameNormalized, EndTime DESC;
*/

-- ============================================================================
-- ALTERNATIVE: Get only MAIN tests (no subtests, one row per test):
-- ============================================================================
/*
SELECT 
    dwr.ID AS TestID,
    dwr.SerialNumber,
    dwr.PartNumber,
    dwr.StartTime,
    dwr.EndTime,
    CASE 
        WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET'
        ELSE dwr.MachineName
    END AS MachineNameNormalized,
    dwr.Result AS TestResult,
    DATEDIFF(SECOND, dwr.StartTime, dwr.EndTime) AS TestDurationSeconds,
    -- Add other main test fields as needed
    COUNT(stl.ID) AS SubTestCount,
    SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) AS PassedSubTestCount,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FailedSubTestCount
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
    AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
    AND dwr.TestArea = 'MEMPHIS'
GROUP BY 
    dwr.ID, dwr.SerialNumber, dwr.PartNumber, dwr.StartTime, dwr.EndTime, 
    dwr.MachineName, dwr.Result
ORDER BY dwr.SerialNumber, dwr.EndTime DESC;
*/

