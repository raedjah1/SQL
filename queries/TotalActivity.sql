SELECT 
    Test_Date,
    Program,
    TestArea,
    MachineName,
    Family,
    LOB,
    CASE 
        WHEN LOB IN ('POWER', 'PVAULT') THEN 'ISG'
        ELSE 'CSG'
    END AS GCF_Type,
    -- Grand Total: All test records on this date
    COUNT(*) AS Total_Test_Records,
    -- FAIL breakdown (all fails are "N")
    SUM(CASE 
        WHEN Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 
                       'FAIL-fail', 'FAIL (NO CHECKED)', 'Scratch & Dent', 
                       'ERROR', 'error')
             OR Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
        THEN 1 ELSE 0 
    END) AS FAIL_No,
    
    -- PASS Total
    SUM(CASE 
        WHEN Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
        THEN 1 ELSE 0 
    END) AS PASS_Total,
    
    -- PASS Y: Passing tests where unit has NO PRIOR tests (first test ever)
    SUM(CASE 
        WHEN Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
             AND Has_Prior_Tests = 0
        THEN 1 ELSE 0 
    END) AS PASS_Y_Single_Test_Ever,
    
    -- PASS N: Passing tests where unit HAS PRIOR tests (multiple tests ever)
    SUM(CASE 
        WHEN Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
             AND Has_Prior_Tests = 1
        THEN 1 ELSE 0 
    END) AS PASS_N_Multiple_Tests_Ever,
    
    -- Key Performance Metrics
    CAST(
        SUM(CASE 
            WHEN Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
                 AND Has_Prior_Tests = 0
            THEN 1 ELSE 0 
        END) * 100.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS Daily_FPY_Percent,
    
    CAST(
        SUM(CASE 
            WHEN Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
            THEN 1 ELSE 0 
        END) * 100.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS Total_Pass_Yield_Percent,
    
    -- Unique units tested on this date
    COUNT(DISTINCT SerialNumber) AS Unique_Units_Tested,
    
    -- Average total tests per unit
    AVG(CAST(Total_Tests_Ever AS DECIMAL(10,2))) AS Avg_Total_Tests_Per_Unit,
    
    -- Cost impact
    SUM(CASE 
        WHEN Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
        THEN Standard_Cost ELSE 0 
    END) AS Pass_Value,
    
    SUM(CASE 
        WHEN Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'ERROR', 'error')
             OR Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
        THEN Standard_Cost ELSE 0 
    END) AS Fail_Value

FROM (
    -- Step 3: Join to Plus database for Family, LOB, Cost (using OUTER APPLY to prevent duplicates)
    SELECT 
        tdr.Test_Date,
        tdr.SerialNumber,
        tdr.Result,
        tdr.Program,
        tdr.TestArea,
        tdr.MachineName,
        tdr.Total_Tests_Ever,
        tdr.Has_Prior_Tests,
        ISNULL(psa_family.Value, 'Unknown') AS Family,
        ISNULL(psa_lob.Value, 'Unknown') AS LOB,
        CASE 
            WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
            ELSE 0
        END AS Standard_Cost
    FROM (
        -- Step 2: Filter to date range using Central timezone conversion
        SELECT 
            ate.SerialNumber,
            ate.PartNumber,
            ate.AsOf,
            ate.Result,
            ate.Program,
            ate.TestArea,
            ate.MachineName,
            ate.Total_Tests_Ever,
            ate.Has_Prior_Tests,
            CAST(ate.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE) AS Test_Date
        FROM (
            -- Step 1: Get ALL FICORE tests with both Total_Tests_Ever and Has_Prior_Tests
            SELECT 
                d.ID,
                d.SerialNumber,
                d.PartNumber,
                d.AsOf,
                d.Result,
                d.Program,
                d.TestArea,
                d.MachineName,
                COUNT(*) OVER (
                    PARTITION BY d.SerialNumber
                ) AS Total_Tests_Ever,
                CASE 
                    WHEN EXISTS (
                        SELECT 1
                        FROM redw.tia.DataWipeResult prior
                        WHERE prior.SerialNumber = d.SerialNumber
                          AND prior.Program = 'DELL_MEM'
                          AND prior.MachineName = 'FICORE'
                          AND prior.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
                          AND prior.AsOf < d.AsOf  -- Only tests BEFORE this one
                    )
                    THEN 1 ELSE 0
                END AS Has_Prior_Tests
            FROM redw.tia.DataWipeResult d
            WHERE d.Program = 'DELL_MEM'
              AND d.MachineName = 'FICORE'
              AND d.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')  -- Exclude incomplete
        ) AS ate
      
    ) AS tdr
    OUTER APPLY (
        SELECT TOP 1 ps.ID, ps.PartNo
        FROM Plus.pls.PartSerial ps
        WHERE ps.SerialNo = tdr.SerialNumber
          AND ps.ProgramID = 10053
        ORDER BY ps.ID DESC
    ) AS ps
    OUTER APPLY (
        SELECT TOP 1 psa.Value
        FROM Plus.pls.PartSerialAttribute psa
        WHERE psa.PartSerialID = ps.ID
          AND psa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttFamily')
        ORDER BY psa.ID DESC
    ) AS psa_family
    OUTER APPLY (
        SELECT TOP 1 psa.Value
        FROM Plus.pls.PartSerialAttribute psa
        WHERE psa.PartSerialID = ps.ID
          AND psa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB')
        ORDER BY psa.ID DESC
    ) AS psa_lob
    OUTER APPLY (
        SELECT TOP 1 pna.Value
        FROM Plus.pls.PartNoAttribute pna
        WHERE pna.PartNo = ps.PartNo
          AND pna.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'STANDARDCOST')
          AND pna.ProgramID = 10053
        ORDER BY pna.ID DESC
    ) AS pna
) AS TestsWithMetadata
GROUP BY Test_Date, Program, TestArea, MachineName, Family, LOB, 
    CASE 
        WHEN LOB IN ('POWER', 'PVAULT') THEN 'ISG'
        ELSE 'CSG'
    END
