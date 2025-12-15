-- ===============================================
-- MEMPHIS SITE SAFE QUERIES - SELECT ALL COLUMNS
-- Using * to avoid column name issues
-- ===============================================

-- Query 1: Program Attributes (All Columns)
SELECT 
    pa.*,
    p.Name as ProgramName
FROM pls.vProgramAttribute pa
INNER JOIN PLUS.pls.Program p ON pa.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS';

-- Query 2: Customer Details (All Columns)
SELECT 
    c.*
FROM pls.vCodeCustomer c
WHERE c.ID IN (37, 43);  -- Direct Customer IDs for DELL and ADT

-- Query 3: Address Details (All Columns)
SELECT 
    a.*
FROM pls.vCodeAddress a
WHERE a.ID IN (312160, 504171);  -- Direct Address IDs for DELL and ADT

-- Query 4: User Information (All Columns)
SELECT 
    u.*
FROM pls.vUser u
WHERE u.ID = 2;  -- Direct User ID

-- Query 5: Work Order Headers (All Columns) - Limited to recent
SELECT TOP 20
    wh.*,
    p.Name as ProgramName
FROM pls.vWOHeader wh
INNER JOIN PLUS.pls.Program p ON wh.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
ORDER BY wh.CreateDate DESC;
