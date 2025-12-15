-- ============================================
-- FIND ADT BRANCH REPORT (ProgramID = 10068)
-- ============================================
-- This query looks for branch-related data specifically for ADT program
-- to understand what the manager meant by "branch report"

-- ============================================
-- 1. FIND ADT PROGRAM DATA IN PLS SCHEMA
-- ============================================
SELECT TOP 10
    'ADT PROGRAM DATA' as InfoType,
    ProgramID,
    Name as ProgramName,
    CustomerID,
    Site,
    CreateDate,
    LastActivityDate
FROM pls.vProgram 
WHERE ProgramID = 10068;

-- ============================================
-- 2. FIND ADT WORK ORDERS WITH BRANCH/REFERENCE DATA
-- ============================================
SELECT TOP 20
    'ADT WORK ORDERS' as InfoType,
    ID as WorkOrderID,
    CustomerReference,
    PartNo,
    SerialNo,
    RepairTypeDescription,
    StatusDescription,
    Username,
    CreateDate,
    LastActivityDate
FROM pls.vWOHeader 
WHERE ProgramID = 10068
ORDER BY CreateDate DESC;

-- ============================================
-- 3. FIND ADT REPAIR ORDERS WITH BRANCH/REFERENCE DATA
-- ============================================
SELECT TOP 20
    'ADT REPAIR ORDERS' as InfoType,
    ID as RepairOrderID,
    RepairOrderNo,
    CustomerReference,
    PartNo,
    SerialNo,
    StatusDescription,
    Username,
    CreateDate,
    LastActivityDate
FROM pls.vROUnit 
WHERE ProgramID = 10068
ORDER BY CreateDate DESC;

-- ============================================
-- 4. FIND ADT PART TRANSACTIONS WITH BRANCH/REFERENCE DATA
-- ============================================
SELECT TOP 20
    'ADT PART TRANSACTIONS' as InfoType,
    ID as TransactionID,
    PartTransaction,
    PartNo,
    SerialNo,
    QtyRequested,
    QtyConsumed,
    Location,
    ToLocation,
    Username,
    CreateDate
FROM pls.vPartTransaction 
WHERE ProgramID = 10068
ORDER BY CreateDate DESC;

-- ============================================
-- 5. FIND ADT SERIAL NUMBERS WITH BRANCH/REFERENCE DATA
-- ============================================
SELECT TOP 20
    'ADT SERIAL NUMBERS' as InfoType,
    SerialNo,
    PartNo,
    WOPass,
    Shippable,
    CreateDate,
    LastActivityDate,
    RODate,
    SODate,
    WOStartDate,
    WOEndDate
FROM pls.vPartSerial 
WHERE ProgramID = 10068
ORDER BY CreateDate DESC;

-- ============================================
-- 6. FIND ADT PART LOCATIONS WITH BRANCH/REFERENCE DATA
-- ============================================
SELECT TOP 20
    'ADT PART LOCATIONS' as InfoType,
    PartNo,
    LocationNo,
    QtyOnHand,
    CreateDate,
    LastActivityDate
FROM pls.vPartLocation 
WHERE ProgramID = 10068
ORDER BY CreateDate DESC;

-- ============================================
-- 7. FIND ADT CUSTOMER REFERENCE PATTERNS
-- ============================================
SELECT 
    'ADT CUSTOMER REFERENCES' as InfoType,
    CustomerReference,
    COUNT(*) as ReferenceCount,
    MIN(CreateDate) as FirstReference,
    MAX(CreateDate) as LastReference
FROM pls.vWOHeader 
WHERE ProgramID = 10068
  AND CustomerReference IS NOT NULL
GROUP BY CustomerReference
ORDER BY ReferenceCount DESC;

-- ============================================
-- 8. FIND ADT REPAIR TYPE PATTERNS
-- ============================================
SELECT 
    'ADT REPAIR TYPES' as InfoType,
    RepairTypeDescription,
    COUNT(*) as TypeCount,
    MIN(CreateDate) as FirstType,
    MAX(CreateDate) as LastType
FROM pls.vWOHeader 
WHERE ProgramID = 10068
  AND RepairTypeDescription IS NOT NULL
GROUP BY RepairTypeDescription
ORDER BY TypeCount DESC;

-- ============================================
-- 9. FIND ADT STATUS PATTERNS
-- ============================================
SELECT 
    'ADT STATUS PATTERNS' as InfoType,
    StatusDescription,
    COUNT(*) as StatusCount,
    MIN(CreateDate) as FirstStatus,
    MAX(CreateDate) as LastStatus
FROM pls.vWOHeader 
WHERE ProgramID = 10068
  AND StatusDescription IS NOT NULL
GROUP BY StatusDescription
ORDER BY StatusCount DESC;

-- ============================================
-- 10. FIND ADT USERNAME PATTERNS (DEPARTMENTS)
-- ============================================
SELECT 
    'ADT USERNAMES (DEPARTMENTS)' as InfoType,
    Username,
    COUNT(*) as UserCount,
    MIN(CreateDate) as FirstActivity,
    MAX(CreateDate) as LastActivity
FROM pls.vWOHeader 
WHERE ProgramID = 10068
  AND Username IS NOT NULL
GROUP BY Username
ORDER BY UserCount DESC;




































