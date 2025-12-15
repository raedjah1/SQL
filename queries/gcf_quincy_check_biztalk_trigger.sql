-- ============================================================================
-- CHECK: GCF Request Trigger Failure - Is there a GCF error in BizTalk?
-- ============================================================================
-- "GCF Request Trigger Failure" might mean:
-- Quincy attempted a fix (isSuccess = 1) but there's NO GCF error in BizTalk
-- to trigger/validate the fix against

SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    COUNT(*) AS [TotalResolutionAttempts],
    -- Cases where there's NO GCF error in BizTalk around the time of the attempt
    SUM(CASE 
        WHEN NOT EXISTS (
            SELECT 1
            FROM Biztalk.dbo.Outmessage_hdr obm
            WHERE obm.Source = 'Plus'
              AND obm.Contract = '10053'
              AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
              AND obm.Processed = 'F'
              AND obm.Customer_order_No = r.serialNo
              -- Check for GCF errors around the time of Quincy attempt (within 1 hour before/after)
              AND obm.Insert_Date >= DATEADD(HOUR, -1, r.createDate)
              AND obm.Insert_Date <= DATEADD(HOUR, 1, r.createDate)
        ) THEN 1 
        ELSE 0 
    END) AS [NoGCFErrorInBizTalk],
    -- Cases with no initialError in agentlogs
    SUM(CASE 
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 1 
        ELSE 0 
    END) AS [NoInitialError],
    -- Cases with no initialErrorDate
    SUM(CASE 
        WHEN r.initialErrorDate IS NULL THEN 1 
        ELSE 0 
    END) AS [NoInitialErrorDate],
    -- Cases where initialError exists but no BizTalk error
    SUM(CASE 
        WHEN (r.initialError IS NOT NULL AND LEN(LTRIM(RTRIM(r.initialError))) > 0)
             AND r.initialErrorDate IS NOT NULL
             AND NOT EXISTS (
                SELECT 1
                FROM Biztalk.dbo.Outmessage_hdr obm
                WHERE obm.Source = 'Plus'
                  AND obm.Contract = '10053'
                  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
                  AND obm.Processed = 'F'
                  AND obm.Customer_order_No = r.serialNo
                  AND obm.Insert_Date >= DATEADD(HOUR, -1, r.initialErrorDate)
                  AND obm.Insert_Date <= DATEADD(HOUR, 1, r.initialErrorDate)
             ) THEN 1 
        ELSE 0 
    END) AS [HasInitialErrorButNoBizTalkGCF]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 1  -- Only resolution attempts
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
GROUP BY CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
ORDER BY [Date] DESC;

-- Sample cases to inspect
SELECT TOP 20
    r.serialNo,
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    r.createDate AS [QuincyAttemptTime],
    r.initialErrorDate,
    CASE 
        WHEN r.initialError IS NULL THEN 'NULL'
        WHEN LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'EMPTY'
        WHEN LEN(r.initialError) > 100 THEN LEFT(r.initialError, 100) + '...'
        ELSE r.initialError
    END AS [InitialErrorPreview],
    -- Check if there's a GCF error in BizTalk around this time
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Biztalk.dbo.Outmessage_hdr obm
            WHERE obm.Source = 'Plus'
              AND obm.Contract = '10053'
              AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
              AND obm.Processed = 'F'
              AND obm.Customer_order_No = r.serialNo
              AND obm.Insert_Date >= DATEADD(HOUR, -1, r.createDate)
              AND obm.Insert_Date <= DATEADD(HOUR, 1, r.createDate)
        ) THEN 'YES - Has GCF in BizTalk'
        ELSE 'NO - Missing GCF in BizTalk'
    END AS [HasGCFInBizTalk],
    -- Get the closest GCF error time if it exists
    (SELECT TOP 1 obm.Insert_Date
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Processed = 'F'
       AND obm.Customer_order_No = r.serialNo
       AND obm.Insert_Date >= DATEADD(DAY, -7, r.createDate)
       AND obm.Insert_Date <= DATEADD(DAY, 7, r.createDate)
     ORDER BY ABS(DATEDIFF(SECOND, obm.Insert_Date, r.createDate))
    ) AS [ClosestGCFErrorTime]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 1
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
ORDER BY r.createDate DESC;

