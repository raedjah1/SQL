-- Find Unfulfilled/Incomplete Tracking Numbers for ASN X-500661125
-- ProgramID = 10068 (ADT)
-- Date Range: December 2025
-- This helps identify tracking numbers that should have been used but weren't

-- ============================================================================
-- PART 1: All Tracking Numbers from CarrierResult - Check Fulfillment Status
-- ============================================================================
SELECT 
    'Tracking Number Fulfillment Status' AS AnalysisType,
    cr.TrackingNo AS TrackingNumber,
    cr.CreateDate AS TrackingCreatedDate,
    cr.Carrier,
    u.Username AS CreatedBy,
    -- Check if this tracking number has any receipts
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Plus.pls.RODockLog dl 
            INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
            WHERE dl.ROHeaderID = rh.ID 
              AND dl.TrackingNo = cr.TrackingNo
              AND rec.ProgramID = 10068
              AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
        ) THEN 'HAS RECEIPTS'
        ELSE 'NO RECEIPTS - UNFULFILLED'
    END AS FulfillmentStatus,
    -- Count how many serials were received with this tracking
    (SELECT COUNT(DISTINCT rec2.SerialNo) 
     FROM Plus.pls.RODockLog dl2 
     INNER JOIN Plus.pls.PartTransaction rec2 ON rec2.RODockLogID = dl2.ID
     WHERE dl2.ROHeaderID = rh.ID 
       AND dl2.TrackingNo = cr.TrackingNo
       AND rec2.ProgramID = 10068
       AND rec2.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
       AND rec2.CreateDate >= '2025-12-01'
    ) AS SerialsReceivedCount,
    -- Show which serials were received (if any)
    (SELECT STRING_AGG(SerialNo, ', ') 
     FROM (
         SELECT DISTINCT rec2.SerialNo 
         FROM Plus.pls.RODockLog dl2 
         INNER JOIN Plus.pls.PartTransaction rec2 ON rec2.RODockLogID = dl2.ID
         WHERE dl2.ROHeaderID = rh.ID 
           AND dl2.TrackingNo = cr.TrackingNo
           AND rec2.ProgramID = 10068
           AND rec2.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
           AND rec2.CreateDate >= '2025-12-01'
     ) AS received) AS SerialsReceived,
    -- Total serials in the ASN (for comparison)
    (SELECT COUNT(DISTINCT ru2.SerialNo) 
     FROM Plus.pls.ROLine rl2 
     INNER JOIN Plus.pls.ROUnit ru2 ON ru2.ROLineID = rl2.ID 
     WHERE rl2.ROHeaderID = rh.ID) AS TotalSerialsInASN
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
LEFT JOIN Plus.pls.[User] u ON u.ID = cr.UserID
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
GROUP BY 
    cr.TrackingNo,
    cr.CreateDate,
    cr.Carrier,
    u.Username,
    rh.ID
ORDER BY 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Plus.pls.RODockLog dl 
            INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
            WHERE dl.ROHeaderID = rh.ID 
              AND dl.TrackingNo = cr.TrackingNo
              AND rec.ProgramID = 10068
              AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
        ) THEN 1
        ELSE 0
    END,
    cr.CreateDate DESC;

-- ============================================================================
-- PART 2: Unfulfilled Tracking Numbers (No Receipts Found)
-- ============================================================================
SELECT 
    'UNFULFILLED TRACKING NUMBERS' AS AnalysisType,
    cr.TrackingNo AS TrackingNumber,
    cr.CreateDate AS TrackingCreatedDate,
    cr.Carrier,
    u.Username AS CreatedBy,
    rh.CustomerReference AS ASN,
    rh.ID AS RMAHeaderID,
    'NO RECEIPTS FOUND - This tracking number was never used for receiving' AS Status
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
LEFT JOIN Plus.pls.[User] u ON u.ID = cr.UserID
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
  -- Only show tracking numbers with NO receipts
  AND NOT EXISTS (
      SELECT 1 
      FROM Plus.pls.RODockLog dl 
      INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
      WHERE dl.ROHeaderID = rh.ID 
        AND dl.TrackingNo = cr.TrackingNo
        AND rec.ProgramID = 10068
        AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
  )
ORDER BY cr.CreateDate DESC;

-- ============================================================================
-- PART 3: RODockLog Entries - Check Which Tracking Numbers Were Actually Used
-- ============================================================================
SELECT 
    'DockLog Tracking Numbers Used' AS AnalysisType,
    dl.TrackingNo AS TrackingNumber,
    dl.CreateDate AS DockLogDate,
    COUNT(DISTINCT rec.SerialNo) AS SerialCount_Received,
    MIN(rec.CreateDate) AS FirstReceiptDate,
    MAX(rec.CreateDate) AS LastReceiptDate,
    (SELECT STRING_AGG(SerialNo, ', ') 
     FROM (SELECT DISTINCT rec2.SerialNo 
           FROM Plus.pls.PartTransaction rec2 
           WHERE rec2.RODockLogID = dl.ID
             AND rec2.ProgramID = 10068
             AND rec2.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')) AS distinct_serials) AS SerialNumbers_Received
FROM Plus.pls.RODockLog dl
INNER JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
    AND rec.ProgramID = 10068
    AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND dl.TrackingNo IS NOT NULL
  AND rec.CreateDate >= '2025-12-01'
GROUP BY 
    dl.TrackingNo,
    dl.CreateDate
ORDER BY dl.CreateDate DESC;

-- ============================================================================
-- PART 4: Comparison - CarrierResult vs RODockLog (Find Missing)
-- ============================================================================
SELECT 
    'MISSING TRACKING NUMBERS' AS AnalysisType,
    cr.TrackingNo AS TrackingNumber_FromCarrierResult,
    cr.CreateDate AS CarrierResultDate,
    cr.Carrier,
    CASE 
        WHEN dl.ID IS NULL THEN 'NOT FOUND IN DOCKLOG - Never used for receiving'
        ELSE 'Found in DockLog'
    END AS DockLogStatus,
    dl.CreateDate AS DockLogDate,
    (SELECT COUNT(DISTINCT rec2.SerialNo) 
     FROM Plus.pls.PartTransaction rec2 
     WHERE rec2.RODockLogID = dl.ID
       AND rec2.ProgramID = 10068
       AND rec2.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
    ) AS SerialsReceivedCount
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
LEFT JOIN Plus.pls.RODockLog dl ON dl.ROHeaderID = rh.ID 
    AND dl.TrackingNo = cr.TrackingNo
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
ORDER BY 
    CASE WHEN dl.ID IS NULL THEN 0 ELSE 1 END,  -- Unfulfilled first
    cr.CreateDate DESC;

