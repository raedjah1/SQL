-- ============================================
-- FIND MISSING TESTING OPERATIONS
-- ============================================
-- Check for gTest, WO-TEST, FICORE operations

-- ============================================
-- 1. CHECK vWOHeader FOR TESTING WORKSTATIONS
-- ============================================
SELECT DISTINCT
    'vWOHeader' as TableName,
    WorkstationDescription,
    COUNT(*) as RecordCount
FROM pls.vWOHeader
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    UPPER(WorkstationDescription) LIKE '%GTEST%' OR
    UPPER(WorkstationDescription) LIKE '%TEST%' OR
    UPPER(WorkstationDescription) LIKE '%FICORE%'
  )
GROUP BY WorkstationDescription
ORDER BY RecordCount DESC;

-- ============================================
-- 2. CHECK vPartTransaction FOR TESTING TRANSACTIONS
-- ============================================
SELECT DISTINCT
    'vPartTransaction' as TableName,
    PartTransaction,
    Source,
    COUNT(*) as RecordCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    UPPER(PartTransaction) LIKE '%TEST%' OR
    UPPER(PartTransaction) LIKE '%FICORE%' OR
    UPPER(Source) LIKE '%TEST%' OR
    UPPER(Source) LIKE '%FICORE%'
  )
GROUP BY PartTransaction, Source
ORDER BY RecordCount DESC;

-- ============================================
-- 3. CHECK FOR DATAWIPE OPERATIONS
-- ============================================
SELECT DISTINCT
    'vPartTransaction' as TableName,
    PartTransaction,
    Source,
    COUNT(*) as RecordCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND UPPER(Source) LIKE '%DATAWIPE%'
GROUP BY PartTransaction, Source
ORDER BY RecordCount DESC;
