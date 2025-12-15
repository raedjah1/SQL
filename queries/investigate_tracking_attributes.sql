-- Investigative Query: Available Tracking Attributes and Tech ID Fields
-- Purpose: Find all tracking-related attributes and identify tech ID for branching logic

-- 1. Check RODockLog TrackingNo structure and patterns
SELECT 
    'RODockLog TrackingNo Analysis' AS InvestigationArea,
    dl.TrackingNo,
    COUNT(*) AS OccurrenceCount,
    MIN(dl.CreateDate) AS FirstSeen,
    MAX(dl.CreateDate) AS LastSeen,
    COUNT(DISTINCT dl.ROHeaderID) AS UniqueASNs,
    -- Check for patterns that might indicate tech ID
    CASE 
        WHEN dl.TrackingNo LIKE '%-%' THEN 'Has Dash'
        WHEN dl.TrackingNo LIKE '%_%' THEN 'Has Underscore'
        WHEN ISNUMERIC(LEFT(dl.TrackingNo, 1)) = 1 THEN 'Starts with Number'
        WHEN ISNUMERIC(LEFT(dl.TrackingNo, 1)) = 0 THEN 'Starts with Letter'
        ELSE 'Other'
    END AS PatternType,
    LEN(dl.TrackingNo) AS TrackingNoLength
FROM Plus.pls.RODockLog dl
JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
WHERE rh.ProgramID = 10068
  AND dl.TrackingNo IS NOT NULL
  AND dl.TrackingNo != ''
GROUP BY 
    dl.TrackingNo,
    CASE 
        WHEN dl.TrackingNo LIKE '%-%' THEN 'Has Dash'
        WHEN dl.TrackingNo LIKE '%_%' THEN 'Has Underscore'
        WHEN ISNUMERIC(LEFT(dl.TrackingNo, 1)) = 1 THEN 'Starts with Number'
        WHEN ISNUMERIC(LEFT(dl.TrackingNo, 1)) = 0 THEN 'Starts with Letter'
        ELSE 'Other'
    END,
    LEN(dl.TrackingNo)
ORDER BY OccurrenceCount DESC;

-- 2. Check for tracking-related attributes in CodeAttribute
SELECT 
    'Available Tracking Attributes' AS InvestigationArea,
    ca.ID AS AttributeID,
    ca.AttributeName,
    COUNT(DISTINCT psa.PartSerialID) AS PartSerialUsage,
    COUNT(DISTINCT pna.PartNo) AS PartNoUsage,
    COUNT(DISTINCT roa.ROHeaderID) AS ROHeaderUsage
FROM Plus.pls.CodeAttribute ca
LEFT JOIN Plus.pls.PartSerialAttribute psa ON psa.AttributeID = ca.ID
LEFT JOIN Plus.pls.PartNoAttribute pna ON pna.AttributeID = ca.ID
LEFT JOIN Plus.pls.ROHeaderAttribute roa ON roa.AttributeID = ca.ID
WHERE UPPER(ca.AttributeName) LIKE '%TRACK%'
   OR UPPER(ca.AttributeName) LIKE '%TECH%'
   OR UPPER(ca.AttributeName) LIKE '%ID%'
   OR UPPER(ca.AttributeName) LIKE '%CARRIER%'
   OR UPPER(ca.AttributeName) LIKE '%SHIP%'
GROUP BY ca.ID, ca.AttributeName
ORDER BY ca.AttributeName;

-- 3. Check ROHeader attributes for tracking/tech ID
SELECT 
    'ROHeader Attributes' AS InvestigationArea,
    ca.AttributeName,
    roa.Value,
    COUNT(*) AS OccurrenceCount,
    COUNT(DISTINCT roa.ROHeaderID) AS UniqueROHeaders
