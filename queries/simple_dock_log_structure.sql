-- =====================================================
-- SIMPLE DOCK LOG STRUCTURE INVESTIGATION  
-- =====================================================
-- First check what fields exist in RODockLog

-- Check RODockLog columns and sample data
SELECT TOP 5 * 
FROM Plus.pls.RODockLog 
WHERE ProgramID = 10053
ORDER BY CreateDate DESC;

-- Check what fields might connect to other tables
SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'RODockLog' 
AND TABLE_SCHEMA = 'pls'
ORDER BY ORDINAL_POSITION;






