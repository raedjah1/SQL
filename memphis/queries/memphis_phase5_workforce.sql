-- ===============================================
-- MEMPHIS SITE INTELLIGENCE - PHASE 5
-- WORKFORCE & USER ACTIVITY
-- ===============================================

-- Query 13: User Activity and Workforce Analysis
SELECT 
    u.ID as UserID,
    u.UserName,
    u.FirstName + ' ' + u.LastName as FullName,
    u.Email,
    u.Department,
    u.Role,
    u.Shift,
    COUNT(*) as WorkOrdersHandled,
    COUNT(CASE WHEN wo.StatusID = 4 THEN 1 END) as CompletedOrders,
    ROUND(COUNT(CASE WHEN wo.StatusID = 4 THEN 1 END) * 100.0 / COUNT(*), 2) as CompletionRate,
    MIN(wo.CreateDate) as FirstActivity,
    MAX(wo.LastActivityDate) as LastActivity,
    DATEDIFF(day, MIN(wo.CreateDate), MAX(wo.LastActivityDate)) as ActiveDays,
    p.Name as ProgramName
FROM PLUS.pls.WorkOrder wo
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
LEFT JOIN PLUS.pls.User u ON wo.UserID = u.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY u.ID, u.UserName, u.FirstName, u.LastName, u.Email, u.Department, u.Role, u.Shift, p.Name
ORDER BY WorkOrdersHandled DESC;

-- Query 14: Shift Patterns and Activity Times
SELECT 
    DATEPART(hour, wo.CreateDate) as HourOfDay,
    DATENAME(weekday, wo.CreateDate) as DayOfWeek,
    COUNT(*) as OrderCount,
    COUNT(DISTINCT u.UserID) as ActiveUsers,
    COUNT(CASE WHEN wo.StatusID = 4 THEN 1 END) as CompletedOrders,
    p.Name as ProgramName,
    AVG(DATEDIFF(minute, wo.CreateDate, wo.LastActivityDate)) as AvgProcessingMinutes
FROM PLUS.pls.WorkOrder wo
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
LEFT JOIN PLUS.pls.User u ON wo.UserID = u.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY DATEPART(hour, wo.CreateDate), DATENAME(weekday, wo.CreateDate), p.Name
ORDER BY HourOfDay, DayOfWeek;

-- Query 15: Team Performance and Collaboration
SELECT 
    u1.Department as Department,
    u1.Role as Role,
    u1.Shift as Shift,
    COUNT(DISTINCT u1.ID) as TeamSize,
    COUNT(*) as TotalWorkOrders,
    AVG(DATEDIFF(day, wo.CreateDate, COALESCE(wo.CompleteDate, GETDATE()))) as AvgProcessingDays,
    COUNT(CASE WHEN wo.StatusID = 4 THEN 1 END) as CompletedOrders,
    ROUND(COUNT(CASE WHEN wo.StatusID = 4 THEN 1 END) * 100.0 / COUNT(*), 2) as TeamCompletionRate,
    p.Name as ProgramName
FROM PLUS.pls.WorkOrder wo
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
LEFT JOIN PLUS.pls.User u1 ON wo.UserID = u1.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY u1.Department, u1.Role, u1.Shift, p.Name
ORDER BY TotalWorkOrders DESC;
