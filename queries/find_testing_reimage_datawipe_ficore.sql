-- ============================================
-- FIND TESTING, REIMAGE, DATAWIPE, FICORE DATA
-- ============================================
-- Check all relevant tables for these operations

-- ============================================
-- 1. CHECK vWOHeader (Work Order Header)
-- ============================================
-- Look for testing, reimage, datawipe, ficore in work orders
SELECT DISTINCT
    'vWOHeader' as TableName,
    WorkstationDescription,
    RepairTypeDescription,
    StatusDescription,
    COUNT(*) as RecordCount
FROM pls.vWOHeader
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    UPPER(WorkstationDescription) LIKE '%TEST%' OR
    UPPER(WorkstationDescription) LIKE '%REIMAGE%' OR
    UPPER(WorkstationDescription) LIKE '%DATAWIPE%' OR
    UPPER(WorkstationDescription) LIKE '%FICORE%' OR
    UPPER(RepairTypeDescription) LIKE '%TEST%' OR
    UPPER(RepairTypeDescription) LIKE '%REIMAGE%' OR
    UPPER(RepairTypeDescription) LIKE '%DATAWIPE%' OR
    UPPER(RepairTypeDescription) LIKE '%FICORE%' OR
    UPPER(StatusDescription) LIKE '%TEST%' OR
    UPPER(StatusDescription) LIKE '%REIMAGE%' OR
    UPPER(StatusDescription) LIKE '%DATAWIPE%' OR
    UPPER(StatusDescription) LIKE '%FICORE%'
  )
GROUP BY WorkstationDescription, RepairTypeDescription, StatusDescription
ORDER BY RecordCount DESC;

-- ============================================
-- 2. CHECK vWOLine (Work Order Lines)
-- ============================================
-- Look for testing, reimage, datawipe, ficore in work order lines
SELECT DISTINCT
    'vWOLine' as TableName,
    StatusDescription,
    COUNT(*) as RecordCount
FROM pls.vWOLine
WHERE CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    UPPER(StatusDescription) LIKE '%TEST%' OR
    UPPER(StatusDescription) LIKE '%REIMAGE%' OR
    UPPER(StatusDescription) LIKE '%DATAWIPE%' OR
    UPPER(StatusDescription) LIKE '%FICORE%'
  )
GROUP BY StatusDescription
ORDER BY RecordCount DESC;

-- ============================================
-- 3. CHECK vPartTransaction (Part Transactions)
-- ============================================
-- Look for testing, reimage, datawipe, ficore in part transactions
SELECT DISTINCT
    'vPartTransaction' as TableName,
    PartTransaction,
    Source,
    Location,
    ToLocation,
    COUNT(*) as RecordCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    UPPER(PartTransaction) LIKE '%TEST%' OR
    UPPER(PartTransaction) LIKE '%REIMAGE%' OR
    UPPER(PartTransaction) LIKE '%DATAWIPE%' OR
    UPPER(PartTransaction) LIKE '%FICORE%' OR
    UPPER(Source) LIKE '%TEST%' OR
    UPPER(Source) LIKE '%REIMAGE%' OR
    UPPER(Source) LIKE '%DATAWIPE%' OR
    UPPER(Source) LIKE '%FICORE%' OR
    UPPER(Location) LIKE '%TEST%' OR
    UPPER(Location) LIKE '%REIMAGE%' OR
    UPPER(Location) LIKE '%DATAWIPE%' OR
    UPPER(Location) LIKE '%FICORE%' OR
    UPPER(ToLocation) LIKE '%TEST%' OR
    UPPER(ToLocation) LIKE '%REIMAGE%' OR
    UPPER(ToLocation) LIKE '%DATAWIPE%' OR
    UPPER(ToLocation) LIKE '%FICORE%'
  )
GROUP BY PartTransaction, Source, Location, ToLocation
ORDER BY RecordCount DESC;

-- ============================================
-- 4. CHECK vProgram (Program Information)
-- ============================================
-- Look for testing, reimage, datawipe, ficore programs
SELECT DISTINCT
    'vProgram' as TableName,
    Name,
    Description,
    COUNT(*) as RecordCount
FROM pls.vProgram
WHERE (
    UPPER(Name) LIKE '%TEST%' OR
    UPPER(Name) LIKE '%REIMAGE%' OR
    UPPER(Name) LIKE '%DATAWIPE%' OR
    UPPER(Name) LIKE '%FICORE%' OR
    UPPER(Description) LIKE '%TEST%' OR
    UPPER(Description) LIKE '%REIMAGE%' OR
    UPPER(Description) LIKE '%DATAWIPE%' OR
    UPPER(Description) LIKE '%FICORE%'
  )
GROUP BY Name, Description
ORDER BY RecordCount DESC;

-- ============================================
-- 5. SAMPLE RECENT RECORDS
-- ============================================
-- Get sample records from each table
SELECT TOP 10
    'vWOHeader' as TableName,
    ID,
    WorkstationDescription,
    RepairTypeDescription,
    StatusDescription,
    Username,
    CreateDate
FROM pls.vWOHeader
WHERE ProgramID = '10053'
  AND CreateDate >= DATEADD(day, -7, GETDATE())
  AND (
    UPPER(WorkstationDescription) LIKE '%TEST%' OR
    UPPER(WorkstationDescription) LIKE '%REIMAGE%' OR
    UPPER(WorkstationDescription) LIKE '%DATAWIPE%' OR
    UPPER(WorkstationDescription) LIKE '%FICORE%'
  )
ORDER BY CreateDate DESC;
