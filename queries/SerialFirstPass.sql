SELECT 
    SerialNumber,
    
    -- First Pass Y/N (based on very first test ever)
    CASE 
        WHEN First_Test_Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
        THEN 'Y'
        ELSE 'N'
    END AS First_Pass,
    
    -- Total number of touches (tests) for this unit
    Total_Tests_Ever AS Total_Touches,
    
    -- Number of days this unit was tested
    Days_Touched,
    
    -- Context information
    Family,
    LOB,
    Program,
    TestArea,
    MachineName,
    
    -- Additional details
    First_Test_Date,
    Last_Test_Date,
    First_Test_Result,
    Latest_Result,
    
    -- Categorization
    CASE 
        WHEN UPPER(First_Test_FileReference) LIKE '%INTERACTIVE%' THEN 'Interactive Test'
        ELSE 'Other'
    END AS Category,
    
    -- GCF Errors Count (distinct days with errors, like Days_Touched)
    ISNULL(gcf_errors.GCF_Errors_Days, 0) AS GCF_Errors_Count,
    
    -- Total Error Touches (Days_Touched - 1 + GCF days)
    (Days_Touched - 1) + ISNULL(gcf_errors.GCF_Errors_Days, 0) AS Total_Error_Touches,
    
    -- Error Status (No Error/FGA if 0, TF if not 0)
    CASE 
        WHEN (Days_Touched - 1) + ISNULL(gcf_errors.GCF_Errors_Days, 0) = 0
        THEN 'No Error/FGA'
        ELSE 'TF'
    END AS Error_Status,
    
    -- Location Information
    loc_info.Current_Location,
    loc_info.From_Location,
    loc_info.Transaction_Date

FROM (
    -- Step 3: Get one row per SerialNumber with first/last test info
    SELECT DISTINCT
        tdr.SerialNumber,
        tdr.Program,
        tdr.TestArea,
        tdr.MachineName,
        tdr.Total_Tests_Ever,
        
        -- Get first test result (for First Pass calculation)
        FIRST_VALUE(tdr.Result) OVER (
            PARTITION BY tdr.SerialNumber 
            ORDER BY tdr.AsOf ASC
        ) AS First_Test_Result,
        
        -- Get first test FileReference (for categorization)
        FIRST_VALUE(tdr.FileReference) OVER (
            PARTITION BY tdr.SerialNumber 
            ORDER BY tdr.AsOf ASC
        ) AS First_Test_FileReference,
        
        -- Get latest test result
        FIRST_VALUE(tdr.Result) OVER (
            PARTITION BY tdr.SerialNumber 
            ORDER BY tdr.AsOf DESC
        ) AS Latest_Result,
        
        -- Get first and last test dates
        MIN(CAST(tdr.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE)) OVER (
            PARTITION BY tdr.SerialNumber
        ) AS First_Test_Date,
        
        MAX(CAST(tdr.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE)) OVER (
            PARTITION BY tdr.SerialNumber
        ) AS Last_Test_Date,
        
        -- Calculate days touched (count distinct test dates per serial)
        (
            SELECT COUNT(DISTINCT CAST(tdr2.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE))
            FROM redw.tia.DataWipeResult tdr2
            WHERE tdr2.SerialNumber = tdr.SerialNumber
              AND tdr2.Program = 'DELL_MEM'
              AND tdr2.MachineName = 'FICORE'
              AND tdr2.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
        ) AS Days_Touched,
        
        ISNULL(psa_family.Value, 'Unknown') AS Family,
        ISNULL(psa_lob.Value, 'Unknown') AS LOB
    FROM (
        -- Step 2: Get all FICORE tests with total count and test date
        SELECT 
            ate.SerialNumber,
            ate.PartNumber,
            ate.AsOf,
            CAST(ate.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE) AS Test_Date,
            ate.Result,
            ate.FileReference,
            ate.Program,
            ate.TestArea,
            ate.MachineName,
            ate.Total_Tests_Ever,
            ate.Has_Prior_Tests
        FROM (
            -- Step 1: Get ALL FICORE tests with both Total_Tests_Ever and Has_Prior_Tests
            SELECT 
                d.ID,
                d.SerialNumber,
                d.PartNumber,
                d.AsOf,
                d.Result,
                d.FileReference,
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
) AS TestsWithMetadata
LEFT JOIN (
    -- GCF Errors: Count distinct days with errors (like Days_Touched)
    SELECT 
        CAST(obm.Insert_Date AS DATE) AS Test_Date,
        1 AS GCF_Errors_Days  -- 1 = day has errors, 0 = no errors (handled by ISNULL)
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Processed = 'F'
    GROUP BY CAST(obm.Insert_Date AS DATE)
) AS gcf_errors ON TestsWithMetadata.First_Test_Date = gcf_errors.Test_Date

-- Location Information Join (INNER JOIN to filter to only matching serials)
INNER JOIN (
    SELECT 
        ps_loc.SerialNo,
        ps_loc.ProgramID,
        pl_loc.LocationNo AS Current_Location,
        pt_loc.Location AS From_Location,
        pt_loc.ToLocation AS To_Location,
        pt_loc.CreateDate AS Transaction_Date,
        ROW_NUMBER() OVER (
            PARTITION BY ps_loc.SerialNo, ps_loc.ProgramID
            ORDER BY pt_loc.CreateDate DESC
        ) AS rn
    FROM Plus.pls.PartSerial ps_loc
        INNER JOIN Plus.pls.PartLocation pl_loc ON pl_loc.ID = ps_loc.LocationID
        LEFT JOIN (
            SELECT 
                pt_inner.SerialNo,
                pt_inner.ProgramID,
                pt_inner.Location,
                pt_inner.ToLocation,
                pt_inner.CreateDate
            FROM Plus.pls.PartTransaction pt_inner
            WHERE pt_inner.ProgramID = 10053
              -- FromLocation = FinishedGoods.ARB.0.0.0 (case-insensitive)
              AND UPPER(pt_inner.Location) = UPPER('FinishedGoods.ARB.0.0.0')
              -- ToLocation = any FinishedGoods or Reserve location (case-insensitive)
                    AND (
                  UPPER(pt_inner.ToLocation) LIKE UPPER('FinishedGoods%')
                  OR UPPER(pt_inner.ToLocation) LIKE UPPER('Reserve%')
              )
        ) pt_loc ON pt_loc.SerialNo = ps_loc.SerialNo 
            AND pt_loc.ProgramID = ps_loc.ProgramID
    WHERE ps_loc.ProgramID = 10053
      AND (
          -- Current location matches criteria
          UPPER(pl_loc.LocationNo) = UPPER('FinishedGoods.ARB.0.0.0')
          OR UPPER(pl_loc.LocationNo) LIKE UPPER('FinishedGoods%')
          OR UPPER(pl_loc.LocationNo) LIKE UPPER('Reserve%')
          -- OR has matching transaction
          OR pt_loc.SerialNo IS NOT NULL
      )
) loc_info ON loc_info.SerialNo = TestsWithMetadata.SerialNumber 
    AND loc_info.rn = 1  -- Get most recent transaction



