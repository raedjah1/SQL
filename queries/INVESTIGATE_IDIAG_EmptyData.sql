-- INVESTIGATIVE QUERY: Empty/Null Data Analysis
-- Purpose: Understand why so many fields are empty and what it means

-- ============================================================================
-- 1. EMPTY SERIALNUMBERS - Why are so many SerialNumbers blank?
-- ============================================================================

-- 1.1: How many tests have empty SerialNumbers?
SELECT 
    MachineName,
    Result,
    COUNT(*) AS TotalTests,
    SUM(CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 1 ELSE 0 END) AS EmptySerialCount,
    SUM(CASE WHEN SerialNumber IS NOT NULL AND SerialNumber != '' THEN 1 ELSE 0 END) AS HasSerialCount,
    SUM(CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS PctEmpty
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
GROUP BY MachineName, Result
ORDER BY MachineName, Result;

-- 1.2: Are empty SerialNumbers clustered in time? (Maybe a system issue?)
SELECT 
    CAST(StartTime AS DATE) AS TestDate,
    MachineName,
    COUNT(*) AS TotalTests,
    SUM(CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 1 ELSE 0 END) AS EmptySerialCount,
    SUM(CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS PctEmpty
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND StartTime >= DATEADD(DAY, -90, GETDATE())
GROUP BY CAST(StartTime AS DATE), MachineName
ORDER BY TestDate DESC, MachineName;

-- 1.3: Do empty SerialNumbers have subtests? (Are they real tests or errors?)
SELECT 
    CASE WHEN dwr.SerialNumber IS NULL OR dwr.SerialNumber = '' THEN 'Empty Serial' ELSE 'Has Serial' END AS SerialStatus,
    COUNT(DISTINCT dwr.ID) AS MainTestCount,
    COUNT(DISTINCT stl.ID) AS SubtestCount,
    AVG(SubtestCountPerTest) AS AvgSubtestsPerTest
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN (
    SELECT MainTestID, COUNT(*) AS SubtestCountPerTest
    FROM [redw].[tia].[SubTestLogs]
    GROUP BY MainTestID
) AS st ON st.MainTestID = dwr.ID
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
GROUP BY CASE WHEN dwr.SerialNumber IS NULL OR dwr.SerialNumber = '' THEN 'Empty Serial' ELSE 'Has Serial' END;

-- 1.4: Can we find SerialNumbers from subtests or other fields?
SELECT TOP 50
    dwr.ID AS TestID,
    dwr.SerialNumber AS MainSerialNumber,
    dwr.PartNumber,
    dwr.MachineName,
    dwr.Result,
    dwr.StartTime,
    -- Check if SerialNumber appears in other fields
    dwr.MiscInfo,
    dwr.Msg,
    dwr.FileReference,
    dwr.FailureReference,
    COUNT(stl.ID) AS SubtestCount
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND (dwr.SerialNumber IS NULL OR dwr.SerialNumber = '')
GROUP BY dwr.ID, dwr.SerialNumber, dwr.PartNumber, dwr.MachineName, dwr.Result, dwr.StartTime, dwr.MiscInfo, dwr.Msg, dwr.FileReference, dwr.FailureReference
ORDER BY dwr.StartTime DESC;

-- ============================================================================
-- 2. EMPTY PARTNUMBERS - Why are PartNumbers often empty?
-- ============================================================================

-- 2.1: PartNumber completeness by machine type
SELECT 
    MachineName,
    Result,
    COUNT(*) AS TotalTests,
    SUM(CASE WHEN PartNumber IS NULL OR PartNumber = '' THEN 1 ELSE 0 END) AS EmptyPartNumber,
    SUM(CASE WHEN PartNumber IS NOT NULL AND PartNumber != '' THEN 1 ELSE 0 END) AS HasPartNumber,
    SUM(CASE WHEN PartNumber IS NOT NULL AND PartNumber != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS PctWithPartNumber
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
GROUP BY MachineName, Result
ORDER BY MachineName, Result;

-- 2.2: When PartNumber IS populated, what does it look like?
SELECT 
    MachineName,
    LEFT(PartNumber, 20) AS PartNumberPrefix,
    COUNT(*) AS Count,
    MIN(StartTime) AS FirstSeen,
    MAX(StartTime) AS LastSeen
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND PartNumber IS NOT NULL
  AND PartNumber != ''
GROUP BY MachineName, LEFT(PartNumber, 20)
ORDER BY Count DESC;

-- 2.3: Can we get PartNumber from PartSerial table when it's missing?
SELECT 
    dwr.ID AS TestID,
    dwr.SerialNumber,
    dwr.PartNumber AS PartNumberInTest,
    ps.PartNo AS PartNumberFromPartSerial,
    CASE 
        WHEN dwr.PartNumber IS NULL OR dwr.PartNumber = '' THEN 'Missing in Test'
        WHEN ps.PartNo IS NULL THEN 'Missing in Both'
        WHEN dwr.PartNumber = ps.PartNo THEN 'Match'
        ELSE 'Mismatch'
    END AS PartNumberStatus,
    dwr.MachineName,
    dwr.Result
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN Plus.pls.PartSerial AS ps ON ps.SerialNumber = dwr.SerialNumber AND ps.ProgramID = 10053
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND dwr.SerialNumber IS NOT NULL
  AND dwr.SerialNumber != ''
  AND dwr.StartTime >= DATEADD(DAY, -7, GETDATE())
ORDER BY dwr.StartTime DESC;

-- ============================================================================
-- 3. EMPTY METADATA FIELDS - What's missing and why?
-- ============================================================================

-- 3.1: Completeness of all optional fields
SELECT 
    'MiscInfo' AS FieldName,
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN MiscInfo IS NULL OR MiscInfo = '' THEN 1 ELSE 0 END) AS EmptyCount,
    SUM(CASE WHEN MiscInfo IS NOT NULL AND MiscInfo != '' THEN 1 ELSE 0 END) AS PopulatedCount
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')

UNION ALL

SELECT 
    'MACAddress' AS FieldName,
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN MACAddress IS NULL OR MACAddress = '' THEN 1 ELSE 0 END) AS EmptyCount,
    SUM(CASE WHEN MACAddress IS NOT NULL AND MACAddress != '' THEN 1 ELSE 0 END) AS PopulatedCount
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')

UNION ALL

SELECT 
    'Msg' AS FieldName,
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN Msg IS NULL OR Msg = '' THEN 1 ELSE 0 END) AS EmptyCount,
    SUM(CASE WHEN Msg IS NOT NULL AND Msg != '' THEN 1 ELSE 0 END) AS PopulatedCount
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')

