-- =====================================================
-- INVESTIGATE ACTUAL SP CUSTOMER REFERENCE PATTERNS
-- =====================================================
-- Find what SP references actually look like in your data

SELECT 
    pt.CustomerReference,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT u.Username) as OperatorCount,
    MIN(pt.CreateDate) as FirstSeen,
    MAX(pt.CreateDate) as LastSeen
    
FROM Plus.pls.PartTransaction pt
JOIN Plus.pls.[User] u ON u.ID = pt.UserID  
JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID

WHERE pt.CreateDate >= DATEADD(day, -7, GETDATE())
  AND u.Username IS NOT NULL
  AND pt.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND pt.CustomerReference IS NOT NULL
  -- Look for potential SP patterns
  AND (
      pt.CustomerReference LIKE 'SP%' OR 
      pt.CustomerReference LIKE 'sp%' OR
      pt.CustomerReference LIKE '%SP%' OR
      pt.CustomerReference LIKE '%sp%' OR
      pt.CustomerReference LIKE 'Special%' OR
      pt.CustomerReference LIKE 'SPECIAL%'
  )
  
GROUP BY pt.CustomerReference
ORDER BY TransactionCount DESC;






