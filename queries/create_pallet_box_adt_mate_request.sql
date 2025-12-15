-- ============================================
-- CREATE PALLET BOX ADT MATE REQUEST ANALYSIS
-- ============================================
-- This query helps find the mate request for Create Pallet Box ADT
-- Based on pallet consolidation intelligence and ADT program analysis

-- ============================================
-- 1. PALLET BOX TRANSACTIONS FOR ADT PROGRAM
-- ============================================
-- Find all pallet box related transactions for ADT program
SELECT 
    'ADT PALLET BOX ACTIVITY' as AnalysisType,
    pt.PartTransaction,
    pt.Location,
    pt.ToLocation,
    pt.PalletBoxNo,
    pt.ToPalletBoxNo,
    pt.PartNo,
    pt.SerialNo,
    pt.Username as Operator,
    pt.CreateDate,
    -- Pallet operation type
    CASE 
        WHEN (pt.PalletBoxNo IS NULL OR pt.PalletBoxNo = '' OR pt.PalletBoxNo = '0') 
             AND (pt.ToPalletBoxNo IS NOT NULL AND pt.ToPalletBoxNo != '' AND pt.ToPalletBoxNo != '0') 
             THEN 'CONSOLIDATION - Move TO Pallet'
        WHEN (pt.PalletBoxNo IS NOT NULL AND pt.PalletBoxNo != '' AND pt.PalletBoxNo != '0') 
             AND (pt.ToPalletBoxNo IS NULL OR pt.ToPalletBoxNo = '' OR pt.ToPalletBoxNo = '0') 
             THEN 'DECONSOLIDATION - Move FROM Pallet'
        WHEN (pt.PalletBoxNo IS NOT NULL AND pt.PalletBoxNo != '' AND pt.PalletBoxNo != '0') 
             AND (pt.ToPalletBoxNo IS NOT NULL AND pt.ToPalletBoxNo != '' AND pt.ToPalletBoxNo != '0') 
             THEN 'PALLET TRANSFER - Move Between Pallets'
        ELSE 'NO PALLET ACTIVITY'
    END as PalletOperationType
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    (pt.PalletBoxNo IS NOT NULL AND pt.PalletBoxNo != '' AND pt.PalletBoxNo != '0') OR
    (pt.ToPalletBoxNo IS NOT NULL AND pt.ToPalletBoxNo != '' AND pt.ToPalletBoxNo != '0')
  )
ORDER BY pt.CreateDate DESC;

-- ============================================
-- 2. CREATE PALLET BOX SPECIFIC SEARCH
-- ============================================
-- Search for "Create Pallet Box" related transactions
SELECT 
    'CREATE PALLET BOX SEARCH' as AnalysisType,
    pt.PartTransaction,
    pt.Location,
    pt.ToLocation,
    pt.PalletBoxNo,
    pt.ToPalletBoxNo,
    pt.PartNo,
    pt.SerialNo,
    pt.Username as Operator,
    pt.CreateDate,
    pt.Comments,
    pt.Description
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= DATEADD(day, -90, GETDATE())  -- Last 90 days
  AND (
    UPPER(pt.PartTransaction) LIKE '%CREATE%' OR
    UPPER(pt.PartTransaction) LIKE '%PALLET%' OR
    UPPER(pt.PartTransaction) LIKE '%BOX%' OR
    UPPER(pt.Comments) LIKE '%CREATE%PALLET%' OR
    UPPER(pt.Comments) LIKE '%PALLET%BOX%' OR
    UPPER(pt.Description) LIKE '%CREATE%PALLET%' OR
    UPPER(pt.Description) LIKE '%PALLET%BOX%'
  )
ORDER BY pt.CreateDate DESC;

-- ============================================
-- 3. MATE REQUEST PATTERN ANALYSIS
-- ============================================
-- Look for mate request patterns in ADT transactions
SELECT 
    'MATE REQUEST ANALYSIS' as AnalysisType,
    pt.PartTransaction,
    pt.Location,
    pt.ToLocation,
    pt.PartNo,
    pt.SerialNo,
    pt.Username as Operator,
    pt.CreateDate,
    pt.Comments,
    pt.Description,
    -- Check for mate request indicators
    CASE 
        WHEN UPPER(pt.Comments) LIKE '%MATE%' OR UPPER(pt.Description) LIKE '%MATE%' THEN 'MATE REQUEST FOUND'
        WHEN UPPER(pt.Comments) LIKE '%REQUEST%' OR UPPER(pt.Description) LIKE '%REQUEST%' THEN 'REQUEST FOUND'
        WHEN UPPER(pt.Comments) LIKE '%CREATE%' OR UPPER(pt.Description) LIKE '%CREATE%' THEN 'CREATE REQUEST FOUND'
        ELSE 'NO MATE INDICATORS'
    END as MateRequestStatus
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= DATEADD(day, -90, GETDATE())  -- Last 90 days
  AND (
    UPPER(pt.Comments) LIKE '%MATE%' OR
    UPPER(pt.Comments) LIKE '%REQUEST%' OR
    UPPER(pt.Comments) LIKE '%CREATE%' OR
    UPPER(pt.Description) LIKE '%MATE%' OR
    UPPER(pt.Description) LIKE '%REQUEST%' OR
    UPPER(pt.Description) LIKE '%CREATE%'
  )
