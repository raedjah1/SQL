
-- Detailed Fail Parts Query - All Failed Attempts (not just first touch of day)
-- Shows all individual failed test records with detailed information
SELECT 
    -- Source columns
    d.SerialNumber,
    d.PartNumber,
    d.StartTime,
    d.EndTime,
    d.MachineName,
    d.Result,
    d.TestArea,
    d.CellNumber,
    d.Program,
    d.MiscInfo,
    d.MACAddress,
    d.Msg,
    d.AsOf AS LogFile,
    d.AsOf,
    d.Exported,
    d.LastModifiedBy,
    d.LastModifiedOn,
    d.Username,
    d.OrderNumber,
    d.UploadTime,
    d.Contract,
    d.FileReference,
    d.FailureReference,
    d.FailureNumber,
    
    -- Date calculations
    CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE) AS TestDate,
    CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE) AS [End Date],
    DATEADD(DAY, 7 - DATEPART(WEEKDAY, CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE)), 
            CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE)) AS EOW,
    EOMONTH(CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE)) AS EOM,
    
    -- Pre-calculated sequence fields
    seq.Total_Tests_Ever AS [Total Touch Count],
    seq.Touch_Number,
    seq.Touch_Filter AS [First, Middle, or Last Touch],
    seq.First_Touch_of_Day AS [First Touch of the Day],
    seq.Has_Prior_Tests,
    
    -- Result categorization
    CASE 
        WHEN d.Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 
                         'FAIL-fail', 'FAIL (NO CHECKED)', 'Scratch & Dent', 
                         'ERROR', 'error')
             OR d.Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
        THEN 'FAIL'
        WHEN d.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
             AND seq.Has_Prior_Tests = 0
        THEN 'PASS_Y'
        WHEN d.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
        THEN 'PASS_N'
        ELSE 'OTHER'
    END AS Result_Category,
    
    -- FPY flag
    CASE 
        WHEN d.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
             AND seq.Has_Prior_Tests = 0
        THEN 'Y'
        ELSE 'N'
    END AS FPY,
    
    -- Outlier calculations
    DATEDIFF(MINUTE, d.StartTime, d.EndTime) AS [Outlier Duration],
    CASE 
        WHEN DATEDIFF(MINUTE, d.StartTime, d.EndTime) > 30 THEN 'Outlier'
        ELSE 'Both'
    END AS [Outlier Filter],
    
    -- Family and LOB
    ISNULL(psa_family.Value, 'Unknown') AS Family,
    ISNULL(psa_lob.Value, 'Unknown') AS LOB,
    
    -- OS Type and Model parsing
    CASE 
        WHEN d.MiscInfo IS NOT NULL AND d.MiscInfo != '' THEN
            CASE 
                WHEN d.MiscInfo LIKE '%WinPE%' OR d.MiscInfo LIKE '%Windows%' THEN 'Windows'
                WHEN d.MiscInfo LIKE '%Linux%' THEN 'Linux'
                WHEN d.MiscInfo LIKE '%macOS%' OR d.MiscInfo LIKE '%Mac%' THEN 'macOS'
                ELSE 'Unknown'
            END
        ELSE 'Unknown'
    END AS [OS Type],
    CASE 
        WHEN d.MiscInfo IS NOT NULL AND d.MiscInfo != '' AND CHARINDEX(',', d.MiscInfo) > 0 THEN
            LTRIM(RTRIM(REVERSE(SUBSTRING(REVERSE(d.MiscInfo), 1, CHARINDEX(',', REVERSE(d.MiscInfo)) - 1))))
        ELSE 'Unknown'
    END AS Model,
    
    -- Interactive Fail
    CASE 
        WHEN d.FileReference IS NOT NULL AND UPPER(d.FileReference) LIKE '%INTERACTIVE%' 
             AND d.Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 
                            'FAIL-fail', 'FAIL (NO CHECKED)', 'Scratch & Dent', 
                            'ERROR', 'error')
             OR d.Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
        THEN 'Interactive Failure'
        ELSE NULL
    END AS [Interactive Fail],
    
    -- TestCategory (matching FailPareots logic)
    CASE 
        -- Priority 1: BuildVerification takes absolute priority if it starts with "buildverify"
        WHEN UPPER(d.FileReference) LIKE 'BUILDVERIFY%' THEN 'BuildVerification'
        -- Priority 2: FiCore API specific patterns (takes priority over generic patterns)
        WHEN UPPER(d.FileReference) LIKE '%FICOREAPI PERSISTLOGFILES%' THEN 'FiCore API'
        -- Priority 3: Other specific patterns (order matters)
        WHEN UPPER(d.FileReference) LIKE '%OA3ACTIVATION%' THEN 'DPK Injections'
        WHEN UPPER(d.FileReference) LIKE '%2373%' THEN 'FiCore API'
        WHEN UPPER(d.FileReference) LIKE '%ERROR9999%' THEN 'ERROR9999'
        WHEN UPPER(d.FileReference) LIKE '%MFGMEDIA%' THEN 'prepMfgMedia'
        WHEN UPPER(d.FileReference) LIKE '%POSTVPE%' THEN 'PostVPE'
        WHEN UPPER(d.FileReference) LIKE '%WLAN%' THEN 'WLAN'
        WHEN UPPER(d.FileReference) LIKE '%INTERACTIVE%' THEN 'Interactive Test'
        WHEN UPPER(d.FileReference) LIKE '%BUILD%' THEN 'BuildVerification'
        WHEN UPPER(d.FileReference) LIKE '%FLASH%' THEN 'Flash'
        WHEN UPPER(d.FileReference) LIKE '%FIST%' THEN 'FIST'
        WHEN UPPER(d.FileReference) LIKE '%WBT%' THEN 'WBT'
        WHEN UPPER(d.FileReference) LIKE '%CONFIGURE%' THEN 'Configure'
        ELSE 'Other'
    END AS TestCategory,
    
    -- Standard Cost
    CASE 
        WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
        ELSE 0
    END AS Standard_Cost

