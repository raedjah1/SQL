-- ============================================
-- SIMPLE STATUS ID LOOKUP
-- ============================================
-- Quick query to see what StatusID 15, 17, 38 mean
-- ============================================

-- Simple lookup from Plus CodeStatus table
SELECT 
    cs.ID AS StatusID,
    cs.Description AS StatusDescription
FROM [Plus].[pls].CodeStatus cs
WHERE cs.ID IN (15, 17, 38)
ORDER BY cs.ID;

-- If you want to see all statuses to understand the context
SELECT 
    cs.ID AS StatusID,
    cs.Description AS StatusDescription
FROM [Plus].[pls].CodeStatus cs
ORDER BY cs.ID;

