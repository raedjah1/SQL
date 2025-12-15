-- ============================================
-- FIND ALL MISSING PROCESSES FOR DASHBOARDS
-- ============================================
-- This will show ALL processes we haven't covered yet

-- ============================================
-- 1. ALL TRANSACTION TYPES (Top 50)



-- ============================================
-- 2. ALL LOCATION PATTERNS (Top 50)
-- ============================================
SELECT 
    'ALL_LOCATION_PATTERNS' as ProcessType,
    Location,
    ToLocation,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT Username) as OperatorCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND Username IS NOT NULL
  AND Location IS NOT NULL
  AND ToLocation IS NOT NULL
GROUP BY Location, ToLocation
ORDER BY TransactionCount DESC;

-- ============================================
-- 3. ALL SOURCE PATTERNS (Top 50)
-- ============================================
SELECT 
    'ALL_SOURCE_PATTERNS' as ProcessType,
    Source,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT Username) as OperatorCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND Username IS NOT NULL
  AND Source IS NOT NULL
GROUP BY Source
ORDER BY TransactionCount DESC;

-- ============================================
-- 4. ALL WORKSTATION DESCRIPTIONS (Top 50)
-- ============================================
SELECT 
    'ALL_WORKSTATIONS' as ProcessType,
    WorkstationDescription,
    COUNT(*) as RecordCount,
    COUNT(DISTINCT Username) as OperatorCount
FROM pls.vWOHeader
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND Username IS NOT NULL
  AND WorkstationDescription IS NOT NULL
GROUP BY WorkstationDescription
ORDER BY RecordCount DESC;

-- ============================================
-- 5. ALL REPAIR TYPES (Top 50)
-- ============================================
SELECT 
    'ALL_REPAIR_TYPES' as ProcessType,
    RepairTypeDescription,
    COUNT(*) as RecordCount,
    COUNT(DISTINCT Username) as OperatorCount
FROM pls.vWOHeader
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND Username IS NOT NULL
  AND RepairTypeDescription IS NOT NULL
GROUP BY RepairTypeDescription
ORDER BY RecordCount DESC;
