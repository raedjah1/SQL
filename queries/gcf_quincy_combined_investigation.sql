-- ============================================================================
-- COMBINED GCF + QUINCY INVESTIGATION
-- ============================================================================
-- Understanding how to link GCF errors (BizTalk) with Quincy repair attempts
-- ============================================================================

-- 1. See how GCF errors and Quincy repair attempts link together
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS QuincyInteractionDate,
    r.initialErrorDate AS InitialGCFErrorDate,
    r.isSuccess,
    -- Extract STATUSREASON from initial GCF error
    SUBSTRING(
        r.initialError,
        CHARINDEX('<STATUSREASON>', r.initialError) + 14,
        CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
    ) AS InitialErrorReason,
    -- Check for GCF errors in BizTalk for this serial
    (SELECT COUNT(*)
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Processed = 'F'
       AND obm.Customer_order_No = r.serialNo
    ) AS TotalGCFErrorsInBizTalk,
    -- Check for NEW GCF errors AFTER the initial error date
    (SELECT COUNT(*)
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Processed = 'F'
       AND obm.Customer_order_No = r.serialNo
       AND CAST(obm.Insert_Date AS DATE) > CAST(r.initialErrorDate AS DATE)
    ) AS NewGCFErrorsAfterInitial,
    -- Get the latest new error STATUSREASON if exists
    (SELECT TOP 1 
        SUBSTRING(obm.Message, 
            CHARINDEX('<STATUSREASON>', obm.Message) + 14,
            CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14)
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Processed = 'F'
       AND obm.Customer_order_No = r.serialNo
       AND CAST(obm.Insert_Date AS DATE) > CAST(r.initialErrorDate AS DATE)
     ORDER BY obm.Insert_Date DESC
    ) AS LatestNewErrorReason,
    -- Quincy log category
    CASE 
        WHEN r.log LIKE '%modsToRepair%' OR r.log LIKE '%modsToRemove%' THEN 'Has Repair Parts'
        WHEN r.log LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' THEN 'Could not find any GCF errors'
        WHEN r.log LIKE '%"error":"No inventory parts were found%' THEN 'No inventory parts were found'
        WHEN r.log LIKE '%"error":"No repair parts found."%' THEN 'No repair parts found'
        WHEN r.log LIKE '%"error":"Unknown error, not trained to resolve."%' THEN 'Not yet trained to resolve'
        WHEN r.log LIKE '%"error":"Could not find route/location code%' OR r.log LIKE '%"error":"Unit is not in correct ReImage%' OR r.log LIKE '%"error":"No route found for pre-existing family%' THEN 'Routing Errors'
        WHEN r.log LIKE '%"error":"Unit does not have a work order created yet."%' THEN 'Unit does not have a work order created yet'
        WHEN r.log LIKE '%"error":"Attempted too many times to fix."%' THEN 'Attempted too many times'
        WHEN r.log LIKE '%"error":"Unit does not have a PartSerial entry."%' THEN 'Unit does not have PartSerial entry'
        WHEN r.log LIKE '%"error":"No pre-existing family found%' OR r.log LIKE '%"error":"No required MODs found from pre-existing family%' THEN 'Unable to locate a unit for reference'
        ELSE 'Other/Unknown'
    END AS QuincyLogCategory
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(r.createDate AS DATE) >= '2025-11-13'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
    AND r.isSuccess = 1  -- Start with successful attempts
ORDER BY r.createDate DESC;

-- 2. Count by date: Total Quincy Interactions (from repair table)
SELECT 
    CAST(createDate AS DATE) AS Date,
    COUNT(*) AS TotalQuincyInteractions
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) >= '2025-11-08'
    AND CAST(createDate AS DATE) <= '2025-11-19'
GROUP BY CAST(createDate AS DATE)
ORDER BY Date DESC;

