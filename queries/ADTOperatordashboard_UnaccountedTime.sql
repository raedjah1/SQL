-- Separate query for Unaccounted Time with Rankings
-- Join to ADTOperatordashboard on: Operator, WorkDate, WorkHour, CustomerCategory
SELECT 
    Operator,
    WorkDate,
    WorkHour,
    CustomerCategory,
    TransactionCount,
    HourlyTarget,
    ActualVsTarget,
    FirstTransaction,
    LastTransaction,
    UnaccountedMinutes,
    UnaccountedTimeFlag,
    HasSignificantUnaccountedTime,
    RankByUnaccountedTime,
    -- Total unaccounted time for this operator across all hours/dates/categories
    TotalUnaccountedMinutesPerOperator,
    -- Overall rank by total unaccounted time per operator (sums across all hours/dates/categories)
    RANK() OVER (
        ORDER BY TotalUnaccountedMinutesPerOperator DESC
    ) as OverallRankByOperator
FROM (
    SELECT 
        Operator,
        WorkDate,
        WorkHour,
        CustomerCategory,
        TransactionCount,
        HourlyTarget,
        TransactionCount - HourlyTarget as ActualVsTarget,
        FirstTransaction,
        LastTransaction,
        UnaccountedMinutes,
        CASE
            WHEN UnaccountedMinutes > 30 THEN 'HIGH - >30 min'
            WHEN UnaccountedMinutes > 15 THEN 'MEDIUM - >15 min'
            WHEN UnaccountedMinutes > 5 THEN 'LOW - >5 min'
            ELSE 'NORMAL - ≤5 min'
        END as UnaccountedTimeFlag,
        CASE
            WHEN UnaccountedMinutes > 15 THEN 1
            ELSE 0
        END as HasSignificantUnaccountedTime,
        RANK() OVER (
            PARTITION BY WorkDate, WorkHour, CustomerCategory 
            ORDER BY UnaccountedMinutes DESC
        ) as RankByUnaccountedTime,
        -- Total unaccounted time for this operator across all hours/dates/categories
        SUM(UnaccountedMinutes) OVER (PARTITION BY Operator) as TotalUnaccountedMinutesPerOperator
    FROM (
    SELECT 
        pt.Username as Operator,
        CAST(pt.CreateDate as DATE) as WorkDate,
        DATEPART(HOUR, pt.CreateDate) as WorkHour,
        CASE
            WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
            WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
            WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
            ELSE 'FSR'
        END as CustomerCategory,
        
        -- Calculate hourly target for expected minutes per transaction
        CASE
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, MIN(pt.CreateDate)) = 12 THEN 125
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, MIN(pt.CreateDate)) = 9 THEN 195
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, MIN(pt.CreateDate)) = 14 THEN 195
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' THEN 250
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'SP' THEN 60
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, MIN(pt.CreateDate)) = 12 THEN 19
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, MIN(pt.CreateDate)) = 9 THEN 29
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, MIN(pt.CreateDate)) = 14 THEN 29
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' THEN 38
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, MIN(pt.CreateDate)) = 12 THEN 15
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, MIN(pt.CreateDate)) = 9 THEN 22
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, MIN(pt.CreateDate)) = 14 THEN 22
            ELSE 30
        END as HourlyTarget,
        
        COUNT(*) as TransactionCount,
        MIN(pt.CreateDate) as FirstTransaction,
        MAX(pt.CreateDate) as LastTransaction,
        
        -- Calculate unaccounted time
        CAST(
            -- Start of hour gap (from hour start to first transaction)
            ISNULL(DATEDIFF(MINUTE, 
                CAST(DATETIMEFROMPARTS(YEAR(CAST(MIN(pt.CreateDate) as DATE)), MONTH(CAST(MIN(pt.CreateDate) as DATE)), DAY(CAST(MIN(pt.CreateDate) as DATE)), DATEPART(HOUR, MIN(pt.CreateDate)), 0, 0, 0) AS DATETIME2),
                MIN(pt.CreateDate)
            ), 0)
            +
            -- End of hour gap (from last transaction to hour end)
            ISNULL(DATEDIFF(MINUTE, 
                MAX(pt.CreateDate),
                CAST(DATETIMEFROMPARTS(YEAR(CAST(MAX(pt.CreateDate) as DATE)), MONTH(CAST(MAX(pt.CreateDate) as DATE)), DAY(CAST(MAX(pt.CreateDate) as DATE)), DATEPART(HOUR, MAX(pt.CreateDate)), 59, 59, 0) AS DATETIME2)
            ), 0)
            +
            -- Between-transaction gaps (excess time beyond expected)
            ISNULL(SUM(
                CASE 
                    WHEN gap_minutes > expected_minutes 
                    THEN gap_minutes - expected_minutes 
                    ELSE 0 
                END
            ), 0)
        AS DECIMAL(10,2)) as UnaccountedMinutes
        
    FROM (
        SELECT 
            pt_inner.*,
            u_inner.Username,
            DATEDIFF(MINUTE, 
                LAG(pt_inner.CreateDate) OVER (
                    PARTITION BY u_inner.Username, CAST(pt_inner.CreateDate as DATE), DATEPART(HOUR, pt_inner.CreateDate),
                        CASE
                            WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR'
                            WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP'
                            WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference'
                            ELSE 'FSR'
                        END
                    ORDER BY pt_inner.CreateDate
                ),
                pt_inner.CreateDate
            ) as gap_minutes,
            -- Expected minutes per transaction (60 minutes / hourly target)
            60.0 / NULLIF(
                CASE
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt_inner.CreateDate) = 12 THEN 125
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt_inner.CreateDate) = 9 THEN 195
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt_inner.CreateDate) = 14 THEN 195
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' THEN 250
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'SP' THEN 60
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt_inner.CreateDate) = 12 THEN 19
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt_inner.CreateDate) = 9 THEN 29
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt_inner.CreateDate) = 14 THEN 29
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' THEN 38
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt_inner.CreateDate) = 12 THEN 15
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt_inner.CreateDate) = 9 THEN 22
                    WHEN (CASE WHEN pt_inner.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt_inner.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt_inner.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt_inner.CreateDate) = 14 THEN 22
                    ELSE 30
                END, 0
            ) as expected_minutes
        FROM Plus.pls.PartTransaction pt_inner
        JOIN Plus.pls.[User] u_inner ON u_inner.ID = pt_inner.UserID
        JOIN Plus.pls.CodePartTransaction cpt_inner ON cpt_inner.ID = pt_inner.PartTransactionID
        WHERE u_inner.Username IS NOT NULL
          AND pt_inner.ProgramID = 10068
          AND cpt_inner.Description = 'RO-RECEIVE'
    ) pt
    GROUP BY pt.Username, CAST(pt.CreateDate as DATE), DATEPART(HOUR, pt.CreateDate),
        CASE
            WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
            WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
            WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
            ELSE 'FSR'
        END,
        CASE
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 125
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 195
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 195
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' THEN 250
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'SP' THEN 60
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 19
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 29
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 29
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' THEN 38
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 15
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 22
            WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 22
            ELSE 30
        END
    ) unaccounted
) ranked
ORDER BY OverallRankByOperator, WorkDate DESC, WorkHour, UnaccountedMinutes DESC
