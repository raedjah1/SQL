-- ===============================================
-- MEMPHIS SITE INTELLIGENCE - PHASE 2
-- OPERATIONAL PERFORMANCE & WORK ORDERS
-- ===============================================

-- Query 4: Work Order Header Performance (Last 12 months)
SELECT 
    COUNT(*) as TotalWorkOrders,
    COUNT(CASE WHEN wh.StatusID = 4 THEN 1 END) as CompletedOrders,
    COUNT(CASE WHEN wh.StatusID IN (1,2,3) THEN 1 END) as ActiveOrders,
    ROUND(COUNT(CASE WHEN wh.StatusID = 4 THEN 1 END) * 100.0 / COUNT(*), 2) as CompletionRate,
    AVG(DATEDIFF(day, wh.CreateDate, COALESCE(wh.CompleteDate, GETDATE()))) as AvgProcessingDays,
    MIN(wh.CreateDate) as EarliestOrder,
    MAX(wh.LastActivityDate) as LatestActivity,
    COUNT(DISTINCT wh.PartNo) as UniquePartsProcessed,
    COUNT(DISTINCT wh.UserID) as ActiveUsers,
    p.Name as ProgramName
FROM PLUS.pls.vWOHeader wh
INNER JOIN PLUS.pls.vProgram p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS' 
AND wh.CreateDate >= DATEADD(year, -1, GETDATE())
GROUP BY p.Name;

-- Query 5: Work Order Status Distribution
SELECT 
    wh.StatusID,
    s.Name as StatusName,
    s.Description as StatusDescription,
    COUNT(*) as OrderCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as Percentage,
    MIN(wh.CreateDate) as FirstOrderDate,
    MAX(wh.LastActivityDate) as LastActivityDate,
    p.Name as ProgramName
FROM PLUS.pls.vWOHeader wh
INNER JOIN PLUS.pls.vProgram p ON wh.ProgramID = p.ID
LEFT JOIN PLUS.pls.vCodeStatus s ON wh.StatusID = s.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY wh.StatusID, s.Name, s.Description, p.Name
ORDER BY OrderCount DESC;

-- Query 6: Work Order Units and Processing
SELECT 
    wu.ID as UnitID,
    wu.WorkOrderID,
    wu.SerialNo,
    wu.PartNo,
    wu.StatusID,
    wu.CreateDate,
    wu.LastActivityDate,
    wh.OrderNo as WorkOrderNumber,
    p.Name as ProgramName
FROM PLUS.pls.vWOUnit wu
INNER JOIN PLUS.pls.vWOHeader wh ON wu.WorkOrderID = wh.ID
INNER JOIN PLUS.pls.vProgram p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
AND wu.CreateDate >= DATEADD(day, -90, GETDATE())
ORDER BY wu.CreateDate DESC;