-- DELL HOURLY METRICS VERIFICATION - ALL SPECIALIZATIONS
-- This query verifies hourly performance for all DELL specializations at once
-- Shows operators, their specializations, hourly performance, and KPI status

SELECT
    'DELL HOURLY METRICS VERIFICATION' as AnalysisType,
    pt.Username as Operator,
    pt.PartTransaction as Specialization,
    DATEPART(hour, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionsPerHour,
    
    -- Specialization-specific target rates
    CASE pt.PartTransaction
        WHEN 'WH-MOVEPART' THEN 80  -- Warehouse Operations
        WHEN 'WO-CONSUMECOMPONENTS' THEN 60  -- Manufacturing Operations
        WHEN 'WO-ISSUEPART' THEN 60  -- Manufacturing Operations
        WHEN 'SO-RESERVE' THEN 40  -- Sales Operations
        WHEN 'SO-SHIP' THEN 40  -- Sales Operations
        WHEN 'RO-RECEIVE' THEN 30  -- Repair Operations
        WHEN 'RO-CLOSE' THEN 30  -- Repair Operations
        ELSE 50  -- Default/Other operations
    END as TargetRate,
    
    -- Calculate performance percentage
    ROUND(COUNT(*) * 100.0 / 
        CASE pt.PartTransaction
            WHEN 'WH-MOVEPART' THEN 80
            WHEN 'WO-CONSUMECOMPONENTS' THEN 60
            WHEN 'WO-ISSUEPART' THEN 60
            WHEN 'SO-RESERVE' THEN 40
            WHEN 'SO-SHIP' THEN 40
            WHEN 'RO-RECEIVE' THEN 30
            WHEN 'RO-CLOSE' THEN 30
            ELSE 50
        END, 2) as PerformancePercentage,
    
    -- KPI Status based on performance percentage
    CASE 
        WHEN ROUND(COUNT(*) * 100.0 / 
            CASE pt.PartTransaction
                WHEN 'WH-MOVEPART' THEN 80
                WHEN 'WO-CONSUMECOMPONENTS' THEN 60
                WHEN 'WO-ISSUEPART' THEN 60
                WHEN 'SO-RESERVE' THEN 40
                WHEN 'SO-SHIP' THEN 40
                WHEN 'RO-RECEIVE' THEN 30
                WHEN 'RO-CLOSE' THEN 30
                ELSE 50
            END, 2) >= 100 THEN 'GREEN - Target Met'
        WHEN ROUND(COUNT(*) * 100.0 / 
            CASE pt.PartTransaction
                WHEN 'WH-MOVEPART' THEN 80
                WHEN 'WO-CONSUMECOMPONENTS' THEN 60
                WHEN 'WO-ISSUEPART' THEN 60
                WHEN 'SO-RESERVE' THEN 40
                WHEN 'SO-SHIP' THEN 40
                WHEN 'RO-RECEIVE' THEN 30
                WHEN 'RO-CLOSE' THEN 30
                ELSE 50
            END, 2) >= 80 THEN 'YELLOW - Acceptable (80% of target)'
        ELSE 'RED - Below Target'
    END as KPI_Status,
    
    -- Specialization category for grouping
    CASE pt.PartTransaction
        WHEN 'WH-MOVEPART' THEN 'WAREHOUSE OPERATIONS'
        WHEN 'WO-CONSUMECOMPONENTS' THEN 'MANUFACTURING OPERATIONS'
        WHEN 'WO-ISSUEPART' THEN 'MANUFACTURING OPERATIONS'
        WHEN 'SO-RESERVE' THEN 'SALES OPERATIONS'
        WHEN 'SO-SHIP' THEN 'SALES OPERATIONS'
        WHEN 'RO-RECEIVE' THEN 'REPAIR OPERATIONS'
        WHEN 'RO-CLOSE' THEN 'REPAIR OPERATIONS'
        ELSE 'OTHER OPERATIONS'
    END as SpecializationCategory,
    
    -- Date information
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATENAME(weekday, pt.CreateDate) as DayOfWeek

FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
  AND pt.PartTransaction IN (
      'WH-MOVEPART',           -- Warehouse Operations
      'WO-CONSUMECOMPONENTS',  -- Manufacturing Operations
      'WO-ISSUEPART',          -- Manufacturing Operations
      'SO-RESERVE',            -- Sales Operations
      'SO-SHIP',               -- Sales Operations
      'RO-RECEIVE',            -- Repair Operations
      'RO-CLOSE'               -- Repair Operations
  )
GROUP BY 
    pt.Username, 
    pt.PartTransaction, 
    DATEPART(hour, pt.CreateDate),
    CAST(pt.CreateDate as DATE),
    DATENAME(weekday, pt.CreateDate)
HAVING COUNT(*) > 0  -- Only show hours with activity
ORDER BY 
    SpecializationCategory,
    pt.Username,
    WorkDate,
    WorkHour;

-- SUMMARY QUERY - Show overall performance by specialization
SELECT
    'DELL SPECIALIZATION SUMMARY' as AnalysisType,
    SpecializationCategory,
    COUNT(DISTINCT Operator) as OperatorCount,
    COUNT(*) as TotalHourlyRecords,
    AVG(TransactionsPerHour) as AvgTransactionsPerHour,
    AVG(PerformancePercentage) as AvgPerformancePercentage,
    SUM(CASE WHEN KPI_Status LIKE 'GREEN%' THEN 1 ELSE 0 END) as GreenHours,
    SUM(CASE WHEN KPI_Status LIKE 'YELLOW%' THEN 1 ELSE 0 END) as YellowHours,
    SUM(CASE WHEN KPI_Status LIKE 'RED%' THEN 1 ELSE 0 END) as RedHours,
    ROUND(SUM(CASE WHEN KPI_Status LIKE 'GREEN%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as GreenPercentage
FROM (
    SELECT
        pt.Username as Operator,
        pt.PartTransaction as Specialization,
        DATEPART(hour, pt.CreateDate) as WorkHour,
        COUNT(*) as TransactionsPerHour,
        CASE pt.PartTransaction
            WHEN 'WH-MOVEPART' THEN 80
            WHEN 'WO-CONSUMECOMPONENTS' THEN 60
            WHEN 'WO-ISSUEPART' THEN 60
            WHEN 'SO-RESERVE' THEN 40
            WHEN 'SO-SHIP' THEN 40
            WHEN 'RO-RECEIVE' THEN 30
            WHEN 'RO-CLOSE' THEN 30
            ELSE 50
        END as TargetRate,
        ROUND(COUNT(*) * 100.0 / 
            CASE pt.PartTransaction
                WHEN 'WH-MOVEPART' THEN 80
                WHEN 'WO-CONSUMECOMPONENTS' THEN 60
                WHEN 'WO-ISSUEPART' THEN 60
                WHEN 'SO-RESERVE' THEN 40
                WHEN 'SO-SHIP' THEN 40
                WHEN 'RO-RECEIVE' THEN 30
                WHEN 'RO-CLOSE' THEN 30
                ELSE 50
            END, 2) as PerformancePercentage,
        CASE 
            WHEN ROUND(COUNT(*) * 100.0 / 
                CASE pt.PartTransaction
                    WHEN 'WH-MOVEPART' THEN 80
                    WHEN 'WO-CONSUMECOMPONENTS' THEN 60
                    WHEN 'WO-ISSUEPART' THEN 60
                    WHEN 'SO-RESERVE' THEN 40
                    WHEN 'SO-SHIP' THEN 40
                    WHEN 'RO-RECEIVE' THEN 30
                    WHEN 'RO-CLOSE' THEN 30
                    ELSE 50
                END, 2) >= 100 THEN 'GREEN - Target Met'
            WHEN ROUND(COUNT(*) * 100.0 / 
                CASE pt.PartTransaction
                    WHEN 'WH-MOVEPART' THEN 80
                    WHEN 'WO-CONSUMECOMPONENTS' THEN 60
                    WHEN 'WO-ISSUEPART' THEN 60
                    WHEN 'SO-RESERVE' THEN 40
                    WHEN 'SO-SHIP' THEN 40
                    WHEN 'RO-RECEIVE' THEN 30
                    WHEN 'RO-CLOSE' THEN 30
                    ELSE 50
                END, 2) >= 80 THEN 'YELLOW - Acceptable (80% of target)'
            ELSE 'RED - Below Target'
        END as KPI_Status,
        CASE pt.PartTransaction
            WHEN 'WH-MOVEPART' THEN 'WAREHOUSE OPERATIONS'
            WHEN 'WO-CONSUMECOMPONENTS' THEN 'MANUFACTURING OPERATIONS'
            WHEN 'WO-ISSUEPART' THEN 'MANUFACTURING OPERATIONS'
            WHEN 'SO-RESERVE' THEN 'SALES OPERATIONS'
            WHEN 'SO-SHIP' THEN 'SALES OPERATIONS'
            WHEN 'RO-RECEIVE' THEN 'REPAIR OPERATIONS'
            WHEN 'RO-CLOSE' THEN 'REPAIR OPERATIONS'
            ELSE 'OTHER OPERATIONS'
        END as SpecializationCategory
    FROM pls.vPartTransaction pt
    WHERE pt.ProgramID = 10053
      AND pt.CreateDate >= DATEADD(day, -7, GETDATE())
      AND pt.Username IS NOT NULL
      AND pt.PartTransaction IN (
          'WH-MOVEPART', 'WO-CONSUMECOMPONENTS', 'WO-ISSUEPART',
          'SO-RESERVE', 'SO-SHIP', 'RO-RECEIVE', 'RO-CLOSE'
      )
    GROUP BY 
        pt.Username, 
        pt.PartTransaction, 
        DATEPART(hour, pt.CreateDate)
    HAVING COUNT(*) > 0
) AS HourlyData
GROUP BY SpecializationCategory
ORDER BY AvgPerformancePercentage DESC;
