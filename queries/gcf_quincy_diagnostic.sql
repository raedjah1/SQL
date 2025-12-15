-- ============================================================================
-- Diagnostic Query: Why are counts different from Excel?
-- ============================================================================

-- Check 1: Total count per date (should match Excel's "Total Quincy Interactions")
-- Testing both COUNT(*) and COUNT(DISTINCT serialNo) to see which matches Excel
SELECT 
    CAST(createDate AS DATE) AS [Date],
    COUNT(DISTINCT serialNo) AS [DistinctSerialNumbers],
    COUNT(*) AS [TotalRecords],
    'Using FIRST attempt (RowNum = 1)' AS [SelectionMethod]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate ASC) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(r.createDate AS DATE) = '2025-11-19'
) AS RankedRecords
WHERE RowNum = 1
GROUP BY CAST(createDate AS DATE)
UNION ALL
SELECT 
    CAST(createDate AS DATE) AS [Date],
    COUNT(DISTINCT serialNo) AS [DistinctSerialNumbers],
    COUNT(*) AS [TotalRecords],
    'Using LAST attempt (RowNum = Last)' AS [SelectionMethod]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate DESC) AS RowNum,
        COUNT(*) OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE)) AS TotalAttempts
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(r.createDate AS DATE) = '2025-11-19'
) AS RankedRecords
WHERE RowNum = 1
GROUP BY CAST(createDate AS DATE)
UNION ALL
SELECT 
    CAST(createDate AS DATE) AS [Date],
    COUNT(DISTINCT serialNo) AS [DistinctSerialNumbers],
    COUNT(*) AS [TotalRecords],
    'Using FIRST attempt with valid XML' AS [SelectionMethod]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (
            PARTITION BY r.serialNo, CAST(r.createDate AS DATE) 
            ORDER BY 
                CASE WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' THEN 0 ELSE 1 END,
                r.createDate ASC
        ) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(r.createDate AS DATE) = '2025-11-19'
) AS RankedRecords
WHERE RowNum = 1
GROUP BY CAST(createDate AS DATE);

-- Check 2: Test Log Translation categorization (with FIXED pattern)
SELECT 
    CASE 
        WHEN isSuccess = 1 THEN 'Quincy Resolution Attempt'
        WHEN log LIKE '%Not trained to resolve%' OR log LIKE '%not trained to resolve%' THEN 'Not yet trained to resolve'
        WHEN log LIKE '%No repair parts found%' THEN 'No repair parts found'
        WHEN log LIKE '%Unit does not have a work order created yet%' THEN 'Unit does not have a work order created yet'
        WHEN log LIKE '%Could not find any GCF errors in B2B outbound data%' THEN 'Could not find any GCF errors in B2B outbound data'
        WHEN log LIKE '%No inventory parts were found%' THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
        WHEN log LIKE '%Attempted too many times to fix%' THEN 'Attempted too many times'
        WHEN log LIKE '%Unit does not have PartSerial entry%' THEN 'Unable to locate a unit for reference'
        WHEN log LIKE '%No required MODs found from pre-existing family%' THEN 'Unable to locate a unit for reference'
        WHEN log LIKE '%No pre-existing family found%' THEN 'Unit does not have PartSerial entry'
        WHEN log LIKE '%Unit is not in%' THEN 'Routing Errors'
        WHEN log LIKE '%Could not find route/location%' THEN 'Routing Errors'
        WHEN log LIKE '%Unit is not in correct ReImage%' THEN 'Routing Errors'
        WHEN log LIKE '%No route found%' THEN 'Routing Errors'
        ELSE 'Error not yet defined'
    END AS [LogTranslation],
    COUNT(*) AS [Count]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate ASC) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(r.createDate AS DATE) = '2025-11-19'
) AS RankedRecords
WHERE RowNum = 1
GROUP BY 
    CASE 
        WHEN isSuccess = 1 THEN 'Quincy Resolution Attempt'
        WHEN log LIKE '%Not trained to resolve%' OR log LIKE '%not trained to resolve%' THEN 'Not yet trained to resolve'
        WHEN log LIKE '%No repair parts found%' THEN 'No repair parts found'
        WHEN log LIKE '%Unit does not have a work order created yet%' THEN 'Unit does not have a work order created yet'
        WHEN log LIKE '%Could not find any GCF errors in B2B outbound data%' THEN 'Could not find any GCF errors in B2B outbound data'
        WHEN log LIKE '%No inventory parts were found%' THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
        WHEN log LIKE '%Attempted too many times to fix%' THEN 'Attempted too many times'
        WHEN log LIKE '%Unit does not have PartSerial entry%' THEN 'Unable to locate a unit for reference'
        WHEN log LIKE '%No required MODs found from pre-existing family%' THEN 'Unable to locate a unit for reference'
        WHEN log LIKE '%No pre-existing family found%' THEN 'Unit does not have PartSerial entry'
        WHEN log LIKE '%Unit is not in%' THEN 'Routing Errors'
        WHEN log LIKE '%Could not find route/location%' THEN 'Routing Errors'
        WHEN log LIKE '%Unit is not in correct ReImage%' THEN 'Routing Errors'
        WHEN log LIKE '%No route found%' THEN 'Routing Errors'
        ELSE 'Error not yet defined'
    END