-- 3. Count Resolution Attempts vs No Attempts (from repair table)
SELECT 
    CAST(createDate AS DATE) AS Date,
    COUNT(*) AS TotalInteractions,
    -- Resolution Attempts (has modsToRepair/Remove OR error but not "no attempt" errors)
    COUNT(CASE 
        WHEN (log LIKE '%modsToRepair%' OR log LIKE '%modsToRemove%' OR 
              (log LIKE '%"error"%' AND 
               log NOT LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' AND
               log NOT LIKE '%"error":"Unknown error, not trained to resolve."%' AND
               log NOT LIKE '%"error":"Could not find route/location code%' AND
               log NOT LIKE '%"error":"Unit is not in correct ReImage%' AND
               log NOT LIKE '%"error":"No route found for pre-existing family%' AND
               log NOT LIKE '%"error":"Unit does not have a work order created yet."%' AND
               log NOT LIKE '%"error":"Unit does not have a PartSerial entry."%' AND
               log NOT LIKE '%"error":"No pre-existing family found%' AND
               log NOT LIKE '%"error":"No required MODs found from pre-existing family%'))
        THEN 1 
    END) AS ResolutionAttempts,
    -- No Resolution Attempts
    COUNT(CASE 
        WHEN log IS NULL OR log = '' OR
             log LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' OR
             log LIKE '%"error":"Unknown error, not trained to resolve."%' OR
             log LIKE '%"error":"Could not find route/location code%' OR
             log LIKE '%"error":"Unit is not in correct ReImage%' OR
             log LIKE '%"error":"No route found for pre-existing family%' OR
             log LIKE '%"error":"Unit does not have a work order created yet."%' OR
             log LIKE '%"error":"Unit does not have a PartSerial entry."%' OR
             log LIKE '%"error":"No pre-existing family found%' OR
             log LIKE '%"error":"No required MODs found from pre-existing family%'
        THEN 1 
    END) AS NoResolutionAttempt
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) >= '2025-11-08'
    AND CAST(createDate AS DATE) <= '2025-11-19'
GROUP BY CAST(createDate AS DATE)
ORDER BY Date DESC;

-- 4. Check for "Resolved but New Error" - need to link with BizTalk GCF errors
SELECT 
    CAST(r.createDate AS DATE) AS Date,
    r.serialNo,
    r.isSuccess,
    -- Initial error reason
    SUBSTRING(r.initialError, 
        CHARINDEX('<STATUSREASON>', r.initialError) + 14,
        CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14) AS InitialErrorReason,
    -- Check if new GCF error exists after initial error date
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Biztalk.dbo.Outmessage_hdr obm
            WHERE obm.Source = 'Plus'
              AND obm.Contract = '10053'
              AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
              AND obm.Processed = 'F'
              AND obm.Customer_order_No = r.serialNo
              AND CAST(obm.Insert_Date AS DATE) > CAST(r.initialErrorDate AS DATE)
        ) THEN 'Has New Error'
        ELSE 'No New Error'
    END AS NewErrorStatus,
    -- Get the new error reason if exists
    (SELECT TOP 1 
        SUBSTRING(obm.Message, 
            CHARINDEX('<STATUSREASON>', obm.Message) + 14,
            CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14)
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Processed = 'F'
       AND obm.Customer_order_No = r.serialNo
       AND CAST(obm.Insert_Date AS DATE) > CAST(r.initialErrorDate AS DATE)
     ORDER BY obm.Insert_Date DESC
    ) AS NewErrorReason
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(r.createDate AS DATE) >= '2025-11-13'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
    AND (r.log LIKE '%modsToRepair%' OR r.log LIKE '%modsToRemove%' OR 
         (r.log LIKE '%"error"%' AND 
          r.log NOT LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' AND
          r.log NOT LIKE '%"error":"Unknown error, not trained to resolve."%' AND
          r.log NOT LIKE '%"error":"Could not find route/location code%' AND
          r.log NOT LIKE '%"error":"Unit is not in correct ReImage%' AND
          r.log NOT LIKE '%"error":"No route found for pre-existing family%' AND
          r.log NOT LIKE '%"error":"Unit does not have a work order created yet."%' AND
          r.log NOT LIKE '%"error":"Unit does not have a PartSerial entry."%' AND
          r.log NOT LIKE '%"error":"No pre-existing family found%' AND
          r.log NOT LIKE '%"error":"No required MODs found from pre-existing family%'))
ORDER BY r.createDate DESC;

