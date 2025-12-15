-- Investigation query: FileReference categorization for 11/20/2025
-- Logic: GCF Error takes priority (if OrderNumber has GCF error), then pattern-based categorization
-- Uses the FIRST TOUCH of the day per SerialNumber (earliest time, regardless of pass/fail)

WITH FirstTouchOfDay AS (
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
        END AS IsFirstTouchOfDay
    FROM redw.tia.DataWipeResult d
    WHERE d.Program = 'DELL_MEM'
      AND d.MachineName = 'FICORE'
      AND d.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
      AND CAST(d.AsOf AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time' AS DATE) = '2025-11-20'
),
CategorizedData AS (
    SELECT 
        f.SerialNumber,
        f.OrderNumber,
        f.FileReference,
        f.Result,
        f.AsOf,
        f.TestDate,
        gcf.Outmessage_Hdr_Id,
        CASE 
            -- Priority 1: Check if OrderNumber has a GCF error (from BizTalk)
            WHEN gcf.Outmessage_Hdr_Id IS NOT NULL THEN 'GCF Error'
            -- Priority 2: Pattern-based categorization
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
    FROM FirstTouchOfDay f
    -- Check for GCF errors: Match OrderNumber to Customer_order_No on the same test date
    LEFT JOIN (
        SELECT 
            obm.Customer_order_No,
            CAST(obm.Insert_Date AS DATE) AS GCF_Date,
            obm.Outmessage_Hdr_Id,
            ROW_NUMBER() OVER (
                PARTITION BY obm.Customer_order_No, CAST(obm.Insert_Date AS DATE) 
                ORDER BY obm.Insert_Date DESC
            ) AS rn
        FROM Biztalk.dbo.Outmessage_hdr obm
        WHERE obm.Source = 'Plus'
          AND obm.Contract = '10053'
          AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
          AND obm.Processed = 'F'
          AND CAST(obm.Insert_Date AS DATE) = '2025-11-20'
    ) AS gcf ON f.OrderNumber = gcf.Customer_order_No 
        AND f.TestDate = gcf.GCF_Date
        AND gcf.rn = 1
    WHERE f.IsFirstTouchOfDay = 1  -- Only first touch of the day (earliest time, regardless of pass/fail)
)
SELECT 
    SerialNumber,
    OrderNumber,
    FileReference,
    Result,
    AsOf,
    TestDate,
    Outmessage_Hdr_Id AS GCF_Error_ID,
    TestCategory
FROM CategorizedData
WHERE TestCategory != 'Other'
ORDER BY 
    CASE TestCategory
        WHEN 'GCF Error' THEN 1
        WHEN 'Interactive Test' THEN 2
        WHEN 'BuildVerification' THEN 3
        WHEN 'Flash' THEN 4
        WHEN 'FIST' THEN 5
        WHEN 'WBT' THEN 6
        WHEN 'PostVPE' THEN 7
        WHEN 'Configure' THEN 8
        WHEN 'ERROR9999' THEN 9
        WHEN 'FiCore API' THEN 10
        WHEN 'prepMfgMedia' THEN 11
        WHEN 'WLAN' THEN 12
        WHEN 'DPK Injections' THEN 13
        ELSE 99
    END,
    SerialNumber;

