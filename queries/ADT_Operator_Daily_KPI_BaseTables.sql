-- ADT Operator Daily KPI Report (Using Base Tables)
-- Converted from vPartTransaction view to base tables
SELECT 
    u.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    COUNT(*) as DailyTransactions,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) AS DECIMAL(10,2)) as AvgTransactionsPerHour,
    -- KPI Status for daily performance
    CASE
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) AS DECIMAL(10,2)) >= 100 THEN 'GREEN - Excellent (125% of target)'
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) AS DECIMAL(10,2)) >= 80 THEN 'GREEN - Target Met'
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) AS DECIMAL(10,2)) >= 64 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) AS DECIMAL(10,2)) >= 40 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as DailyKPI_Status
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
INNER JOIN Plus.pls.[User] u ON u.ID = pt.UserID
WHERE pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND u.Username IS NOT NULL
  AND pt.ProgramID = 10068  -- ADT program specifically
  AND cpt.Description = 'RO-RECEIVE'
GROUP BY u.Username, CAST(pt.CreateDate as DATE)
HAVING DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) > 0;

