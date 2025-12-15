-- ===============================================
-- MEMPHIS SITE INTELLIGENCE - PHASE 1 (WORKING QUERIES)
-- Using confirmed working schema references
-- ===============================================

-- Query 1: Basic Program Details (CONFIRMED WORKING)
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

-- Query 2: Let's try to find Work Orders for Memphis programs
SELECT TOP 10
    wh.*
FROM PLUS.pls.vWOHeader wh
WHERE wh.ProgramID IN (SELECT ID FROM PLUS.pls.Program WHERE Site = 'MEMPHIS');

-- Query 3: Alternative - try without PLUS prefix
SELECT TOP 10 * FROM pls.vWOHeader 
WHERE ProgramID IN (SELECT ID FROM PLUS.pls.Program WHERE Site = 'MEMPHIS');

-- Query 4: Let's see if we can get User information
SELECT TOP 10 * FROM PLUS.pls.vUser
WHERE ID IN (SELECT DISTINCT UserID FROM PLUS.pls.Program WHERE Site = 'MEMPHIS');

-- Query 5: Alternative User query
SELECT TOP 10 * FROM pls.vUser
WHERE ID IN (SELECT DISTINCT UserID FROM PLUS.pls.Program WHERE Site = 'MEMPHIS');
