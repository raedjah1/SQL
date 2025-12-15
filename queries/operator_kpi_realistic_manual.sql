-- ============================================
-- OPERATOR KPI ANALYSIS - REALISTIC MANUAL WORK ONLY
-- ============================================
-- Track operator performance for truly manual work transactions
-- Filtered for ADT program (ID: 10068) specifically
-- Engineering Target: 80 transactions/hour (600 per 7.5 hours)

-- ============================================
-- 1. OPERATOR HOURLY OUTPUT SUMMARY (REALISTIC MANUAL)
-- ============================================
-- Shows each operator's hourly transaction volume for manual work only
SELECT TOP 100
    pt.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATEPART(HOUR, pt.CreateDate) as WorkHour,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActiveMinutes,
    -- KPI Status based on 80 transactions/hour target
    CASE
        WHEN COUNT(*) >= 100 THEN 'GREEN - Excellent (125% of target)'
        WHEN COUNT(*) >= 80 THEN 'GREEN - Target Met'
        WHEN COUNT(*) >= 64 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN COUNT(*) >= 40 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    -- Performance percentage
    CAST(COUNT(*) * 100.0 / 80 AS DECIMAL(5,1)) as PerformancePercentage
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
  AND pt.ProgramID = 10068  -- ADT program specifically
  AND pt.PartTransaction IN (
    'WO-REPAIR',            -- Repair work (manual) - MOST COMMON
    'RO-CLOSE',             -- Closing repair orders (manual)
    'SO-CSCLOSE',           -- Closing sales orders (manual)
    'WO-SCRAP',             -- Scrapping work orders (manual)
    'WO-HARVEST',           -- Harvesting completed work (manual)
    'WO-RTS',               -- Return to stock (manual)
    'WO-CANCEL',            -- Canceling work orders (manual)
    'WO-REOPEN',            -- Reopening work orders (manual)
    'RO-CANCEL',            -- Canceling repair orders (manual)
    'RO-CTSRECEIVE',        -- CTS receiving (manual)
    'WH-ADDPART',           -- Adding parts to warehouse (manual)
    'WH-REMOVEPART',        -- Removing parts from warehouse (manual)
    'WH-DISCREPANCYRECEIVE' -- Receiving with discrepancies (manual)
  )
GROUP BY pt.Username, CAST(pt.CreateDate as DATE), DATEPART(HOUR, pt.CreateDate)
ORDER BY WorkDate DESC, WorkHour DESC, TransactionCount DESC;

-- ============================================
-- 2. DAILY OPERATOR PERFORMANCE WITH KPI STATUS (REALISTIC MANUAL)
-- ============================================
-- Shows daily performance with green/red status for manual work only
WITH DailyOperatorStats AS (
    SELECT 
        pt.Username as Operator,
        CAST(pt.CreateDate as DATE) as WorkDate,
        COUNT(*) as DailyTransactions,
        COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
        CAST(COUNT(*) as FLOAT) / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1, 0) as AvgTransactionsPerHour,
        DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)) + 1 as HoursWorked
    FROM pls.vPartTransaction pt
    WHERE pt.CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
      AND pt.Username IS NOT NULL
      AND pt.PartTransaction IN (
        'WO-REPAIR',            -- Repair work (manual) - MOST COMMON
        'RO-CLOSE',             -- Closing repair orders (manual)
        'SO-CSCLOSE',           -- Closing sales orders (manual)
        'WO-SCRAP',             -- Scrapping work orders (manual)
        'WO-HARVEST',           -- Harvesting completed work (manual)
        'WO-RTS',               -- Return to stock (manual)
        'WO-CANCEL',            -- Canceling work orders (manual)
        'WO-REOPEN',            -- Reopening work orders (manual)
        'RO-CANCEL',            -- Canceling repair orders (manual)
        'RO-CTSRECEIVE',        -- CTS receiving (manual)
        'WH-ADDPART',           -- Adding parts to warehouse (manual)
        'WH-REMOVEPART',        -- Removing parts from warehouse (manual)
        'WH-DISCREPANCYRECEIVE' -- Receiving with discrepancies (manual)
      )
      AND pt.ProgramID = 10068  -- ADT program specifically
    GROUP BY pt.Username, CAST(pt.CreateDate as DATE)
)
SELECT TOP 100
    Operator,
    WorkDate,
    DailyTransactions,
    UnitsProcessed,
    HoursWorked,
    CAST(AvgTransactionsPerHour AS DECIMAL(8,2)) as TransactionsPerHour,
    -- KPI Status Logic (Engineering Target: 80/hour = 600 per 7.5 hours)
    CASE 
        WHEN AvgTransactionsPerHour >= 100 THEN 'GREEN - Excellent (125% of target)'
        WHEN AvgTransactionsPerHour >= 80 THEN 'GREEN - Target Met'
        WHEN AvgTransactionsPerHour >= 64 THEN 'YELLOW - Acceptable (80% of target)'
        WHEN AvgTransactionsPerHour >= 40 THEN 'RED - Below Target (50% of target)'
        ELSE 'RED - Critical Performance'
    END as KPI_Status,
    -- Performance Rating (1-5 scale)
    CASE 
        WHEN AvgTransactionsPerHour >= 100 THEN 5  -- 125%+ of target
        WHEN AvgTransactionsPerHour >= 80 THEN 4   -- 100% of target
        WHEN AvgTransactionsPerHour >= 64 THEN 3   -- 80% of target
        WHEN AvgTransactionsPerHour >= 40 THEN 2   -- 50% of target
        ELSE 1                                     -- Below 50%
    END as PerformanceRating