UNION ALL

SELECT 
    'FileReference' AS FieldName,
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN FileReference IS NULL OR FileReference = '' THEN 1 ELSE 0 END) AS EmptyCount,
    SUM(CASE WHEN FileReference IS NOT NULL AND FileReference != '' THEN 1 ELSE 0 END) AS PopulatedCount
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')

UNION ALL

SELECT 
    'FailureReference' AS FieldName,
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN FailureReference IS NULL OR FailureReference = '' THEN 1 ELSE 0 END) AS EmptyCount,
    SUM(CASE WHEN FailureReference IS NOT NULL AND FailureReference != '' THEN 1 ELSE 0 END) AS PopulatedCount
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')

UNION ALL

SELECT 
    'BatteryHealthGrade' AS FieldName,
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN BatteryHealthGrade IS NULL OR BatteryHealthGrade = '' THEN 1 ELSE 0 END) AS EmptyCount,
    SUM(CASE WHEN BatteryHealthGrade IS NOT NULL AND BatteryHealthGrade != '' THEN 1 ELSE 0 END) AS PopulatedCount
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')

ORDER BY PopulatedCount DESC;

-- 3.2: When fields ARE populated, what do they contain?
SELECT TOP 50
    ID,
    SerialNumber,
    MachineName,
    Result,
    MiscInfo,
    MACAddress,
    Msg,
    FileReference,
    FailureReference,
    BatteryHealthGrade
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND (
      (MiscInfo IS NOT NULL AND MiscInfo != '')
      OR (MACAddress IS NOT NULL AND MACAddress != '')
      OR (Msg IS NOT NULL AND Msg != '')
      OR (FileReference IS NOT NULL AND FileReference != '')
      OR (FailureReference IS NOT NULL AND FailureReference != '')
      OR (BatteryHealthGrade IS NOT NULL AND BatteryHealthGrade != '')
  )
ORDER BY StartTime DESC;

-- ============================================================================
-- 4. PATTERNS IN EMPTY DATA - Are there correlations?
-- ============================================================================

-- 4.1: Do empty SerialNumbers correlate with empty PartNumbers?
SELECT 
    CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 'Empty Serial' ELSE 'Has Serial' END AS SerialStatus,
    CASE WHEN PartNumber IS NULL OR PartNumber = '' THEN 'Empty Part' ELSE 'Has Part' END AS PartStatus,
    COUNT(*) AS Count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS PctOfTotal
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
GROUP BY 
    CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 'Empty Serial' ELSE 'Has Serial' END,
    CASE WHEN PartNumber IS NULL OR PartNumber = '' THEN 'Empty Part' ELSE 'Has Part' END
