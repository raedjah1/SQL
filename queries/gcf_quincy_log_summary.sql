-- ============================================================================
-- QUINCY LOG SUMMARY
-- ============================================================================
-- Matches Excel pivot: "Quincy Log Summary"
-- Shows all Quincy interactions categorized by "Log Translation"
-- Split by isSuccess: "Fix Attempt" (isSuccess = 1) vs "No Fix Attempt" (isSuccess = 0)
-- ============================================================================
-- Categories:
--   - "Quincy Resolution Attempt" (isSuccess = 1)
--   - All other categories (isSuccess = 0, from log field patterns)
-- ============================================================================

SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Quincy Resolution Date Attempt],
    -- Categorize based on isSuccess and log patterns (matching Excel logic)
    CASE 
        -- Resolution attempts (isSuccess = 1)
        WHEN r.isSuccess = 1 THEN 'Quincy Resolution Attempt'
        
        -- No resolution attempts (isSuccess = 0) - check specific patterns first
        -- Order matters: check more specific patterns before general ones
        
        -- "Attempted too many times" (check first as it's specific)
        WHEN r.log LIKE '%"error":"Attempted too many times to fix."%' THEN 'Attempted too many times'
        
        -- "Could not find any GCF errors" (check longer pattern first)
        WHEN r.log LIKE '%"error":"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."%' 
             OR r.log LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' 
        THEN 'Could not find any GCF errors in B2B outbound data'
        
        -- "No inventory parts were found" (specific pattern)
        WHEN r.log LIKE '%"error":"No inventory parts were found, likely incorrect route location or failed GTO call."%' 
        THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
        
        -- "No repair parts found" (specific pattern)
        WHEN r.log LIKE '%"error":"No repair parts found."%' 
        THEN 'No repair parts found'
        
        -- "Unit does not have PartSerial entry" (check multiple patterns - must come before "Unable to locate")
        -- IMPORTANT: "No pre-existing family found in FG to use as a reference." = PartSerial entry issue
        WHEN r.log LIKE '%"error":"Unit does not have a PartSerial entry."%' 
             OR r.log LIKE '%"error":"Unit does not have PartSerial entry."%'
             OR r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%'
        THEN 'Unit does not have PartSerial entry'
        
        -- "Not yet trained to resolve" (specific pattern)
        WHEN r.log LIKE '%"error":"Unknown error, not trained to resolve."%' 
        THEN 'Not yet trained to resolve'
        
        -- "Routing Errors" (check multiple patterns)
        WHEN r.log LIKE '%"error":"Unit is not in correct ReImage%' 
             OR r.log LIKE '%"error":"Unit is not in the correct route%' 
             OR r.log LIKE '%"error":"Could not find route/location code for the unit in Plus."%' 
             OR r.log LIKE '%"error":"No route found for pre-existing family%' 
        THEN 'Routing Errors'
        
        -- "Unable to locate a unit for reference" (check specific pattern - must come after PartSerial check)
        -- Only "No required MODs found from pre-existing family" goes here (not the "No pre-existing family" one)
        WHEN r.log LIKE '%"error":"No required MODs found from pre-existing family%' 
        THEN 'Unable to locate a unit for reference'
        
        -- "Unit does not have a work order created yet" (specific pattern)
        WHEN r.log LIKE '%"error":"Unit does not have a work order created yet."%' 
        THEN 'Unit does not have a work order created yet'
        
        -- Default fallback (shouldn't happen if patterns are correct)
        ELSE 'Other/Unknown'
    END AS [Log Translation],
    -- Count total records (matching Excel - Excel uses COUNT(*), not COUNT(DISTINCT))
    COUNT(*) AS [Count of serialNo],
    -- Show isSuccess for filtering/splitting in Power BI
    MAX(r.isSuccess) AS [isSuccess]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
GROUP BY 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE),
    CASE 
        WHEN r.isSuccess = 1 THEN 'Quincy Resolution Attempt'
        WHEN r.log LIKE '%"error":"Attempted too many times to fix."%' THEN 'Attempted too many times'
        WHEN r.log LIKE '%"error":"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."%' 
             OR r.log LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' 
        THEN 'Could not find any GCF errors in B2B outbound data'
        WHEN r.log LIKE '%"error":"No inventory parts were found, likely incorrect route location or failed GTO call."%' 
        THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
        WHEN r.log LIKE '%"error":"No repair parts found."%' 
        THEN 'No repair parts found'
        WHEN r.log LIKE '%"error":"Unit does not have a PartSerial entry."%' 
             OR r.log LIKE '%"error":"Unit does not have PartSerial entry."%'
             OR r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%'
        THEN 'Unit does not have PartSerial entry'
        WHEN r.log LIKE '%"error":"Unknown error, not trained to resolve."%' 
        THEN 'Not yet trained to resolve'
        WHEN r.log LIKE '%"error":"Unit is not in correct ReImage%' 
             OR r.log LIKE '%"error":"Unit is not in the correct route%' 
             OR r.log LIKE '%"error":"Could not find route/location code for the unit in Plus."%' 
             OR r.log LIKE '%"error":"No route found for pre-existing family%' 
        THEN 'Routing Errors'
        WHEN r.log LIKE '%"error":"No required MODs found from pre-existing family%' 
        THEN 'Unable to locate a unit for reference'
        WHEN r.log LIKE '%"error":"Unit does not have a work order created yet."%' 
        THEN 'Unit does not have a work order created yet'
        ELSE 'Other/Unknown'
    END
ORDER BY 
    [Quincy Resolution Date Attempt] DESC,
    [Count of serialNo] DESC;

