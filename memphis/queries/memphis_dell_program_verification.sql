-- =====================================================
-- DELL PROGRAM VERIFICATION QUERY
-- =====================================================
-- Purpose: Verify DELL Program ID and get sample data
-- =====================================================

-- 1. Verify DELL Program exists and get basic info
SELECT 
    'PROGRAM VERIFICATION' as CheckType,
    p.ID as ProgramID,
    p.Name as ProgramName,
    p.CustomerID,
    p.Status,
    p.CreateDate,
    p.AddressID
FROM pls.vProgram p
WHERE p.Name = 'DELL'
   OR p.ID = 10053;

-- 2. Get sample DELL transaction data (last 7 days, top 10 operators)
SELECT TOP 10
    'SAMPLE DELL DATA' as CheckType,
    pt.Username as Operator,
    COUNT(*) as TransactionCount,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    COUNT(DISTINCT pt.PartNo) as UniqueParts
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(day, -7, GETDATE())  -- Last 7 days
  AND pt.Username IS NOT NULL
GROUP BY pt.Username
ORDER BY TransactionCount DESC;

-- 3. Check if we have any data for Program ID 10053
SELECT 
    'DATA AVAILABILITY CHECK' as CheckType,
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT pt.Username) as UniqueOperators,
    MIN(pt.CreateDate) as EarliestTransaction,
    MAX(pt.CreateDate) as LatestTransaction
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053;

-- 4. VERIFY MEMPHIS DELL - Check Address and Location
SELECT 
    'MEMPHIS VERIFICATION' as CheckType,
    p.ID as ProgramID,
    p.Name as ProgramName,
    a.City,
    a.Country,
    a.Name as AddressName,
    COUNT(pt.ID) as TransactionCount
FROM pls.vProgram p
LEFT JOIN pls.vCodeAddress a ON p.AddressID = a.ID
LEFT JOIN pls.vPartTransaction pt ON p.ID = pt.ProgramID
WHERE p.ID = 10053
GROUP BY p.ID, p.Name, a.City, a.Country, a.Name;
