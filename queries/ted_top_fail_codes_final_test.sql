-- ============================================================================
-- TOP FAIL CODES - FINAL TEST RECORD ONLY (POWER BI READY)
-- ============================================================================
-- Definition: Report last test record per service tag, grouped by fail code
-- Goal: Final disposition to help prioritize corrective actions
-- Optional Filters: Date range, Family, LOB, MachineName (via Power BI slicers)
-- Note: Uses AsOf (reliable timestamp) instead of StartTime (has corrupted dates)
-- ============================================================================

WITH AllFiCoreTests AS (
    -- Get all FICORE test attempts with ranking
    SELECT 
        d.SerialNumber,
        d.Result,
        d.Program,
        d.TestArea,
        d.MachineName,
        d.AsOf AS TestDate,
        ROW_NUMBER() OVER (
            PARTITION BY d.SerialNumber 
            ORDER BY d.AsOf DESC
        ) AS TestRank,  -- 1 = Most recent (final) test
        COUNT(*) OVER (
            PARTITION BY d.SerialNumber
        ) AS Total_Tests_For_Unit
    FROM redw.tia.DataWipeResult d
    WHERE d.Program = 'DELL_MEM'
      AND d.MachineName = 'FICORE'
),
FinalTestOnly AS (
    -- Get only the final (last) test per serial
    SELECT 
        SerialNumber,
        Result AS Final_Fail_Code,
        Program,
        TestArea,
        MachineName,
        TestDate AS Final_Test_Date,
        Total_Tests_For_Unit
    FROM AllFiCoreTests
    WHERE TestRank = 1  -- Last test only
),
WithMetadata AS (
    -- Join to Plus database for Family and LOB (for optional filtering)
    SELECT 
        ft.SerialNumber,
        ft.Final_Fail_Code,
        ft.Program,
        ft.TestArea,
        ft.MachineName,
        CAST(ft.Final_Test_Date AS DATE) AS Test_Date,
        ft.Total_Tests_For_Unit,
        ps.PartNo,
        ISNULL(psa_family.Value, 'Unknown') AS Family,
        ISNULL(psa_lob.Value, 'Unknown') AS LOB,
        CASE 
            WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
            ELSE 0
        END AS Standard_Cost,
        -- Categorize for reference
        CASE 
            WHEN ft.Final_Fail_Code IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
            THEN 'PASS'
            WHEN ft.Final_Fail_Code IN ('FAIL', 'FAILED', 'Failed', 'Fail')
            THEN 'FAIL'
            WHEN ft.Final_Fail_Code IN ('NA', 'ABORT', 'CANCELLED', 'aborted')
            THEN 'INCOMPLETE'
            ELSE 'OTHER'
        END AS Result_Category,
        -- Final disposition
        CASE 
            WHEN ft.Final_Fail_Code IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
            THEN 'READY_TO_SHIP'
            WHEN ft.Final_Fail_Code IN ('FAIL', 'FAILED', 'Failed', 'Fail')
            THEN 'NEEDS_REWORK'
            WHEN ft.Final_Fail_Code IN ('NA', 'ABORT', 'CANCELLED', 'aborted')
            THEN 'INCOMPLETE_TESTING'
            ELSE 'UNKNOWN_STATUS'
        END AS Final_Disposition
    FROM FinalTestOnly ft
    LEFT JOIN Plus.pls.PartSerial ps 
        ON ft.SerialNumber = ps.SerialNo
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
)
-- Group by Final Fail Code (primary dimension)
SELECT 
    Final_Fail_Code,
    Result_Category,
    Final_Disposition,
    
    -- Add optional filter columns (Power BI will use these for slicers)
    Test_Date,
    Family,
    LOB,
    Program,
    TestArea,
    MachineName,
    
    -- Metrics
    COUNT(*) AS Total_Units,
    SUM(Total_Tests_For_Unit) AS Total_Test_Attempts_All_Units,
    AVG(CAST(Total_Tests_For_Unit AS DECIMAL(10,2))) AS Avg_Tests_Per_Unit,
    
    -- Units that needed retesting
    SUM(CASE WHEN Total_Tests_For_Unit > 1 THEN 1 ELSE 0 END) AS Units_With_Retests,
    
    -- Percentage of all units
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()
        AS DECIMAL(5,2)
    ) AS Percent_Of_All_Units,
    
    -- Cost impact (for prioritization)
    SUM(Standard_Cost) AS Total_Value_At_Risk
    
FROM WithMetadata
GROUP BY Final_Fail_Code, Result_Category, Final_Disposition, Test_Date, Family, LOB, Program, TestArea, MachineName
ORDER BY Total_Units DESC, Final_Fail_Code;
