
SELECT 
    -- Source columns
    d.ID,
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
    d.ErrItem,
    d.TestAreaOrig,
    d.BatteryHealthGrade,
    d.LogFileStatus,
    
    -- Date calculations
    CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE) AS Test_Date,
    CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE) AS [End Date],
    DATEADD(DAY, 7 - DATEPART(WEEKDAY, CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE)), 
            CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE)) AS EOW,
    EOMONTH(CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE)) AS EOM,
    
    -- Pre-calculated sequence fields
    seq.Total_Tests_Ever,
    seq.Touch_Number,
    seq.Touch_Filter,
    seq.First_Touch_of_Day,
    seq.Has_Prior_Tests,
    
    -- Result categorization (using pre-calculated Has_Prior_Tests)
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
    
    -- FPY flag (using pre-calculated Has_Prior_Tests)
    CASE 
        WHEN d.Result IN ('PASS', 'SUCCEEDED', 'Passed', 'finished', 'Like New')
             AND seq.Has_Prior_Tests = 0
        THEN 'Y'
        ELSE 'N'
    END AS FPY,
    
    -- Outlier calculations
    DATEDIFF(MINUTE, d.StartTime, d.EndTime) AS Outlier_Duration,
    CASE 
        WHEN DATEDIFF(MINUTE, d.StartTime, d.EndTime) > 30 THEN 'Outlier'
        ELSE 'Both'
    END AS Outlier_Filter,
    
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
        WHEN d.ErrItem IS NOT NULL AND d.ErrItem != '' THEN 'Other'
        WHEN d.FailureReference IS NOT NULL AND d.FailureReference != '' THEN 'Other'
        ELSE NULL
    END AS [Interactive Fail],
    
    -- Standard Cost
    CASE 
        WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
        ELSE 0
    END AS Standard_Cost,
    
    -- FileReference Category (based on Excel patterns)
    CASE 
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
    END AS FileReferenceCategory

FROM redw.tia.DataWipeResult d
-- ✅ OPTIMIZED: Pre-calculate all sequence fields in one pass
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
        -- ✅ OPTIMIZED: Replace EXISTS with window function
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
  AND d.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '');