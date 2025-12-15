-- Query: All distinct FileReference errors (Power BI Ready)
-- Shows every unique FileReference with its categorization
-- Only includes FileReferences where the FIRST TOUCH of the day was a FAIL
-- ✅ NO hardcoded date - Power BI will filter by TestDate using slicer
-- ✅ NO CTEs - Single SELECT statement for Power BI compatibility

SELECT 
    TestDate,
    FileReference,
    TestCategory,
    COUNT(*) AS OccurrenceCount
FROM (
    SELECT 
        f.TestDate,
        f.FileReference,
        CASE 
            -- Pattern-based categorization
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
                -- Identify first touch of the day per SerialNumber (same logic as First_Touch_of_Day in main query)
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
ORDER BY 
    TestDate,
    CASE TestCategory
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
    END,
    FileReference;
