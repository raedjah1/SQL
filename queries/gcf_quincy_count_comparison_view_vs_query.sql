-- ============================================================================
-- COUNT COMPARISON: View vs Query
-- ============================================================================
-- Simple comparison of total interactions per day from view vs query
-- ============================================================================

-- Count from View
SELECT 
    CAST(arl.createDate AS DATE) AS [Date],
    COUNT(*) AS [View_TotalInteractions]
FROM rpt.AgentRepairLog arl
WHERE arl.programID = 10053
    AND arl.agentName = 'quincy'
    AND CAST(arl.createDate AS DATE) >= '2025-11-08'
GROUP BY CAST(arl.createDate AS DATE)

UNION ALL

-- Count from Query (using the same base table with same filters as view)
SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    COUNT(*) AS [Query_TotalInteractions]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.debug = 0  -- Match view's filter
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
GROUP BY CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)

ORDER BY [Date] DESC;

-- Side-by-side comparison
SELECT 
    COALESCE(v.[Date], q.[Date]) AS [Date],
    v.[View_TotalInteractions],
    q.[Query_TotalInteractions],
    v.[View_TotalInteractions] - q.[Query_TotalInteractions] AS [Difference],
    -- Show percentage difference
    CASE 
        WHEN q.[Query_TotalInteractions] > 0 
        THEN CAST(ROUND(100.0 * (v.[View_TotalInteractions] - q.[Query_TotalInteractions]) / q.[Query_TotalInteractions], 2) AS DECIMAL(5,2))
        ELSE NULL
    END AS [PercentDifference]
FROM (
    SELECT 
        CAST(arl.createDate AS DATE) AS [Date],
        COUNT(*) AS [View_TotalInteractions]
    FROM rpt.AgentRepairLog arl
    WHERE arl.programID = 10053
        AND arl.agentName = 'quincy'
        AND CAST(arl.createDate AS DATE) >= '2025-11-08'
    GROUP BY CAST(arl.createDate AS DATE)
) v
FULL OUTER JOIN (
    SELECT 
        CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
        COUNT(*) AS [Query_TotalInteractions]
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND r.debug = 0  -- Match view's filter
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
    GROUP BY CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
) q ON v.[Date] = q.[Date]
ORDER BY [Date] DESC;

-- Diagnostic: Show records where time zone conversion causes different dates
SELECT 
    CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) AS [View_Date_EST],
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Query_Date_CST],
    COUNT(*) AS [RecordCount],
    MIN(r.createDate) AS [EarliestCreateDate],
    MAX(r.createDate) AS [LatestCreateDate]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.debug = 0
    AND CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) >= '2025-11-08'
    AND CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE) != CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
GROUP BY 
    CAST(r.createDate AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS DATE),
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
ORDER BY [View_Date_EST] DESC, [Query_Date_CST] DESC;

