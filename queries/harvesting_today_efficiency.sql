-- ============================================
-- HARVESTING TODAY - EFFICIENCY QUERY STRUCTURE
-- ============================================
-- Shows harvesting operations with efficiency metrics (like your main query)

SELECT 
  Username,
  Hour,
  Date,
  ProcessCategory,
  TransactionCount,
  MinutesWorked,
  TransactionsPerHour,
  Green_Threshold,
  Yellow_Threshold,
  PerformanceStatus,
  EfficiencyPercentage
FROM (
  SELECT 
    cm.Username,
    cm.Hour,
    cm.Date,
    cm.ProcessCategory,
    COUNT(*) as TransactionCount,
    MIN(cm.CreateDate) as FirstTransaction,
    MAX(cm.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) as MinutesWorked,
    CASE 
      WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
      THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
      ELSE COUNT(*) 
    END as TransactionsPerHour,
    pt.Green_Threshold,
    pt.Yellow_Threshold,
    CASE 
      WHEN (CASE 
              WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
              THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
              ELSE COUNT(*) 
            END) >= pt.Green_Threshold THEN 'Green'
      WHEN (CASE 
              WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
              THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
              ELSE COUNT(*) 
            END) >= pt.Yellow_Threshold THEN 'Yellow'
      ELSE 'Red'
    END as PerformanceStatus,
    CASE 
      WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) = 0 THEN 0
      ELSE ROUND(((CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60) / pt.Green_Threshold) * 100, 1)
    END as EfficiencyPercentage
  FROM (
    SELECT 
      Username,
      CreateDate,
      DATEPART(HOUR, CreateDate) as Hour,
      CAST(CreateDate AS DATE) as Date,
      -- HARVESTING CATEGORIZATION
      CASE
        WHEN PartTransaction = 'WH-ADDPART' AND UPPER(Source) LIKE '%HARVESTING%' THEN 'Harvesting'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'CRA.ARB.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Harvest Parts'
        ELSE 'TBD'
      END AS ProcessCategory
    FROM pls.vPartTransaction 
    WHERE ProgramID = '10053' 
      AND Username IS NOT NULL
      AND CAST(DATEADD(hour, -6, CreateDate) AS DATE) = CAST(DATEADD(hour, -6, GETDATE()) AS DATE)  -- TODAY ONLY
  ) cm
  LEFT JOIN (
    SELECT 
      cm.ProcessCategory,
      CASE 
        WHEN cm.ProcessCategory = 'Harvesting' THEN 40  -- Harvest
        WHEN cm.ProcessCategory LIKE '%Put Away%' THEN 35  -- Put Away
        ELSE 25
      END as Green_Threshold,
      CASE 
        WHEN cm.ProcessCategory = 'Harvesting' THEN 20  -- Harvest
        WHEN cm.ProcessCategory LIKE '%Put Away%' THEN 17  -- Put Away
        ELSE 12
      END as Yellow_Threshold
    FROM (SELECT DISTINCT ProcessCategory FROM (
      SELECT 
        CASE
          WHEN PartTransaction = 'WH-ADDPART' AND UPPER(Source) LIKE '%HARVESTING%' THEN 'Harvesting'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'CRA.ARB.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Harvest Parts'
          ELSE 'TBD'
        END AS ProcessCategory
      FROM pls.vPartTransaction WHERE ProgramID = '10053'
    ) x WHERE ProcessCategory != 'TBD'
    ) cm
  ) pt ON cm.ProcessCategory = pt.ProcessCategory
  WHERE cm.ProcessCategory != 'TBD'
  GROUP BY cm.Username, cm.Hour, cm.Date, cm.ProcessCategory, pt.Green_Threshold, pt.Yellow_Threshold
) HarvestingEfficiency
ORDER BY Username, Hour;