ORDER BY Count DESC;

-- 4.2: Do empty SerialNumbers correlate with test results?
SELECT 
    CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 'Empty Serial' ELSE 'Has Serial' END AS SerialStatus,
    Result,
    COUNT(*) AS Count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 'Empty Serial' ELSE 'Has Serial' END) AS PctOfGroup
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
GROUP BY 
    CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 'Empty Serial' ELSE 'Has Serial' END,
    Result
ORDER BY SerialStatus, Result;

-- 4.3: Do empty SerialNumbers correlate with machine type?
SELECT 
    MachineName,
    CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 'Empty Serial' ELSE 'Has Serial' END AS SerialStatus,
    COUNT(*) AS Count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY MachineName) AS PctOfMachine
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
GROUP BY MachineName,
    CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 'Empty Serial' ELSE 'Has Serial' END
ORDER BY MachineName, SerialStatus;

-- ============================================================================
-- 5. DATA COMPLETENESS OVER TIME - Is it getting better or worse?
-- ============================================================================

-- 5.1: SerialNumber completeness trend
SELECT 
    CAST(StartTime AS DATE) AS TestDate,
    COUNT(*) AS TotalTests,
    SUM(CASE WHEN SerialNumber IS NULL OR SerialNumber = '' THEN 1 ELSE 0 END) AS EmptySerialCount,
    SUM(CASE WHEN SerialNumber IS NOT NULL AND SerialNumber != '' THEN 1 ELSE 0 END) AS HasSerialCount,
    SUM(CASE WHEN SerialNumber IS NOT NULL AND SerialNumber != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS PctComplete
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND StartTime >= DATEADD(DAY, -90, GETDATE())
GROUP BY CAST(StartTime AS DATE)
ORDER BY TestDate DESC;

-- 5.2: PartNumber completeness trend
SELECT 
    CAST(StartTime AS DATE) AS TestDate,
    MachineName,
    COUNT(*) AS TotalTests,
    SUM(CASE WHEN PartNumber IS NULL OR PartNumber = '' THEN 1 ELSE 0 END) AS EmptyPartCount,
    SUM(CASE WHEN PartNumber IS NOT NULL AND PartNumber != '' THEN 1 ELSE 0 END) AS HasPartCount,
    SUM(CASE WHEN PartNumber IS NOT NULL AND PartNumber != '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS PctComplete
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND StartTime >= DATEADD(DAY, -90, GETDATE())
GROUP BY CAST(StartTime AS DATE), MachineName
ORDER BY TestDate DESC, MachineName;

-- ============================================================================
-- 6. CAN WE RECOVER MISSING DATA? - Look for alternative sources
-- ============================================================================

-- 6.1: Find tests with empty SerialNumber but see if we can match by PartNumber
SELECT 
    dwr.ID AS TestID,
    dwr.SerialNumber AS TestSerialNumber,
    dwr.PartNumber AS TestPartNumber,
    ps.SerialNumber AS PartSerialSerialNumber,
    ps.PartNo AS PartSerialPartNumber,
    dwr.MachineName,
    dwr.Result,
    dwr.StartTime
FROM [redw].[tia].[DataWipeResult] AS dwr
LEFT JOIN Plus.pls.PartSerial AS ps ON ps.PartNo = dwr.PartNumber AND ps.ProgramID = 10053
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND (dwr.SerialNumber IS NULL OR dwr.SerialNumber = '')
  AND dwr.PartNumber IS NOT NULL
  AND dwr.PartNumber != ''
  AND ps.SerialNumber IS NOT NULL
ORDER BY dwr.StartTime DESC;

-- 6.2: Check if OrderNumber can help identify units
SELECT 
    OrderNumber,
    COUNT(*) AS TestCount,
    COUNT(DISTINCT SerialNumber) AS UniqueSerials,
    COUNT(DISTINCT PartNumber) AS UniqueParts,
    MIN(StartTime) AS FirstTest,
    MAX(StartTime) AS LastTest
FROM [redw].[tia].[DataWipeResult]
WHERE Contract = '10053'
  AND TestArea = 'MEMPHIS'
  AND (MachineName = 'IDIAGS' OR MachineName = 'IDIAGS-MB-RESET')
  AND OrderNumber IS NOT NULL
  AND OrderNumber != ''
GROUP BY OrderNumber
HAVING COUNT(*) > 1
ORDER BY TestCount DESC;

