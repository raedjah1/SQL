-- ============================================================================
-- GCF QUINCY DASHBOARD - By Date and Category
-- Matching Excel Formula Logic EXACTLY
-- ============================================================================
-- Excel Formula Logic:
-- IF(isSuccess=1, "Quincy Resolution Attempt", 
--    IFS(SEARCH("text", log), "Category", ...))
-- Uses FIRST record per serial number per date
-- ============================================================================

SELECT 
    Date AS [Quincy Resolution Date Attempt],
    Category AS [Log Translation],
    SUM(CASE WHEN Category = 'Quincy Resolution Attempt' THEN 1 ELSE 0 END) AS [Fix Attempt],
    SUM(CASE WHEN Category != 'Quincy Resolution Attempt' THEN 1 ELSE 0 END) AS [No Fix Attempt],
    COUNT(*) AS [Grand Total]
FROM (
    SELECT 
        CAST(createDate AS DATE) AS Date,
        serialNo,
        -- Get FIRST record per serial number per date (Excel uses first record)
        ROW_NUMBER() OVER (PARTITION BY serialNo, CAST(createDate AS DATE) ORDER BY createDate ASC) AS RowNum,
        -- Excel formula logic: IF(isSuccess=1) THEN "Quincy Resolution Attempt" ELSE search log field
        CASE 
            -- First check: If isSuccess = 1, it's a resolution attempt
            WHEN isSuccess = 1 THEN 'Quincy Resolution Attempt'
            
            -- Otherwise, search log field for text patterns (order matters - first match wins)
            WHEN log LIKE '%Not trained to resolve%' THEN 'Not yet trained to resolve'
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
            
            -- If none match, it's undefined
            ELSE 'Error not yet defined'
        END AS Category
    FROM ClarityWarehouse.agentlogs.repair
    WHERE programID = 10053
        AND agentName = 'quincy'
        AND CAST(createDate AS DATE) >= '2025-11-08'
        AND CAST(createDate AS DATE) <= '2025-11-19'
) AS RankedRecords
WHERE RowNum = 1  -- Only take FIRST record per serial number per date
GROUP BY Date, Category
ORDER BY [Quincy Resolution Date Attempt] DESC, [Log Translation];

-- ============================================================================
-- TESTING QUERIES
-- ============================================================================

-- Test 1: Check for 11/19/2025 specifically
SELECT 
    Category AS [Log Translation],
    COUNT(*) AS [Grand Total],
    SUM(CASE WHEN Category = 'Quincy Resolution Attempt' THEN 1 ELSE 0 END) AS [Fix Attempt],
    SUM(CASE WHEN Category != 'Quincy Resolution Attempt' THEN 1 ELSE 0 END) AS [No Fix Attempt]
FROM (
    SELECT 
        serialNo,
        ROW_NUMBER() OVER (PARTITION BY serialNo ORDER BY createDate ASC) AS RowNum,
        CASE 
            WHEN isSuccess = 1 THEN 'Quincy Resolution Attempt'
            WHEN log LIKE '%Not trained to resolve%' THEN 'Not yet trained to resolve'
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
        END AS Category
    FROM ClarityWarehouse.agentlogs.repair
    WHERE programID = 10053
        AND agentName = 'quincy'
        AND CAST(createDate AS DATE) = '2025-11-19'
) AS RankedRecords
WHERE RowNum = 1
GROUP BY Category
ORDER BY [Log Translation];

-- Test 2: Check if using LAST record instead of FIRST makes a difference
SELECT 
    'Using LAST record' AS TestType,
    Category AS [Log Translation],
    COUNT(*) AS [Grand Total]
FROM (
    SELECT 
        serialNo,
        ROW_NUMBER() OVER (PARTITION BY serialNo ORDER BY createDate DESC) AS RowNum,  -- DESC = LAST record
        CASE 
            WHEN isSuccess = 1 THEN 'Quincy Resolution Attempt'
            WHEN log LIKE '%Not trained to resolve%' THEN 'Not yet trained to resolve'
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
        END AS Category
    FROM ClarityWarehouse.agentlogs.repair
    WHERE programID = 10053
        AND agentName = 'quincy'
        AND CAST(createDate AS DATE) = '2025-11-19'
) AS RankedRecords
WHERE RowNum = 1
GROUP BY Category
ORDER BY [Log Translation];

-- Test 3: Check serial numbers with multiple records to see which one Excel might use
SELECT TOP 20
    serialNo,
    COUNT(*) AS RecordCount,
    MIN(createDate) AS FirstRecord,
    MAX(createDate) AS LastRecord,
    -- Category of first record
    (SELECT TOP 1 
        CASE 
            WHEN isSuccess = 1 THEN 'Quincy Resolution Attempt'
            WHEN log LIKE '%Not trained to resolve%' THEN 'Not yet trained to resolve'
            ELSE 'Other'
        END
     FROM ClarityWarehouse.agentlogs.repair r2
     WHERE r2.serialNo = r.serialNo
       AND CAST(r2.createDate AS DATE) = '2025-11-19'
     ORDER BY r2.createDate ASC
    ) AS FirstRecordCategory,
    -- Category of last record
    (SELECT TOP 1 
        CASE 
            WHEN isSuccess = 1 THEN 'Quincy Resolution Attempt'
            WHEN log LIKE '%Not trained to resolve%' THEN 'Not yet trained to resolve'
            ELSE 'Other'
        END
     FROM ClarityWarehouse.agentlogs.repair r2
     WHERE r2.serialNo = r.serialNo
       AND CAST(r2.createDate AS DATE) = '2025-11-19'
     ORDER BY r2.createDate DESC
    ) AS LastRecordCategory
FROM ClarityWarehouse.agentlogs.repair r
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) = '2025-11-19'
GROUP BY serialNo
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC;

