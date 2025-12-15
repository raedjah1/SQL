-- ============================================
-- INVESTIGATE DATA PATTERNS FOR REPORTS
-- ============================================
-- This query looks for specific data patterns that might help us understand
-- what the manager meant about receipt reports and inbound shipments

-- ============================================
-- 1. LOOK FOR REFERENCE FIELD PATTERNS
-- ============================================
-- Check what reference fields exist and what they contain
SELECT TOP 10
    'REFERENCE FIELD SAMPLE' as InfoType,
    'vWOHeader' as TableName,
    'CustomerReference' as FieldName,
    CustomerReference as SampleValue,
    COUNT(*) as Count
FROM pls.vWOHeader 
WHERE CustomerReference IS NOT NULL
GROUP BY CustomerReference
ORDER BY COUNT(*) DESC;

-- ============================================
-- 2. LOOK FOR RMA/RTV PATTERNS
-- ============================================
-- Check if there are any RMA/RTV related fields in the data
SELECT TOP 10
    'RMA/RTV PATTERN SEARCH' as InfoType,
    'vWOHeader' as TableName,
    'RepairTypeDescription' as FieldName,
    RepairTypeDescription as SampleValue,
    COUNT(*) as Count
FROM pls.vWOHeader 
WHERE RepairTypeDescription IS NOT NULL
  AND (RepairTypeDescription LIKE '%RMA%' 
       OR RepairTypeDescription LIKE '%RTV%'
       OR RepairTypeDescription LIKE '%return%'
       OR RepairTypeDescription LIKE '%RETURN%')
GROUP BY RepairTypeDescription
ORDER BY COUNT(*) DESC;

-- ============================================
-- 3. LOOK FOR DEPARTMENT PATTERNS
-- ============================================
-- Check if there are any department-related fields
SELECT TOP 10
    'DEPARTMENT PATTERN SEARCH' as InfoType,
    'vWOHeader' as TableName,
    'Username' as FieldName,
    Username as SampleValue,
    COUNT(*) as Count
FROM pls.vWOHeader 
WHERE Username IS NOT NULL
GROUP BY Username
ORDER BY COUNT(*) DESC;

-- ============================================
-- 4. LOOK FOR QUANTITY/UNIT PATTERNS
-- ============================================
-- Check what quantity fields exist in part transactions
SELECT TOP 10
    'QUANTITY PATTERN SEARCH' as InfoType,
    'vPartTransaction' as TableName,
    'QtyRequested' as FieldName,
    QtyRequested as SampleValue,
    COUNT(*) as Count
FROM pls.vPartTransaction 
WHERE QtyRequested IS NOT NULL
GROUP BY QtyRequested
ORDER BY COUNT(*) DESC;

-- ============================================
-- 5. LOOK FOR TRACKING NUMBER PATTERNS
-- ============================================
-- Check if there are any tracking number fields
SELECT TOP 10
    'TRACKING PATTERN SEARCH' as InfoType,
    'vWOHeader' as TableName,
    'BizTalkID' as FieldName,
    BizTalkID as SampleValue,
    COUNT(*) as Count
FROM pls.vWOHeader 
WHERE BizTalkID IS NOT NULL
GROUP BY BizTalkID
ORDER BY COUNT(*) DESC;

-- ============================================
-- 6. LOOK FOR LOCATION PATTERNS
-- ============================================
-- Check what location fields exist
SELECT TOP 10
    'LOCATION PATTERN SEARCH' as InfoType,
    'vWOHeader' as TableName,
    'DefaultLocationNo' as FieldName,
    DefaultLocationNo as SampleValue,
    COUNT(*) as Count
FROM pls.vWOHeader 
WHERE DefaultLocationNo IS NOT NULL
GROUP BY DefaultLocationNo
ORDER BY COUNT(*) DESC;

-- ============================================
-- 7. LOOK FOR PROGRAM PATTERNS
-- ============================================
-- Check what programs exist (DELL, ADT, etc.)
SELECT 
    'PROGRAM PATTERN SEARCH' as InfoType,
    'vWOHeader' as TableName,
    'ProgramID' as FieldName,
    ProgramID as SampleValue,
    COUNT(*) as Count
FROM pls.vWOHeader 
WHERE ProgramID IS NOT NULL
GROUP BY ProgramID
ORDER BY COUNT(*) DESC;

-- ============================================
-- 8. LOOK FOR STATUS PATTERNS
-- ============================================
-- Check what status values exist
SELECT TOP 10
    'STATUS PATTERN SEARCH' as InfoType,
    'vWOHeader' as TableName,
    'StatusDescription' as FieldName,
    StatusDescription as SampleValue,
    COUNT(*) as Count
FROM pls.vWOHeader 
WHERE StatusDescription IS NOT NULL
GROUP BY StatusDescription
ORDER BY COUNT(*) DESC;




































