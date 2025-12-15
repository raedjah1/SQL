-- ============================================================================
-- GCF QUINCY DASHBOARD - INVESTIGATIVE QUERIES
-- ============================================================================
-- Investigating the first 3 metrics to understand the data structure
-- ============================================================================

-- ============================================================================
-- INVESTIGATION 1: Total Quincy Interactions
-- ============================================================================
-- Count all records in agentlogs.repair per date
-- This should match "Total Quincy Interactions"
SELECT 
    CAST(createDate AS DATE) AS InteractionDate,
    COUNT(*) AS TotalQuincyInteractions,
    COUNT(CASE WHEN isSuccess = 1 THEN 1 END) AS SuccessfulAttempts,
    COUNT(CASE WHEN isSuccess = 0 THEN 1 END) AS FailedAttempts,
    COUNT(CASE WHEN isSuccess IS NULL THEN 1 END) AS UnknownStatus
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) >= '2025-11-08'
    AND CAST(createDate AS DATE) <= '2025-11-19'
GROUP BY CAST(createDate AS DATE)
ORDER BY InteractionDate DESC;

-- ============================================================================
-- INVESTIGATION 2: Resolution Attempts vs No Attempts
-- ============================================================================
-- Need to understand what constitutes a "Resolution Attempt"
-- vs "No Resolution Attempt"
-- 
-- Hypothesis:
-- - Resolution Attempt = has log data with repair attempt (modsToRepair or error)
-- - No Attempt = log is NULL or empty, or specific error messages
SELECT 
    CAST(createDate AS DATE) AS InteractionDate,
    COUNT(*) AS TotalInteractions,
    -- Check if log contains modsToRepair (successful attempt)
    COUNT(CASE WHEN log LIKE '%modsToRepair%' THEN 1 END) AS HasModsToRepair,
    -- Check if log contains error field (failed attempt)
    COUNT(CASE WHEN log LIKE '%"error"%' THEN 1 END) AS HasErrorInLog,
    -- Check if log is NULL or empty
    COUNT(CASE WHEN log IS NULL OR LEN(LTRIM(RTRIM(log))) = 0 THEN 1 END) AS LogIsEmpty,
    -- Check isSuccess flag
    COUNT(CASE WHEN isSuccess = 1 THEN 1 END) AS IsSuccess_True,
    COUNT(CASE WHEN isSuccess = 0 THEN 1 END) AS IsSuccess_False,
    COUNT(CASE WHEN isSuccess IS NULL THEN 1 END) AS IsSuccess_Null
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) >= '2025-11-08'
    AND CAST(createDate AS DATE) <= '2025-11-19'
GROUP BY CAST(createDate AS DATE)
ORDER BY InteractionDate DESC;

-- ============================================================================
-- INVESTIGATION 3: Sample Data to Understand Resolution Attempt Logic
-- ============================================================================
-- Get sample records to see what differentiates "attempt" vs "no attempt"
SELECT TOP 20
    CAST(createDate AS DATE) AS InteractionDate,
    serialNo,
    isSuccess,
    CASE 
        WHEN log LIKE '%modsToRepair%' THEN 'Has ModsToRepair'
        WHEN log LIKE '%"error"%' THEN 'Has Error'
        WHEN log IS NULL OR LEN(LTRIM(RTRIM(log))) = 0 THEN 'Log Empty'
        ELSE 'Other'
    END AS LogCategory,
    LEFT(log, 200) AS LogPreview,
    LEFT(initialError, 200) AS InitialErrorPreview
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) >= '2025-11-13'
    AND CAST(createDate AS DATE) <= '2025-11-19'
ORDER BY createDate DESC;

-- ============================================================================
-- INVESTIGATION 4: "Encountered New Error" Detection
-- ============================================================================
-- Need to understand how to detect if a new GCF error occurred after resolution
-- 
-- Hypothesis:
-- - Check if there's a new GCF error in BizTalk after initialErrorDate
-- - Compare STATUSREASON to see if it's the same or different error
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS ResolutionDate,
    r.initialErrorDate,
    r.isSuccess,
    -- Extract STATUSREASON from initialError XML
    SUBSTRING(
        r.initialError,
        CHARINDEX('<STATUSREASON>', r.initialError) + 14,
        CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
    ) AS InitialErrorReason,
    -- Check for new GCF errors after initialErrorDate
    (SELECT COUNT(*)
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Processed = 'F'
       AND obm.Customer_order_No = r.serialNo
       AND CAST(obm.Insert_Date AS DATE) > CAST(r.initialErrorDate AS DATE)
    ) AS NewGCFErrorsAfterResolution,
    -- Get the latest GCF error after resolution
    (SELECT TOP 1 obm.Message
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Processed = 'F'
       AND obm.Customer_order_No = r.serialNo
       AND CAST(obm.Insert_Date AS DATE) > CAST(r.initialErrorDate AS DATE)
     ORDER BY obm.Insert_Date DESC
    ) AS LatestNewError
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(r.createDate AS DATE) >= '2025-11-13'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
    AND r.isSuccess = 1  -- Only look at successful attempts first
ORDER BY r.createDate DESC;

-- ============================================================================
-- INVESTIGATION 5: Parse Log JSON to Understand Error Categories
-- ============================================================================
-- Extract specific error messages from log JSON to understand categorization
SELECT 
    CAST(createDate AS DATE) AS InteractionDate,
    serialNo,
    isSuccess,
    -- Extract error message from JSON
    CASE 
        WHEN log LIKE '%"error":"Could not find any GCF errors in B2B outbound data"%' THEN 'Could not find any GCF errors in B2B outbound data'
        WHEN log LIKE '%"error":"No inventory parts were found, likely incorrect route location or failed GTO call"%' THEN 'No inventory parts were found'
        WHEN log LIKE '%"error":"No repair parts found"%' THEN 'No repair parts found'
        WHEN log LIKE '%"error":"Unit does not have PartSerial entry"%' THEN 'Unit does not have PartSerial entry'
        WHEN log LIKE '%"error":"Not yet trained to resolve"%' THEN 'Not yet trained to resolve'
        WHEN log LIKE '%"error":"Routing Errors"%' THEN 'Routing Errors'
        WHEN log LIKE '%"error":"Attempted too many times"%' THEN 'Attempted too many times'
        WHEN log LIKE '%"error":"Unable to locate a unit for reference"%' THEN 'Unable to locate a unit for reference'
        WHEN log LIKE '%"error":"Unit does not have a work order created yet"%' THEN 'Unit does not have a work order created yet'
        WHEN log LIKE '%modsToRepair%' THEN 'Has Repair Parts'
        ELSE 'Other/Unknown'
    END AS ErrorCategory,
    LEFT(log, 500) AS LogPreview
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) >= '2025-11-13'
    AND CAST(createDate AS DATE) <= '2025-11-19'
ORDER BY createDate DESC;

