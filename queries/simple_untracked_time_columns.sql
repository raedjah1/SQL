-- =====================================================
-- SIMPLE CALCULATED COLUMNS FOR UNTRACKED TIME
-- =====================================================
-- Add these columns to your existing efficiency query

-- In your main SELECT, add these calculated columns:

-- ESTIMATED ACTUAL WORKING MINUTES (using transaction frequency)
CASE 
    WHEN COUNT(*) > 1 
    THEN CAST(COUNT(*) AS FLOAT) * 2.0  -- Assume 2 minutes per transaction average
    ELSE DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate))
END as EstimatedWorkingMinutes,

-- TIME UTILIZATION PERCENTAGE  
CASE 
    WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0
    THEN (CASE 
            WHEN COUNT(*) > 1 
            THEN CAST(COUNT(*) AS FLOAT) * 2.0  
            ELSE DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate))
          END) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 100
    ELSE 100
END as TimeUtilizationPercentage,

-- CORRECTED TRANSACTIONS PER HOUR
CASE 
    WHEN COUNT(*) > 1 AND (CAST(COUNT(*) AS FLOAT) * 2.0) > 0
    THEN CAST(COUNT(*) AS FLOAT) / (CAST(COUNT(*) AS FLOAT) * 2.0) * 60
    WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
    THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
    ELSE COUNT(*) 
END as CorrectedTransactionsPerHour,

-- EFFICIENCY IMPROVEMENT INDICATOR
CASE 
    WHEN COUNT(*) > 1 AND DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > (COUNT(*) * 2)
    THEN 'GAPS DETECTED'
    WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) <= 5
    THEN 'CONTINUOUS WORK'
    ELSE 'NORMAL PACE'
END as WorkPatternIndicator