FROM redw.tia.DataWipeResult d

-- Pre-calculate all sequence fields in one pass
INNER JOIN (
    SELECT 
        d2.SerialNumber,
        d2.AsOf,
        COUNT(*) OVER (PARTITION BY d2.SerialNumber) AS Total_Tests_Ever,
        ROW_NUMBER() OVER (PARTITION BY d2.SerialNumber ORDER BY d2.AsOf ASC) AS Touch_Number,
        CASE 
            WHEN ROW_NUMBER() OVER (PARTITION BY d2.SerialNumber ORDER BY d2.AsOf ASC) = 1 THEN 'First Touch'
            WHEN ROW_NUMBER() OVER (PARTITION BY d2.SerialNumber ORDER BY d2.AsOf DESC) = 1 THEN 'Last Touch'
            ELSE 'Multi'
        END AS Touch_Filter,
        CASE 
            WHEN d2.AsOf = MIN(d2.AsOf) OVER (
                PARTITION BY d2.SerialNumber, 
                CAST(d2.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE)
            ) THEN 'First Touch of the Day'
            ELSE 'No'
        END AS First_Touch_of_Day,
        CASE 
            WHEN LAG(d2.AsOf) OVER (PARTITION BY d2.SerialNumber ORDER BY d2.AsOf) IS NOT NULL THEN 1
            ELSE 0
        END AS Has_Prior_Tests
    FROM redw.tia.DataWipeResult d2
    WHERE d2.Program = 'DELL_MEM'
      AND d2.MachineName = 'FICORE'
      AND d2.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
) AS seq ON d.SerialNumber = seq.SerialNumber AND d.AsOf = seq.AsOf

OUTER APPLY (
    SELECT TOP 1 ps.ID, ps.PartNo
    FROM Plus.pls.PartSerial ps
    WHERE ps.SerialNo = d.SerialNumber
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

WHERE d.Program = 'DELL_MEM'
  AND d.MachineName = 'FICORE'
  AND d.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
  -- ✅ All failed attempts (not just first touch of the day)
  AND (
      d.Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 
                   'FAIL-fail', 'FAIL (NO CHECKED)', 'Scratch & Dent', 
                   'ERROR', 'error')
      OR d.Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
  )
  AND d.FileReference IS NOT NULL

UNION ALL

-- Add GCF Errors as individual records (matching FailPareots summary)
SELECT 
    NULL AS SerialNumber,
    NULL AS PartNumber,
    NULL AS StartTime,
    NULL AS EndTime,
    'GCF' AS MachineName,
    'FAIL' AS Result,
    NULL AS TestArea,
    NULL AS CellNumber,
    'DELL_MEM' AS Program,
    NULL AS MiscInfo,
    NULL AS MACAddress,
    gcf.Message AS Msg,
    gcf.Insert_Date AS LogFile,
    gcf.Insert_Date AS AsOf,
    NULL AS Exported,
    NULL AS LastModifiedBy,
    NULL AS LastModifiedOn,
    NULL AS Username,
    gcf.Customer_order_No AS OrderNumber,
    NULL AS UploadTime,
    '10053' AS Contract,
    NULL AS FileReference,
    NULL AS FailureReference,
    NULL AS FailureNumber,
    
    -- Date calculations
    CAST(gcf.Insert_Date AS DATE) AS TestDate,
    CAST(gcf.Insert_Date AS DATE) AS [End Date],
    DATEADD(DAY, 7 - DATEPART(WEEKDAY, CAST(gcf.Insert_Date AS DATE)), 
            CAST(gcf.Insert_Date AS DATE)) AS EOW,
    EOMONTH(CAST(gcf.Insert_Date AS DATE)) AS EOM,
    
    -- Sequence fields (N/A for GCF)
    1 AS [Total Touch Count],
    1 AS Touch_Number,
    'First Touch' AS [First, Middle, or Last Touch],
    'First Touch of the Day' AS [First Touch of the Day],
    0 AS Has_Prior_Tests,
    
    'FAIL' AS Result_Category,
    'N' AS FPY,
    NULL AS [Outlier Duration],
    'Both' AS [Outlier Filter],
    
    -- Try to get Family/LOB from work order
    ISNULL(psa_family.Value, 'Unknown') AS Family,
    ISNULL(psa_lob.Value, 'Unknown') AS LOB,
    
    'Unknown' AS [OS Type],
    'Unknown' AS Model,
    
    NULL AS [Interactive Fail],
    
    'GCF Error' AS TestCategory,
    
    0 AS Standard_Cost

FROM (
    SELECT 
        obm.Insert_Date,
        obm.Customer_order_No,
        obm.Message,
        ROW_NUMBER() OVER (
            PARTITION BY obm.Customer_order_No, CAST(obm.Insert_Date AS DATE) 
            ORDER BY obm.Insert_Date DESC
        ) AS rn
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Processed = 'F'
) AS gcf
LEFT JOIN Plus.pls.SOHeader sh ON sh.CustomerReference = gcf.Customer_order_No AND sh.ProgramID = 10053
OUTER APPLY (
    SELECT TOP 1 ps.ID, ps.PartNo
    FROM Plus.pls.PartSerial ps
    WHERE ps.SOHeaderID = sh.ID
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
WHERE gcf.rn = 1  -- Only first GCF error per work order per day

