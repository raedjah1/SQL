-- Investigation query: FileReference categorization based on Excel patterns
SELECT 
    d.FileReference,
    CASE 
        -- Order matters: check more specific patterns first
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
    END AS FileReferenceCategory,
    COUNT(*) AS RecordCount
FROM redw.tia.DataWipeResult d
WHERE d.Program = 'DELL_MEM'
  AND d.MachineName = 'FICORE'
  AND d.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
  AND d.FileReference IS NOT NULL
GROUP BY 
    d.FileReference,
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
    END
ORDER BY FileReferenceCategory, d.FileReference;

-- Summary by category (matching Excel counts)
SELECT 
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
    END AS FileReferenceCategory,
    COUNT(*) AS TotalCount
FROM redw.tia.DataWipeResult d
WHERE d.Program = 'DELL_MEM'
  AND d.MachineName = 'FICORE'
  AND d.Result NOT IN ('NA', 'ABORT', 'CANCELLED', 'aborted', '')
  AND d.FileReference IS NOT NULL
GROUP BY 
    CASE 
        WHEN UPPER(d.FileReference) LIKE '%OA3ACTIVATION%' THEN 'DPK Injections'
        WHEN UPPER(d.FileReference) LIKE '%2373%' THEN 'FiCore API'
        WHEN UPPER(d.FileReference) LIKE '%MFGMEDIA%' THEN 'prepMfgMedia'
        WHEN UPPER(d.FileReference) LIKE '%POSTVPE%' THEN 'PostVPE'
        WHEN UPPER(d.FileReference) LIKE '%WLAN%' THEN 'WLAN'
        WHEN UPPER(d.FileReference) LIKE '%INTERACTIVE%' THEN 'Interactive Test'
        WHEN UPPER(d.FileReference) LIKE '%BUILD%' THEN 'BuildVerification'
        WHEN UPPER(d.FileReference) LIKE '%FLASH%' THEN 'Flash'
        WHEN UPPER(d.FileReference) LIKE '%FIST%' THEN 'FIST'
        WHEN UPPER(d.FileReference) LIKE '%WBT%' THEN 'WBT'
        WHEN UPPER(d.FileReference) LIKE '%CONFIGURE%' THEN 'Configure'
        WHEN UPPER(d.FileReference) LIKE '%ERROR9999%' THEN 'ERROR9999'
        ELSE 'Other'
    END
ORDER BY TotalCount DESC;

