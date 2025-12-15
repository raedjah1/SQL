-- Test query to verify ADTOperatordashboard returns data for today
-- This matches the exact logic of ADTOperatordashboard.sql but filters for today only

SELECT 
    u.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATEPART(HOUR, pt.CreateDate) as WorkHour,
    
    -- CUSTOMER CATEGORY FOR SLICER
    CASE
        WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
        WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
        WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
        ELSE 'FSR'
    END as CustomerCategory,
    
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActiveMinutes

FROM Plus.pls.PartTransaction pt
JOIN Plus.pls.[User] u ON u.ID = pt.UserID
JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE u.Username IS NOT NULL
  AND pt.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND CAST(pt.CreateDate AS DATE) = CAST(GETDATE() AS DATE)  -- ✅ TODAY ONLY
GROUP BY u.Username, CAST(pt.CreateDate as DATE), DATEPART(HOUR, pt.CreateDate),
    CASE
        WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
        WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
        WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
        ELSE 'FSR'
    END
ORDER BY u.Username, DATEPART(HOUR, pt.CreateDate);



