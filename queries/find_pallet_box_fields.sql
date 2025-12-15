-- ============================================
-- FIND PALLET BOX CONSOLIDATION FIELDS
-- ============================================
-- Albert Vincent is asking for tracking of:
-- 1. Move TO pallet box transactions
-- 2. Move FROM pallet box transactions (deconsolidation)

-- ============================================
-- 1. EXAMINE vPartTransaction TABLE STRUCTURE
-- ============================================
-- First, let's see what columns are available
SELECT TOP 1 * FROM pls.vPartTransaction;

-- Check for any pallet-related columns
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'vPartTransaction' 
  AND TABLE_SCHEMA = 'pls'
  AND (
    COLUMN_NAME LIKE '%pallet%' OR 
    COLUMN_NAME LIKE '%box%' OR
    COLUMN_NAME LIKE '%container%' OR
    COLUMN_NAME LIKE '%consolidat%'
  )
ORDER BY COLUMN_NAME;

-- ============================================
-- 2. SEARCH FOR PALLET BOX TRANSACTIONS
-- ============================================
-- Look for transaction types that might be pallet consolidation
SELECT DISTINCT
    PartTransaction,
    COUNT(*) as TransactionCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    UPPER(PartTransaction) LIKE '%PALLET%' OR
    UPPER(PartTransaction) LIKE '%BOX%' OR
    UPPER(PartTransaction) LIKE '%CONSOLIDAT%' OR
    UPPER(PartTransaction) LIKE '%CONTAINER%'
  )
GROUP BY PartTransaction
ORDER BY TransactionCount DESC;

-- ============================================
-- 3. SEARCH FOR PALLET BOX ACTIVITY
-- ============================================
-- Look for transactions with pallet box activity
SELECT DISTINCT
    PalletBoxNo,
    ToPalletBoxNo,
    PartTransaction,
    Location,
    ToLocation,
    COUNT(*) as TransactionCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    PalletBoxNo IS NOT NULL AND PalletBoxNo != '' AND PalletBoxNo != '0' OR
    ToPalletBoxNo IS NOT NULL AND ToPalletBoxNo != '' AND ToPalletBoxNo != '0'
  )
GROUP BY PalletBoxNo, ToPalletBoxNo, PartTransaction, Location, ToLocation
ORDER BY TransactionCount DESC;

-- ============================================
-- 4. EXAMINE ALL AVAILABLE FIELDS
-- ============================================
-- Get all column names from vPartTransaction
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'vPartTransaction' 
  AND TABLE_SCHEMA = 'pls'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- 5. PALLET CONSOLIDATION ANALYSIS
-- ============================================
-- Albert Vincent's specific requirements:

-- A. Move TO Pallet Box (Consolidation)
SELECT 
    'CONSOLIDATION - Move TO Pallet' as OperationType,
    PartTransaction,
    Location,
    ToLocation,
    ToPalletBoxNo,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT Username) as OperatorCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'
  AND CreateDate >= DATEADD(day, -30, GETDATE())
  AND ToPalletBoxNo IS NOT NULL AND ToPalletBoxNo != '' AND ToPalletBoxNo != '0'
  AND (PalletBoxNo IS NULL OR PalletBoxNo = '' OR PalletBoxNo = '0')
GROUP BY PartTransaction, Location, ToLocation, ToPalletBoxNo
ORDER BY TransactionCount DESC;

-- B. Move FROM Pallet Box (Deconsolidation)
SELECT 
    'DECONSOLIDATION - Move FROM Pallet' as OperationType,
    PartTransaction,
    Location,
    ToLocation,
    PalletBoxNo,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT Username) as OperatorCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'
  AND CreateDate >= DATEADD(day, -30, GETDATE())
  AND PalletBoxNo IS NOT NULL AND PalletBoxNo != '' AND PalletBoxNo != '0'
  AND (ToPalletBoxNo IS NULL OR ToPalletBoxNo = '' OR ToPalletBoxNo = '0')
