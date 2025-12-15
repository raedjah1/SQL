-- ============================================================================
-- SIMPLE INVESTIGATIVE QUERIES - See Actual Data
-- ============================================================================

-- 1. Total Quincy Interactions per date (match Excel date range)
SELECT 
    CAST(createDate AS DATE) AS Date,
    COUNT(*) AS TotalQuincyInteractions
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) >= '2025-11-08'
    AND CAST(createDate AS DATE) <= '2025-11-19'
GROUP BY CAST(createDate AS DATE)
ORDER BY Date DESC;

-- 2. What's in "Other/Unknown" - see actual log content
SELECT TOP 50
    CAST(createDate AS DATE) AS Date,
    serialNo,
    isSuccess,
    LEFT(log, 300) AS LogContent
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) = '2025-11-19'
    AND log NOT LIKE '%modsToRepair%'
    AND log NOT LIKE '%Could not find any GCF errors%'
    AND log NOT LIKE '%No inventory parts were found%'
    AND log NOT LIKE '%No repair parts found%'
    AND log NOT LIKE '%Unit does not have PartSerial entry%'
    AND log NOT LIKE '%Not yet trained to resolve%'
    AND log NOT LIKE '%Routing Errors%'
    AND log NOT LIKE '%Attempted too many times%'
    AND log NOT LIKE '%Unable to locate a unit for reference%'
    AND log NOT LIKE '%Unit does not have a work order created yet%'
ORDER BY createDate DESC;

-- 3. Count Resolution Attempts - what exactly counts as an attempt?
-- Hypothesis: isSuccess=1 OR (isSuccess=0 AND has modsToRepair) OR has error message
SELECT 
    CAST(createDate AS DATE) AS Date,
    COUNT(*) AS TotalInteractions,
    -- Count resolution attempts (different hypotheses)
    COUNT(CASE WHEN isSuccess = 1 THEN 1 END) AS IsSuccess_True,
    COUNT(CASE WHEN isSuccess = 0 AND log LIKE '%modsToRepair%' THEN 1 END) AS IsSuccess_False_ButHasMods,
    COUNT(CASE WHEN log LIKE '%modsToRepair%' THEN 1 END) AS HasModsToRepair_Any,
    COUNT(CASE WHEN log LIKE '%"error"%' THEN 1 END) AS HasErrorInLog,
    -- Combined: attempt = has modsToRepair OR has error (but not empty)
    COUNT(CASE WHEN (log LIKE '%modsToRepair%' OR log LIKE '%"error"%') 
               AND log IS NOT NULL AND LEN(LTRIM(RTRIM(log))) > 0 THEN 1 END) AS Attempt_HasModsOrError
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) >= '2025-11-13'
    AND CAST(createDate AS DATE) <= '2025-11-19'
GROUP BY CAST(createDate AS DATE)
ORDER BY Date DESC;

-- 4. Get all distinct error messages from "Other/Unknown" to find patterns
SELECT DISTINCT
    CASE 
        WHEN log LIKE '%"error":"%' THEN 
            SUBSTRING(log, CHARINDEX('"error":"', log) + 9, 
                     CHARINDEX('"', log, CHARINDEX('"error":"', log) + 9) - CHARINDEX('"error":"', log) - 9)
        ELSE 'No error field'
    END AS ErrorMessage,
    COUNT(*) AS Count
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) = '2025-11-19'
    AND log NOT LIKE '%modsToRepair%'
    AND log NOT LIKE '%Could not find any GCF errors%'
    AND log NOT LIKE '%No inventory parts were found%'
    AND log NOT LIKE '%No repair parts found%'
    AND log NOT LIKE '%Unit does not have PartSerial entry%'
    AND log NOT LIKE '%Not yet trained to resolve%'
    AND log NOT LIKE '%Routing Errors%'
    AND log NOT LIKE '%Attempted too many times%'
    AND log NOT LIKE '%Unable to locate a unit for reference%'
    AND log NOT LIKE '%Unit does not have a work order created yet%'
GROUP BY CASE 
        WHEN log LIKE '%"error":"%' THEN 
            SUBSTRING(log, CHARINDEX('"error":"', log) + 9, 
                     CHARINDEX('"', log, CHARINDEX('"error":"', log) + 9) - CHARINDEX('"error":"', log) - 9)
        ELSE 'No error field'
    END
ORDER BY Count DESC;

