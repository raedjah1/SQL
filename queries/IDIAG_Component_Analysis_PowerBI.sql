-- PowerBI-Ready: IDIAG Component Analysis Dashboard
-- Purpose: Comprehensive component-level statistics for PowerBI visualization
-- Shows: Component performance, failure patterns, trends, and insights

WITH ComponentStats AS (
    SELECT 
        stl.TestName AS ComponentName,
        dwr.MachineName,
        CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END AS MachineNameNormalized,
        CAST(dwr.EndTime AS DATE) AS TestDate,
        dwr.Result AS MainTestResult,
        stl.Result AS SubtestResult,
        COUNT(*) AS TestCount,
        SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) AS PassCount,
        SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) AS FailCount,
        SUM(CASE WHEN stl.Result = 'PASSED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS PassRate,
        SUM(CASE WHEN stl.Result = 'FAILED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS FailRate
    FROM [redw].[tia].[SubTestLogs] AS stl
    INNER JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.ID = stl.MainTestID
    WHERE dwr.Contract = '10053'
      AND dwr.TestArea = 'MEMPHIS'
      AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
    GROUP BY 
        stl.TestName,
        dwr.MachineName,
        CASE WHEN dwr.MachineName = 'IDIAGS-MB-RESET' THEN 'MB-RESET' ELSE dwr.MachineName END,
        CAST(dwr.EndTime AS DATE),
        dwr.Result,
        stl.Result
),
ComponentSummary AS (
    SELECT 
        ComponentName,
        MachineNameNormalized,
        TestDate,
        MainTestResult,
        SUM(TestCount) AS TotalTests,
        SUM(PassCount) AS TotalPasses,
        SUM(FailCount) AS TotalFails,
        CASE 
            WHEN SUM(TestCount) > 0 THEN SUM(PassCount) * 100.0 / SUM(TestCount)
            ELSE 0
        END AS PassRate,
        CASE 
            WHEN SUM(TestCount) > 0 THEN SUM(FailCount) * 100.0 / SUM(TestCount)
            ELSE 0
        END AS FailRate
    FROM ComponentStats
    GROUP BY ComponentName, MachineNameNormalized, TestDate, MainTestResult
),
ComponentCategories AS (
    SELECT 
        ComponentName,
        CASE 
            -- Input Devices
            WHEN ComponentName LIKE '%KEYBOARD%' OR ComponentName LIKE '%KBL%' THEN 'Input Device'
            WHEN ComponentName LIKE '%TOUCHPAD%' OR ComponentName LIKE '%TOUCHSCREEN%' THEN 'Input Device'
            WHEN ComponentName LIKE '%FINGERPRINT%' OR ComponentName LIKE '%CAMERA%' THEN 'Input Device'
            WHEN ComponentName LIKE '%LIDSENSOR%' OR ComponentName LIKE '%PROXIMITY%' OR ComponentName LIKE '%ALS%' THEN 'Input Device'
            WHEN ComponentName LIKE '%ACCELEROMETER%' OR ComponentName LIKE '%GYROMETER%' THEN 'Input Device'
            
            -- Output Devices
            WHEN ComponentName LIKE '%DISPLAY%' OR ComponentName LIKE '%VIDEO%' THEN 'Output Device'
            WHEN ComponentName LIKE '%SOUND%' OR ComponentName LIKE '%AUDIO%' THEN 'Output Device'
            
            -- Connectivity
            WHEN ComponentName LIKE '%USB%' OR ComponentName LIKE '%RJ45%' OR ComponentName LIKE '%VIDPORTS%' THEN 'Connectivity'
            WHEN ComponentName LIKE '%BLUETOOTH%' OR ComponentName LIKE '%WLAN%' OR ComponentName LIKE '%NFC%' THEN 'Connectivity'
            WHEN ComponentName LIKE '%SMARTCARD%' THEN 'Connectivity'
            
            -- Power & Charging
            WHEN ComponentName LIKE '%BATTERY%' OR ComponentName LIKE '%CHARGER%' THEN 'Power'
            
            -- Processing & Performance
            WHEN ComponentName LIKE '%CPU%' OR ComponentName LIKE '%NPU%' THEN 'Processing'
            WHEN ComponentName LIKE '%MEMORY%' OR ComponentName LIKE '%STORAGE%' THEN 'Processing'
            
            -- System Components
            WHEN ComponentName LIKE '%FAN%' OR ComponentName LIKE '%TPM%' THEN 'System Component'
            WHEN ComponentName LIKE '%PCI%' OR ComponentName LIKE '%MB_%' THEN 'System Component'
            WHEN ComponentName LIKE '%CABLES%' THEN 'System Component'
            
            -- Special/Unknown
            WHEN ComponentName LIKE '%0TTT%' OR ComponentName LIKE '%INVENTORY%' THEN 'Special/Unknown'
            WHEN ComponentName LIKE '%HEADSET%' OR ComponentName LIKE '%AFX%' THEN 'Special/Unknown'
            
            ELSE 'Other'
        END AS ComponentCategory,
        CASE 
            WHEN ComponentName LIKE '%STRESS%' OR ComponentName LIKE '%PRIME95%' THEN 'Stress Test'
            WHEN ComponentName LIKE '%TEST_STATUS_%' THEN 'Standard Test'
            ELSE 'Other'
        END AS TestType
    FROM (
        SELECT DISTINCT ComponentName
        FROM ComponentSummary
    ) AS comps
)
SELECT 
    cs.ComponentName,
    cc.ComponentCategory,
    cc.TestType,
    cs.MachineNameNormalized,
    cs.TestDate,
    cs.MainTestResult,
    cs.TotalTests,
    cs.TotalPasses,
    cs.TotalFails,
    cs.PassRate,
    cs.FailRate,
    
    -- Ranking metrics for PowerBI
    ROW_NUMBER() OVER (PARTITION BY cs.TestDate, cs.MachineNameNormalized ORDER BY cs.TotalTests DESC) AS RankByOccurrences,
    ROW_NUMBER() OVER (PARTITION BY cs.TestDate, cs.MachineNameNormalized ORDER BY cs.FailRate DESC, cs.TotalFails DESC) AS RankByFailureRate,
    ROW_NUMBER() OVER (PARTITION BY cs.TestDate, cs.MachineNameNormalized ORDER BY cs.PassRate DESC) AS RankByPassRate,
    
    -- Overall totals (for all-time stats)
    SUM(cs.TotalTests) OVER (PARTITION BY cs.ComponentName, cs.MachineNameNormalized) AS AllTimeTotalTests,
    SUM(cs.TotalPasses) OVER (PARTITION BY cs.ComponentName, cs.MachineNameNormalized) AS AllTimeTotalPasses,
    SUM(cs.TotalFails) OVER (PARTITION BY cs.ComponentName, cs.MachineNameNormalized) AS AllTimeTotalFails,
    CASE 
        WHEN SUM(cs.TotalTests) OVER (PARTITION BY cs.ComponentName, cs.MachineNameNormalized) > 0 
        THEN SUM(cs.TotalPasses) OVER (PARTITION BY cs.ComponentName, cs.MachineNameNormalized) * 100.0 / 
             SUM(cs.TotalTests) OVER (PARTITION BY cs.ComponentName, cs.MachineNameNormalized)
        ELSE 0
    END AS AllTimePassRate,
    CASE 
        WHEN SUM(cs.TotalTests) OVER (PARTITION BY cs.ComponentName, cs.MachineNameNormalized) > 0 
        THEN SUM(cs.TotalFails) OVER (PARTITION BY cs.ComponentName, cs.MachineNameNormalized) * 100.0 / 
             SUM(cs.TotalTests) OVER (PARTITION BY cs.ComponentName, cs.MachineNameNormalized)
        ELSE 0
    END AS AllTimeFailRate,
    
    -- Flags for special cases
    CASE 
        WHEN cs.TotalFails = 0 AND cs.TotalTests > 100 THEN 'Zero Failures (Reliable)'
        WHEN cs.FailRate = 100 THEN 'Always Fails'
        WHEN cs.FailRate >= 50 THEN 'High Failure Rate'
        WHEN cs.FailRate >= 10 THEN 'Moderate Failure Rate'
        WHEN cs.FailRate > 0 THEN 'Low Failure Rate'
        ELSE 'Perfect (No Failures)'
    END AS ReliabilityCategory,
    
    -- Component description (for tooltips)
    CASE ComponentName
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
    END AS ComponentDescription

FROM ComponentSummary AS cs
INNER JOIN ComponentCategories AS cc ON cc.ComponentName = cs.ComponentName

-- Optional: Add date filter for recent data only (remove if you want all history)
-- WHERE cs.TestDate >= DATEADD(DAY, -90, GETDATE())

ORDER BY cs.TestDate DESC, cs.TotalTests DESC;

