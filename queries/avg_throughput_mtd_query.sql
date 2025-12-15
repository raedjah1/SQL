-- ============================================
-- AVG THROUGHPUT MTD - SQL QUERY
-- ============================================
-- This query calculates average throughput month-to-date
-- Throughput = Count of rows where StatusID IN (15, 17, 38)
-- Average = Throughput Count / Business Days Month-to-Date
-- ============================================
-- This query can be used as a DirectQuery in Power BI
-- or to verify the calculation
-- ============================================

WITH DateSeries AS (
    -- Generate dates from first day of month to today
    SELECT DATEADD(DAY, 1 - DAY(GETDATE()), CAST(GETDATE() AS DATE)) AS BusinessDate
    UNION ALL
    SELECT DATEADD(DAY, 1, BusinessDate)
    FROM DateSeries
    WHERE BusinessDate < CAST(GETDATE() AS DATE)
),
BusinessDaysMTD AS (
    -- Calculate business days month-to-date (excluding weekends)
    SELECT 
        COUNT(*) AS BusinessDaysCount
    FROM DateSeries
    WHERE DATEPART(WEEKDAY, BusinessDate) NOT IN (1, 7)  -- Exclude Sunday (1) and Saturday (7)
),
ThroughputCountMTD AS (
    -- Count throughput rows (StatusID IN 15, 17, 38) for current month
    SELECT 
        COUNT(*) AS ThroughputCount
    FROM (
        -- Plus data
        SELECT 
            WOH.StatusID,
            WOH.CreateDate
        FROM [Plus].[pls].WOHeader WOH
        WHERE WOH.ProgramID = 10053
          AND WOH.StatusID IN (15, 17, 38)
          AND YEAR(WOH.CreateDate) = YEAR(GETDATE())
          AND MONTH(WOH.CreateDate) = MONTH(GETDATE())
        
        UNION ALL
        
        -- ClarityLakehouse data
        SELECT 
            CASE
                WHEN so.on_hold_flag = 'TRUE' THEN 28
                WHEN so.quotation_result IN ('1', '2') THEN 17
                WHEN so.quotation_result = '3' THEN 15
                ELSE 19
            END AS StatusID,
            so.date_entered AS CreateDate
        FROM ClarityLakehouse.ifsapp.shop_ord_tab so
        INNER JOIN ClarityLakehouse.ifsapp.site_tab s ON so.contract = s.contract AND so.region = s.region
        INNER JOIN ClarityLakehouse.ifsapp.work_order_shop_ord_tab wo
            ON so.order_no = wo.order_no AND so.region = wo.region
        WHERE (SELECT TOP 1 ID
               FROM ClarityLakehouse.rpt.program
               WHERE ERPID = s.contract
                 AND ERP = CONCAT('IFS-', s.region)) = 10053
          AND YEAR(so.date_entered) = YEAR(GETDATE())
          AND MONTH(so.date_entered) = MONTH(GETDATE())
          AND (
              so.on_hold_flag = 'FALSE' AND so.quotation_result IN ('1', '2')  -- StatusID = 17
              OR so.quotation_result = '3'  -- StatusID = 15
              OR (so.on_hold_flag = 'FALSE' AND so.quotation_result NOT IN ('1', '2', '3'))  -- StatusID = 19 (but we want 15, 17, 38)
          )
    ) AS CombinedData
    WHERE StatusID IN (15, 17, 38)
)
SELECT 
    bd.BusinessDaysCount,
    tc.ThroughputCount,
    CASE 
        WHEN bd.BusinessDaysCount > 0 
        THEN CAST(tc.ThroughputCount AS FLOAT) / bd.BusinessDaysCount
        ELSE 0
    END AS AvgThroughputMTD,
    YEAR(GETDATE()) AS Year,
    MONTH(GETDATE()) AS Month,
    CAST(GETDATE() AS DATE) AS CurrentDate
FROM BusinessDaysMTD bd
CROSS JOIN ThroughputCountMTD tc
OPTION (MAXRECURSION 31);  -- Allow up to 31 days in a month

