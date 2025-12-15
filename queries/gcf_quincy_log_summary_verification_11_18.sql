-- ============================================================================
-- QUINCY LOG SUMMARY - VERIFICATION FOR 11/18/2025
-- ============================================================================
-- Quick verification query to compare with Excel data for 11/18/2025
-- Shows breakdown by Log Translation category
-- ============================================================================

-- Summary by category
SELECT 
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
    END AS [Log Translation],
    COUNT(*) AS [Count of serialNo],
    COUNT(*) AS [TotalRecords],
    SUM(CASE WHEN r.isSuccess = 1 THEN 1 ELSE 0 END) AS [FixAttempt],
    SUM(CASE WHEN r.isSuccess = 0 THEN 1 ELSE 0 END) AS [NoFixAttempt]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-18'
GROUP BY 
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
ORDER BY [Count of serialNo] DESC;

-- Total summary
SELECT 
    'Total' AS [Summary],
    COUNT(*) AS [Count of serialNo],
    COUNT(*) AS [TotalRecords],
    SUM(CASE WHEN r.isSuccess = 1 THEN 1 ELSE 0 END) AS [FixAttempt],
    SUM(CASE WHEN r.isSuccess = 0 THEN 1 ELSE 0 END) AS [NoFixAttempt]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-18';

