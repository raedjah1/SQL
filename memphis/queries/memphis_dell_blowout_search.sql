-- =====================================================
-- DELL BLOW OUT SEARCH
-- =====================================================
-- Purpose: Search for "blow out" references in the database
-- Program: DELL (ProgramID: 10053) - Memphis
-- =====================================================

-- Search for "blow out" in all text fields
SELECT 
    'BLOW OUT SEARCH' as SearchType,
    'PartTransaction' as FieldName,
    pt.PartTransaction as FieldValue,
    COUNT(*) as Occurrences
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND (
      pt.PartTransaction LIKE '%BLOW%' 
      OR pt.PartTransaction LIKE '%OUT%'
  )
GROUP BY pt.PartTransaction
ORDER BY Occurrences DESC;

-- Search for "blow out" in location fields
SELECT 
    'BLOW OUT SEARCH' as SearchType,
    'Location' as FieldName,
    pt.Location as FieldValue,
    COUNT(*) as Occurrences
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.Location IS NOT NULL
  AND (
      pt.Location LIKE '%BLOW%' 
      OR pt.Location LIKE '%OUT%'
  )
GROUP BY pt.Location
ORDER BY Occurrences DESC;

-- Search for "blow out" in part number fields
SELECT 
    'BLOW OUT SEARCH' as SearchType,
    'PartNo' as FieldName,
    pt.PartNo as FieldValue,
    COUNT(*) as Occurrences
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.PartNo IS NOT NULL
  AND (
      pt.PartNo LIKE '%BLOW%' 
      OR pt.PartNo LIKE '%OUT%'
  )
GROUP BY pt.PartNo
ORDER BY Occurrences DESC;

-- Search for "blow out" in serial number fields
SELECT 
    'BLOW OUT SEARCH' as SearchType,
    'SerialNo' as FieldName,
    pt.SerialNo as FieldValue,
    COUNT(*) as Occurrences
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.SerialNo IS NOT NULL
  AND (
      pt.SerialNo LIKE '%BLOW%' 
      OR pt.SerialNo LIKE '%OUT%'
  )
GROUP BY pt.SerialNo
ORDER BY Occurrences DESC;

-- Search for "blow out" in work order fields
SELECT 
    'BLOW OUT SEARCH' as SearchType,
    'WorkOrderNo' as FieldName,
    pt.WorkOrderNo as FieldValue,
    COUNT(*) as Occurrences
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -3, GETDATE())  -- Last 3 months
  AND pt.WorkOrderNo IS NOT NULL
  AND (
      pt.WorkOrderNo LIKE '%BLOW%' 
      OR pt.WorkOrderNo LIKE '%OUT%'
  )
GROUP BY pt.WorkOrderNo
ORDER BY Occurrences DESC;
