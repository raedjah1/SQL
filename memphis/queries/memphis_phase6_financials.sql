-- ===============================================
-- MEMPHIS SITE INTELLIGENCE - PHASE 6
-- FINANCIAL & BUSINESS METRICS
-- ===============================================

-- Query 16: Revenue and Cost Analysis
SELECT 
    p.Name as ProgramName,
    p.CustomerID,
    c.Name as CustomerName,
    COUNT(*) as TotalOrders,
    SUM(COALESCE(wo.EstimatedCost, 0)) as TotalEstimatedCost,
    AVG(COALESCE(wo.EstimatedCost, 0)) as AvgOrderCost,
    SUM(COALESCE(wo.ActualCost, 0)) as TotalActualCost,
    SUM(COALESCE(wo.Revenue, 0)) as TotalRevenue,
    SUM(COALESCE(wo.Revenue, 0)) - SUM(COALESCE(wo.ActualCost, 0)) as NetProfit,
    CASE 
        WHEN SUM(COALESCE(wo.Revenue, 0)) > 0 
        THEN ROUND((SUM(COALESCE(wo.Revenue, 0)) - SUM(COALESCE(wo.ActualCost, 0))) * 100.0 / SUM(COALESCE(wo.Revenue, 0)), 2)
        ELSE 0 
    END as ProfitMargin
FROM PLUS.pls.WorkOrder wo
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
LEFT JOIN PLUS.pls.Customer c ON p.CustomerID = c.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY p.Name, p.CustomerID, c.Name
ORDER BY TotalRevenue DESC;

-- Query 17: Monthly Trend Analysis
SELECT 
    YEAR(wo.CreateDate) as Year,
    MONTH(wo.CreateDate) as Month,
    DATENAME(month, wo.CreateDate) as MonthName,
    COUNT(*) as OrderVolume,
    COUNT(CASE WHEN wo.StatusID = 4 THEN 1 END) as CompletedOrders,
    ROUND(COUNT(CASE WHEN wo.StatusID = 4 THEN 1 END) * 100.0 / COUNT(*), 2) as CompletionRate,
    ROUND(AVG(DATEDIFF(day, wo.CreateDate, COALESCE(wo.CompleteDate, wo.LastActivityDate))), 2) as AvgProcessingDays,
    SUM(COALESCE(wo.Revenue, 0)) as MonthlyRevenue,
    SUM(COALESCE(wo.ActualCost, 0)) as MonthlyCost,
    p.Name as ProgramName
FROM PLUS.pls.WorkOrder wo
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
AND wo.CreateDate >= DATEADD(year, -2, GETDATE())
GROUP BY YEAR(wo.CreateDate), MONTH(wo.CreateDate), DATENAME(month, wo.CreateDate), p.Name
ORDER BY Year DESC, Month DESC;

-- Query 18: Customer Profitability Analysis
SELECT 
    c.ID as CustomerID,
    c.Name as CustomerName,
    c.Industry,
    c.Region as CustomerRegion,
    COUNT(*) as TotalOrders,
    COUNT(CASE WHEN wo.StatusID = 4 THEN 1 END) as CompletedOrders,
    SUM(COALESCE(wo.Revenue, 0)) as TotalRevenue,
    SUM(COALESCE(wo.ActualCost, 0)) as TotalCost,
    SUM(COALESCE(wo.Revenue, 0)) - SUM(COALESCE(wo.ActualCost, 0)) as CustomerProfit,
    AVG(DATEDIFF(day, wo.CreateDate, COALESCE(wo.CompleteDate, GETDATE()))) as AvgTurnaroundTime,
    MIN(wo.CreateDate) as FirstOrder,
    MAX(wo.LastActivityDate) as LastOrder,
    p.Name as ProgramName
FROM PLUS.pls.WorkOrder wo
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
LEFT JOIN PLUS.pls.Customer c ON p.CustomerID = c.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY c.ID, c.Name, c.Industry, c.Region, p.Name
ORDER BY TotalRevenue DESC;
