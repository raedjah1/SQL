-- ============================================================================
-- Simple Query: Count Quincy Attempts per Serial Number per Date
-- ============================================================================
-- Use this to check how many attempts there were for a specific serial number

-- SIMPLE VERSION: Just count the rows
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    COUNT(*) AS [TotalAttempts]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    -- Filter by serial number (change this)
    AND r.serialNo = '27TG794'  -- <-- CHANGE THIS
    -- Filter by date range (optional)
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
GROUP BY r.serialNo, CAST(r.createDate AS DATE)
ORDER BY CAST(r.createDate AS DATE) DESC, r.serialNo;

-- DETAILED VERSION: With first/last times
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    COUNT(*) AS [TotalAttempts],
    MIN(r.createDate) AS [FirstAttemptTime],
    MAX(r.createDate) AS [LastAttemptTime]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    -- Filter by serial number (change this)
    AND r.serialNo = '27TG794'  -- <-- CHANGE THIS
    -- Filter by date range (optional)
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
GROUP BY r.serialNo, CAST(r.createDate AS DATE)
ORDER BY CAST(r.createDate AS DATE) DESC, r.serialNo;

-- ============================================================================
-- Alternative: Show ALL attempts with details (not just count)
-- ============================================================================
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate ASC) AS [AttemptNumber],
    r.createDate AS [AttemptTime],
    r.isSuccess,
    CASE 
        WHEN r.isSuccess = 1 THEN 'Success'
        ELSE 'Failed'
    END AS [Status],
    -- Show if initialError has XML or is plain text
    CASE 
        WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' THEN 'XML'
        WHEN r.initialError IS NOT NULL AND LEN(LTRIM(RTRIM(r.initialError))) > 0 THEN 'Plain Text'
        ELSE 'NULL'
    END AS [ErrorType],
    LEFT(r.initialError, 100) AS [InitialErrorPreview]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    -- Filter by serial number (change this)
    AND r.serialNo = '27TG794'  -- <-- CHANGE THIS
    -- Filter by date range (optional)
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
ORDER BY r.createDate ASC;

