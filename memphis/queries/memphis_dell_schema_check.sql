-- =====================================================
-- DELL SCHEMA DISCOVERY - CHECK vPartTransaction COLUMNS
-- =====================================================

-- Check what columns exist in vPartTransaction
SELECT TOP 1 * FROM pls.vPartTransaction;

-- Alternative: Check if workstation info is in a different table
-- Check vWOHeader for workstation info
SELECT TOP 5 
    wh.WorkstationDescription,
    wh.ProgramID,
    p.Name as ProgramName
FROM pls.vWOHeader wh
INNER JOIN pls.vProgram p ON wh.ProgramID = p.ID
WHERE p.ID = 10053  -- DELL program
  AND wh.WorkstationDescription IS NOT NULL;

























