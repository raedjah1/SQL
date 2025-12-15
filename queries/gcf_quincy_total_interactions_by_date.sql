-- ============================================================================
-- Total Quincy Interactions by Date - Testing Different Methods
-- ============================================================================

-- Method 1: COUNT(DISTINCT serialNo) - One per serial number per date
SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    COUNT(DISTINCT r.serialNo) AS [Method1_DistinctSerialNo],
    'One per serial number per date' AS [Description]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
GROUP BY CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)

UNION ALL

-- Method 2: COUNT(*) - All records (multiple attempts per serial number)
SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    COUNT(*) AS [Method2_AllRecords],
    'All records (multiple attempts counted)' AS [Description]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
GROUP BY CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)

UNION ALL

-- Method 3: COUNT(DISTINCT serialNo) but using UTC date (not CST)
SELECT 
    CAST(r.createDate AS DATE) AS [Date],
    COUNT(DISTINCT r.serialNo) AS [Method3_UTC_DistinctSerialNo],
    'One per serial number per UTC date' AS [Description]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(r.createDate AS DATE) >= '2025-11-08'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
GROUP BY CAST(r.createDate AS DATE)

ORDER BY [Date] DESC, [Description];

-- ============================================================================
-- Side-by-Side Comparison: All Methods vs Excel (Clean Version)
-- ============================================================================
WITH CST_Data AS (
    SELECT 
        CAST(DATEADD(HOUR, -6, createDate) AS DATE) AS [CSTDate],
        COUNT(DISTINCT serialNo) AS [CST_DistinctSerialNo],
        COUNT(*) AS [CST_AllRecords]
    FROM ClarityWarehouse.agentlogs.repair
    WHERE programID = 10053
        AND agentName = 'quincy'
        AND CAST(DATEADD(HOUR, -6, createDate) AS DATE) >= '2025-11-08'
        AND CAST(DATEADD(HOUR, -6, createDate) AS DATE) <= '2025-11-19'
    GROUP BY CAST(DATEADD(HOUR, -6, createDate) AS DATE)
),
UTC_Data AS (
    SELECT 
        CAST(createDate AS DATE) AS [UTCDate],
        COUNT(DISTINCT serialNo) AS [UTC_DistinctSerialNo],
        COUNT(*) AS [UTC_AllRecords]
    FROM ClarityWarehouse.agentlogs.repair
    WHERE programID = 10053
        AND agentName = 'quincy'
        AND CAST(createDate AS DATE) >= '2025-11-08'
        AND CAST(createDate AS DATE) <= '2025-11-19'
    GROUP BY CAST(createDate AS DATE)
)
SELECT 
    c.CSTDate AS [Date],
    c.CST_DistinctSerialNo,
    c.CST_AllRecords,
    u.UTC_DistinctSerialNo,
    u.UTC_AllRecords
FROM CST_Data c
FULL OUTER JOIN UTC_Data u ON c.CSTDate = u.UTCDate
ORDER BY [Date] DESC;