FROM Plus.pls.ROHeaderAttribute roa
JOIN Plus.pls.CodeAttribute ca ON ca.ID = roa.AttributeID
JOIN Plus.pls.ROHeader rh ON rh.ID = roa.ROHeaderID
WHERE rh.ProgramID = 10068
  AND (
    UPPER(ca.AttributeName) LIKE '%TRACK%'
    OR UPPER(ca.AttributeName) LIKE '%TECH%'
    OR UPPER(ca.AttributeName) LIKE '%ID%'
    OR UPPER(ca.AttributeName) LIKE '%CARRIER%'
  )
GROUP BY ca.AttributeName, roa.Value
ORDER BY ca.AttributeName, OccurrenceCount DESC;

-- 4. Check RODockLog for any additional fields that might be tech ID
SELECT 
    'RODockLog All Fields' AS InvestigationArea,
    'TrackingNo' AS FieldName,
    dl.TrackingNo AS FieldValue,
    COUNT(*) AS OccurrenceCount
FROM Plus.pls.RODockLog dl
JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
WHERE rh.ProgramID = 10068
  AND dl.TrackingNo IS NOT NULL
GROUP BY dl.TrackingNo
HAVING COUNT(*) > 1  -- Show only tracking numbers that appear multiple times
ORDER BY OccurrenceCount DESC;

-- 5. Sample RODockLog records with all fields to see structure
SELECT TOP 20
    'RODockLog Sample Records' AS InvestigationArea,
    dl.ID,
    dl.ROHeaderID,
    rh.CustomerReference AS ASN,
    dl.TrackingNo,
    dl.Qty,
    dl.CreateDate,
    dl.UserID,
    u.Username AS Operator,
    dl.Carrier,
    dl.Reference,
    dl.Notes,
    dl.StatusID,
    cs.Description AS Status
FROM Plus.pls.RODockLog dl
JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
LEFT JOIN Plus.pls.[User] u ON u.ID = dl.UserID
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = dl.StatusID
WHERE rh.ProgramID = 10068
  AND dl.TrackingNo IS NOT NULL
ORDER BY dl.CreateDate DESC;

-- 6. Check if TrackingNo has patterns that could indicate different branches
SELECT 
    'TrackingNo Pattern Analysis' AS InvestigationArea,
    CASE 
        WHEN dl.TrackingNo LIKE 'FSR%' THEN 'FSR Pattern'
        WHEN dl.TrackingNo LIKE 'X-%' THEN 'X- Pattern'
        WHEN dl.TrackingNo LIKE 'EX%' THEN 'EX Pattern'
        WHEN dl.TrackingNo LIKE '1Z%' THEN 'UPS Pattern'
        WHEN dl.TrackingNo LIKE '[0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9]%' THEN 'USPS Pattern'
        WHEN ISNUMERIC(dl.TrackingNo) = 1 THEN 'Numeric Only'
        ELSE 'Other Pattern'
    END AS TrackingPattern,
    COUNT(*) AS OccurrenceCount,
    COUNT(DISTINCT dl.ROHeaderID) AS UniqueASNs,
    MIN(dl.TrackingNo) AS SampleTrackingNo
FROM Plus.pls.RODockLog dl
JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
WHERE rh.ProgramID = 10068
  AND dl.TrackingNo IS NOT NULL
  AND dl.TrackingNo != ''
GROUP BY 
    CASE 
        WHEN dl.TrackingNo LIKE 'FSR%' THEN 'FSR Pattern'
        WHEN dl.TrackingNo LIKE 'X-%' THEN 'X- Pattern'
        WHEN dl.TrackingNo LIKE 'EX%' THEN 'EX Pattern'
        WHEN dl.TrackingNo LIKE '1Z%' THEN 'UPS Pattern'
        WHEN dl.TrackingNo LIKE '[0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9]%' THEN 'USPS Pattern'
        WHEN ISNUMERIC(dl.TrackingNo) = 1 THEN 'Numeric Only'
        ELSE 'Other Pattern'
    END
ORDER BY OccurrenceCount DESC;







