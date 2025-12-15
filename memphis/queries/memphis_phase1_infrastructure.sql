-- ===============================================
-- MEMPHIS SITE INTELLIGENCE - PHASE 1
-- CORE SITE INFRASTRUCTURE & RELATIONSHIPS
-- ===============================================

-- Query 1: Complete Program Details (Start with basic Program table that we know works)
SELECT 
    p.ID,
    p.Name as ProgramName,
    p.Site,
    p.TimeZone,
    p.AddressID,
    p.CustomerID,
    p.UserID,
    p.CreateDate,
    p.LastActivityDate,
    p.StatusID,
    p.Region
FROM PLUS.pls.Program p
WHERE p.Site = 'MEMPHIS'
ORDER BY p.CreateDate;

-- Query 2: Program Attributes (Let's explore what additional data we can get)
SELECT 
    pa.*,
    p.Name as ProgramName
FROM PLUS.pls.vProgramAttribute pa
INNER JOIN PLUS.pls.Program p ON pa.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY p.Name, pa.AttributeName;

-- Query 3: Customer Information (if available through views)
SELECT TOP 10 * FROM PLUS.pls.vCodeCustomer
WHERE ID IN (SELECT DISTINCT CustomerID FROM PLUS.pls.Program WHERE Site = 'MEMPHIS');