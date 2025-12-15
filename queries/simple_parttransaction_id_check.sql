-- =====================================================
-- SIMPLE CHECK: WHAT IS PARTTRANSACTIONID = 1?
-- =====================================================

-- First, see what columns actually exist in CodePartTransaction
SELECT TOP 5 * 
FROM Plus.pls.CodePartTransaction
ORDER BY ID;

-- Check what PartTransactionID = 1 means
SELECT * 
FROM Plus.pls.CodePartTransaction 
WHERE ID = 1;

-- See all transaction types to understand the codes
SELECT 
    cpt.ID as PartTransactionID,
    cpt.Description,
    COUNT(*) as UsageCount
FROM Plus.pls.CodePartTransaction cpt
    LEFT JOIN Plus.pls.PartTransaction pt ON pt.PartTransactionID = cpt.ID
WHERE pt.ProgramID = 10053
GROUP BY cpt.ID, cpt.Description
ORDER BY cpt.ID;

-- Simple test of your exact join to see what transaction type 1 gives you
SELECT TOP 5
    pt.PartTransactionID,
    cpt.Description as TransactionType,
    pt.Qty,
    pt.CreateDate,
    pt.PartNo
FROM Plus.pls.PartTransaction pt
    JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE pt.PartTransactionID = 1 
  AND pt.ProgramID = 10053
ORDER BY pt.CreateDate DESC;
