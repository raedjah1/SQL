-- =====================================================
-- CLEAN CHECK: WHAT IS PARTTRANSACTIONID = 1?
-- =====================================================

-- Simple check - what is ID = 1 in CodePartTransaction?
SELECT 
    ID as PartTransactionID,
    Description
FROM Plus.pls.CodePartTransaction 
WHERE ID = 1;

-- Show all transaction types available
SELECT 
    ID as PartTransactionID,
    Description
FROM Plus.pls.CodePartTransaction
ORDER BY ID;






