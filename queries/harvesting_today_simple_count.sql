-- ============================================
-- HARVESTING TODAY - SIMPLE TRANSACTION COUNT
-- ============================================
-- Shows simple transaction counts for harvesting operations today

SELECT 
  Username,
  DATEPART(HOUR, CreateDate) as Hour,
  CAST(CreateDate AS DATE) as Date,
  PartTransaction,
  Location,
  ToLocation,
  Source,
  COUNT(*) as TransactionCount,
  COUNT(DISTINCT PartNo) as UniqueParts,
  COUNT(DISTINCT SerialNo) as UniqueSerials,
  MIN(CreateDate) as FirstTransaction,
  MAX(CreateDate) as LastTransaction
FROM pls.vPartTransaction 
WHERE ProgramID = '10053' 
  AND Username IS NOT NULL
  AND CAST(DATEADD(hour, -6, CreateDate) AS DATE) = CAST(DATEADD(hour, -6, GETDATE()) AS DATE)  -- TODAY ONLY
  AND (
    -- HARVESTING CONDITIONS
    (PartTransaction = 'WH-ADDPART' AND UPPER(Source) LIKE '%HARVESTING%')
    OR 
    (PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'CRA.ARB.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%')
    OR
    -- ADD MISSING HARVESTING TRANSACTIONS
    (PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'CRA.ARB.%')
    OR
    (PartTransaction = 'WH-MOVEPART' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%')
  )
GROUP BY 
  Username, 
  DATEPART(HOUR, CreateDate), 
  CAST(CreateDate AS DATE),
  PartTransaction,
  Location,
  ToLocation,
  Source
ORDER BY Username, Hour, TransactionCount DESC;
