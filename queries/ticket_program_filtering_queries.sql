-- ============================================
-- TICKET/CASE FILTERING BY PROGRAM STATUS
-- ============================================
-- This query helps filter tickets/cases to see what's open on which program
-- Based on Memphis manufacturing intelligence analysis

-- ============================================
-- 1. ACTIVE CASES BY PROGRAM (CASE MANAGEMENT)
-- ============================================
-- Shows open cases organized by program for quality management
SELECT 
    'CASE MANAGEMENT' as SystemType,
    c.ProgramID,
    p.Name as ProgramName,
    c.Status as CaseStatus,
    COUNT(*) as OpenCases,
    COUNT(DISTINCT c.Username) as AssignedOperators,
    MIN(c.CreateDate) as OldestCase,
    MAX(c.CreateDate) as NewestCase,
    -- Case priority based on age
    CASE 
        WHEN DATEDIFF(day, MIN(c.CreateDate), GETDATE()) > 7 THEN 'HIGH PRIORITY - Over 7 days'
        WHEN DATEDIFF(day, MIN(c.CreateDate), GETDATE()) > 3 THEN 'MEDIUM PRIORITY - 3-7 days'
        ELSE 'LOW PRIORITY - Recent'
    END as PriorityLevel
FROM pls.[Case] c
INNER JOIN PLUS.pls.Program p ON c.ProgramID = p.ID
WHERE c.Status IN ('Open', 'Active', 'In Progress', 'Assigned', 'New')
  AND p.Site = 'MEMPHIS'
GROUP BY c.ProgramID, p.Name, c.Status
ORDER BY OpenCases DESC, ProgramName;

-- ============================================
-- 2. WORK ORDER STATUS BY PROGRAM (MANUFACTURING TICKETS)
-- ============================================
-- Shows work order status distribution by program
SELECT 
    'WORK ORDERS' as SystemType,
    wo.ProgramID,
    p.Name as ProgramName,
    wo.StatusDescription as TicketStatus,
    COUNT(*) as TicketCount,
    COUNT(DISTINCT wo.Username) as AssignedOperators,
    -- Performance metrics
    AVG(CASE WHEN wo.IsPass = 1 THEN 1.0 ELSE 0.0 END) * 100 as PassRate,
    DATEDIFF(day, MIN(wo.CreateDate), GETDATE()) as OldestTicketDays,
    DATEDIFF(day, MAX(wo.CreateDate), GETDATE()) as NewestTicketDays
FROM pls.vWOHeader wo
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
WHERE wo.StatusDescription IN ('HOLD', 'WIP', 'Active', 'Released', 'Started', 'In Progress')
  AND p.Site = 'MEMPHIS'
  AND wo.CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
GROUP BY wo.ProgramID, p.Name, wo.StatusDescription
ORDER BY TicketCount DESC, ProgramName;

-- ============================================
-- 3. REPAIR ORDER STATUS BY PROGRAM (FSR TICKETS)
-- ============================================
-- Shows repair order status for FSR work
SELECT 
    'REPAIR ORDERS' as SystemType,
    ro.ProgramID,
    p.Name as ProgramName,
    ro.StatusDescription as TicketStatus,
    COUNT(*) as TicketCount,
    COUNT(DISTINCT ro.Username) as AssignedOperators,
    -- Performance metrics
    AVG(CASE WHEN ro.IsPass = 1 THEN 1.0 ELSE 0.0 END) * 100 as PassRate,
    DATEDIFF(day, MIN(ro.CreateDate), GETDATE()) as OldestTicketDays
FROM pls.vROUnit ro
INNER JOIN PLUS.pls.Program p ON ro.ProgramID = p.ID
WHERE ro.StatusDescription IN ('Open', 'Active', 'In Progress', 'Assigned', 'New')
  AND p.Site = 'MEMPHIS'
  AND ro.CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
GROUP BY ro.ProgramID, p.Name, ro.StatusDescription
ORDER BY TicketCount DESC, ProgramName;

