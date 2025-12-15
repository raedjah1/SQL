-- ============================================================================
-- CHECK: Are there any cases that should be "GCF Request Trigger Failure"?
-- ============================================================================
-- This checks if there are resolution attempts (isSuccess = 1) where we can't
-- determine the error status (no initialError or initialErrorDate)

SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    COUNT(*) AS [TotalResolutionAttempts],
    -- Cases with no initialError
    SUM(CASE 
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 1 
        ELSE 0 
    END) AS [NoInitialError],
    -- Cases with no initialErrorDate
    SUM(CASE 
        WHEN r.initialErrorDate IS NULL THEN 1 
        ELSE 0 
    END) AS [NoInitialErrorDate],
    -- Cases with both missing
    SUM(CASE 
        WHEN (r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0) 
             AND r.initialErrorDate IS NULL THEN 1 
        ELSE 0 
    END) AS [BothMissing],
    -- Sample serial numbers for inspection
    STRING_AGG(
        CASE 
            WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 
                 OR r.initialErrorDate IS NULL 
            THEN r.serialNo 
            ELSE NULL 
        END, 
        ', '
    ) WITHIN GROUP (ORDER BY r.serialNo) AS [SampleSerialNumbers]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 1  -- Only resolution attempts
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
GROUP BY CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
ORDER BY [Date] DESC;

-- Also check individual cases to see what's happening
SELECT TOP 20
    r.serialNo,
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    r.createDate,
    r.isSuccess,
    r.initialErrorDate,
    CASE 
        WHEN r.initialError IS NULL THEN 'NULL'
        WHEN LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'EMPTY'
        WHEN LEN(r.initialError) > 100 THEN LEFT(r.initialError, 100) + '...'
        ELSE r.initialError
    END AS [InitialErrorPreview],
    CASE 
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Missing InitialError'
        WHEN r.initialErrorDate IS NULL THEN 'Missing InitialErrorDate'
        ELSE 'Has Both'
    END AS [Status]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 1
    AND (
        r.initialError IS NULL 
        OR LEN(LTRIM(RTRIM(r.initialError))) = 0 
        OR r.initialErrorDate IS NULL
    )
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
ORDER BY r.createDate DESC;

