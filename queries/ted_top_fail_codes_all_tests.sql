-- ============================================================================
-- TOP FAIL CODES - ALL TEST INSTANCES (POWER BI READY)
-- ============================================================================
-- Definition: Show total count of all test attempts grouped by fail code
-- Goal: Identify high-frequency failure types
-- Optional Filters: Date range, Family, LOB (via Power BI slicers)
-- Note: Uses AsOf (reliable timestamp) instead of StartTime (has corrupted dates)
-- ============================================================================

WITH AllFiCoreTests AS (
    -- Get all FICORE test attempts
    SELECT 
        d.SerialNumber,
        d.Result AS Fail_Code,
        d.Program,
        d.TestArea,
        d.MachineName,
        d.AsOf AS TestDate
    FROM redw.tia.DataWipeResult d
    WHERE d.Program = 'DELL_MEM'
      AND d.MachineName = 'FICORE'
),
WithMetadata AS (
    -- Join to Plus database for Family and LOB (for optional filtering)
    SELECT 
        ft.SerialNumber,
        ft.Fail_Code,
        ft.Program,
        ft.TestArea,
        ft.MachineName,
        CAST(ft.TestDate AS DATE) AS Test_Date,
        ps.PartNo,
        ISNULL(psa_family.Value, 'Unknown') AS Family,
        ISNULL(psa_lob.Value, 'Unknown') AS LOB,
        -- Categorize for reference
        CASE 
            WHEN ft.Fail_Code IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
            THEN 'PASS'
            WHEN ft.Fail_Code IN ('FAIL', 'FAILED', 'Failed', 'Fail')
            THEN 'FAIL'
            WHEN ft.Fail_Code IN ('NA', 'ABORT', 'CANCELLED', 'aborted')
            THEN 'INCOMPLETE'
            ELSE 'OTHER'
        END AS Result_Category
    FROM AllFiCoreTests ft
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
)
-- Group by Fail Code only (primary dimension)
SELECT 
    Fail_Code,
    Result_Category,
    
    -- Add optional filter columns (Power BI will use these for slicers)
    Test_Date,
    Family,
    LOB,
    Program,
    TestArea,
    MachineName,
    
    -- Metrics
    COUNT(*) AS Total_Test_Attempts,
    COUNT(DISTINCT SerialNumber) AS Unique_Units_Affected,
    
    -- Percentage of all tests
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()
        AS DECIMAL(5,2)
    ) AS Percent_Of_All_Tests
    
FROM WithMetadata
GROUP BY Fail_Code, Result_Category, Test_Date, Family, LOB, Program, TestArea, MachineName
ORDER BY Total_Test_Attempts DESC, Fail_Code;
