-- ADT Hourly Total Output with Trend (Using Actual Tables)
SELECT 
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATEPART(HOUR, pt.CreateDate) as WorkHour,
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT u.Username) as ActiveOperators,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    
    -- Add trend comparison
    LAG(COUNT(*)) OVER (PARTITION BY DATEPART(HOUR, pt.CreateDate) ORDER BY CAST(pt.CreateDate as DATE)) as PreviousDayTransactions,
    
    -- Calculate trend arrow
    CASE 
        WHEN LAG(COUNT(*)) OVER (PARTITION BY DATEPART(HOUR, pt.CreateDate) ORDER BY CAST(pt.CreateDate as DATE)) IS NULL THEN '='
        WHEN COUNT(*) > LAG(COUNT(*)) OVER (PARTITION BY DATEPART(HOUR, pt.CreateDate) ORDER BY CAST(pt.CreateDate as DATE)) THEN '↑'
        WHEN COUNT(*) < LAG(COUNT(*)) OVER (PARTITION BY DATEPART(HOUR, pt.CreateDate) ORDER BY CAST(pt.CreateDate as DATE)) THEN '↓'
        ELSE '='
    END as TrendArrow,
    
    -- Combined number with trend
    CAST(COUNT(*) AS VARCHAR) + ' ' + 
    CASE 
        WHEN LAG(COUNT(*)) OVER (PARTITION BY DATEPART(HOUR, pt.CreateDate) ORDER BY CAST(pt.CreateDate as DATE)) IS NULL THEN '='
        WHEN COUNT(*) > LAG(COUNT(*)) OVER (PARTITION BY DATEPART(HOUR, pt.CreateDate) ORDER BY CAST(pt.CreateDate as DATE)) THEN '↑'
        WHEN COUNT(*) < LAG(COUNT(*)) OVER (PARTITION BY DATEPART(HOUR, pt.CreateDate) ORDER BY CAST(pt.CreateDate as DATE)) THEN '↓'
        ELSE '='
    END as NumberWithTrend,
    
    -- Average per operator for the hour
    CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT u.Username), 0) AS DECIMAL(10,2)) as AvgTransactionsPerOperator,
    -- Overall hourly KPI status
    CASE
        WHEN COUNT(*) >= (COUNT(DISTINCT u.Username) * 100) THEN 'GREEN - Excellent (125% of target)'
        WHEN COUNT(*) >= (COUNT(DISTINCT u.Username) * 80) THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= (COUNT(DISTINCT u.Username) * 64) THEN 'YELLOW - Acceptable (80% of target)'
        WHEN COUNT(*) >= (COUNT(DISTINCT u.Username) * 40) THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as HourlyKPI_Status,
    -- Performance percentage for the hour
    CAST(COUNT(*) * 100.0 / (COUNT(DISTINCT u.Username) * 80) AS DECIMAL(5,1)) as HourlyPerformancePercentage
FROM Plus.pls.PartTransaction pt
JOIN Plus.pls.[User] u ON u.ID = pt.UserID
JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE pt.CreateDate >= DATEADD(day, -7, GETDATE())
  AND u.Username IS NOT NULL
  AND pt.ProgramID = 10068
  AND cpt.Description IN (
    'WO-REPAIR', 'RO-CLOSE', 'SO-CSCLOSE', 'WO-SCRAP', 'WO-HARVEST',
    'WO-RTS', 'WO-CANCEL', 'WO-REOPEN', 'RO-CANCEL', 'RO-CTSRECEIVE',
    'WH-ADDPART', 'WH-REMOVEPART', 'WH-DISCREPANCYRECEIVE'
  )
GROUP BY CAST(pt.CreateDate as DATE), DATEPART(HOUR, pt.CreateDate)

