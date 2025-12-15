-- ============================================================================
-- TOTAL YIELD QUERY - POWER BI READY
-- ============================================================================
-- Definition: Total Passes / Total Test Attempts for a given period
-- Includes: ALL test instances, not just first attempts
-- Data Source: redw.tia.DataWipeResult
-- Granularity: Individual test attempts
-- Filtering: Use Power BI slicers for Date, Program, Family, LOB
-- Note: Uses AsOf (reliable timestamp) instead of StartTime (has corrupted dates)
-- ============================================================================

WITH AllTestAttempts AS (
    -- Get ALL test attempts (not just first attempts)
    SELECT 
        d.SerialNumber,
        d.Result,
        d.Program,
        d.TestArea,
        d.MachineName,
        d.AsOf AS TestDate,  -- Test processing timestamp (reliable)
        -- Categorize each test result
        CASE 
            -- SUCCESS
            WHEN d.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
            THEN 'PASS'
            
            -- FAILURE (explicit failures)
            WHEN d.Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 
                             'FAIL-fail', 'FAIL (NO CHECKED)', 'Scratch & Dent')
            THEN 'FAIL'
            
            -- FAILURE (hex error codes)
            WHEN d.Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
                 OR d.Result IN ('0000', '21C0', '768A', '762A', '76FF', '76A7', '2112', 
                                '21CE', '21CF', '21AD', 'B113', '76F0', 'B102', 'B116', 
                                '5B85', 'B105', 'B119', '5BFF', '27F1', '27F4', '5B1B', 
                                '6B10', 'B114', '0100', '0820', '0821', '7711', '1A21', 
                                '1A01', '79B0', 'B117', '7710', '79EF', 'FFFF', '1A42', 
                                '1A4F', '79F2', '0823', '0803', '79F4', '79B1', '7648', 
                                '1A02', '1A20', '7933', '79FF', '6B03')
            THEN 'FAIL'
            
            -- FAILURE (explicit errors)
            WHEN d.Result IN ('ERROR', 'error')
            THEN 'FAIL'
            
            -- EXCLUDED (incomplete/aborted tests)
            WHEN d.Result IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
                 OR d.Result IS NULL
            THEN 'EXCLUDED'
            
            -- OTHER (needs investigation)
            ELSE 'OTHER'
        END AS ResultCategory
    FROM redw.tia.DataWipeResult d
    WHERE d.Program = 'DELL_MEM'  -- Focus on Memphis Dell program
),
UnitTestDates AS (
    -- Calculate first touch and last touch dates for each unit
    SELECT 
        d.SerialNumber,
        MIN(d.AsOf) AS First_Touch_Date,
        MAX(d.AsOf) AS Last_Touch_Date,
        COUNT(*) AS Total_Test_Count,
        CASE 
            WHEN COUNT(*) = 1 THEN 'Single'
            ELSE 'Multi'
        END AS Test_Pattern
    FROM redw.tia.DataWipeResult d
    WHERE d.Program = 'DELL_MEM'
      AND d.MachineName = 'FICORE'
    GROUP BY d.SerialNumber
),
WithMetadata AS (
    -- Join to Plus database for Family and LOB
    SELECT 
        ta.SerialNumber,
        ta.Result,
        ta.ResultCategory,
        ta.Program,
        ta.TestArea,
        ta.MachineName,
        ta.TestDate,
        ps.PartNo,
        ISNULL(psa_family.Value, 'Unknown') AS Family,
        ISNULL(psa_lob.Value, 'Unknown') AS LOB,
        CASE 
            WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
            ELSE 0
        END AS Standard_Cost,
        -- First Touch / Last Touch fields
        utd.First_Touch_Date,
        utd.Last_Touch_Date,
        utd.Total_Test_Count,
        utd.Test_Pattern,
        CASE 
            WHEN ta.TestDate = utd.First_Touch_Date AND ta.TestDate = utd.Last_Touch_Date THEN 'Both'
            WHEN ta.TestDate = utd.First_Touch_Date THEN 'First Touch'
            WHEN ta.TestDate = utd.Last_Touch_Date THEN 'Last Touch'
            ELSE 'Middle'
        END AS Touch_Type
    FROM AllTestAttempts ta
    LEFT JOIN UnitTestDates utd ON ta.SerialNumber = utd.SerialNumber
    LEFT JOIN Plus.pls.PartSerial ps 
        ON ta.SerialNumber = ps.SerialNo
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
    CAST(TestDate AS DATE) AS TestDate,  -- For Power BI date slicer
    Program,
    TestArea,
    Family,
    LOB,
    Test_Pattern,  -- 'Single' or 'Multi'
    Touch_Type,    -- 'First Touch', 'Last Touch', 'Both', 'Middle'
    
    -- Total test attempts
    COUNT(*) AS Total_Test_Attempts,
    
    -- Pass/Fail/Excluded breakdown
    SUM(CASE WHEN ResultCategory = 'PASS' THEN 1 ELSE 0 END) AS Total_Passes,
    SUM(CASE WHEN ResultCategory = 'FAIL' THEN 1 ELSE 0 END) AS Total_Failures,
    SUM(CASE WHEN ResultCategory = 'EXCLUDED' THEN 1 ELSE 0 END) AS Excluded_Tests,
    SUM(CASE WHEN ResultCategory = 'OTHER' THEN 1 ELSE 0 END) AS Other_Results,
    
    -- Valid test attempts (exclude incomplete/aborted)
    SUM(CASE WHEN ResultCategory IN ('PASS', 'FAIL') THEN 1 ELSE 0 END) AS Valid_Test_Attempts,
    
    -- Total Yield Rate (Pass / Valid Attempts)
    CAST(
        SUM(CASE WHEN ResultCategory = 'PASS' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN ResultCategory IN ('PASS', 'FAIL') THEN 1 ELSE 0 END), 0)
        AS DECIMAL(5,2)
    ) AS Total_Yield_Percent,
    
    -- Failure Rate
    CAST(
        SUM(CASE WHEN ResultCategory = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN ResultCategory IN ('PASS', 'FAIL') THEN 1 ELSE 0 END), 0)
        AS DECIMAL(5,2)
    ) AS Failure_Rate_Percent,
    
    -- Exclusion Rate
    CAST(
        SUM(CASE WHEN ResultCategory = 'EXCLUDED' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS Exclusion_Rate_Percent,
    
    -- Unique units tested
    COUNT(DISTINCT SerialNumber) AS Unique_Units_Tested,
    
    -- Average attempts per unit
    CAST(
        COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT SerialNumber), 0)
        AS DECIMAL(5,2)
    ) AS Avg_Attempts_Per_Unit,
    
    -- Cost metrics (optional)
    SUM(CASE WHEN ResultCategory = 'PASS' THEN Standard_Cost ELSE 0 END) AS Pass_Value,
    SUM(CASE WHEN ResultCategory = 'FAIL' THEN Standard_Cost ELSE 0 END) AS Fail_Value,
    SUM(Standard_Cost) AS Total_Value_Tested
