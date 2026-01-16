-- First Touch of Day Failures Only
-- Shows only the first test attempt per serial number per day that resulted in a FAIL

SELECT 
    TestDate,
    FileReference,
    TestCategory,
    COUNT(*) AS OccurrenceCount
FROM (
    SELECT 
        f.TestDate,
        f.OrderNumber,
        f.FileReference,
        CASE 
            -- Pattern-based categorization only (GCF Error added separately via UNION ALL)
            -- Priority 1: BuildVerification takes absolute priority if it starts with "buildverify"
            WHEN UPPER(f.FileReference) LIKE 'BUILDVERIFY%' THEN 'BuildVerification'
            -- Priority 2: FiCore API specific patterns (takes priority over generic patterns)
            WHEN UPPER(f.FileReference) LIKE '%FICOREAPI PERSISTLOGFILES%' THEN 'FiCore API'
            -- Priority 3: Other specific patterns (order matters)
            WHEN UPPER(f.FileReference) LIKE '%OA3ACTIVATION%' THEN 'DPK Injections'
            WHEN UPPER(f.FileReference) LIKE '%2373%' THEN 'FiCore API'
            WHEN UPPER(f.FileReference) LIKE '%ERROR9999%' THEN 'ERROR9999'
            WHEN UPPER(f.FileReference) LIKE '%MFGMEDIA%' THEN 'prepMfgMedia'
            WHEN UPPER(f.FileReference) LIKE '%POSTVPE%' THEN 'PostVPE'
            WHEN UPPER(f.FileReference) LIKE '%WLAN%' THEN 'WLAN'
            WHEN UPPER(f.FileReference) LIKE '%INTERACTIVE%' THEN 'Interactive Test'
            WHEN UPPER(f.FileReference) LIKE '%BUILD%' THEN 'BuildVerification'
            WHEN UPPER(f.FileReference) LIKE '%FLASH%' THEN 'Flash'
            WHEN UPPER(f.FileReference) LIKE '%FIST%' THEN 'FIST'
            WHEN UPPER(f.FileReference) LIKE '%WBT%' THEN 'WBT'
            WHEN UPPER(f.FileReference) LIKE '%CONFIGURE%' THEN 'Configure'
            ELSE 'Other'
        END AS TestCategory
    FROM (
        SELECT 
            a.SerialNumber,
            a.OrderNumber,
            a.FileReference,
            a.Result,
            a.AsOf,
            a.TestDate
        FROM (
            SELECT 
                d.SerialNumber,
                d.OrderNumber,
                d.FileReference,
                d.Result,
                d.AsOf,
                CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE) AS TestDate,
                -- Identify first touch of the day per SerialNumber
                CASE 
                    WHEN d.AsOf = MIN(d.AsOf) OVER (
                        PARTITION BY d.SerialNumber, 
                        CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE)
                    ) THEN 1
                    ELSE 0
                END AS IsFirstTouchOfDay,
                -- Check if result is a FAIL
                CASE 
                    WHEN d.Result IN ('FAIL', 'FAILED', 'Failed', 'Fail', 'FAIL-', 'FAIL-fds', 
                                     'FAIL-fail', 'FAIL (NO CHECKED)', 'Scratch & Dent', 
                                     'ERROR', 'error')
                         OR d.Result LIKE '[0-9A-F][0-9A-F][0-9A-F][0-9A-F]'
                    THEN 1
                    ELSE 0
                END AS IsFail
            FROM redw.tia.DataWipeResult d
            WHERE d.Program = 'DELL_MEM'
              AND d.MachineName = 'FICORE'
              AND d.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
              -- ✅ NO hardcoded date - Power BI will filter by TestDate
        ) AS a
        WHERE a.IsFirstTouchOfDay = 1  -- Only first touch of the day
          AND a.IsFail = 1  -- Only if first touch was a FAIL
    ) AS f
    WHERE f.FileReference IS NOT NULL
) AS CategorizedData
GROUP BY 
    TestDate,
    FileReference, 
    TestCategory,
    CASE TestCategory
        WHEN 'GCF Error' THEN 0
        WHEN 'Interactive Test' THEN 1
        WHEN 'BuildVerification' THEN 2
        WHEN 'Flash' THEN 3
        WHEN 'FIST' THEN 4
        WHEN 'WBT' THEN 5
        WHEN 'PostVPE' THEN 6
        WHEN 'Configure' THEN 7
        WHEN 'ERROR9999' THEN 8
        WHEN 'FiCore API' THEN 9
        WHEN 'prepMfgMedia' THEN 10
        WHEN 'WLAN' THEN 11
        WHEN 'DPK Injections' THEN 12
        ELSE 99
    END

UNION ALL

-- Add GCF Errors as a separate category (first GCF error per work order per day)
SELECT 
    CAST(gcf.Insert_Date AS DATE) AS TestDate,
    NULL AS FileReference,
    'GCF Error' AS TestCategory,
    COUNT(*) AS OccurrenceCount
FROM (
    SELECT 
        obm.Insert_Date,
        ROW_NUMBER() OVER (
            PARTITION BY obm.Customer_order_No, CAST(obm.Insert_Date AS DATE) 
            ORDER BY obm.Insert_Date DESC
        ) AS rn
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Processed = 'F'
      -- ✅ NO hardcoded date - Power BI will filter by TestDate
) AS gcf
WHERE gcf.rn = 1  -- Only first GCF error per work order per day
GROUP BY 
    CAST(gcf.Insert_Date AS DATE)