ORDER BY [Count] DESC;

-- Check 2b: What's STILL in "Error not yet defined" category? (should be much smaller now)
SELECT TOP 20
    log,
    LEFT(log, 150) AS [LogPreview]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate ASC) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(r.createDate AS DATE) = '2025-11-19'
        AND isSuccess != 1
) AS RankedRecords
WHERE RowNum = 1
    AND (
        log NOT LIKE '%Not trained to resolve%' AND log NOT LIKE '%not trained to resolve%'
        AND log NOT LIKE '%No repair parts found%'
        AND log NOT LIKE '%Unit does not have a work order created yet%'
        AND log NOT LIKE '%Could not find any GCF errors in B2B outbound data%'
        AND log NOT LIKE '%No inventory parts were found%'
        AND log NOT LIKE '%Attempted too many times to fix%'
        AND log NOT LIKE '%Unit does not have PartSerial entry%'
        AND log NOT LIKE '%No required MODs found from pre-existing family%'
        AND log NOT LIKE '%No pre-existing family found%'
        AND log NOT LIKE '%Unit is not in%'
        AND log NOT LIKE '%Could not find route/location%'
        AND log NOT LIKE '%Unit is not in correct ReImage%'
        AND log NOT LIKE '%No route found%'
    )
ORDER BY createDate DESC;

-- Check 3: Count by isSuccess (should match Excel's breakdown)
SELECT 
    CAST(createDate AS DATE) AS [Date],
    isSuccess,
    COUNT(*) AS [Count]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate ASC) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(r.createDate AS DATE) = '2025-11-19'
) AS RankedRecords
WHERE RowNum = 1
GROUP BY CAST(createDate AS DATE), isSuccess
ORDER BY CAST(createDate AS DATE), isSuccess;

-- Check 4: Pattern matching test for "Not yet trained to resolve" (with FIXED pattern)
SELECT 
    CASE 
        WHEN log LIKE '%Not trained to resolve%' OR log LIKE '%not trained to resolve%' THEN 'MATCHED: Not yet trained to resolve'
        ELSE 'NOT MATCHED'
    END AS [MatchStatus],
    COUNT(*) AS [Count]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate ASC) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(r.createDate AS DATE) = '2025-11-19'
        AND isSuccess != 1
) AS RankedRecords
WHERE RowNum = 1
GROUP BY 
    CASE 
        WHEN log LIKE '%Not trained to resolve%' OR log LIKE '%not trained to resolve%' THEN 'MATCHED: Not yet trained to resolve'
        ELSE 'NOT MATCHED'
    END
ORDER BY [Count] DESC;

-- Check 5: Compare with Excel totals for 11/19/2025
-- Excel shows: Total = 412, Resolution Attempts = 105, No Resolution = 307
-- Testing UTC date vs CST date filtering
SELECT 
    'SQL Results (UTC Date Filter)' AS [Source],
    COUNT(*) AS [TotalInteractions],
    SUM(CASE WHEN isSuccess = 1 THEN 1 ELSE 0 END) AS [ResolutionAttempts],
    SUM(CASE WHEN isSuccess != 1 THEN 1 ELSE 0 END) AS [NoResolutionAttempts]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate ASC) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(r.createDate AS DATE) = '2025-11-19'  -- UTC date filter
) AS RankedRecords
WHERE RowNum = 1
UNION ALL
SELECT 
    'SQL Results (CST Date Filter)' AS [Source],
    COUNT(*) AS [TotalInteractions],
    SUM(CASE WHEN isSuccess = 1 THEN 1 ELSE 0 END) AS [ResolutionAttempts],
    SUM(CASE WHEN isSuccess != 1 THEN 1 ELSE 0 END) AS [NoResolutionAttempts]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) ORDER BY r.createDate ASC) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-19'  -- CST date filter (UTC - 6 hours)
) AS RankedRecords
WHERE RowNum = 1
UNION ALL
SELECT 
    'SQL Results (DISTINCT serialNo - UTC)' AS [Source],
    COUNT(DISTINCT serialNo) AS [TotalInteractions],
    COUNT(DISTINCT CASE WHEN isSuccess = 1 THEN serialNo END) AS [ResolutionAttempts],
    COUNT(DISTINCT CASE WHEN isSuccess != 1 THEN serialNo END) AS [NoResolutionAttempts]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate ASC) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(r.createDate AS DATE) = '2025-11-19'
) AS RankedRecords
WHERE RowNum = 1
UNION ALL
SELECT 
    'SQL Results (DISTINCT serialNo - CST)' AS [Source],
    COUNT(DISTINCT serialNo) AS [TotalInteractions],
    COUNT(DISTINCT CASE WHEN isSuccess = 1 THEN serialNo END) AS [ResolutionAttempts],
    COUNT(DISTINCT CASE WHEN isSuccess != 1 THEN serialNo END) AS [NoResolutionAttempts]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) ORDER BY r.createDate ASC) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-19'
) AS RankedRecords
WHERE RowNum = 1
UNION ALL
SELECT 
    'Excel (Expected)' AS [Source],
    412 AS [TotalInteractions],
    105 AS [ResolutionAttempts],
    307 AS [NoResolutionAttempts];

