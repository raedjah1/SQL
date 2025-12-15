-- ============================================================================
-- Quincy Interactions - No Resolution Attempt (by Reason)
-- ============================================================================
-- This query categorizes interactions where Quincy did NOT attempt a resolution
-- (isSuccess = 0) by the reason why no attempt was made
-- ============================================================================

SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    -- Total "No Resolution Attempt" interactions
    COUNT(*) AS [TotalNoResolutionAttempts],
    -- Breakdown by reason (matching Excel categorization - order matters, check specific patterns first)
    -- Note: Must check more specific patterns before general ones
    SUM(CASE 
        -- Check longer pattern first (more specific)
        WHEN r.log LIKE '%"error":"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."%' 
        THEN 1 
        -- Then shorter pattern
        WHEN r.log LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' 
        THEN 1 
        ELSE 0 
    END) AS [CouldNotFindGCFErrors],
    SUM(CASE 
        WHEN r.log LIKE '%"error":"No inventory parts were found, likely incorrect route location or failed GTO call."%' 
        THEN 1 
        ELSE 0 
    END) AS [NoInventoryPartsFound],
    SUM(CASE 
        WHEN r.log LIKE '%"error":"No repair parts found."%' 
        THEN 1 
        ELSE 0 
    END) AS [NoRepairPartsFound],
    SUM(CASE 
        WHEN r.log LIKE '%"error":"Unit does not have a PartSerial entry."%' 
        THEN 1 
        ELSE 0 
    END) AS [UnitDoesNotHavePartSerialEntry],
    SUM(CASE 
        WHEN r.log LIKE '%"error":"Unknown error, not trained to resolve."%' 
        THEN 1 
        ELSE 0 
    END) AS [NotYetTrainedToResolve],
    SUM(CASE 
        -- Check specific routing error patterns (order matters)
        WHEN r.log LIKE '%"error":"Unit is not in correct ReImage%' 
        THEN 1 
        WHEN r.log LIKE '%"error":"Unit is not in the correct route%' 
        THEN 1 
        WHEN r.log LIKE '%"error":"Could not find route/location code for the unit in Plus."%' 
        THEN 1 
        WHEN r.log LIKE '%"error":"No route found for pre-existing family%' 
        THEN 1 
        ELSE 0 
    END) AS [RoutingErrors],
    SUM(CASE 
        WHEN r.log LIKE '%"error":"Attempted too many times to fix."%' 
        THEN 1 
        ELSE 0 
    END) AS [AttemptedTooManyTimes],
    SUM(CASE 
        -- Check specific patterns (order matters)
        WHEN r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' 
        THEN 1 
        WHEN r.log LIKE '%"error":"No required MODs found from pre-existing family%' 
        THEN 1 
        ELSE 0 
    END) AS [UnableToLocateUnitForReference],
    SUM(CASE 
        WHEN r.log LIKE '%"error":"Unit does not have a work order created yet."%' 
        THEN 1 
        ELSE 0 
    END) AS [UnitDoesNotHaveWorkOrder],
    -- Percentages (as decimals 0.0 to 1.0, not multiplied by 100)
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.log LIKE '%"error":"Could not find any GCF errors in B2B outbound data, or there were too many attempts to resolve."%' 
             OR r.log LIKE '%"error":"Could not find any GCF errors in B2B outbound data."%' 
        THEN 1 
        ELSE 0 
    END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [CouldNotFindGCFErrorsPercent],
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.log LIKE '%"error":"No inventory parts were found, likely incorrect route location or failed GTO call."%' 
        THEN 1 
        ELSE 0 
    END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [NoInventoryPartsFoundPercent],
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.log LIKE '%"error":"No repair parts found."%' 
        THEN 1 
        ELSE 0 
    END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [NoRepairPartsFoundPercent],
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.log LIKE '%"error":"Unit does not have a PartSerial entry."%' 
        THEN 1 
        ELSE 0 
    END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [UnitDoesNotHavePartSerialEntryPercent],
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.log LIKE '%"error":"Unknown error, not trained to resolve."%' 
        THEN 1 
        ELSE 0 
    END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [NotYetTrainedToResolvePercent],
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.log LIKE '%"error":"Unit is not in correct ReImage%' 
             OR r.log LIKE '%"error":"Unit is not in the correct route%' 
             OR r.log LIKE '%"error":"Could not find route/location code for the unit in Plus."%' 
             OR r.log LIKE '%"error":"No route found for pre-existing family%' 
        THEN 1 
        ELSE 0 
    END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [RoutingErrorsPercent],
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.log LIKE '%"error":"Attempted too many times to fix."%' 
        THEN 1 
        ELSE 0 
    END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [AttemptedTooManyTimesPercent],
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.log LIKE '%"error":"No pre-existing family found in FG to use as a reference."%' 
             OR r.log LIKE '%"error":"No required MODs found from pre-existing family%' 
        THEN 1 
        ELSE 0 
    END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [UnableToLocateUnitForReferencePercent],
    CAST(ROUND(CAST(SUM(CASE 
        WHEN r.log LIKE '%"error":"Unit does not have a work order created yet."%' 
        THEN 1 
        ELSE 0 
    END) AS FLOAT) / NULLIF(COUNT(*), 0), 4) AS DECIMAL(5,4)) AS [UnitDoesNotHaveWorkOrderPercent]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 0  -- Only "No Resolution Attempt" interactions
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
GROUP BY CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
ORDER BY [Date] DESC;

