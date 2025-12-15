-- ============================================================================
-- DEBUG: Check actual log patterns for 11/18/2025
-- ============================================================================
-- This will help identify pattern matching issues
-- ============================================================================

-- Check for "Unit does not have PartSerial entry" patterns
SELECT 
    'PartSerial Entry Patterns' AS [CheckType],
    r.serialNo,
    r.isSuccess,
    r.log,
    CASE 
        WHEN r.log LIKE '%PartSerial%' THEN 'Contains PartSerial'
        ELSE 'No PartSerial'
    END AS [HasPartSerial]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-18'
    AND r.log LIKE '%PartSerial%'
ORDER BY r.serialNo;

-- Check for "Unable to locate" patterns
SELECT 
    'Unable to Locate Patterns' AS [CheckType],
    r.serialNo,
    r.isSuccess,
    r.log,
    CASE 
        WHEN r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' THEN 'Pattern 1: No pre-existing family'
        WHEN r.log LIKE '%"error":"No required MODs found from pre-existing family%' THEN 'Pattern 2: No required MODs'
        WHEN r.log LIKE '%reference%' OR r.log LIKE '%pre-existing%' THEN 'Contains reference/pre-existing'
        ELSE 'Other'
    END AS [PatternMatch]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-18'
    AND (r.log LIKE '%reference%' OR r.log LIKE '%pre-existing%')
ORDER BY r.serialNo;

-- Check what's in "Other/Unknown"
SELECT 
    'Other/Unknown Category' AS [CheckType],
    r.serialNo,
    r.isSuccess,
    r.log
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-18'
    AND r.isSuccess = 0
    AND NOT (
        r.log LIKE '%"error":"Attempted too many times to fix."%'
        OR r.log LIKE '%"error":"Could not find any GCF errors in B2B outbound data%'
        OR r.log LIKE '%"error":"No inventory parts were found%'
        OR r.log LIKE '%"error":"No repair parts found."%'
        OR r.log LIKE '%"error":"Unit does not have%PartSerial%'
        OR r.log LIKE '%"error":"Unknown error, not trained to resolve."%'
        OR r.log LIKE '%"error":"Unit is not in correct ReImage%'
        OR r.log LIKE '%"error":"Unit is not in the correct route%'
        OR r.log LIKE '%"error":"Could not find route/location code%'
        OR r.log LIKE '%"error":"No route found for pre-existing family%'
        OR r.log LIKE '%"error":"No pre-existing family found in FG%'
        OR r.log LIKE '%"error":"No required MODs found from pre-existing family%'
        OR r.log LIKE '%"error":"Unit does not have a work order created yet."%'
    )
ORDER BY r.serialNo;

