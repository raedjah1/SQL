SELECT 
    u.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATEPART(HOUR, pt.CreateDate) as WorkHour,
    
    -- CUSTOMER CATEGORY FOR SLICER (Mail Innovations takes precedence even if ASN starts with FSR/EX/SP)
    cat.CustomerCategory,
    
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActiveMinutes,
    
    -- DYNAMIC THRESHOLD BY CUSTOMER CATEGORY AND HOUR (computed once)
    tgt.HourlyTarget,

    -- DYNAMIC KPI STATUS (same logic, without repeating the category/target CASE blocks)
    CASE
        WHEN COUNT(*) >= tgt.HourlyTarget THEN 'GREEN - Target Met'
        ELSE 'RED - Below Target'
    END as KPI_Status,
    
    CAST(COUNT(*) * 100.0 / 80 AS DECIMAL(10,2)) as PerformancePercentage
    
FROM Plus.pls.PartTransaction pt
JOIN Plus.pls.[User] u ON u.ID = pt.UserID
JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
-- Identify Mail Innovations: ASNs created by @reconext.com users (matches ADTOperatordashboard.sql exactly)
LEFT JOIN Plus.pls.ROHeader rh_mi ON rh_mi.CustomerReference = pt.CustomerReference 
    AND rh_mi.ProgramID = 10068
OUTER APPLY (
    SELECT TOP 1 crst_mi.UserID
    FROM Plus.pls.CarrierResult crst_mi 
    WHERE crst_mi.OrderHeaderID = rh_mi.ID 
      AND crst_mi.ProgramID = rh_mi.ProgramID 
      AND crst_mi.OrderType = 'RO' 
    ORDER BY crst_mi.ID DESC
) crst_mi
LEFT JOIN Plus.pls.[User] u_mi ON u_mi.ID = crst_mi.UserID 
    AND u_mi.Username LIKE '%@reconext.com'

-- Compute CustomerCategory once (re-used by HourlyTarget + GROUP BY)
CROSS APPLY (
    SELECT
    CASE
        WHEN u_mi.ID IS NOT NULL THEN 'Mail Innovations'
        WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
        WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
        WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
        ELSE 'FSR'
        END AS CustomerCategory
) cat

-- Compute HourlyTarget once (re-used by KPI_Status + GROUP BY)
CROSS APPLY (
    SELECT
        CASE
            -- Mail Innovations (baseline 26/hour, adjusted for breaks)
            WHEN cat.CustomerCategory = 'Mail Innovations' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 20
            WHEN cat.CustomerCategory = 'Mail Innovations' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 22
            WHEN cat.CustomerCategory = 'Mail Innovations' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 22
            WHEN cat.CustomerCategory = 'Mail Innovations' THEN 26

            -- ECR (EX% only)
            WHEN cat.CustomerCategory = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 125
            WHEN cat.CustomerCategory = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 195
            WHEN cat.CustomerCategory = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 195
            WHEN cat.CustomerCategory = 'ECR' THEN 250

            -- SP (Special Projects)
            WHEN cat.CustomerCategory = 'SP' THEN 60

            -- FSR (original targets)
            WHEN cat.CustomerCategory = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 19
            WHEN cat.CustomerCategory = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 29
            WHEN cat.CustomerCategory = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 29
            WHEN cat.CustomerCategory = 'FSR' THEN 38

            -- No Customer Reference (lower targets)
            WHEN cat.CustomerCategory = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 15
            WHEN cat.CustomerCategory = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 22
            WHEN cat.CustomerCategory = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 22
            ELSE 30
        END AS HourlyTarget
) tgt

WHERE u.Username IS NOT NULL
  AND pt.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'

GROUP BY
    u.Username,
    CAST(pt.CreateDate as DATE),
    DATEPART(HOUR, pt.CreateDate),
    cat.CustomerCategory,
    tgt.HourlyTarget;