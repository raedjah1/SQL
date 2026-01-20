-- Check if Missing Tracking Numbers Were Dock Logged
-- ASN: X-500661125
-- ProgramID = 10068 (ADT)
-- This checks if tracking numbers exist in RODockLog (were dock logged) but have no receipts

-- ============================================================================
-- PART 1: All Tracking Numbers - DockLog Status vs Receipt Status
-- ============================================================================
SELECT 
    'Tracking Number Status' AS AnalysisType,
    cr.TrackingNo AS TrackingNumber,
    cr.CreateDate AS CarrierResultDate,
    cr.Carrier,
    -- Check if dock logged
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Plus.pls.RODockLog dl 
            WHERE dl.ROHeaderID = rh.ID 
              AND dl.TrackingNo = cr.TrackingNo
        ) THEN 'DOCK LOGGED'
        ELSE 'NOT DOCK LOGGED'
    END AS DockLogStatus,
    dl.CreateDate AS DockLogDate,
    -- Check if has receipts
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Plus.pls.RODockLog dl2 
            INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl2.ID
            WHERE dl2.ROHeaderID = rh.ID 
              AND dl2.TrackingNo = cr.TrackingNo
              AND rec.ProgramID = 10068
              AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
              AND rec.CreateDate >= '2025-12-01'
        ) THEN 'HAS RECEIPTS'
        ELSE 'NO RECEIPTS'
    END AS ReceiptStatus,
    -- Count receipts
    (SELECT COUNT(DISTINCT rec2.SerialNo) 
     FROM Plus.pls.RODockLog dl2 
     INNER JOIN Plus.pls.PartTransaction rec2 ON rec2.RODockLogID = dl2.ID
     WHERE dl2.ROHeaderID = rh.ID 
       AND dl2.TrackingNo = cr.TrackingNo
       AND rec2.ProgramID = 10068
       AND rec2.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
       AND rec2.CreateDate >= '2025-12-01'
    ) AS SerialCount_Received
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
LEFT JOIN Plus.pls.RODockLog dl ON dl.ROHeaderID = rh.ID 
    AND dl.TrackingNo = cr.TrackingNo
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
GROUP BY 
    cr.TrackingNo,
    cr.CreateDate,
    cr.Carrier,
    rh.ID,
    dl.CreateDate
ORDER BY 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Plus.pls.RODockLog dl2 
            WHERE dl2.ROHeaderID = rh.ID 
              AND dl2.TrackingNo = cr.TrackingNo
        ) THEN 0
        ELSE 1
    END,  -- Not dock logged first
    cr.CreateDate DESC;

-- ============================================================================
-- PART 2: Tracking Numbers That Were Dock Logged But Have No Receipts
-- ============================================================================
SELECT 
    'DOCK LOGGED BUT NO RECEIPTS' AS AnalysisType,
    cr.TrackingNo AS TrackingNumber,
    cr.CreateDate AS CarrierResultDate,
    cr.Carrier,
    dl.ID AS DockLogID,
    dl.CreateDate AS DockLogDate,
    'This tracking number was dock logged but never received' AS Issue
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
INNER JOIN Plus.pls.RODockLog dl ON dl.ROHeaderID = rh.ID 
    AND dl.TrackingNo = cr.TrackingNo
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
  -- Dock logged but no receipts
  AND NOT EXISTS (
      SELECT 1 
      FROM Plus.pls.PartTransaction rec 
      WHERE rec.RODockLogID = dl.ID
        AND rec.ProgramID = 10068
        AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
        AND rec.CreateDate >= '2025-12-01'
  )
ORDER BY dl.CreateDate DESC;

-- ============================================================================
-- PART 3: Tracking Numbers That Were Never Dock Logged
-- ============================================================================
SELECT 
    'NEVER DOCK LOGGED' AS AnalysisType,
    cr.TrackingNo AS TrackingNumber,
    cr.CreateDate AS CarrierResultDate,
    cr.Carrier,
    'This tracking number exists in CarrierResult but was never dock logged' AS Issue
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
  -- Never dock logged
  AND NOT EXISTS (
      SELECT 1 
      FROM Plus.pls.RODockLog dl 
      WHERE dl.ROHeaderID = rh.ID 
        AND dl.TrackingNo = cr.TrackingNo
  )
ORDER BY cr.CreateDate DESC;

-- ============================================================================
-- PART 4: Summary - DockLog vs Receipt Status
-- ============================================================================
SELECT 
    'SUMMARY' AS AnalysisType,
    'Total Tracking Numbers in CarrierResult' AS Metric,
    COUNT(DISTINCT cr.TrackingNo) AS Count
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'

UNION ALL

SELECT 
    'SUMMARY' AS AnalysisType,
    'Tracking Numbers Dock Logged' AS Metric,
    COUNT(DISTINCT cr.TrackingNo) AS Count
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
  AND EXISTS (
      SELECT 1 
      FROM Plus.pls.RODockLog dl 
      WHERE dl.ROHeaderID = rh.ID 
        AND dl.TrackingNo = cr.TrackingNo
  )

UNION ALL

SELECT 
    'SUMMARY' AS AnalysisType,
    'Tracking Numbers NOT Dock Logged' AS Metric,
    COUNT(DISTINCT cr.TrackingNo) AS Count
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
  AND NOT EXISTS (
      SELECT 1 
      FROM Plus.pls.RODockLog dl 
      WHERE dl.ROHeaderID = rh.ID 
        AND dl.TrackingNo = cr.TrackingNo
  )

UNION ALL

SELECT 
    'SUMMARY' AS AnalysisType,
    'Dock Logged But No Receipts' AS Metric,
    COUNT(DISTINCT cr.TrackingNo) AS Count
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
INNER JOIN Plus.pls.RODockLog dl ON dl.ROHeaderID = rh.ID 
    AND dl.TrackingNo = cr.TrackingNo
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
  AND NOT EXISTS (
      SELECT 1 
      FROM Plus.pls.PartTransaction rec 
      WHERE rec.RODockLogID = dl.ID
        AND rec.ProgramID = 10068
        AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
        AND rec.CreateDate >= '2025-12-01'
  )

UNION ALL

SELECT 
    'SUMMARY' AS AnalysisType,
    'Dock Logged AND Has Receipts' AS Metric,
    COUNT(DISTINCT cr.TrackingNo) AS Count
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
INNER JOIN Plus.pls.RODockLog dl ON dl.ROHeaderID = rh.ID 
    AND dl.TrackingNo = cr.TrackingNo
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
  AND EXISTS (
      SELECT 1 
      FROM Plus.pls.PartTransaction rec 
      WHERE rec.RODockLogID = dl.ID
        AND rec.ProgramID = 10068
        AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
        AND rec.CreateDate >= '2025-12-01'
  );

