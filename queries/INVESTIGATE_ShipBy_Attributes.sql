-- Investigate all attributes related to Ship By Date / Shipping dates
-- Purpose: Find all attributes that might contain ship-by date information

-- ============================================================================
-- 1. SOHeaderAttribute - Attributes on Order Header
-- ============================================================================
SELECT 
    'SOHeaderAttribute' AS AttributeTable,
    ca.AttributeName,
    COUNT(DISTINCT sha.SOHeaderID) AS OrderCount,
    COUNT(*) AS TotalValues,
    MIN(sha.Value) AS SampleValue1,
    MAX(sha.Value) AS SampleValue2,
    MIN(sha.CreateDate) AS FirstSeen,
    MAX(sha.LastActivityDate) AS LastSeen
FROM Plus.pls.SOHeaderAttribute AS sha
INNER JOIN Plus.pls.CodeAttribute AS ca ON ca.ID = sha.AttributeID
INNER JOIN Plus.pls.SOHeader AS sh ON sh.ID = sha.SOHeaderID
WHERE sh.ProgramID = 10053
  AND (
      ca.AttributeName LIKE '%SHIP%'
      OR ca.AttributeName LIKE '%BY%'
      OR ca.AttributeName LIKE '%DATE%'
      OR ca.AttributeName LIKE '%NEED%'
      OR ca.AttributeName LIKE '%DUE%'
      OR ca.AttributeName LIKE '%REQUIRED%'
  )
GROUP BY ca.AttributeName
ORDER BY OrderCount DESC;

-- ============================================================================
-- 2. SOLineAttribute - Attributes on Order Line Items
-- ============================================================================
SELECT 
    'SOLineAttribute' AS AttributeTable,
    ca.AttributeName,
    COUNT(DISTINCT sla.SOLineID) AS LineCount,
    COUNT(*) AS TotalValues,
    MIN(sla.Value) AS SampleValue1,
    MAX(sla.Value) AS SampleValue2,
    MIN(sla.CreateDate) AS FirstSeen,
    MAX(sla.LastActivityDate) AS LastSeen
FROM Plus.pls.SOLineAttribute AS sla
INNER JOIN Plus.pls.CodeAttribute AS ca ON ca.ID = sla.AttributeID
INNER JOIN Plus.pls.SOLine AS sl ON sl.ID = sla.SOLineID
INNER JOIN Plus.pls.SOHeader AS sh ON sh.ID = sl.SOHeaderID
WHERE sh.ProgramID = 10053
  AND (
      ca.AttributeName LIKE '%SHIP%'
      OR ca.AttributeName LIKE '%BY%'
      OR ca.AttributeName LIKE '%DATE%'
      OR ca.AttributeName LIKE '%NEED%'
      OR ca.AttributeName LIKE '%DUE%'
      OR ca.AttributeName LIKE '%REQUIRED%'
  )
GROUP BY ca.AttributeName
ORDER BY LineCount DESC;

-- ============================================================================
-- 3. Sample Values for NEED_BY_DATE (if it exists)
-- ============================================================================
SELECT TOP 20
    'NEED_BY_DATE Samples' AS InfoType,
    sh.CustomerReference,
    sl.PartNo,
    sh.CreateDate,
    sla.Value AS NeedByDateValue,
    sla.CreateDate AS AttributeCreateDate,
    sla.LastActivityDate AS AttributeLastActivity
FROM Plus.pls.SOLineAttribute AS sla
INNER JOIN Plus.pls.CodeAttribute AS ca ON ca.ID = sla.AttributeID
INNER JOIN Plus.pls.SOLine AS sl ON sl.ID = sla.SOLineID
INNER JOIN Plus.pls.SOHeader AS sh ON sh.ID = sl.SOHeaderID
WHERE sh.ProgramID = 10053
  AND ca.AttributeName = 'NEED_BY_DATE'
ORDER BY sla.CreateDate DESC;

-- ============================================================================
-- 4. All Attributes with "SHIP" in the name (case insensitive)
-- ============================================================================
SELECT DISTINCT
    'All SHIP Attributes' AS InfoType,
    ca.AttributeName,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM Plus.pls.SOHeaderAttribute sha2 
            WHERE sha2.AttributeID = ca.ID
        ) THEN 'SOHeaderAttribute'
        WHEN EXISTS (
            SELECT 1 FROM Plus.pls.SOLineAttribute sla2 
            WHERE sla2.AttributeID = ca.ID
        ) THEN 'SOLineAttribute'
        ELSE 'Unknown'
    END AS UsedInTable
FROM Plus.pls.CodeAttribute AS ca
WHERE ca.AttributeName LIKE '%SHIP%'
ORDER BY ca.AttributeName;

-- ============================================================================
-- 5. All Attributes with "BY" or "DATE" in the name (case insensitive)
-- ============================================================================
SELECT DISTINCT
    'All BY/DATE Attributes' AS InfoType,
    ca.AttributeName,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM Plus.pls.SOHeaderAttribute sha2 
            WHERE sha2.AttributeID = ca.ID
        ) THEN 'SOHeaderAttribute'
        WHEN EXISTS (
            SELECT 1 FROM Plus.pls.SOLineAttribute sla2 
            WHERE sla2.AttributeID = ca.ID
        ) THEN 'SOLineAttribute'
        ELSE 'Unknown'
    END AS UsedInTable
FROM Plus.pls.CodeAttribute AS ca
WHERE ca.AttributeName LIKE '%BY%'
   OR ca.AttributeName LIKE '%DATE%'
ORDER BY ca.AttributeName;