ORDER BY pt.CreateDate DESC;

-- ============================================
-- 4. ADT PALLET CONSOLIDATION SUMMARY
-- ============================================
-- Summary of pallet consolidation activities for ADT
SELECT 
    'ADT PALLET SUMMARY' as AnalysisType,
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT pt.PalletBoxNo) as UniquePalletBoxes,
    COUNT(DISTINCT pt.ToPalletBoxNo) as UniqueToPalletBoxes,
    COUNT(DISTINCT pt.Username) as OperatorsInvolved,
    COUNT(DISTINCT pt.PartNo) as UniqueParts,
    MIN(pt.CreateDate) as FirstActivity,
    MAX(pt.CreateDate) as LastActivity,
    -- Pallet operation breakdown
    SUM(CASE 
        WHEN (pt.PalletBoxNo IS NULL OR pt.PalletBoxNo = '' OR pt.PalletBoxNo = '0') 
             AND (pt.ToPalletBoxNo IS NOT NULL AND pt.ToPalletBoxNo != '' AND pt.ToPalletBoxNo != '0') 
             THEN 1 ELSE 0 
    END) as ConsolidationMoves,
    SUM(CASE 
        WHEN (pt.PalletBoxNo IS NOT NULL AND pt.PalletBoxNo != '' AND pt.PalletBoxNo != '0') 
             AND (pt.ToPalletBoxNo IS NULL OR pt.ToPalletBoxNo = '' OR pt.ToPalletBoxNo = '0') 
             THEN 1 ELSE 0 
    END) as DeconsolidationMoves,
    SUM(CASE 
        WHEN (pt.PalletBoxNo IS NOT NULL AND pt.PalletBoxNo != '' AND pt.PalletBoxNo != '0') 
             AND (pt.ToPalletBoxNo IS NOT NULL AND pt.ToPalletBoxNo != '' AND pt.ToPalletBoxNo != '0') 
             THEN 1 ELSE 0 
    END) as PalletTransfers
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND (
    (pt.PalletBoxNo IS NOT NULL AND pt.PalletBoxNo != '' AND pt.PalletBoxNo != '0') OR
    (pt.ToPalletBoxNo IS NOT NULL AND pt.ToPalletBoxNo != '' AND pt.ToPalletBoxNo != '0')
  );

-- ============================================
-- 5. ADT OPERATORS INVOLVED IN PALLET WORK
-- ============================================
-- Find operators who work with pallet boxes in ADT program
SELECT 
    'ADT PALLET OPERATORS' as AnalysisType,
    pt.Username as Operator,
    COUNT(*) as PalletTransactions,
    COUNT(DISTINCT pt.PalletBoxNo) as UniquePalletBoxes,
    COUNT(DISTINCT pt.ToPalletBoxNo) as UniqueToPalletBoxes,
    COUNT(DISTINCT pt.PartNo) as UniqueParts,
    MIN(pt.CreateDate) as FirstPalletWork,
    MAX(pt.CreateDate) as LastPalletWork,
    -- Operator specialization
    CASE 
        WHEN COUNT(*) > 50 THEN 'PALLET SPECIALIST'
        WHEN COUNT(*) > 20 THEN 'PALLET EXPERIENCED'
        WHEN COUNT(*) > 5 THEN 'PALLET TRAINED'
        ELSE 'PALLET OCCASIONAL'
    END as PalletSpecialization
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
  AND pt.Username IS NOT NULL
  AND (
    (pt.PalletBoxNo IS NOT NULL AND pt.PalletBoxNo != '' AND pt.PalletBoxNo != '0') OR
    (pt.ToPalletBoxNo IS NOT NULL AND pt.ToPalletBoxNo != '' AND pt.ToPalletBoxNo != '0')
  )
GROUP BY pt.Username
ORDER BY PalletTransactions DESC;

-- ============================================
-- 6. RECENT PALLET BOX CREATION ACTIVITY
-- ============================================
-- Look for recent pallet box creation activities
SELECT 
    'RECENT PALLET CREATION' as AnalysisType,
    pt.PartTransaction,
    pt.Location,
    pt.ToLocation,
    pt.PalletBoxNo,
    pt.ToPalletBoxNo,
    pt.PartNo,
    pt.SerialNo,
    pt.Username as Operator,
    pt.CreateDate,
    pt.Comments,
    pt.Description,
    -- Time since creation
    DATEDIFF(hour, pt.CreateDate, GETDATE()) as HoursAgo
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND (
    (pt.ToPalletBoxNo IS NOT NULL AND pt.ToPalletBoxNo != '' AND pt.ToPalletBoxNo != '0') OR
    UPPER(pt.PartTransaction) LIKE '%CREATE%' OR
    UPPER(pt.Comments) LIKE '%CREATE%' OR
    UPPER(pt.Description) LIKE '%CREATE%'
  )
ORDER BY pt.CreateDate DESC;
