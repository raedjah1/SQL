-- =====================================================
-- INVESTIGATE DOCK LOG CODES - WHAT DOES CODE 1 MEAN?
-- =====================================================

-- Check all possible code fields in RODockLog
SELECT TOP 10
    dl.*,
    dla.AttributeID,
    dla.[Value] as SerialNumber
FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
WHERE dl.ProgramID = 10053
ORDER BY dl.CreateDate DESC;

-- Look for STATUS or CODE fields and their values
SELECT 
    DISTINCT 
    dl.Status,
    COUNT(*) as RecordCount
FROM Plus.pls.RODockLog dl
WHERE dl.ProgramID = 10053
GROUP BY dl.Status
ORDER BY dl.Status;

-- Check if there's a CodeType or similar field
SELECT 
    DISTINCT 
    dl.CodeType,
    COUNT(*) as RecordCount  
FROM Plus.pls.RODockLog dl
WHERE dl.ProgramID = 10053
GROUP BY dl.CodeType
ORDER BY dl.CodeType;

-- Look for any field that might contain "1" as a code
SELECT TOP 20
    dl.ID,
    dl.Status,
    dl.CreateDate,
    -- Add other potential code fields here
    dla.[Value] as SerialNumber
FROM Plus.pls.RODockLog dl
    LEFT JOIN Plus.pls.RODockLogAttribute dla ON dla.RODockLogID = dl.ID AND dla.AttributeID = 627
WHERE dl.ProgramID = 10053
  AND (dl.Status = '1' OR dl.Status = 1)  -- Check if Status = 1
ORDER BY dl.CreateDate DESC;

-- Check if there's a lookup table for dock log codes
SELECT 
    c.ID,
    c.Code,
    c.Description,
    c.CodeType
FROM Plus.pls.Code c
WHERE c.CodeType LIKE '%DOCK%' OR c.CodeType LIKE '%LOG%'
ORDER BY c.CodeType, c.Code;