FROM WithMetadata
GROUP BY CAST(TestDate AS DATE), Program, TestArea, Family, LOB, Test_Pattern, Touch_Type
ORDER BY TestDate, Program, TestArea, Family, LOB, Test_Pattern, Touch_Type;

-- ============================================================================
-- Optional: Additional rollup views
-- ============================================================================

-- Rollup by Family only
-- SELECT 
--     Family,
--     COUNT(*) AS Total_Test_Attempts,
--     SUM(CASE WHEN ResultCategory = 'PASS' THEN 1 ELSE 0 END) AS Total_Passes,
--     SUM(CASE WHEN ResultCategory IN ('PASS', 'FAIL') THEN 1 ELSE 0 END) AS Valid_Attempts,
--     CAST(
--         SUM(CASE WHEN ResultCategory = 'PASS' THEN 1 ELSE 0 END) * 100.0 / 
--         NULLIF(SUM(CASE WHEN ResultCategory IN ('PASS', 'FAIL') THEN 1 ELSE 0 END), 0)
--         AS DECIMAL(5,2)
--     ) AS Total_Yield_Percent,
--     COUNT(DISTINCT SerialNumber) AS Unique_Units
-- FROM WithMetadata
-- GROUP BY Family
-- ORDER BY Total_Yield_Percent DESC;

-- Rollup by LOB only
-- SELECT 
--     LOB,
--     COUNT(*) AS Total_Test_Attempts,
--     SUM(CASE WHEN ResultCategory = 'PASS' THEN 1 ELSE 0 END) AS Total_Passes,
--     SUM(CASE WHEN ResultCategory IN ('PASS', 'FAIL') THEN 1 ELSE 0 END) AS Valid_Attempts,
--     CAST(
--         SUM(CASE WHEN ResultCategory = 'PASS' THEN 1 ELSE 0 END) * 100.0 / 
--         NULLIF(SUM(CASE WHEN ResultCategory IN ('PASS', 'FAIL') THEN 1 ELSE 0 END), 0)
--         AS DECIMAL(5,2)
--     ) AS Total_Yield_Percent,
--     COUNT(DISTINCT SerialNumber) AS Unique_Units
-- FROM WithMetadata
-- GROUP BY LOB
-- ORDER BY Total_Yield_Percent DESC;

-- Overall Total Yield (all programs, all families, all LOBs)
-- SELECT 
--     COUNT(*) AS Total_Test_Attempts,
--     SUM(CASE WHEN ResultCategory = 'PASS' THEN 1 ELSE 0 END) AS Total_Passes,
--     SUM(CASE WHEN ResultCategory IN ('PASS', 'FAIL') THEN 1 ELSE 0 END) AS Valid_Attempts,
--     CAST(
--         SUM(CASE WHEN ResultCategory = 'PASS' THEN 1 ELSE 0 END) * 100.0 / 
--         NULLIF(SUM(CASE WHEN ResultCategory IN ('PASS', 'FAIL') THEN 1 ELSE 0 END), 0)
--         AS DECIMAL(5,2)
--     ) AS Total_Yield_Percent,
--     COUNT(DISTINCT SerialNumber) AS Unique_Units,
--     CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT SerialNumber), 0) AS DECIMAL(5,2)) AS Avg_Attempts_Per_Unit
-- FROM WithMetadata;

-- ============================================================================
-- Time-series view (daily trend)
-- ============================================================================

-- SELECT 
--     CAST(TestDate AS DATE) AS Test_Date,
--     Program,
--     COUNT(*) AS Total_Test_Attempts,
--     SUM(CASE WHEN ResultCategory = 'PASS' THEN 1 ELSE 0 END) AS Total_Passes,
--     CAST(
--         SUM(CASE WHEN ResultCategory = 'PASS' THEN 1 ELSE 0 END) * 100.0 / 
--         NULLIF(SUM(CASE WHEN ResultCategory IN ('PASS', 'FAIL') THEN 1 ELSE 0 END), 0)
--         AS DECIMAL(5,2)
--     ) AS Total_Yield_Percent,
--     COUNT(DISTINCT SerialNumber) AS Unique_Units
-- FROM WithMetadata
-- GROUP BY CAST(TestDate AS DATE), Program
-- ORDER BY Test_Date, Program;

