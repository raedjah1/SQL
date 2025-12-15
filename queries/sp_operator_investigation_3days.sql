-- =====================================================
-- SPECIAL PROJECTS (SP%) OPERATOR INVESTIGATION
-- =====================================================
-- Simple 3-day analysis of SP% performance by operator

SELECT 
    u.Username as Operator,
    
    -- ACTIVITY SUMMARY
    COUNT(*) as Total_SP_Transactions,
    COUNT(DISTINCT CAST(pt.CreateDate as DATE)) as Days_Worked_SP,
    COUNT(DISTINCT pt.PartNo) as Unique_Parts_SP,
    COUNT(DISTINCT pt.SerialNo) as Units_Processed_SP,
    
    -- DAILY AVERAGES
    CAST(COUNT(*) * 1.0 / COUNT(DISTINCT CAST(pt.CreateDate as DATE)) AS DECIMAL(10,1)) as Avg_SP_Transactions_Per_Day,
    CAST(COUNT(DISTINCT pt.PartNo) * 1.0 / COUNT(DISTINCT CAST(pt.CreateDate as DATE)) AS DECIMAL(10,1)) as Avg_Parts_Per_Day,
    
    -- DATE RANGE
    MIN(CAST(pt.CreateDate as DATE)) as First_SP_Date,
    MAX(CAST(pt.CreateDate as DATE)) as Last_SP_Date,
    
    -- PERFORMANCE INDICATOR (Compared to ECR standard of 250/day)
    CASE 
        WHEN COUNT(*) * 1.0 / COUNT(DISTINCT CAST(pt.CreateDate as DATE)) >= 250 THEN 'EXCELLENT - Meets ECR Standard'
        WHEN COUNT(*) * 1.0 / COUNT(DISTINCT CAST(pt.CreateDate as DATE)) >= 200 THEN 'GOOD - Close to ECR Standard'
        WHEN COUNT(*) * 1.0 / COUNT(DISTINCT CAST(pt.CreateDate as DATE)) >= 150 THEN 'FAIR - Below ECR Standard'
        ELSE 'NEEDS IMPROVEMENT'
    END as SP_Performance_Rating

FROM Plus.pls.PartTransaction pt
JOIN Plus.pls.[User] u ON u.ID = pt.UserID
JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID

WHERE pt.CreateDate >= DATEADD(day, -3, GETDATE())
  AND u.Username IS NOT NULL
  AND pt.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND pt.CustomerReference LIKE 'SP%'  -- SPECIAL PROJECTS ONLY

GROUP BY u.Username

ORDER BY Avg_SP_Transactions_Per_Day DESC;






