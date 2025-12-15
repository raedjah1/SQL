-- ============================================================================
-- DEBUG: All "Unable to locate a unit for reference" records for 11/18/2025
-- ============================================================================
-- This will show all 22 records to identify which 15 should be "Unit does not have PartSerial entry"
-- ============================================================================

-- Summary: Distinct error messages with counts
SELECT 
    -- Show the actual error message extracted (cleaned up - remove serial numbers from "No required MODs" messages)
    CASE 
        WHEN r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' 
        THEN 'No pre-existing family found in FG to use as a reference.'
        WHEN r.log LIKE '%"error":"No required MODs found from pre-existing family%' 
        THEN 'No required MODs found from pre-existing family'
        ELSE 'Other'
    END AS [ExtractedErrorMessage],
    COUNT(*) AS [Count],
    -- Check if any contain PartSerial
    SUM(CASE WHEN r.log LIKE '%PartSerial%' THEN 1 ELSE 0 END) AS [ContainsPartSerial]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-18'
    AND r.isSuccess = 0
    -- Match the "Unable to locate" patterns
    AND (
        r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' 
        OR r.log LIKE '%"error":"No required MODs found from pre-existing family%'
    )
GROUP BY 
    CASE 
        WHEN r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' 
        THEN 'No pre-existing family found in FG to use as a reference.'
        WHEN r.log LIKE '%"error":"No required MODs found from pre-existing family%' 
        THEN 'No required MODs found from pre-existing family'
        ELSE 'Other'
    END
ORDER BY [Count] DESC;

-- Detail: All records (for reference)
SELECT 
    r.serialNo,
    r.createDate,
    r.isSuccess,
    r.log,
    -- Check if it matches PartSerial pattern
    CASE 
        WHEN r.log LIKE '%PartSerial%' THEN 'YES - Contains PartSerial'
        ELSE 'NO - No PartSerial'
    END AS [HasPartSerialInLog],
    -- Show the actual error message extracted
    CASE 
        WHEN r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' 
        THEN 'No pre-existing family found in FG to use as a reference.'
        WHEN r.log LIKE '%"error":"No required MODs found from pre-existing family%' 
        THEN 'No required MODs found from pre-existing family'
        ELSE 'Other'
    END AS [ExtractedErrorMessage]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-18'
    AND r.isSuccess = 0
    -- Match the "Unable to locate" patterns
    AND (
        r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' 
        OR r.log LIKE '%"error":"No required MODs found from pre-existing family%'
    )
ORDER BY r.serialNo, r.createDate;

