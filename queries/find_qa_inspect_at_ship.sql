-- ============================================
-- FIND QA INSPECT AT SHIP OPERATIONS
-- ============================================
-- Looking for quality inspection processes during shipping

-- ============================================
-- 1. SEARCH FOR QA/INSPECT TRANSACTION TYPES
-- ============================================
-- Look for transaction types that might be QA inspection
SELECT DISTINCT
    PartTransaction,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT Username) as OperatorCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    UPPER(PartTransaction) LIKE '%QA%' OR
    UPPER(PartTransaction) LIKE '%INSPECT%' OR
    UPPER(PartTransaction) LIKE '%QUALITY%' OR
    UPPER(PartTransaction) LIKE '%CHECK%' OR
    UPPER(PartTransaction) LIKE '%VERIFY%'
  )
GROUP BY PartTransaction
ORDER BY TransactionCount DESC;

-- ============================================
-- 2. SEARCH FOR SHIP-RELATED QA OPERATIONS
-- ============================================
-- Look for QA operations that happen during shipping
SELECT DISTINCT
    PartTransaction,
    Location,
    ToLocation,
    COUNT(*) as TransactionCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    UPPER(PartTransaction) LIKE '%SHIP%' OR
    UPPER(Location) LIKE '%SHIP%' OR
    UPPER(ToLocation) LIKE '%SHIP%'
  )
  AND (
    UPPER(PartTransaction) LIKE '%QA%' OR
    UPPER(PartTransaction) LIKE '%INSPECT%' OR
    UPPER(PartTransaction) LIKE '%QUALITY%'
  )
GROUP BY PartTransaction, Location, ToLocation
ORDER BY TransactionCount DESC;

-- ============================================
-- 3. SEARCH FOR CONDITION-BASED QA
-- ============================================
-- Look for transactions with quality conditions
SELECT DISTINCT
    PartTransaction,
    Condition,
    COUNT(*) as TransactionCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND Condition IS NOT NULL 
  AND Condition != ''
  AND (
    UPPER(Condition) LIKE '%QA%' OR
    UPPER(Condition) LIKE '%INSPECT%' OR
    UPPER(Condition) LIKE '%QUALITY%' OR
    UPPER(Condition) LIKE '%GOOD%' OR
    UPPER(Condition) LIKE '%BAD%'
  )
GROUP BY PartTransaction, Condition
ORDER BY TransactionCount DESC;

-- ============================================
-- 4. SEARCH FOR SO-SHIP WITH QA PATTERNS
-- ============================================
-- Look for shipping transactions that might include QA
SELECT DISTINCT
    PartTransaction,
    Location,
    ToLocation,
    Condition,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT Username) as OperatorCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND PartTransaction = 'SO-SHIP'  -- Shipping operations
GROUP BY PartTransaction, Location, ToLocation, Condition
ORDER BY TransactionCount DESC;

-- ============================================
-- 5. SEARCH FOR WORKSTATION QA PATTERNS
-- ============================================
-- Look for QA-related workstation operations
SELECT DISTINCT
    PartTransaction,
    Source,
    COUNT(*) as TransactionCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    UPPER(Source) LIKE '%QA%' OR
    UPPER(Source) LIKE '%INSPECT%' OR
    UPPER(Source) LIKE '%QUALITY%' OR
    UPPER(Source) LIKE '%TEST%'
  )
GROUP BY PartTransaction, Source
ORDER BY TransactionCount DESC;

-- ============================================
-- 6. SAMPLE RECENT QA/SHIP TRANSACTIONS
-- ============================================
-- Look at recent transactions to understand QA at ship patterns
SELECT TOP 20
    CreateDate,
    PartTransaction,
    Username,
    Location,
    ToLocation,
    Condition,
    PartNo,
    SerialNo,
    Source
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -1, GETDATE())  -- Last day
  AND (
    UPPER(PartTransaction) LIKE '%SHIP%' OR
    UPPER(PartTransaction) LIKE '%QA%' OR
    UPPER(PartTransaction) LIKE '%INSPECT%'
  )
ORDER BY CreateDate DESC;