FROM DailyOperatorStats
WHERE DailyTransactions > 0  -- Only include days with actual work
ORDER BY WorkDate DESC, AvgTransactionsPerHour DESC;

-- ============================================
-- 3. TRANSACTION TYPE BREAKDOWN (VERIFICATION)
-- ============================================
-- Verify we're getting realistic manual work transactions
SELECT TOP 100
    pt.PartTransaction,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    AVG(CAST(COUNT(*) as FLOAT)) OVER (PARTITION BY pt.PartTransaction) as AvgPerOperator,
    MIN(pt.CreateDate) as EarliestTransaction,
    MAX(pt.CreateDate) as LatestTransaction
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= CAST(GETDATE() as DATE)  -- Today only
  AND pt.Username IS NOT NULL
  AND pt.ProgramID = 10068  -- ADT program specifically
  AND pt.PartTransaction IN (
    'WO-REPAIR',            -- Repair work (manual) - MOST COMMON
    'RO-CLOSE',             -- Closing repair orders (manual)
    'SO-CSCLOSE',           -- Closing sales orders (manual)
    'WO-SCRAP',             -- Scrapping work orders (manual)
    'WO-HARVEST',           -- Harvesting completed work (manual)
    'WO-RTS',               -- Return to stock (manual)
    'WO-CANCEL',            -- Canceling work orders (manual)
    'WO-REOPEN',            -- Reopening work orders (manual)
    'RO-CANCEL',            -- Canceling repair orders (manual)
    'RO-CTSRECEIVE',        -- CTS receiving (manual)
    'WH-ADDPART',           -- Adding parts to warehouse (manual)
    'WH-REMOVEPART',        -- Removing parts from warehouse (manual)
    'WH-DISCREPANCYRECEIVE' -- Receiving with discrepancies (manual)
  )
GROUP BY pt.PartTransaction
ORDER BY TransactionCount DESC;

-- ============================================
-- 4. REALISTIC OPERATOR RANKING
-- ============================================
-- Ranks operators by manual work performance over last 7 days
SELECT TOP 100
    pt.Username as Operator,
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT CAST(pt.CreateDate as DATE)) as DaysActive,
    CAST(COUNT(*) as FLOAT) / COUNT(DISTINCT CAST(pt.CreateDate as DATE)) as AvgTransactionsPerDay,
    CAST(COUNT(*) as FLOAT) / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)), 0) as AvgTransactionsPerHour,
    -- Ranking
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) as VolumeRank,
    ROW_NUMBER() OVER (ORDER BY CAST(COUNT(*) as FLOAT) / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)), 0) DESC) as EfficiencyRank,
    -- Performance vs Target
    CASE 
        WHEN CAST(COUNT(*) as FLOAT) / NULLIF(DATEDIFF(HOUR, MIN(pt.CreateDate), MAX(pt.CreateDate)), 0) >= 80 
        THEN 'MEETS TARGET'
        ELSE 'BELOW TARGET'
    END as TargetStatus
FROM pls.vPartTransaction pt
WHERE pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
  AND pt.ProgramID = 10068  -- ADT program specifically
  AND pt.PartTransaction IN (
    'WO-REPAIR',            -- Repair work (manual) - MOST COMMON
    'RO-CLOSE',             -- Closing repair orders (manual)
    'SO-CSCLOSE',           -- Closing sales orders (manual)
    'WO-SCRAP',             -- Scrapping work orders (manual)
    'WO-HARVEST',           -- Harvesting completed work (manual)
    'WO-RTS',               -- Return to stock (manual)
    'WO-CANCEL',            -- Canceling work orders (manual)
    'WO-REOPEN',            -- Reopening work orders (manual)
    'RO-CANCEL',            -- Canceling repair orders (manual)
    'RO-CTSRECEIVE',        -- CTS receiving (manual)
    'WH-ADDPART',           -- Adding parts to warehouse (manual)
    'WH-REMOVEPART',        -- Removing parts from warehouse (manual)
    'WH-DISCREPANCYRECEIVE' -- Receiving with discrepancies (manual)
  )
GROUP BY pt.Username
HAVING COUNT(*) >= 5  -- Minimum activity threshold
ORDER BY AvgTransactionsPerHour DESC;
