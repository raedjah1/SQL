-- ============================================================================
-- GCF QUINCY DASHBOARD - By Date and Category (Matching Excel Pivot)
-- ============================================================================

SELECT 
    CAST(createDate AS DATE) AS [Quincy Resolution Date Attempt],
    CASE 
        -- Resolution Attempts (Fix Attempt) - must have modsToRepair or modsToRemove
        WHEN log LIKE '%modsToRepair%' OR log LIKE '%modsToRemove%' THEN 'Quincy Resolution Attempt'
        
        -- No Fix Attempt categories (must match Excel exactly)
        WHEN log LIKE '%"error":"Unknown error, not trained to resolve."%' THEN 'Not yet trained to resolve'
        
        WHEN log LIKE '%"error":"Unit is not in correct ReImage%' OR 
             log LIKE '%"error":"Unit is not in the correct route%' OR
             log LIKE '%"error":"Could not find route/location code for the unit in Plus."%' OR
             log LIKE '%"error":"No route found for pre-existing family%' THEN 'Routing Errors'
        
        WHEN log LIKE '%"error":"No repair parts found."%' THEN 'No repair parts found'
        
        WHEN log LIKE '%"error":"Attempted too many times to fix."%' THEN 'Attempted too many times'
        
        WHEN log LIKE '%"error":"Unit does not have a PartSerial entry."%' THEN 'Unit does not have PartSerial entry'
        
        WHEN log LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' OR
             log LIKE '%"error":"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."%' THEN 'Could not find any GCF errors in B2B outbound data'
        
        WHEN log LIKE '%"error":"No inventory parts were found, likely incorrect route location or failed GTO call."%' THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
        
        WHEN log LIKE '%"error":"Unit does not have a work order created yet."%' THEN 'Unit does not have a work order created yet'
        
        WHEN log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' OR
             log LIKE '%"error":"No required MODs found from pre-existing family%' THEN 'Unable to locate a unit for reference'
        
        -- Catch any records that don't match above patterns
        WHEN log IS NULL OR log = '' THEN 'Other/Unknown'
        ELSE 'Other/Unknown'
    END AS [Log Translation],
    -- Fix Attempt count (only for "Quincy Resolution Attempt")
    SUM(CASE 
        WHEN (log LIKE '%modsToRepair%' OR log LIKE '%modsToRemove%') THEN 1 
        ELSE 0 
    END) AS [Fix Attempt],
    -- No Fix Attempt count (all other categories)
    SUM(CASE 
        WHEN NOT (log LIKE '%modsToRepair%' OR log LIKE '%modsToRemove%') THEN 1 
        ELSE 0 
    END) AS [No Fix Attempt],
    COUNT(*) AS [Grand Total]
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) >= '2025-11-08'
    AND CAST(createDate AS DATE) <= '2025-11-19'
GROUP BY CAST(createDate AS DATE),
    CASE 
        WHEN log LIKE '%modsToRepair%' OR log LIKE '%modsToRemove%' THEN 'Quincy Resolution Attempt'
        WHEN log LIKE '%"error":"Unknown error, not trained to resolve."%' THEN 'Not yet trained to resolve'
        WHEN log LIKE '%"error":"Unit is not in correct ReImage%' OR 
             log LIKE '%"error":"Unit is not in the correct route%' OR
             log LIKE '%"error":"Could not find route/location code for the unit in Plus."%' OR
             log LIKE '%"error":"No route found for pre-existing family%' THEN 'Routing Errors'
        WHEN log LIKE '%"error":"No repair parts found."%' THEN 'No repair parts found'
        WHEN log LIKE '%"error":"Attempted too many times to fix."%' THEN 'Attempted too many times'
        WHEN log LIKE '%"error":"Unit does not have a PartSerial entry."%' THEN 'Unit does not have PartSerial entry'
        WHEN log LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' OR
             log LIKE '%"error":"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."%' THEN 'Could not find any GCF errors in B2B outbound data'
        WHEN log LIKE '%"error":"No inventory parts were found, likely incorrect route location or failed GTO call."%' THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
        WHEN log LIKE '%"error":"Unit does not have a work order created yet."%' THEN 'Unit does not have a work order created yet'
        WHEN log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' OR
             log LIKE '%"error":"No required MODs found from pre-existing family%' THEN 'Unable to locate a unit for reference'
        WHEN log IS NULL OR log = '' THEN 'Other/Unknown'
        ELSE 'Other/Unknown'
    END
ORDER BY [Quincy Resolution Date Attempt] DESC, [Log Translation];

-- ============================================================================
-- DEBUG: Check what's in "Other/Unknown" category
-- ============================================================================
SELECT TOP 50
    CAST(createDate AS DATE) AS Date,
    serialNo,
    isSuccess,
    LEFT(log, 300) AS LogPreview
FROM ClarityWarehouse.agentlogs.repair
WHERE programID = 10053
    AND agentName = 'quincy'
    AND CAST(createDate AS DATE) >= '2025-11-08'
    AND CAST(createDate AS DATE) <= '2025-11-19'
    AND NOT (log LIKE '%modsToRepair%' OR log LIKE '%modsToRemove%')
    AND NOT (log LIKE '%"error":"Unknown error, not trained to resolve."%')
    AND NOT (log LIKE '%"error":"Unit is not in correct ReImage%' OR log LIKE '%"error":"Unit is not in the correct route%' OR log LIKE '%"error":"Could not find route/location code%' OR log LIKE '%"error":"No route found for pre-existing family%')
    AND NOT (log LIKE '%"error":"No repair parts found."%')
    AND NOT (log LIKE '%"error":"Attempted too many times to fix."%')
    AND NOT (log LIKE '%"error":"Unit does not have a PartSerial entry."%')
    AND NOT (log LIKE '%"error":"Could not find any GCF errors in B2B outbound data%')
    AND NOT (log LIKE '%"error":"No inventory parts were found%')
    AND NOT (log LIKE '%"error":"Unit does not have a work order created yet."%')
    AND NOT (log LIKE '%"error":"No pre-existing family found%' OR log LIKE '%"error":"No required MODs found from pre-existing family%')
ORDER BY createDate DESC;

