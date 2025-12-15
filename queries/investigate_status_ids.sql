-- ============================================
-- INVESTIGATE STATUS ID MEANINGS
-- ============================================
-- This query shows what StatusID values 15, 17, 38 mean
-- ============================================

-- Check Plus database CodeStatus table
SELECT 
    'Plus' AS Source,
    cs.ID AS StatusID,
    cs.Description AS StatusDescription,
    COUNT(woh.ID) AS WorkOrderCount
FROM [Plus].[pls].CodeStatus cs
LEFT JOIN [Plus].[pls].WOHeader woh ON woh.StatusID = cs.ID
WHERE cs.ID IN (15, 17, 38)
GROUP BY cs.ID, cs.Description
ORDER BY cs.ID;

-- Check all statuses in Plus to see what 15, 17, 38 are
SELECT 
    'Plus - All Statuses' AS Source,
    cs.ID AS StatusID,
    cs.Description AS StatusDescription
FROM [Plus].[pls].CodeStatus cs
WHERE cs.ID IN (15, 17, 38)
ORDER BY cs.ID;

-- Check if there are other statuses that might be related
SELECT 
    'Plus - Related Statuses' AS Source,
    cs.ID AS StatusID,
    cs.Description AS StatusDescription
FROM [Plus].[pls].CodeStatus cs
WHERE cs.Description LIKE '%COMPLETE%'
   OR cs.Description LIKE '%SHIP%'
   OR cs.Description LIKE '%FINISH%'
   OR cs.Description LIKE '%DONE%'
   OR cs.Description LIKE '%PASS%'
ORDER BY cs.ID;

-- Check ClarityLakehouse status mappings (from the UNION ALL query logic)
SELECT 
    'ClarityLakehouse Status Mapping' AS Source,
    CASE
        WHEN so.on_hold_flag = 'TRUE' THEN 28
        WHEN so.quotation_result IN ('1', '2') THEN 17
        WHEN so.quotation_result = '3' THEN 15
        ELSE 19
    END AS StatusID,
    CASE
        WHEN so.on_hold_flag = 'TRUE' THEN 'HOLD'
        WHEN so.quotation_result IN ('1', '2') THEN 'SCRAP'
        WHEN so.quotation_result = '3' THEN 'REPAIR'
        ELSE 'WIP'
    END AS StatusDescription,
    COUNT(*) AS OrderCount
FROM ClarityLakehouse.ifsapp.shop_ord_tab so
WHERE CASE
        WHEN so.on_hold_flag = 'TRUE' THEN 28
        WHEN so.quotation_result IN ('1', '2') THEN 17
        WHEN so.quotation_result = '3' THEN 15
        ELSE 19
    END IN (15, 17, 38)
GROUP BY 
    CASE
        WHEN so.on_hold_flag = 'TRUE' THEN 28
        WHEN so.quotation_result IN ('1', '2') THEN 17
        WHEN so.quotation_result = '3' THEN 15
        ELSE 19
    END,
    CASE
        WHEN so.on_hold_flag = 'TRUE' THEN 'HOLD'
        WHEN so.quotation_result IN ('1', '2') THEN 'SCRAP'
        WHEN so.quotation_result = '3' THEN 'REPAIR'
        ELSE 'WIP'
    END
ORDER BY StatusID;

-- Check what quotation_result values mean
SELECT DISTINCT
    'ClarityLakehouse Quotation Results' AS Source,
    so.quotation_result,
    CASE
        WHEN so.quotation_result = '1' THEN 'Result 1'
        WHEN so.quotation_result = '2' THEN 'Result 2'
        WHEN so.quotation_result = '3' THEN 'Result 3'
        ELSE 'Other'
    END AS Description,
    COUNT(*) AS OrderCount
FROM ClarityLakehouse.ifsapp.shop_ord_tab so
WHERE so.quotation_result IS NOT NULL
GROUP BY so.quotation_result
ORDER BY so.quotation_result;

-- Check actual work orders with these status IDs
SELECT TOP 100
    'Plus Work Orders' AS Source,
    woh.ID AS WorkOrderID,
    woh.StatusID,
    cs.Description AS StatusDescription,
    woh.PartNo,
    woh.SerialNo,
    woh.CreateDate,
    woh.LastActivityDate,
    woh.ProgramID
FROM [Plus].[pls].WOHeader woh
INNER JOIN [Plus].[pls].CodeStatus cs ON cs.ID = woh.StatusID
WHERE woh.StatusID IN (15, 17, 38)
ORDER BY woh.CreateDate DESC;

-- Summary: What do StatusIDs 15, 17, 38 represent?
SELECT 
    'SUMMARY' AS Source,
    cs.ID AS StatusID,
    cs.Description AS StatusDescription,
    COUNT(woh.ID) AS TotalWorkOrders,
    MIN(woh.CreateDate) AS FirstSeen,
    MAX(woh.CreateDate) AS LastSeen
FROM [Plus].[pls].CodeStatus cs
LEFT JOIN [Plus].[pls].WOHeader woh ON woh.StatusID = cs.ID
WHERE cs.ID IN (15, 17, 38)
GROUP BY cs.ID, cs.Description
ORDER BY cs.ID;

