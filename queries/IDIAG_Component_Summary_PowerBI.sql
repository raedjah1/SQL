-- PowerBI Direct Query: IDIAG Component Summary Statistics
-- Purpose: All-time aggregated component statistics for summary tables and cards
-- No WITH clauses - simple SELECT for PowerBI DirectQuery

SELECT 
    CAST(dwr.EndTime AS DATE) AS TestDate,
    CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END AS MachineNameNormalized,
    stl.TestName AS ComponentName,
    MIN(ISNULL(ps.PartNo, dwr.PartNumber)) AS PartNumber,  -- Get PartNumber (same logic as IDIAGFINAL)
    COUNT(*) AS TotalOccurrences,
    SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FailCount,
    SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS ErrorCount,  -- Alias for clarity
    CASE WHEN SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) > 0 THEN 1 ELSE 0 END AS HasErrors,  -- Flag: 1 = has errors, 0 = no errors
    CASE 
        WHEN COUNT(*) > 0 
        THEN CAST(SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)
        ELSE 0.0
    END AS PassRate,
    CASE 
        WHEN COUNT(*) > 0 
        THEN CAST(SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)
        ELSE 0.0
    END AS FailRate,
    CASE 
        WHEN COUNT(*) > 0 
        THEN CAST(SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)
        ELSE 0.0
    END AS ErrorRate,  -- Alias for FailRate for clarity
    -- Component Category (extract part after TEST_STATUS_)
    CASE 
        WHEN stl.TestName LIKE 'TEST_STATUS_%' THEN 
            SUBSTRING(stl.TestName, 13, LEN(stl.TestName))  -- Extract after 'TEST_STATUS_'
        ELSE stl.TestName
    END AS ComponentCategory,
    -- Component Description
    CASE stl.TestName
        WHEN 'TEST_STATUS_BATTERY' THEN 'Battery health and functionality'
        WHEN 'TEST_STATUS_BLUETOOTH' THEN 'Bluetooth connectivity'
        WHEN 'TEST_STATUS_CABLES' THEN 'Cable connections'
        WHEN 'TEST_STATUS_CAMERA' THEN 'Camera functionality'
        WHEN 'TEST_STATUS_CHARGER_WATTS' THEN 'Charger/power adapter'
        WHEN 'TEST_STATUS_CPU_PRIME95' THEN 'CPU stress test (Prime95)'
        WHEN 'TEST_STATUS_CPU_STRESS' THEN 'CPU stress test'
        WHEN 'TEST_STATUS_DISPLAY' THEN 'Display/screen functionality'
        WHEN 'TEST_STATUS_FAN' THEN 'Cooling fan'
        WHEN 'TEST_STATUS_FINGERPRINT' THEN 'Fingerprint reader'
        WHEN 'TEST_STATUS_KBL' THEN 'Keyboard backlight'
        WHEN 'TEST_STATUS_KEYBOARD' THEN 'Keyboard functionality'
        WHEN 'TEST_STATUS_LIDSENSOR' THEN 'Lid sensor'
        WHEN 'TEST_STATUS_MEMORY_STRESS' THEN 'Memory stress test'
        WHEN 'TEST_STATUS_NFC' THEN 'NFC functionality'
        WHEN 'TEST_STATUS_NPU_STRESS' THEN 'NPU (Neural Processing Unit) stress test'
        WHEN 'TEST_STATUS_PCI' THEN 'PCI component'
        WHEN 'TEST_STATUS_RJ45' THEN 'Ethernet port'
        WHEN 'TEST_STATUS_SMARTCARD' THEN 'Smart card reader'
        WHEN 'TEST_STATUS_SOUND_OUT' THEN 'Audio output'
        WHEN 'TEST_STATUS_STORAGE_STRESS' THEN 'Storage stress test'
        WHEN 'TEST_STATUS_TOUCHPAD' THEN 'Touchpad'
        WHEN 'TEST_STATUS_TOUCHSCREEN' THEN 'Touchscreen'
        WHEN 'TEST_STATUS_TPM' THEN 'Trusted Platform Module'
        WHEN 'TEST_STATUS_USB' THEN 'USB ports'
        WHEN 'TEST_STATUS_VIDEO_STRESS' THEN 'Video stress test'
        WHEN 'TEST_STATUS_VIDPORTS' THEN 'Video ports'
        WHEN 'TEST_STATUS_WLAN' THEN 'Wireless LAN (WiFi)'
        WHEN 'TEST_STATUS_MB_HW_MSR' THEN 'Motherboard hardware MSR'
        WHEN 'TEST_STATUS_0TTT' THEN 'Unknown test (0TTT)'
        WHEN 'TEST_STATUS_INVENTORY' THEN 'Inventory check'
        WHEN 'TEST_STATUS_PROXIMITY_SENSOR' THEN 'Proximity sensor'
        WHEN 'TEST_STATUS_ALS' THEN 'Ambient light sensor'
        WHEN 'TEST_STATUS_ACCELEROMETER' THEN 'Accelerometer'
        WHEN 'TEST_STATUS_GYROMETER' THEN 'Gyrometer'
        WHEN 'TEST_STATUS_AFX' THEN 'AFX component'
        WHEN 'TEST_STATUS_HEADSET' THEN 'Headset functionality'
        WHEN 'TEST_STATUS_AUDIO_LOOPBACK' THEN 'Audio loopback test'
        WHEN 'TEST_STATUS_SOUND_IN' THEN 'Audio input'
        WHEN 'TEST_STATUS_Overall_FPT_BIOS' THEN 'Overall FPT BIOS test'
        ELSE 'Component test'
    END AS ComponentDescription,
    -- Reliability Category (using decimal rates)
    CASE 
        WHEN SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) = 0 AND COUNT(*) > 100 THEN 'Perfect (Zero Failures)'
        WHEN COUNT(*) > 0 AND CAST(SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) = 1.0 THEN 'Always Fails'
        WHEN COUNT(*) > 0 AND CAST(SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) >= 0.50 THEN 'High Failure Rate (≥50%)'
        WHEN COUNT(*) > 0 AND CAST(SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) >= 0.10 THEN 'Moderate Failure Rate (10-50%)'
        WHEN COUNT(*) > 0 AND CAST(SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) >= 0.01 THEN 'Low Failure Rate (1-10%)'
        WHEN COUNT(*) > 0 AND CAST(SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) > 0.0 THEN 'Minimal Failures (<1%)'
        ELSE 'Perfect (No Failures)'
    END AS ReliabilityCategory,
    -- Frequency Category
    CASE 
        WHEN COUNT(*) >= 5000 THEN 'Very Common (5000+)'
        WHEN COUNT(*) >= 3000 THEN 'Common (3000-5000)'
        WHEN COUNT(*) >= 1000 THEN 'Moderate (1000-3000)'
        WHEN COUNT(*) >= 100 THEN 'Less Common (100-1000)'
        WHEN COUNT(*) > 0 THEN 'Rare (<100)'
        ELSE 'No Data'
    END AS FrequencyCategory
FROM [redw].[tia].[DataWipeResult] AS dwr
INNER JOIN [redw].[tia].[SubTestLogs] AS stl ON stl.MainTestID = dwr.ID
OUTER APPLY (
    SELECT TOP 1 ps.PartNo
    FROM Plus.pls.PartSerial ps
    WHERE ps.SerialNo = dwr.SerialNumber
      AND ps.ProgramID = 10053
    ORDER BY ps.ID DESC
) AS ps
WHERE dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
GROUP BY 
    CAST(dwr.EndTime AS DATE),
    CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END,
    stl.TestName;
