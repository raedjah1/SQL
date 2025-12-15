-- ============================================================================
-- FIRST PASS YIELD (FPY) QUERY - POWER BI READY
-- ============================================================================
-- Definition: A unit is FPY if it passes FiCore on the first test attempt
-- Data Source: redw.tia.DataWipeResult (FICORE tests only)
-- Granularity: Service tag level
-- Filtering: Use Power BI slicers for Date, Program, Family, LOB
-- Note: Uses AsOf (reliable timestamp) instead of StartTime (has corrupted dates)
-- ============================================================================

WITH FiCoreTestAttempts AS (
    -- Get all FICORE test attempts with attempt numbering
    SELECT 
        d.SerialNumber,
        d.Result,
        d.Program,
        d.TestArea,
        d.MachineName,
        d.AsOf AS TestDate,  -- Test processing timestamp (reliable)
        ROW_NUMBER() OVER (
            PARTITION BY d.SerialNumber 
            ORDER BY d.AsOf ASC
        ) AS AttemptNumber,
        COUNT(*) OVER (
            PARTITION BY d.SerialNumber
        ) AS TotalFiCoreAttempts
    FROM redw.tia.DataWipeResult d
    WHERE d.Program = 'DELL_MEM'  -- Focus on Memphis Dell program
      AND d.MachineName = 'FICORE'  -- FICORE tests only
),
FirstFiCoreAttemptOnly AS (
    -- Get only first FICORE attempts
    SELECT 
        SerialNumber,
        Result AS First_FiCore_Result,
        Program,
        TestArea,
        MachineName,
        TestDate AS First_FiCore_Date,
        TotalFiCoreAttempts,
        CASE 
            -- SUCCESS: First FICORE test PASS (subsequent retests don't matter)
            WHEN AttemptNumber = 1 
                 AND Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
            THEN 'FPY'
            
            -- NOT FPY: First FICORE test failed or error
            WHEN AttemptNumber = 1 
                 AND (Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 
                                'FAIL-fail', 'FAIL (NO CHECKED)', 'Scratch & Dent', 
                                'ERROR', 'error')
                      OR Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]')
            THEN 'NOT_FPY_FAIL'
            
            -- NOT FPY: First FICORE test incomplete
            WHEN AttemptNumber = 1 
                 AND Result IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
            THEN 'NOT_FPY_INCOMPLETE'
            
            ELSE 'NOT_FPY_OTHER'
        END AS FPY_Status
    FROM FiCoreTestAttempts
    WHERE AttemptNumber = 1  -- Only analyze first FICORE attempts
),
EventualPassStatus AS (
    -- Check if unit EVER passed (for Total Pass Yield calculation)
    SELECT 
        d.SerialNumber,
        MAX(CASE 
            WHEN d.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
            THEN 1 ELSE 0 
        END) AS Eventually_Passed
    FROM redw.tia.DataWipeResult d
    WHERE d.Program = 'DELL_MEM'
      AND d.MachineName = 'FICORE'
    GROUP BY d.SerialNumber
),
WithMetadata AS (
    -- Join to Plus database for Family and LOB
    SELECT 
        fa.SerialNumber,
        fa.First_FiCore_Result,
        fa.First_FiCore_Date,
        fa.Program,
        fa.TestArea,
        fa.MachineName,
        fa.TotalFiCoreAttempts,
        fa.FPY_Status,
        eps.Eventually_Passed,
        ps.PartNo,
        ISNULL(psa_family.Value, 'Unknown') AS Family,
        ISNULL(psa_lob.Value, 'Unknown') AS LOB,
        CASE 
            WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
            ELSE 0
        END AS Standard_Cost
    FROM FirstFiCoreAttemptOnly fa
    LEFT JOIN EventualPassStatus eps ON fa.SerialNumber = eps.SerialNumber
    LEFT JOIN Plus.pls.PartSerial ps 
        ON fa.SerialNumber = ps.SerialNo
        AND ps.ProgramID = 10053  -- Memphis program
    LEFT JOIN Plus.pls.PartSerialAttribute psa_family 
        ON ps.ID = psa_family.PartSerialID 
        AND psa_family.AttributeID = (
            SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttFamily'
        )
    LEFT JOIN Plus.pls.PartSerialAttribute psa_lob 
        ON ps.ID = psa_lob.PartSerialID 
        AND psa_lob.AttributeID = (
            SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB'
        )
    LEFT JOIN Plus.pls.PartNoAttribute pna 
        ON ps.PartNo = pna.PartNo 
        AND pna.AttributeID = (
            SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'STANDARDCOST'
        )
        AND pna.ProgramID = 10053
)
-- Final aggregation with rollup options
SELECT 
    CAST(First_FiCore_Date AS DATE) AS Test_Date,  -- For Power BI date slicer
    Program,
    TestArea,
    Family,
    LOB,
    COUNT(*) AS Total_Units_Tested,
    SUM(CASE WHEN FPY_Status = 'FPY' THEN 1 ELSE 0 END) AS FPY_Units,
    SUM(CASE WHEN FPY_Status LIKE 'NOT_FPY%' THEN 1 ELSE 0 END) AS Non_FPY_Units,
    
    -- FPY Rate
    CAST(
        SUM(CASE WHEN FPY_Status = 'FPY' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(*), 0) 
        AS DECIMAL(5,2)
    ) AS FPY_Rate_Percent,
    
    -- Total Pass Yield (units that eventually passed)
    SUM(Eventually_Passed) AS Units_Eventually_Passed,
    CAST(
        SUM(Eventually_Passed) * 100.0 / 
        NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS Total_Pass_Yield_Percent,
    
    -- PASS breakdown: Y (single test) vs N (retested)
    SUM(CASE WHEN FPY_Status = 'FPY' AND TotalFiCoreAttempts = 1 THEN 1 ELSE 0 END) AS PASS_Y_Single_Test,
    SUM(CASE WHEN FPY_Status = 'FPY' AND TotalFiCoreAttempts > 1 THEN 1 ELSE 0 END) AS PASS_N_Retested,
    
    -- Breakdown of failures
    SUM(CASE WHEN FPY_Status = 'NOT_FPY_FAIL' THEN 1 ELSE 0 END) AS First_FiCore_Failed,
    SUM(CASE WHEN FPY_Status = 'NOT_FPY_INCOMPLETE' THEN 1 ELSE 0 END) AS First_FiCore_Incomplete,
    SUM(CASE WHEN FPY_Status = 'NOT_FPY_OTHER' THEN 1 ELSE 0 END) AS Other_Issues,
    
    -- Additional metrics
    SUM(CASE WHEN TotalFiCoreAttempts > 1 THEN 1 ELSE 0 END) AS Units_With_FiCore_Retests,
    AVG(CAST(TotalFiCoreAttempts AS DECIMAL(10,2))) AS Avg_FiCore_Tests_Per_Unit,
    MAX(TotalFiCoreAttempts) AS Max_FiCore_Tests_Single_Unit,
    
    -- Cost impact
    SUM(CASE WHEN FPY_Status = 'FPY' THEN Standard_Cost ELSE 0 END) AS FPY_Value,
    SUM(CASE WHEN FPY_Status LIKE 'NOT_FPY%' THEN Standard_Cost ELSE 0 END) AS Non_FPY_Value,
    SUM(Standard_Cost) AS Total_Value_Tested
FROM WithMetadata
GROUP BY CAST(First_FiCore_Date AS DATE), Program, TestArea, Family, LOB
ORDER BY Test_Date, Program, TestArea, Family, LOB;

-- ============================================================================
-- DETAIL VIEW: Individual Serials with Test Sequences (for validation)
-- ============================================================================

-- Uncomment to see individual serial numbers with their FICORE test sequences
/*
SELECT 
    fa.SerialNumber,
    fa.Program,
    fa.TestArea,
    wm.Family,
    wm.LOB,
    fa.TotalFiCoreAttempts AS Test_Count,
    fa.FPY_Status,
    CAST(fa.First_FiCore_Date AS DATE) AS First_Test_Date,
    -- Show FICORE test result sequence
    (SELECT STRING_AGG(d2.Result, ' → ') WITHIN GROUP (ORDER BY d2.AsOf)
     FROM redw.tia.DataWipeResult d2
     WHERE d2.SerialNumber = fa.SerialNumber 
       AND d2.Program = 'DELL_MEM'
       AND d2.MachineName = 'FICORE') AS FiCore_Result_Sequence,
    wm.Standard_Cost
FROM FirstFiCoreAttemptOnly fa
JOIN WithMetadata wm ON fa.SerialNumber = wm.SerialNumber
WHERE fa.TotalFiCoreAttempts > 1  -- Only show units with multiple FICORE tests
ORDER BY fa.TotalFiCoreAttempts DESC, fa.SerialNumber;
*/

-- ============================================================================
-- Optional: Detailed rollup by different levels
-- ============================================================================

-- Rollup by Family only
-- SELECT 
--     Family,
--     COUNT(*) AS Total_Units,
--     SUM(CASE WHEN FPY_Status = 'FPY' THEN 1 ELSE 0 END) AS FPY_Units,
--     CAST(SUM(CASE WHEN FPY_Status = 'FPY' THEN 1 ELSE 0 END) * 100.0 / 
--          NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS FPY_Rate_Percent
-- FROM WithMetadata
-- GROUP BY Family
-- ORDER BY FPY_Rate_Percent DESC;

-- Rollup by LOB only
-- SELECT 
--     LOB,
--     COUNT(*) AS Total_Units,
--     SUM(CASE WHEN FPY_Status = 'FPY' THEN 1 ELSE 0 END) AS FPY_Units,
--     CAST(SUM(CASE WHEN FPY_Status = 'FPY' THEN 1 ELSE 0 END) * 100.0 / 
--          NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS FPY_Rate_Percent
-- FROM WithMetadata
-- GROUP BY LOB
-- ORDER BY FPY_Rate_Percent DESC;

-- Overall FPY (all programs, all families, all LOBs)
-- SELECT 
--     COUNT(*) AS Total_Units,
--     SUM(CASE WHEN FPY_Status = 'FPY' THEN 1 ELSE 0 END) AS FPY_Units,
--     CAST(SUM(CASE WHEN FPY_Status = 'FPY' THEN 1 ELSE 0 END) * 100.0 / 
--          NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS FPY_Rate_Percent
-- FROM WithMetadata;

