-- ADT Operator Receipts Average Per Hour - Monthly and Weekly
-- From September 2025 onwards
-- Based on ADTOperatordashboard.sql pattern
-- Uses ACTUAL HOURS WORKED (counts distinct date+hour per operator), not transaction time span
-- Customer Category is editable (see WHERE clause filter)

WITH PeriodData AS (
    SELECT 
        -- Month column (format: YYYY-MM)
        CAST(YEAR(CAST(pt.CreateDate AS DATE)) AS VARCHAR) + '-' + 
        RIGHT('0' + CAST(MONTH(CAST(pt.CreateDate AS DATE)) AS VARCHAR), 2) AS Month,
        
        -- Week column (format: YYYY-WW)
        CAST(DATEPART(YEAR, CAST(pt.CreateDate AS DATE)) AS VARCHAR) + '-W' + 
        RIGHT('0' + CAST(DATEPART(WEEK, CAST(pt.CreateDate AS DATE)) AS VARCHAR), 2) AS Week,
        
        -- Customer Category (matches ADTOperatordashboard.sql logic)
        CASE
            WHEN u_mi.ID IS NOT NULL THEN 'Mail Innovations'
            WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
            WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
            WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
            ELSE 'FSR'
        END as CustomerCategory,
        
        -- Total Receipts (TransactionCount)
        COUNT(*) as TotalReceipts,
        
        -- Number of Operators
        COUNT(DISTINCT u.Username) as NumberOfOperators,
        
        -- ACTUAL HOURS WORKED: Count distinct (date, hour) combinations per operator, then sum
        -- This gives total operator-hours (e.g., if operator works 7-16 = 10 hours, counts 10)
        SUM(
            (SELECT COUNT(DISTINCT CAST(CAST(pt2.CreateDate AS DATE) AS VARCHAR) + '-' + CAST(DATEPART(HOUR, pt2.CreateDate) AS VARCHAR))
             FROM Plus.pls.PartTransaction pt2
             WHERE pt2.UserID = pt.UserID
               AND YEAR(CAST(pt2.CreateDate AS DATE)) = YEAR(CAST(pt.CreateDate AS DATE))
               AND MONTH(CAST(pt2.CreateDate AS DATE)) = MONTH(CAST(pt.CreateDate AS DATE))
               AND DATEPART(WEEK, pt2.CreateDate) = DATEPART(WEEK, pt.CreateDate)
               AND DATEPART(YEAR, pt2.CreateDate) = DATEPART(YEAR, pt.CreateDate)
               AND pt2.ProgramID = 10068
               AND EXISTS (
                   SELECT 1 FROM Plus.pls.CodePartTransaction cpt2 
                   WHERE cpt2.ID = pt2.PartTransactionID 
                   AND cpt2.Description = 'RO-RECEIVE'
               )
            )
        ) / COUNT(DISTINCT u.Username) as TotalHoursWorked,
        
        -- For sorting and cumulative calculations
        YEAR(CAST(pt.CreateDate AS DATE)) AS YearNum,
        MONTH(CAST(pt.CreateDate AS DATE)) AS MonthNum,
        DATEPART(WEEK, CAST(pt.CreateDate AS DATE)) AS WeekNum,
        DATEPART(YEAR, CAST(pt.CreateDate AS DATE)) AS YearForWeek
        
    FROM Plus.pls.PartTransaction pt
    JOIN Plus.pls.[User] u ON u.ID = pt.UserID
    JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    -- Mail Innovations logic (matches ADTOperatordashboard.sql exactly)
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
      AND pt.ProgramID = 10068  -- ADT program
      AND cpt.Description = 'RO-RECEIVE'
      AND CAST(pt.CreateDate AS DATE) >= '2025-09-01'
      -- ============================================
      -- EDITABLE CUSTOMER CATEGORY FILTER
      -- Uncomment ONE of the lines below to filter by category:
      -- ============================================
      
      -- For Mail Innovations only:
      -- AND u_mi.ID IS NOT NULL
      
      -- For ECR only:
      -- AND pt.CustomerReference LIKE 'EX%' AND u_mi.ID IS NULL
      
      -- For FSR only:
      -- AND pt.CustomerReference NOT LIKE 'EX%' 
      -- AND pt.CustomerReference NOT LIKE 'SP%' 
      -- AND pt.CustomerReference IS NOT NULL
      -- AND u_mi.ID IS NULL
      
      -- For SP only:
      -- AND pt.CustomerReference LIKE 'SP%' AND u_mi.ID IS NULL
      
      -- For "No Customer Reference" only:
      -- AND pt.CustomerReference IS NULL AND u_mi.ID IS NULL
      
      -- Default: All categories (no filter applied)
      
    GROUP BY 
        YEAR(CAST(pt.CreateDate AS DATE)),
        MONTH(CAST(pt.CreateDate AS DATE)),
        DATEPART(WEEK, CAST(pt.CreateDate AS DATE)),
        DATEPART(YEAR, CAST(pt.CreateDate AS DATE)),
        CASE
            WHEN u_mi.ID IS NOT NULL THEN 'Mail Innovations'
            WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
            WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
            WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
            ELSE 'FSR'
        END
),
OperatorHoursCalc AS (
    -- Calculate actual operator-hours: count distinct (date, hour) per operator, then sum
    SELECT 
        YearNum,
        MonthNum,
        WeekNum,
        YearForWeek,
        CustomerCategory,
        -- Sum of distinct hours worked across all operators
        SUM(HoursPerOperator) as TotalOperatorHours
    FROM (
        SELECT 
            YEAR(CAST(pt.CreateDate AS DATE)) AS YearNum,
            MONTH(CAST(pt.CreateDate AS DATE)) AS MonthNum,
            DATEPART(WEEK, CAST(pt.CreateDate AS DATE)) AS WeekNum,
            DATEPART(YEAR, CAST(pt.CreateDate AS DATE)) AS YearForWeek,
            CASE
                WHEN u_mi.ID IS NOT NULL THEN 'Mail Innovations'
                WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
                WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
                WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
                ELSE 'FSR'
            END as CustomerCategory,
            u.Username,
            -- Count distinct hours worked per operator (e.g., 7-16 = 10 hours)
            COUNT(DISTINCT CAST(CAST(pt.CreateDate AS DATE) AS VARCHAR) + '-' + CAST(DATEPART(HOUR, pt.CreateDate) AS VARCHAR)) as HoursPerOperator
        FROM Plus.pls.PartTransaction pt
        JOIN Plus.pls.[User] u ON u.ID = pt.UserID
        JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
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
        GROUP BY 
            YEAR(CAST(pt.CreateDate AS DATE)),
            MONTH(CAST(pt.CreateDate AS DATE)),
            DATEPART(WEEK, CAST(pt.CreateDate AS DATE)),
            DATEPART(YEAR, CAST(pt.CreateDate AS DATE)),
            CASE
                WHEN u_mi.ID IS NOT NULL THEN 'Mail Innovations'
                WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
                WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
                WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
                ELSE 'FSR'
            END,
            u.Username
    ) op
    GROUP BY YearNum, MonthNum, WeekNum, YearForWeek, CustomerCategory
)
SELECT
    pd.Month,
    pd.Week,
    pd.CustomerCategory,
    pd.TotalReceipts,
    pd.NumberOfOperators,
    ohc.TotalOperatorHours,
    
    -- Period Average Receipts Per Hour (Overall - total receipts / total operator-hours)
    CAST(
        pd.TotalReceipts * 1.0 / NULLIF(ohc.TotalOperatorHours, 0)
        AS DECIMAL(10,2)
    ) AS AvgReceiptsPerHour_Overall,
    
    -- Period Average Receipts Per Hour Per Operator
    -- Formula: Total Receipts / Total Operator-Hours
    -- Example: 100 receipts, 1 operator worked 10 hours = 100/10 = 10 receipts/hour/operator
    -- Same as Overall when using actual hours worked
    CAST(
        pd.TotalReceipts * 1.0 / NULLIF(ohc.TotalOperatorHours, 0)
        AS DECIMAL(10,2)
    ) AS AvgReceiptsPerHour_PerOperator,
    
    -- CUMULATIVE: Total Receipts from Sept 2025 to this period
    SUM(pd.TotalReceipts) OVER (
        PARTITION BY pd.CustomerCategory 
        ORDER BY pd.YearNum, pd.MonthNum, pd.WeekNum 
        ROWS UNBOUNDED PRECEDING
    ) AS CumulativeTotalReceipts,
    
    -- CUMULATIVE: Total Operator-Hours from Sept 2025 to this period
    SUM(ohc.TotalOperatorHours) OVER (
        PARTITION BY pd.CustomerCategory 
        ORDER BY pd.YearNum, pd.MonthNum, pd.WeekNum 
        ROWS UNBOUNDED PRECEDING
    ) AS CumulativeOperatorHours,
    
    -- CUMULATIVE: Average Receipts Per Hour (Overall) from Sept 2025 to this period
    CAST(
        SUM(pd.TotalReceipts) OVER (
            PARTITION BY pd.CustomerCategory 
            ORDER BY pd.YearNum, pd.MonthNum, pd.WeekNum 
            ROWS UNBOUNDED PRECEDING
        ) * 1.0 / NULLIF(
            SUM(ohc.TotalOperatorHours) OVER (
                PARTITION BY pd.CustomerCategory 
                ORDER BY pd.YearNum, pd.MonthNum, pd.WeekNum 
                ROWS UNBOUNDED PRECEDING
            ), 0
        )
        AS DECIMAL(10,2)
    ) AS CumulativeAvgReceiptsPerHour_Overall,
    
    -- CUMULATIVE: Average Receipts Per Hour Per Operator from Sept 2025 to this period
    -- This shows the per-operator efficiency trend (key metric showing improvement)
    CAST(
        SUM(pd.TotalReceipts) OVER (
            PARTITION BY pd.CustomerCategory 
            ORDER BY pd.YearNum, pd.MonthNum, pd.WeekNum 
            ROWS UNBOUNDED PRECEDING
        ) * 1.0 / NULLIF(
            SUM(ohc.TotalOperatorHours) OVER (
                PARTITION BY pd.CustomerCategory 
                ORDER BY pd.YearNum, pd.MonthNum, pd.WeekNum 
                ROWS UNBOUNDED PRECEDING
            ), 0
        )
        AS DECIMAL(10,2)
    ) AS CumulativeAvgReceiptsPerHour_PerOperator
    
FROM PeriodData pd
JOIN OperatorHoursCalc ohc ON 
    pd.YearNum = ohc.YearNum
    AND pd.MonthNum = ohc.MonthNum
    AND pd.WeekNum = ohc.WeekNum
    AND pd.YearForWeek = ohc.YearForWeek
    AND pd.CustomerCategory = ohc.CustomerCategory
ORDER BY 
    pd.YearNum,
    pd.MonthNum,
    pd.WeekNum,
    pd.CustomerCategory;