-- ============================================
-- SIMPLIFIED VERSION: Direct from rpt.WOHeader view
-- ============================================
-- If you have a view called rpt.WOHeader that contains the UNION ALL query,
-- use this simpler version:

WITH DateSeries AS (
    -- Generate dates from first day of month to today
    SELECT DATEADD(DAY, 1 - DAY(GETDATE()), CAST(GETDATE() AS DATE)) AS BusinessDate
    UNION ALL
    SELECT DATEADD(DAY, 1, BusinessDate)
    FROM DateSeries
    WHERE BusinessDate < CAST(GETDATE() AS DATE)
),
BusinessDaysMTD AS (
    SELECT 
        COUNT(*) AS BusinessDaysCount
    FROM DateSeries
    WHERE DATEPART(WEEKDAY, BusinessDate) NOT IN (1, 7)  -- Exclude Sunday (1) and Saturday (7)
)
SELECT 
    bd.BusinessDaysCount,
    COUNT(*) AS ThroughputCount,
    CASE 
        WHEN bd.BusinessDaysCount > 0 
        THEN CAST(COUNT(*) AS FLOAT) / bd.BusinessDaysCount
        ELSE 0
    END AS AvgThroughputMTD,
    YEAR(GETDATE()) AS Year,
    MONTH(GETDATE()) AS Month,
    CAST(GETDATE() AS DATE) AS CurrentDate
FROM rpt.WOHeader wo
CROSS JOIN BusinessDaysMTD bd
WHERE wo.ProgramID = 10053
  AND wo.StatusID IN (15, 17, 38)
  AND YEAR(wo.CreateDate) = YEAR(GETDATE())
  AND MONTH(wo.CreateDate) = MONTH(GETDATE())
GROUP BY bd.BusinessDaysCount;

-- ============================================
-- DAILY BREAKDOWN VERSION (for detailed analysis)
-- ============================================

SELECT 
    CAST(wo.CreateDate AS DATE) AS Date,
    DATENAME(WEEKDAY, wo.CreateDate) AS DayOfWeek,
    CASE WHEN DATEPART(WEEKDAY, wo.CreateDate) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS DayType,
    COUNT(*) AS ThroughputCount,
    SUM(COUNT(*)) OVER (PARTITION BY YEAR(wo.CreateDate), MONTH(wo.CreateDate)) AS TotalThroughputMTD,
    COUNT(CASE WHEN DATEPART(WEEKDAY, wo.CreateDate) NOT IN (1, 7) THEN 1 END) 
        OVER (PARTITION BY YEAR(wo.CreateDate), MONTH(wo.CreateDate)) AS BusinessDaysMTD,
    CASE 
        WHEN COUNT(CASE WHEN DATEPART(WEEKDAY, wo.CreateDate) NOT IN (1, 7) THEN 1 END) 
             OVER (PARTITION BY YEAR(wo.CreateDate), MONTH(wo.CreateDate)) > 0
        THEN CAST(SUM(COUNT(*)) OVER (PARTITION BY YEAR(wo.CreateDate), MONTH(wo.CreateDate)) AS FLOAT) / 
             COUNT(CASE WHEN DATEPART(WEEKDAY, wo.CreateDate) NOT IN (1, 7) THEN 1 END) 
             OVER (PARTITION BY YEAR(wo.CreateDate), MONTH(wo.CreateDate))
        ELSE 0
    END AS AvgThroughputMTD
FROM rpt.WOHeader wo
WHERE wo.ProgramID = 10053
  AND wo.StatusID IN (15, 17, 38)
  AND YEAR(wo.CreateDate) = YEAR(GETDATE())
  AND MONTH(wo.CreateDate) = MONTH(GETDATE())
GROUP BY 
    CAST(wo.CreateDate AS DATE),
    DATENAME(WEEKDAY, wo.CreateDate),
    DATEPART(WEEKDAY, wo.CreateDate),
    YEAR(wo.CreateDate),
    MONTH(wo.CreateDate)
ORDER BY Date;