-- ============================================
-- 4. COMPREHENSIVE PROGRAM STATUS SUMMARY
-- ============================================
-- Overall view of all open tickets by program
WITH ProgramStatus AS (
    -- Case Management
    SELECT 
        c.ProgramID,
        p.Name as ProgramName,
        'CASE' as TicketType,
        COUNT(*) as OpenTickets
    FROM pls.[Case] c
    INNER JOIN PLUS.pls.Program p ON c.ProgramID = p.ID
    WHERE c.Status IN ('Open', 'Active', 'In Progress', 'Assigned', 'New')
      AND p.Site = 'MEMPHIS'
    GROUP BY c.ProgramID, p.Name
    
    UNION ALL
    
    -- Work Orders
    SELECT 
        wo.ProgramID,
        p.Name as ProgramName,
        'WORK_ORDER' as TicketType,
        COUNT(*) as OpenTickets
    FROM pls.vWOHeader wo
    INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
    WHERE wo.StatusDescription IN ('HOLD', 'WIP', 'Active', 'Released', 'Started', 'In Progress')
      AND p.Site = 'MEMPHIS'
      AND wo.CreateDate >= DATEADD(day, -30, GETDATE())
    GROUP BY wo.ProgramID, p.Name
    
    UNION ALL
    
    -- Repair Orders
    SELECT 
        ro.ProgramID,
        p.Name as ProgramName,
        'REPAIR_ORDER' as TicketType,
        COUNT(*) as OpenTickets
    FROM pls.vROUnit ro
    INNER JOIN PLUS.pls.Program p ON ro.ProgramID = p.ID
    WHERE ro.StatusDescription IN ('Open', 'Active', 'In Progress', 'Assigned', 'New')
      AND p.Site = 'MEMPHIS'
      AND ro.CreateDate >= DATEADD(day, -30, GETDATE())
    GROUP BY ro.ProgramID, p.Name
)
SELECT 
    ProgramID,
    ProgramName,
    SUM(CASE WHEN TicketType = 'CASE' THEN OpenTickets ELSE 0 END) as OpenCases,
    SUM(CASE WHEN TicketType = 'WORK_ORDER' THEN OpenTickets ELSE 0 END) as OpenWorkOrders,
    SUM(CASE WHEN TicketType = 'REPAIR_ORDER' THEN OpenTickets ELSE 0 END) as OpenRepairOrders,
    SUM(OpenTickets) as TotalOpenTickets,
    -- Program priority based on total open tickets
    CASE 
        WHEN SUM(OpenTickets) > 1000 THEN 'CRITICAL - High Volume'
        WHEN SUM(OpenTickets) > 500 THEN 'HIGH - Medium Volume'
        WHEN SUM(OpenTickets) > 100 THEN 'MEDIUM - Low Volume'
        ELSE 'LOW - Minimal Volume'
    END as ProgramPriority
FROM ProgramStatus
GROUP BY ProgramID, ProgramName
ORDER BY TotalOpenTickets DESC;

-- ============================================
-- 5. ADT PROGRAM SPECIFIC FILTERING
-- ============================================
-- Focus on ADT program tickets (ProgramID = 10068)
SELECT 
    'ADT PROGRAM FOCUS' as FilterType,
    wo.StatusDescription as Status,
    wo.WorkstationDescription as Workstation,
    COUNT(*) as TicketCount,
    COUNT(DISTINCT wo.Username) as Operators,
    MIN(wo.CreateDate) as OldestTicket,
    MAX(wo.CreateDate) as NewestTicket,
    -- ADT specific metrics
    AVG(CASE WHEN wo.IsPass = 1 THEN 1.0 ELSE 0.0 END) * 100 as PassRate
FROM pls.vWOHeader wo
WHERE wo.ProgramID = 10068  -- ADT Program
  AND wo.StatusDescription IN ('HOLD', 'WIP', 'Active', 'Released', 'Started', 'In Progress')
  AND wo.CreateDate >= DATEADD(day, -30, GETDATE())
GROUP BY wo.StatusDescription, wo.WorkstationDescription
ORDER BY TicketCount DESC;

-- ============================================
-- 6. DELL PROGRAM SPECIFIC FILTERING
-- ============================================
-- Focus on DELL program tickets (ProgramID = 10053)
SELECT 
    'DELL PROGRAM FOCUS' as FilterType,
    wo.StatusDescription as Status,
    wo.WorkstationDescription as Workstation,
    COUNT(*) as TicketCount,
    COUNT(DISTINCT wo.Username) as Operators,
    MIN(wo.CreateDate) as OldestTicket,
    MAX(wo.CreateDate) as NewestTicket,
    -- DELL specific metrics
    AVG(CASE WHEN wo.IsPass = 1 THEN 1.0 ELSE 0.0 END) * 100 as PassRate
FROM pls.vWOHeader wo
WHERE wo.ProgramID = 10053  -- DELL Program
  AND wo.StatusDescription IN ('HOLD', 'WIP', 'Active', 'Released', 'Started', 'In Progress')
  AND wo.CreateDate >= DATEADD(day, -30, GETDATE())
GROUP BY wo.StatusDescription, wo.WorkstationDescription
ORDER BY TicketCount DESC;
