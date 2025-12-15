-- ============================================================================
-- INVESTIGATIVE: "No Resolution Attempt" interactions - DETAIL ROWS for 11/12/2025
-- ============================================================================
-- Shows individual records with categorization for "No Resolution Attempt" interactions
-- ============================================================================

SELECT 
    r.serialNo,
    r.woHeaderID,
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    r.createDate AS [QuincyInteractionTime],
    r.isSuccess,
    
    -- Categorization (matching Excel logic - order matters, check specific patterns first)
    CASE 
        -- Check longer pattern first (more specific)
        WHEN r.[log] LIKE '%"error":"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."%' 
        THEN 'Could not find any GCF errors in B2B outbound data'
        -- Then shorter pattern
        WHEN r.[log] LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' 
        THEN 'Could not find any GCF errors in B2B outbound data'
        
        WHEN r.[log] LIKE '%"error":"No inventory parts were found, likely incorrect route location or failed GTO call."%' 
        THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
        
        WHEN r.[log] LIKE '%"error":"No repair parts found."%' 
        THEN 'No repair parts found'
        
        WHEN r.[log] LIKE '%"error":"Unit does not have a PartSerial entry."%' 
        THEN 'Unit does not have PartSerial entry'
        
        WHEN r.[log] LIKE '%"error":"Unknown error, not trained to resolve."%' 
        THEN 'Not yet trained to resolve'
        
        -- Check specific routing error patterns (order matters)
        WHEN r.[log] LIKE '%"error":"Unit is not in correct ReImage%' 
        THEN 'Routing Errors'
        WHEN r.[log] LIKE '%"error":"Unit is not in the correct route%' 
        THEN 'Routing Errors'
        WHEN r.[log] LIKE '%"error":"Could not find route/location code for the unit in Plus."%' 
        THEN 'Routing Errors'
        WHEN r.[log] LIKE '%"error":"No route found for pre-existing family%' 
        THEN 'Routing Errors'
        
        WHEN r.[log] LIKE '%"error":"Attempted too many times to fix."%' 
        THEN 'Attempted too many times'
        
        -- Check specific patterns (order matters)
        WHEN r.[log] LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' 
        THEN 'Unable to locate a unit for reference'
        WHEN r.[log] LIKE '%"error":"No required MODs found from pre-existing family%' 
        THEN 'Unable to locate a unit for reference'
        
        WHEN r.[log] LIKE '%"error":"Unit does not have a work order created yet."%' 
        THEN 'Unit does not have a work order created yet'
        
        ELSE 'Other/Unknown'
    END AS [Category],
    
    -- Full log for inspection
    r.[log] AS [FullLog]
    
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 0  -- Only "No Resolution Attempt" interactions
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-12'
ORDER BY r.createDate DESC, r.serialNo;