GROUP BY PartTransaction, Location, ToLocation, PalletBoxNo
ORDER BY TransactionCount DESC;

-- C. Complete Pallet Consolidation Flow
SELECT 
    CASE 
        WHEN (PalletBoxNo IS NULL OR PalletBoxNo = '' OR PalletBoxNo = '0') 
             AND (ToPalletBoxNo IS NOT NULL AND ToPalletBoxNo != '' AND ToPalletBoxNo != '0') 
             THEN 'CONSOLIDATION - Move TO Pallet'
        WHEN (PalletBoxNo IS NOT NULL AND PalletBoxNo != '' AND PalletBoxNo != '0') 
             AND (ToPalletBoxNo IS NULL OR ToPalletBoxNo = '' OR ToPalletBoxNo = '0') 
             THEN 'DECONSOLIDATION - Move FROM Pallet'
        WHEN (PalletBoxNo IS NOT NULL AND PalletBoxNo != '' AND PalletBoxNo != '0') 
             AND (ToPalletBoxNo IS NOT NULL AND ToPalletBoxNo != '' AND ToPalletBoxNo != '0') 
             THEN 'PALLET TRANSFER - Move Between Pallets'
        ELSE 'NO PALLET ACTIVITY'
    END as PalletOperationType,
    PartTransaction,
    Location,
    ToLocation,
    PalletBoxNo,
    ToPalletBoxNo,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT Username) as OperatorCount
FROM pls.vPartTransaction
WHERE ProgramID = '10053'
  AND CreateDate >= DATEADD(day, -30, GETDATE())
  AND (
    (PalletBoxNo IS NOT NULL AND PalletBoxNo != '' AND PalletBoxNo != '0') OR
    (ToPalletBoxNo IS NOT NULL AND ToPalletBoxNo != '' AND ToPalletBoxNo != '0')
  )
GROUP BY 
    CASE 
        WHEN (PalletBoxNo IS NULL OR PalletBoxNo = '' OR PalletBoxNo = '0') 
             AND (ToPalletBoxNo IS NOT NULL AND ToPalletBoxNo != '' AND ToPalletBoxNo != '0') 
             THEN 'CONSOLIDATION - Move TO Pallet'
        WHEN (PalletBoxNo IS NOT NULL AND PalletBoxNo != '' AND PalletBoxNo != '0') 
             AND (ToPalletBoxNo IS NULL OR ToPalletBoxNo = '' OR ToPalletBoxNo = '0') 
             THEN 'DECONSOLIDATION - Move FROM Pallet'
        WHEN (PalletBoxNo IS NOT NULL AND PalletBoxNo != '' AND PalletBoxNo != '0') 
             AND (ToPalletBoxNo IS NOT NULL AND ToPalletBoxNo != '' AND ToPalletBoxNo != '0') 
             THEN 'PALLET TRANSFER - Move Between Pallets'
        ELSE 'NO PALLET ACTIVITY'
    END,
    PartTransaction, Location, ToLocation, PalletBoxNo, ToPalletBoxNo
ORDER BY TransactionCount DESC;

-- ============================================
-- 6. SAMPLE RECENT TRANSACTIONS WITH PALLET DATA
-- ============================================
-- Look at recent transactions to understand data structure
SELECT TOP 20
    CreateDate,
    PartTransaction,
    Username,
    Location,
    ToLocation,
    PalletBoxNo,
    ToPalletBoxNo,
    PartNo,
    SerialNo,
    Qty,
    Source
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -1, GETDATE())  -- Last day
  AND (
    (PalletBoxNo IS NOT NULL AND PalletBoxNo != '' AND PalletBoxNo != '0') OR
    (ToPalletBoxNo IS NOT NULL AND ToPalletBoxNo != '' AND ToPalletBoxNo != '0')
  )
ORDER BY CreateDate DESC;
