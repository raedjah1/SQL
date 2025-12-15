-- ============================================================================
-- POWER BI DAILY TEST ACTIVITY - ALL TEST RECORDS BY DATE
-- ============================================================================
-- Definition: Counts ALL test records (not unique units) by test date
-- Use Case: Daily operations, workload tracking, test volume analysis
-- Difference from FPY: This counts test ACTIVITY, FPY counts unit COHORTS
-- Timezone: All dates displayed in Central Standard Time (converted from UTC)
-- ============================================================================

SELECT 
    CAST(tod.TestDate AS DATE) AS Test_Date,
    tod.Program,
    tod.TestArea,
    tod.MachineName,
    ISNULL(psa_family.Value, 'Unknown') AS Family,
    ISNULL(psa_lob.Value, 'Unknown') AS LOB,
    
    -- Grand Total: All test records on this date
    COUNT(*) AS Total_Test_Records,
    
    -- FAIL breakdown (all fails are "N")
    SUM(CASE 
        WHEN tod.Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 
                           'FAIL-fail', 'FAIL (NO CHECKED)', 'Scratch & Dent', 
                           'ERROR', 'error')
             OR tod.Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
        THEN 1 ELSE 0 
    END) AS FAIL_N,
    
    -- PASS Total
    SUM(CASE 
        WHEN tod.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
        THEN 1 ELSE 0 
    END) AS PASS_Total,
    
    -- PASS Y: Passing tests that are the unit's FIRST EVER test
    SUM(CASE 
        WHEN tod.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
             AND tod.AttemptNumber = 1
        THEN 1 ELSE 0 
    END) AS PASS_Y_First_Test,
    
    -- PASS N: Passing tests that are RETESTS (2nd, 3rd, 4th... attempt)
    SUM(CASE 
        WHEN tod.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
             AND tod.AttemptNumber > 1
        THEN 1 ELSE 0 
    END) AS PASS_N_Retest,
    
    -- Key Performance Metrics
    CAST(
        SUM(CASE 
            WHEN tod.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
                 AND tod.AttemptNumber = 1
            THEN 1 ELSE 0 
        END) * 100.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS Daily_FPY_Percent,
    
    CAST(
        SUM(CASE 
            WHEN tod.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
            THEN 1 ELSE 0 
        END) * 100.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS Total_Pass_Yield_Percent,
    
    -- Additional breakdowns
    -- Note: Incomplete_Tests will always be 0 because incomplete tests are excluded from base query
    SUM(CASE 
        WHEN tod.Result IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
        THEN 1 ELSE 0 
    END) AS Incomplete_Tests,
    
    SUM(CASE 
        WHEN tod.Result NOT IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New',
                               'FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 
                               'FAIL-fail', 'FAIL (NO CHECKED)', 'Scratch & Dent', 
                               'ERROR', 'error',
                               'NA', 'ABORT', 'CANCELLED', 'aborted', '')
             AND tod.Result NOT LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
        THEN 1 ELSE 0 
    END) AS Other_Results,
    
    -- Unique units tested on this date
    COUNT(DISTINCT tod.SerialNumber) AS Unique_Units_Tested,
    
    -- Average attempts per test record
    AVG(CAST(tod.AttemptNumber AS DECIMAL(10,2))) AS Avg_Attempt_Number,
    
    -- Cost impact
    SUM(CASE 
        WHEN tod.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
        THEN CASE WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2)) ELSE 0 END
        ELSE 0 
    END) AS Pass_Value,
    
    SUM(CASE 
        WHEN tod.Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'ERROR', 'error')
             OR tod.Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
        THEN CASE WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2)) ELSE 0 END
        ELSE 0 
    END) AS Fail_Value

FROM (
    -- Get ALL FICORE tests with attempt numbering (excludes incomplete tests from numbering)
    -- Timezone: Convert UTC stored times to Central Time for reporting
    -- Note: AsOf is stored in UTC, converted to Central for Test_Date grouping
    -- Important: Incomplete tests (NA, ABORT, etc.) are EXCLUDED from attempt counting
    --            This means only PASS/FAIL tests count toward attempt numbers
    SELECT 
        d.SerialNumber,
        d.Result,
        d.Program,
        d.TestArea,
        d.MachineName,
        d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS TestDate,
        ROW_NUMBER() OVER (
            PARTITION BY d.SerialNumber 
            ORDER BY d.AsOf ASC, d.ID ASC
        ) AS AttemptNumber
    FROM redw.tia.DataWipeResult d
    WHERE d.Program = 'DELL_MEM'
      AND d.MachineName = 'FICORE'
      AND d.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')  -- Exclude incomplete from attempt counting
) AS tod
OUTER APPLY (
    -- Get single PartSerial record per SerialNumber (prevents duplicates)
    SELECT TOP 1 ps.ID, ps.PartNo
    FROM Plus.pls.PartSerial ps
    WHERE ps.SerialNo = tod.SerialNumber
      AND ps.ProgramID = 10053
    ORDER BY ps.ID DESC  -- Get most recent if multiple exist
) AS ps
OUTER APPLY (
    -- Get Family attribute
    SELECT TOP 1 psa.Value
    FROM Plus.pls.PartSerialAttribute psa
    WHERE psa.PartSerialID = ps.ID
      AND psa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttFamily')
    ORDER BY psa.ID DESC
) AS psa_family
OUTER APPLY (
    -- Get LOB attribute
    SELECT TOP 1 psa.Value
    FROM Plus.pls.PartSerialAttribute psa
    WHERE psa.PartSerialID = ps.ID
      AND psa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB')
    ORDER BY psa.ID DESC
) AS psa_lob
OUTER APPLY (
    -- Get Standard Cost
    SELECT TOP 1 pna.Value
    FROM Plus.pls.PartNoAttribute pna
    WHERE pna.PartNo = ps.PartNo
      AND pna.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'STANDARDCOST')
      AND pna.ProgramID = 10053
    ORDER BY pna.ID DESC
) AS pna
GROUP BY CAST(tod.TestDate AS DATE), tod.Program, tod.TestArea, tod.MachineName, 
         psa_family.Value, psa_lob.Value
ORDER BY Test_Date DESC, Program, TestArea, Family, LOB;

-- ============================================================================
-- POWER BI USAGE:
-- ============================================================================
-- 1. Load this query into Power BI
-- 2. Use Test_Date as your primary date slicer
-- 3. Create Matrix visual:
--    - Columns: Test_Date
--    - Rows: Create a category table with "FAIL/N" and "PASS/Y" and "PASS/N"
--    - Values: Corresponding count fields
-- 4. Filter by Family and LOB for department-level views
-- 5. Use Unique_Units_Tested to see how many units were tested vs test records
-- ============================================================================

-- VERIFICATION QUERY for 10/27/2025:
-- Should return: Total_Test_Records = 627, FAIL_N = 208, PASS_Total = 419, 
--                PASS_Y = 308, PASS_N = 111
--                Daily_FPY_Percent = 49.12%, Total_Pass_Yield_Percent = 66.83%

