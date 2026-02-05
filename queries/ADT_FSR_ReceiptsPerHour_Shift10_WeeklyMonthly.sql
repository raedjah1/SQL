-- ADT FSR Receipts Per Hour (Fixed Shift Hours)
-- Requirement: assume each operator works 10 hours/day (e.g., 07:00–16:00), regardless of transaction timestamps.
-- Exclude any WorkDate with 2 or fewer operators (Operators <= 2).
-- Output: Weekly + Monthly rollups starting Sept 2025.
--
-- Edit these two values if the shift changes:
DECLARE @ShiftHours DECIMAL(5,2) = 10.0;
DECLARE @MinOperatorsPerDay INT = 3; -- excludes days with <= 2 operators

WITH Categorized AS (
    -- Matches ADTOperatordashboard.sql category logic (Mail Innovations takes precedence)
    SELECT
        pt.CreateDate,
        u.Username AS Operator,
        CASE
            WHEN u_mi.ID IS NOT NULL THEN 'Mail Innovations'
            WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
            WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
            WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
            ELSE 'FSR'
        END AS CustomerCategory
    FROM Plus.pls.PartTransaction pt
    JOIN Plus.pls.[User] u ON u.ID = pt.UserID
    JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    -- Mail Innovations identification (copied from ADTOperatordashboard.sql)
    LEFT JOIN Plus.pls.ROHeader rh_mi ON rh_mi.CustomerReference = pt.CustomerReference
        AND rh_mi.ProgramID = 10068
    OUTER APPLY (
        SELECT TOP 1 crst_mi.UserID
        FROM Plus.pls.CarrierResult crst_mi
        WHERE crst_mi.OrderHeaderID = rh_mi.ID
          AND crst_mi.ProgramID = rh_mi.ProgramID
          AND crst_mi.OrderType = 'RO'
        ORDER BY crst_mi.ID DESC
    ) crst_mi
    LEFT JOIN Plus.pls.[User] u_mi ON u_mi.ID = crst_mi.UserID
        AND u_mi.Username LIKE '%@reconext.com'
    WHERE u.Username IS NOT NULL
      AND pt.ProgramID = 10068
      AND cpt.Description = 'RO-RECEIVE'
      AND CAST(pt.CreateDate AS DATE) >= '2025-09-01'
),
Daily AS (
    -- Daily totals for FSR only
    SELECT
        CAST(CreateDate AS DATE) AS WorkDate,
        YEAR(CAST(CreateDate AS DATE)) AS YearNum,
        MONTH(CAST(CreateDate AS DATE)) AS MonthNum,
        DATEPART(WEEK, CAST(CreateDate AS DATE)) AS WeekNum,
        DATEPART(YEAR, CAST(CreateDate AS DATE)) AS YearForWeek,
        CustomerCategory,
        COUNT(*) AS TotalReceipts,
        COUNT(DISTINCT Operator) AS NumberOfOperators
    FROM Categorized
    WHERE CustomerCategory = 'FSR'
    GROUP BY
        CAST(CreateDate AS DATE),
        YEAR(CAST(CreateDate AS DATE)),
        MONTH(CAST(CreateDate AS DATE)),
        DATEPART(WEEK, CAST(CreateDate AS DATE)),
        DATEPART(YEAR, CAST(CreateDate AS DATE)),
        CustomerCategory
),
DailyFiltered AS (
    -- Apply the "exclude days with <= 2 operators" rule
    SELECT
        *,
        CAST(NumberOfOperators * @ShiftHours AS DECIMAL(10,2)) AS OperatorHours
    FROM Daily
    WHERE NumberOfOperators >= @MinOperatorsPerDay
),
Weekly AS (
    SELECT
        'WEEKLY' AS PeriodType,
        CAST(YearNum AS VARCHAR) + '-' + RIGHT('0' + CAST(MonthNum AS VARCHAR), 2) AS [Month],
        CAST(YearForWeek AS VARCHAR) + '-W' + RIGHT('0' + CAST(WeekNum AS VARCHAR), 2) AS [Week],
        CustomerCategory,
        COUNT(*) AS DaysIncluded,
        SUM(NumberOfOperators) AS OperatorDays, -- sum of daily operators (operator-days)
        SUM(TotalReceipts) AS TotalReceipts,
        SUM(OperatorHours) AS TotalOperatorHours,
        CAST(SUM(TotalReceipts) * 1.0 / NULLIF(SUM(OperatorHours), 0) AS DECIMAL(10,2)) AS ReceiptsPerOperatorHour
    FROM DailyFiltered
    GROUP BY YearNum, MonthNum, YearForWeek, WeekNum, CustomerCategory
    HAVING COUNT(*) = 5 -- only keep full 5-day weeks (after the Operators >= @MinOperatorsPerDay filter)
),
Monthly AS (
    SELECT
        'MONTHLY' AS PeriodType,
        CAST(YearNum AS VARCHAR) + '-' + RIGHT('0' + CAST(MonthNum AS VARCHAR), 2) AS [Month],
        'ALL' AS [Week],
        CustomerCategory,
        COUNT(*) AS DaysIncluded,
        SUM(NumberOfOperators) AS OperatorDays, -- sum of daily operators (operator-days)
        SUM(TotalReceipts) AS TotalReceipts,
        SUM(OperatorHours) AS TotalOperatorHours,
        CAST(SUM(TotalReceipts) * 1.0 / NULLIF(SUM(OperatorHours), 0) AS DECIMAL(10,2)) AS ReceiptsPerOperatorHour
    FROM DailyFiltered
    GROUP BY YearNum, MonthNum, CustomerCategory
),
AllPeriods AS (
    SELECT * FROM Weekly
    UNION ALL
    SELECT * FROM Monthly
)
SELECT
    PeriodType,
    [Month],
    [Week],
    CustomerCategory,
    DaysIncluded,
    OperatorDays,
    TotalReceipts,
    TotalOperatorHours,
    ReceiptsPerOperatorHour,
    -- Cumulative trend (within each PeriodType) since Sept 2025
    SUM(TotalReceipts) OVER (
        PARTITION BY PeriodType, CustomerCategory
        ORDER BY [Month], [Week]
        ROWS UNBOUNDED PRECEDING
    ) AS CumulativeTotalReceipts,
    SUM(TotalOperatorHours) OVER (
        PARTITION BY PeriodType, CustomerCategory
        ORDER BY [Month], [Week]
        ROWS UNBOUNDED PRECEDING
    ) AS CumulativeTotalOperatorHours,
    CAST(
        SUM(TotalReceipts) OVER (
            PARTITION BY PeriodType, CustomerCategory
            ORDER BY [Month], [Week]
            ROWS UNBOUNDED PRECEDING
        ) * 1.0 / NULLIF(
            SUM(TotalOperatorHours) OVER (
                PARTITION BY PeriodType, CustomerCategory
                ORDER BY [Month], [Week]
                ROWS UNBOUNDED PRECEDING
            ), 0
        )
        AS DECIMAL(10,2)
    ) AS CumulativeReceiptsPerOperatorHour
FROM AllPeriods
ORDER BY PeriodType, [Month], [Week];


