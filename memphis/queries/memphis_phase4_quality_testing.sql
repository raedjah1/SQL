-- ===============================================
-- MEMPHIS SITE INTELLIGENCE - PHASE 4
-- QUALITY & TESTING ANALYSIS
-- ===============================================

-- Query 10: Quality Test Results and Pass/Fail Rates
SELECT 
    tr.TestName,
    tr.TestType,
    tr.TestCategory,
    COUNT(*) as TotalTests,
    COUNT(CASE WHEN tr.Result = 'PASS' OR tr.IsPass = 1 THEN 1 END) as PassCount,
    COUNT(CASE WHEN tr.Result = 'FAIL' OR tr.IsPass = 0 THEN 1 END) as FailCount,
    ROUND(COUNT(CASE WHEN tr.Result = 'PASS' OR tr.IsPass = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as PassRate,
    AVG(tr.TestDuration) as AvgTestDuration,
    p.Name as ProgramName,
    MIN(tr.CreateDate) as FirstTest,
    MAX(tr.CreateDate) as LastTest
FROM PLUS.pls.TestResult tr
INNER JOIN PLUS.pls.WorkOrder wo ON tr.WorkOrderID = wo.ID
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY tr.TestName, tr.TestType, tr.TestCategory, p.Name
ORDER BY TotalTests DESC;

-- Query 11: Workstation Performance at Memphis
SELECT 
    ws.ID as WorkstationID,
    ws.Name as WorkstationName,
    ws.Description as WorkstationDescription,
    ws.Type as WorkstationType,
    ws.Location,
    ws.Capacity,
    COUNT(*) as OrdersProcessed,
    COUNT(CASE WHEN wo.StatusID = 4 THEN 1 END) as CompletedOrders,
    ROUND(COUNT(CASE WHEN wo.StatusID = 4 THEN 1 END) * 100.0 / COUNT(*), 2) as CompletionRate,
    AVG(DATEDIFF(minute, wo.StartTime, wo.EndTime)) as AvgProcessingMinutes,
    p.Name as ProgramName,
    MIN(wo.CreateDate) as FirstOrder,
    MAX(wo.LastActivityDate) as LastActivity
FROM PLUS.pls.WorkOrder wo
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
LEFT JOIN PLUS.pls.Workstation ws ON wo.WorkstationID = ws.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY ws.ID, ws.Name, ws.Description, ws.Type, ws.Location, ws.Capacity, p.Name
ORDER BY OrdersProcessed DESC;

-- Query 12: Quality Defects and Failure Analysis
SELECT 
    df.DefectCode,
    df.DefectDescription,
    df.DefectCategory,
    df.Severity,
    COUNT(*) as DefectCount,
    COUNT(DISTINCT wo.ID) as AffectedWorkOrders,
    COUNT(DISTINCT pt.PartNumber) as AffectedParts,
    p.Name as ProgramName,
    AVG(df.RepairTime) as AvgRepairTime,
    SUM(df.RepairCost) as TotalRepairCost
FROM PLUS.pls.Defect df
INNER JOIN PLUS.pls.WorkOrder wo ON df.WorkOrderID = wo.ID
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
LEFT JOIN PLUS.pls.Part pt ON wo.PartID = pt.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY df.DefectCode, df.DefectDescription, df.DefectCategory, df.Severity, p.Name
ORDER BY DefectCount DESC;
