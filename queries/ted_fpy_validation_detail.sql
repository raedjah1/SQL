-- ============================================================================
-- FPY VALIDATION QUERY - Show Individual Serials with Test Sequences
-- ============================================================================
-- Purpose: Validate FPY logic by showing each serial's test sequence
-- Use this to verify that FPY classification is correct
-- Note: Uses AsOf (reliable timestamp) instead of StartTime (has corrupted dates)
-- ============================================================================

SELECT 
    d.SerialNumber,
    COUNT(*) AS Test_Count,
    MIN(d.AsOf) AS First_Test_Time,
    MAX(d.AsOf) AS Last_Test_Time,
    
    -- First FICORE test result (determines FPY)
    (SELECT TOP 1 d2.Result 
     FROM redw.tia.DataWipeResult d2 
     WHERE d2.SerialNumber = d.SerialNumber 
       AND d2.Program = 'DELL_MEM'
       AND d2.MachineName = 'FICORE'
     ORDER BY d2.AsOf ASC) AS First_FiCore_Result,
    
    -- When first FICORE test happened
    (SELECT TOP 1 d2.AsOf 
     FROM redw.tia.DataWipeResult d2 
     WHERE d2.SerialNumber = d.SerialNumber 
       AND d2.Program = 'DELL_MEM'
       AND d2.MachineName = 'FICORE'
     ORDER BY d2.AsOf ASC) AS First_FiCore_Time,
    
    -- Count of FICORE tests
    (SELECT COUNT(*) 
     FROM redw.tia.DataWipeResult d2 
     WHERE d2.SerialNumber = d.SerialNumber 
       AND d2.Program = 'DELL_MEM'
       AND d2.MachineName = 'FICORE') AS FiCore_Test_Count,
    
    -- FPY Status based on first FICORE test
    CASE 
        -- No FICORE test at all
        WHEN NOT EXISTS (SELECT 1 FROM redw.tia.DataWipeResult d2 
                        WHERE d2.SerialNumber = d.SerialNumber 
                          AND d2.Program = 'DELL_MEM'
                          AND d2.MachineName = 'FICORE')
        THEN 'NO FICORE TEST'
        
        -- First FICORE test = PASS
        WHEN (SELECT TOP 1 d2.Result 
              FROM redw.tia.DataWipeResult d2 
              WHERE d2.SerialNumber = d.SerialNumber 
                AND d2.Program = 'DELL_MEM'
                AND d2.MachineName = 'FICORE'
              ORDER BY d2.AsOf ASC) IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
        THEN 'FPY'
        
        -- First FICORE test = FAIL
        WHEN (SELECT TOP 1 d2.Result 
              FROM redw.tia.DataWipeResult d2 
              WHERE d2.SerialNumber = d.SerialNumber 
                AND d2.Program = 'DELL_MEM'
                AND d2.MachineName = 'FICORE'
              ORDER BY d2.AsOf ASC) IN ('FAIL', 'FAILED', 'Failed', 'Fail')
        THEN 'NOT FPY (FAIL)'
        
        -- First FICORE test = NA/ABORT
        WHEN (SELECT TOP 1 d2.Result 
              FROM redw.tia.DataWipeResult d2 
              WHERE d2.SerialNumber = d.SerialNumber 
                AND d2.Program = 'DELL_MEM'
                AND d2.MachineName = 'FICORE'
              ORDER BY d2.AsOf ASC) IN ('NA', 'ABORT', 'CANCELLED')
        THEN 'NOT FPY (INCOMPLETE)'
        
        ELSE 'NOT FPY (OTHER)'
    END AS FPY_Status,
    
    -- Complete test sequence
    STRING_AGG(d.Result, ' → ') WITHIN GROUP (ORDER BY d.AsOf) AS Result_Sequence,
    
    -- Machine sequence (shows which machine was used for each test)
    STRING_AGG(d.MachineName, ' → ') WITHIN GROUP (ORDER BY d.AsOf) AS Machine_Sequence,
    
    -- Pass/Fail counts
    SUM(CASE WHEN d.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New') THEN 1 ELSE 0 END) AS Pass_Count,
    SUM(CASE WHEN d.Result IN ('FAIL', 'FAILED', 'Failed', 'Fail') THEN 1 ELSE 0 END) AS Fail_Count,
    SUM(CASE WHEN d.Result IN ('NA', 'ABORT', 'CANCELLED') THEN 1 ELSE 0 END) AS NA_Count
FROM redw.tia.DataWipeResult d
WHERE d.Program = 'DELL_MEM'
  AND d.AsOf >= '2025-10-01'
  AND d.AsOf < '2025-11-01'
GROUP BY d.SerialNumber
HAVING COUNT(*) > 1  -- Show only units with multiple tests
ORDER BY Test_Count DESC, SerialNumber;

-- ============================================================================
-- Expected Results Examples:
-- ============================================================================
-- SerialNumber: 8GMV564
-- Test_Count: 31
-- First_Test_Result: PASS
-- FPY_Status: FPY
-- Result_Sequence: PASS then PASS then PASS (31 times)
--
-- SerialNumber: 2FBCZ44
-- Test_Count: 43
-- First_Test_Result: FAIL
-- FPY_Status: NOT FPY (FAIL)
-- Result_Sequence: FAIL then FAIL then FAIL eventually PASS then PASS
--
-- SerialNumber: 60FVMW3
-- Test_Count: 19
-- First_Test_Result: PASS
-- FPY_Status: FPY
-- Result_Sequence: PASS then PASS then FAIL then FAIL (degrades over time)
-- ============================================================================

