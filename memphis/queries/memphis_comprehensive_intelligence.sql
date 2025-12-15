-- ===============================================
-- MEMPHIS SITE COMPREHENSIVE INTELLIGENCE QUERIES
-- Using Correct Schema: pls.vViewName
-- ===============================================

-- PHASE 1: INFRASTRUCTURE & PROGRAMS
-- ===================================

-- Query 1: Program Attributes and Configuration
SELECT 
    pa.ID,
    pa.ProgramID,
    pa.Attribute,
    pa.Value,
    pa.Username,
    pa.CreateDate,
    pa.LastActivityDate,
    p.Name as ProgramName
FROM pls.vProgramAttribute pa
INNER JOIN PLUS.pls.Program p ON pa.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY p.Name, pa.Attribute;

-- Query 2: Customer Details
SELECT 
    c.*
FROM pls.vCodeCustomer c
WHERE c.ID IN (SELECT DISTINCT CustomerID FROM PLUS.pls.Program WHERE Site = 'MEMPHIS');

-- Query 3: Address and Location Details
SELECT 
    a.*
FROM pls.vCodeAddress a
WHERE a.ID IN (SELECT DISTINCT AddressID FROM PLUS.pls.Program WHERE Site = 'MEMPHIS');

-- Query 4: User Information
SELECT 
    u.*
FROM pls.vUser u
WHERE u.ID IN (SELECT DISTINCT UserID FROM PLUS.pls.Program WHERE Site = 'MEMPHIS');

-- PHASE 2: WORK ORDERS & OPERATIONS
-- =================================

-- Query 5A: Work Order Summary Statistics
SELECT 
    p.Name as ProgramName,
    COUNT(*) as TotalWorkOrders,
    MIN(wh.CreateDate) as EarliestOrder,
    MAX(wh.CreateDate) as LatestOrder,
    COUNT(DISTINCT wh.StatusDescription) as UniqueStatuses,
    COUNT(DISTINCT wh.PartNo) as UniqueParts,
    COUNT(CASE WHEN wh.IsPass = 1 THEN 1 END) as PassedOrders,
    COUNT(CASE WHEN wh.IsPass = 0 THEN 1 END) as FailedOrders,
    ROUND(COUNT(CASE WHEN wh.IsPass = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as PassRate
FROM pls.vWOHeader wh
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY p.Name;

-- Query 5B: Recent Work Orders Sample (Last 50)
SELECT TOP 50
    wh.ID,
    wh.CustomerReference,
    wh.PartNo,
    wh.SerialNo,
    wh.StatusDescription,
    wh.IsPass,
    wh.WorkstationDescription,
    wh.CreateDate,
    wh.LastActivityDate,
    wh.Username,
    p.Name as ProgramName
FROM pls.vWOHeader wh
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY wh.CreateDate DESC;

-- Query 6: Work Order Lines (Component Consumption)
SELECT TOP 50
    wl.ID as LineID,
    wl.WOHeaderID,
    wl.ComponentPartNo,
    wl.QtyRequested,
    wl.QtyConsumed,
    wl.StatusDescription as LineStatus,
    wl.Username as LineUser,
    wl.CreateDate as LineCreateDate,
    p.Name as ProgramName
FROM pls.vWOLine wl
INNER JOIN pls.vWOHeader wh ON wl.WOHeaderID = wh.ID
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY wl.CreateDate DESC;

-- Query 7: Work Order Units (Serial Number Consumption)
SELECT TOP 50
    wu.ID as UnitID,
    wu.WOLineID,
    wu.SerialNo,
    wu.QtyIssued,
    wu.QtyConsumed,
    wu.ConsumeWorkstationDescription,
    wu.PartLocationNo,
    wu.ConsumedUserName,
    wu.ConsumedDate,
    wl.ComponentPartNo,
    p.Name as ProgramName
FROM pls.vWOUnit wu
INNER JOIN pls.vWOLine wl ON wu.WOLineID = wl.ID
INNER JOIN pls.vWOHeader wh ON wl.WOHeaderID = wh.ID
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY wu.CreateDate DESC;

-- PHASE 3: PARTS & INVENTORY
-- ===========================

-- Query 8: Parts Information
SELECT DISTINCT
    pn.*
FROM pls.vPartNo pn
INNER JOIN pls.vWOHeader wh ON pn.PartNo = wh.PartNo
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS';

-- Query 9: Part Serial Numbers
SELECT TOP 50
    ps.*,
    p.Name as ProgramName
FROM pls.vPartSerial ps
INNER JOIN pls.vWOUnit wu ON ps.SerialNo = wu.SerialNo
INNER JOIN pls.vWOLine wl ON wu.WOLineID = wl.ID
INNER JOIN pls.vWOHeader wh ON wl.WOHeaderID = wh.ID
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY ps.CreateDate DESC;

-- Query 10: Part Transactions (Fixed to use ProgramID directly)
SELECT TOP 100
    pt.*,
    p.Name as ProgramName
FROM pls.vPartTransaction pt
INNER JOIN PLUS.pls.Program p ON pt.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY pt.CreateDate DESC;

-- PHASE 4: QUALITY & WORKSTATIONS
-- ================================

-- Query 11: Workstation Information (Simplified approach)
SELECT DISTINCT
    wh.WorkstationDescription as WorkstationName,
    COUNT(*) as OrderCount,
    p.Name as ProgramName
FROM pls.vWOHeader wh
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
AND wh.WorkstationDescription IS NOT NULL
GROUP BY wh.WorkstationDescription, p.Name
ORDER BY OrderCount DESC;

-- Query 12: Work Order Status and Performance Analysis
SELECT 
    wh.StatusDescription,
    wh.WorkstationDescription,
    wh.IsPass,
    COUNT(*) as OrderCount,
    ROUND(AVG(CAST(wh.IsPass as FLOAT)) * 100, 2) as PassRate,
    p.Name as ProgramName
FROM pls.vWOHeader wh
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY wh.StatusDescription, wh.WorkstationDescription, wh.IsPass, p.Name
ORDER BY OrderCount DESC;

-- Query 13: QA Check Audits (Fixed with correct relationship)
SELECT TOP 50
    qa.*,
    p.Name as ProgramName
FROM pls.vQACheckAudit qa
INNER JOIN PLUS.pls.Program p ON qa.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY qa.CreateDate DESC;

-- PHASE 5: ORDERS & CUSTOMER OPERATIONS
-- ======================================

-- Query 14: Repair Orders (RO) - Fixed
SELECT TOP 50
    ro.*,
    p.Name as ProgramName
FROM pls.vROHeader ro
INNER JOIN PLUS.pls.Program p ON ro.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY ro.CreateDate DESC;

-- Query 15: Sales Orders (SO) - Fixed
SELECT TOP 50
    so.*,
    p.Name as ProgramName
FROM pls.vSOHeader so
INNER JOIN PLUS.pls.Program p ON so.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY so.CreateDate DESC;

-- PHASE 6: CASE MANAGEMENT & ISSUES
-- ==================================

-- Query 16: Case Management - Fixed
SELECT TOP 50
    cm.*,
    p.Name as ProgramName
FROM pls.vCaseMgt cm
INNER JOIN PLUS.pls.Program p ON cm.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY cm.CreateDate DESC;

-- Query 17: Tracking and Logistics - Fixed
SELECT TOP 50
    th.*,
    p.Name as ProgramName
FROM pls.vTrackingHeader th
INNER JOIN PLUS.pls.Program p ON th.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY th.CreateDate DESC;
