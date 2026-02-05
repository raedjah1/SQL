-- Investigate why SIXMINICT2A has no FromLoc_w_OnHandQty
-- Purpose: Root cause why location is NULL for this part

-- ============================================================================
-- 1. Check if PartQty exists for SIXMINICT2A
-- ============================================================================
SELECT 
    'PartQty Check' AS InvestigationType,
    pq.PartNo,
    pq.AvailableQty,
    pq.LocationID,
    pq.ConfigurationID,
    pq.PalletBoxNo,
    pq.LotNo,
    pq.CreateDate,
    pq.LastActivityDate
FROM Plus.pls.PartQty pq
WHERE pq.PartNo = 'SIXMINICT2A'
  AND pq.ProgramID = 10068
ORDER BY pq.AvailableQty DESC, pq.CreateDate DESC;

-- ============================================================================
-- 2. Check PartLocation for SIXMINICT2A (via PartQty)
-- ============================================================================
SELECT 
    'PartLocation via PartQty' AS InvestigationType,
    pq.PartNo,
    pq.AvailableQty,
    loc.ID AS LocationID,
    loc.LocationNo,
    loc.Warehouse,
    loc.Bay,
    loc.StatusID,
    cs.Description AS StatusDescription,
    -- Check if it matches the filters
    CASE WHEN loc.LocationNo LIKE 'FGI%' THEN 'YES' ELSE 'NO' END AS Matches_FGI,
    CASE WHEN loc.StatusID = (SELECT ID FROM Plus.pls.CodeStatus WHERE Description = 'ACTIVE') THEN 'YES' ELSE 'NO' END AS Matches_ACTIVE,
    CASE WHEN (loc.Bay LIKE '%Z%' OR loc.LocationNo LIKE 'FGI.ADT.Z%') THEN 'YES' ELSE 'NO' END AS Matches_Z_Location,
    -- Overall match
    CASE 
        WHEN loc.LocationNo LIKE 'FGI%' 
         AND loc.StatusID = (SELECT ID FROM Plus.pls.CodeStatus WHERE Description = 'ACTIVE')
         AND (loc.Bay LIKE '%Z%' OR loc.LocationNo LIKE 'FGI.ADT.Z%')
        THEN 'MATCHES ALL FILTERS'
        ELSE 'DOES NOT MATCH'
    END AS FilterMatchStatus
FROM Plus.pls.PartQty pq
LEFT JOIN Plus.pls.PartLocation loc ON loc.ID = pq.LocationID
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = loc.StatusID
WHERE pq.PartNo = 'SIXMINICT2A'
  AND pq.ProgramID = 10068
  AND pq.AvailableQty > 0
ORDER BY pq.AvailableQty DESC;

-- ============================================================================
-- 3. Check ALL PartLocation records for SIXMINICT2A (even with 0 qty)
-- ============================================================================
SELECT 
    'All PartQty Records (including 0 qty)' AS InvestigationType,
    pq.PartNo,
    pq.AvailableQty,
    loc.LocationNo,
    loc.Warehouse,
    loc.Bay,
    cs.Description AS StatusDescription,
    CASE WHEN pq.AvailableQty > 0 THEN 'Has Inventory' ELSE 'No Inventory' END AS InventoryStatus
FROM Plus.pls.PartQty pq
LEFT JOIN Plus.pls.PartLocation loc ON loc.ID = pq.LocationID
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = loc.StatusID
WHERE pq.PartNo = 'SIXMINICT2A'
  AND pq.ProgramID = 10068
ORDER BY pq.AvailableQty DESC;

-- ============================================================================
-- 4. Check if PartLocation exists but doesn't match filters (show what's wrong)
-- ============================================================================
SELECT 
    'PartLocation Filter Analysis' AS InvestigationType,
    pq.PartNo,
    pq.AvailableQty,
    loc.LocationNo,
    loc.Warehouse,
    loc.Bay,
    loc.StatusID,
    cs.Description AS StatusDescription,
    -- Show why it doesn't match
    CASE 
        WHEN loc.LocationNo IS NULL THEN 'NO LOCATION'
        WHEN loc.LocationNo NOT LIKE 'FGI%' THEN 'NOT FGI Location: ' + ISNULL(loc.LocationNo, 'NULL')
        WHEN loc.StatusID != (SELECT ID FROM Plus.pls.CodeStatus WHERE Description = 'ACTIVE') THEN 'NOT ACTIVE: ' + ISNULL(cs.Description, 'NULL')
        WHEN loc.Bay NOT LIKE '%Z%' AND loc.LocationNo NOT LIKE 'FGI.ADT.Z%' THEN 'NOT Z Location: Bay=' + ISNULL(loc.Bay, 'NULL') + ', LocationNo=' + ISNULL(loc.LocationNo, 'NULL')
        ELSE 'SHOULD MATCH - CHECK QUERY'
    END AS WhyNoMatch
FROM Plus.pls.PartQty pq
LEFT JOIN Plus.pls.PartLocation loc ON loc.ID = pq.LocationID
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = loc.StatusID
WHERE pq.PartNo = 'SIXMINICT2A'
  AND pq.ProgramID = 10068
  AND pq.AvailableQty > 0
ORDER BY pq.AvailableQty DESC;

-- ============================================================================
-- 5. Check what ACTIVE status ID is
-- ============================================================================
SELECT 
    'ACTIVE Status ID Check' AS InvestigationType,
    cs.ID AS StatusID,
    cs.Description
FROM Plus.pls.CodeStatus cs
WHERE cs.Description = 'ACTIVE';

-- ============================================================================
-- 6. Compare with a working part (76724) to see the difference
-- ============================================================================
SELECT 
    'Comparison: Working Part (76724) vs Problem Part (SIXMINICT2A)' AS InvestigationType,
    pq.PartNo,
    pq.AvailableQty,
    loc.LocationNo,
    loc.Warehouse,
    loc.Bay,
    loc.StatusID,
    cs.Description AS StatusDescription,
    CASE 
        WHEN loc.LocationNo LIKE 'FGI%' 
         AND loc.StatusID = (SELECT ID FROM Plus.pls.CodeStatus WHERE Description = 'ACTIVE')
         AND (loc.Bay LIKE '%Z%' OR loc.LocationNo LIKE 'FGI.ADT.Z%')
        THEN 'MATCHES'
        ELSE 'NO MATCH'
    END AS FilterMatchStatus
FROM Plus.pls.PartQty pq
LEFT JOIN Plus.pls.PartLocation loc ON loc.ID = pq.LocationID
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = loc.StatusID
WHERE pq.PartNo IN ('76724', 'SIXMINICT2A')
  AND pq.ProgramID = 10068
  AND pq.AvailableQty > 0
ORDER BY pq.PartNo, pq.AvailableQty DESC;








