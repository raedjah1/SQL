SELECT 
    u.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATEPART(HOUR, pt.CreateDate) as WorkHour,
    
    -- CUSTOMER CATEGORY FOR SLICER
    CASE
        WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
        WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
        WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
        ELSE 'FSR'
    END as CustomerCategory,
    
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActiveMinutes,
    
    -- DYNAMIC THRESHOLD BY CUSTOMER CATEGORY AND HOUR
    CASE
        -- ECR Thresholds (Ultra-High - ~250/hour baseline) - EX% ONLY
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 125
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 195
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 195
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' THEN 250
        
        -- SP Thresholds (Special Projects - 60 target all hours)
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'SP' THEN 60
        
        -- FSR Thresholds (Original targets)
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 19
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 29
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 29
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' THEN 38
        
        -- No Customer Reference Thresholds (Lower targets)
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 15
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 22
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 22
        ELSE 30
    END as HourlyTarget,
    
    -- DYNAMIC KPI STATUS BY CUSTOMER CATEGORY AND HOUR
    CASE
        -- ECR KPI Status (Ultra-High thresholds) - EX% ONLY
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 12 AND COUNT(*) >= 125 THEN 'GREEN - Target Met'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 'RED - Below Target'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 9 AND COUNT(*) >= 195 THEN 'GREEN - Target Met'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 'RED - Below Target'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 14 AND COUNT(*) >= 195 THEN 'GREEN - Target Met'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 'RED - Below Target'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'ECR' AND COUNT(*) >= 250 THEN 'GREEN - Target Met'
        
        -- SP KPI Status (Special Projects - 60 target all hours)
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'SP' AND COUNT(*) >= 60 THEN 'GREEN - Target Met'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'SP' THEN 'RED - Below Target'
        
        -- FSR KPI Status (Original targets)
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 12 AND COUNT(*) >= 19 THEN 'GREEN - Target Met'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 'RED - Below Target'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 9 AND COUNT(*) >= 29 THEN 'GREEN - Target Met'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 'RED - Below Target'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 14 AND COUNT(*) >= 29 THEN 'GREEN - Target Met'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 'RED - Below Target'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'FSR' AND COUNT(*) >= 38 THEN 'GREEN - Target Met'
        
        -- No Customer Reference KPI Status (Lower targets)
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 12 AND COUNT(*) >= 15 THEN 'GREEN - Target Met'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 12 THEN 'RED - Below Target'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 9 AND COUNT(*) >= 22 THEN 'GREEN - Target Met'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 9 THEN 'RED - Below Target'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 14 AND COUNT(*) >= 22 THEN 'GREEN - Target Met'  
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND DATEPART(HOUR, pt.CreateDate) = 14 THEN 'RED - Below Target'
        WHEN (CASE WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR' WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP' WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference' ELSE 'FSR' END) = 'No Customer Reference' AND COUNT(*) >= 30 THEN 'GREEN - Target Met'
        
        ELSE 'RED - Below Target'
    END as KPI_Status,
    
    CAST(COUNT(*) * 100.0 / 80 AS DECIMAL(10,2)) as PerformancePercentage
    
FROM Plus.pls.PartTransaction pt
JOIN Plus.pls.[User] u ON u.ID = pt.UserID
JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE u.Username IS NOT NULL
  AND pt.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
GROUP BY u.Username, CAST(pt.CreateDate as DATE), DATEPART(HOUR, pt.CreateDate),
    CASE
        WHEN pt.CustomerReference LIKE 'EX%' THEN 'ECR'
        WHEN pt.CustomerReference LIKE 'SP%' THEN 'SP'
        WHEN pt.CustomerReference IS NULL THEN 'No Customer Reference'
        ELSE 'FSR'
    END;