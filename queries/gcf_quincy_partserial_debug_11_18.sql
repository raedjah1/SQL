-- ============================================================================
-- DEBUG: Check for "Unit does not have PartSerial entry" patterns for 11/18/2025
-- ============================================================================
-- This will show all records that mention PartSerial to see what patterns exist
-- ============================================================================

SELECT 
    r.serialNo,
    r.createDate,
    r.isSuccess,
    r.log,
    -- Show the actual error message extracted
    CASE 
        WHEN r.log LIKE '%"error":"%' THEN 
            SUBSTRING(
                r.log,
                CHARINDEX('"error":"', r.log) + 9,
                CASE 
                    WHEN CHARINDEX('"', r.log, CHARINDEX('"error":"', r.log) + 9) > 0 
                    THEN CHARINDEX('"', r.log, CHARINDEX('"error":"', r.log) + 9) - CHARINDEX('"error":"', r.log) - 9
                    ELSE 100
                END
            )
        ELSE 'No error field found'
    END AS [ExtractedErrorMessage],
    -- Check which pattern it matches
    CASE 
        WHEN r.log LIKE '%"error":"Unit does not have a PartSerial entry."%' THEN 'Pattern 1: Unit does not have a PartSerial entry.'
        WHEN r.log LIKE '%"error":"Unit does not have PartSerial entry."%' THEN 'Pattern 2: Unit does not have PartSerial entry.'
        WHEN r.log LIKE '%PartSerial%' THEN 'Contains PartSerial but pattern not matched'
        ELSE 'Other'
    END AS [PatternMatch],
    -- Check current categorization
    CASE 
        WHEN r.isSuccess = 1 THEN 'Quincy Resolution Attempt'
        WHEN r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' 
             OR r.log LIKE '%"error":"No required MODs found from pre-existing family%' 
        THEN 'Currently: Unable to locate a unit for reference'
        ELSE 'Other category'
    END AS [CurrentCategory]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-18'
    AND r.log LIKE '%PartSerial%'
ORDER BY r.serialNo, r.createDate;

