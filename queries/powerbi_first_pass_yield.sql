-- ============================================================================
-- POWER BI FIRST PASS YIELD - INLINE QUERY FORMAT
-- ============================================================================
-- Definition: FPY with Total Pass Yield and PASS breakdown (Y/N)
-- Use this query directly in Power BI for FPY dashboard
-- ============================================================================

SELECT 
    CAST(wm.First_FiCore_Date AS DATE) AS Test_Date,
    wm.Program,
    wm.TestArea,
    wm.MachineName,
    wm.Family,
    wm.LOB,
    COUNT(*) AS Total_Units_Tested,
    
    -- FPY Metrics
    SUM(CASE WHEN wm.FPY_Status = 'FPY' THEN 1 ELSE 0 END) AS FPY_Units,
    SUM(CASE WHEN wm.FPY_Status LIKE 'NOT_FPY%' THEN 1 ELSE 0 END) AS Non_FPY_Units,
    CAST(
        SUM(CASE WHEN wm.FPY_Status = 'FPY' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(*), 0) 
        AS DECIMAL(5,2)
    ) AS FPY_Rate_Percent,
    
    -- Total Pass Yield (units that eventually passed)
    SUM(wm.Eventually_Passed) AS Units_Eventually_Passed,
    CAST(
        SUM(wm.Eventually_Passed) * 100.0 / 
        NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS Total_Pass_Yield_Percent,
    
    -- PASS breakdown: Y (single test) vs N (retested)
    SUM(CASE WHEN wm.FPY_Status = 'FPY' AND wm.TotalFiCoreAttempts = 1 THEN 1 ELSE 0 END) AS PASS_Y_Single_Test,
    SUM(CASE WHEN wm.FPY_Status = 'FPY' AND wm.TotalFiCoreAttempts > 1 THEN 1 ELSE 0 END) AS PASS_N_Retested,
    
    -- FAIL breakdown (all are N - failed on first test)
    SUM(CASE WHEN wm.FPY_Status = 'NOT_FPY_FAIL' THEN 1 ELSE 0 END) AS FAIL_N,
    
    -- Breakdown of failures
    SUM(CASE WHEN wm.FPY_Status = 'NOT_FPY_FAIL' THEN 1 ELSE 0 END) AS First_FiCore_Failed,
    SUM(CASE WHEN wm.FPY_Status = 'NOT_FPY_INCOMPLETE' THEN 1 ELSE 0 END) AS First_FiCore_Incomplete,
    SUM(CASE WHEN wm.FPY_Status = 'NOT_FPY_OTHER' THEN 1 ELSE 0 END) AS Other_Issues,
    
    -- Additional metrics
    SUM(CASE WHEN wm.TotalFiCoreAttempts > 1 THEN 1 ELSE 0 END) AS Units_With_FiCore_Retests,
    AVG(CAST(wm.TotalFiCoreAttempts AS DECIMAL(10,2))) AS Avg_FiCore_Tests_Per_Unit,
    MAX(wm.TotalFiCoreAttempts) AS Max_FiCore_Tests_Single_Unit,
    
    -- Cost impact
    SUM(CASE WHEN wm.FPY_Status = 'FPY' THEN wm.Standard_Cost ELSE 0 END) AS FPY_Value,
    SUM(CASE WHEN wm.FPY_Status LIKE 'NOT_FPY%' THEN wm.Standard_Cost ELSE 0 END) AS Non_FPY_Value,
    SUM(wm.Standard_Cost) AS Total_Value_Tested
FROM (
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
    FROM (
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
                -- SUCCESS: First FICORE test PASS
                WHEN AttemptNumber = 1 
                     AND Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
                THEN 'FPY'
                
                -- NOT FPY: First FICORE test failed
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
        FROM (
            -- Get all FICORE test attempts with attempt numbering
            SELECT 
                d.SerialNumber,
                d.Result,
                d.Program,
                d.TestArea,
                d.MachineName,
                d.AsOf AS TestDate,
                ROW_NUMBER() OVER (
                    PARTITION BY d.SerialNumber 
                    ORDER BY d.AsOf ASC
                ) AS AttemptNumber,
                COUNT(*) OVER (
                    PARTITION BY d.SerialNumber
                ) AS TotalFiCoreAttempts
            FROM redw.tia.DataWipeResult d
            WHERE d.Program = 'DELL_MEM'
              AND d.MachineName = 'FICORE'
        ) AS FiCoreTestAttempts
        WHERE AttemptNumber = 1
    ) AS fa
    LEFT JOIN (
        -- Check if unit EVER passed (for Total Pass Yield)
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
    ) AS eps ON fa.SerialNumber = eps.SerialNumber
    LEFT JOIN Plus.pls.PartSerial ps 
        ON fa.SerialNumber = ps.SerialNo
        AND ps.ProgramID = 10053
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
) AS wm
GROUP BY CAST(wm.First_FiCore_Date AS DATE), wm.Program, wm.TestArea, wm.MachineName, wm.Family, wm.LOB
ORDER BY Test_Date, Program, TestArea, Family, LOB;

