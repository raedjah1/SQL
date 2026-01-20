-- Find Tracking Numbers That Were NOT Used for Receiving
-- ASN: X-500661125
-- ProgramID = 10068 (ADT)
-- Date Range: December 2025
-- This confirms that some tracking numbers were never used because all serials were mistakenly received with one tracking number

-- ============================================================================
-- PART 1: All Tracking Numbers for ASN X-500661125 in December 2025
-- ============================================================================
SELECT 
    'All Tracking Numbers for ASN' AS AnalysisType,
    cr.TrackingNo AS TrackingNumber,
    cr.CreateDate AS TrackingCreatedDate,
    cr.Carrier,
    u.Username AS CreatedBy,
    -- Check if ANY receipts exist for this tracking number
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Plus.pls.RODockLog dl 
            INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
            WHERE dl.ROHeaderID = rh.ID 
              AND dl.TrackingNo = cr.TrackingNo
              AND rec.ProgramID = 10068
              AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
              AND rec.CreateDate >= '2025-12-01'
        ) THEN 'HAS RECEIPTS'
        ELSE 'NO RECEIPTS - MISSING/UNFULFILLED'
    END AS ReceiptStatus,
    -- Count receipts for this tracking number
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
              AND rec.CreateDate >= '2025-12-01'
        ) THEN 1
        ELSE 0
    END,  -- Show unfulfilled first
    cr.CreateDate DESC;

-- ============================================================================
-- PART 2: Tracking Numbers With NO Receipts (Definitely Missing)
-- ============================================================================
SELECT 
    'MISSING TRACKING NUMBERS - Never Used for Receiving' AS AnalysisType,
    cr.TrackingNo AS TrackingNumber,
    cr.CreateDate AS TrackingCreatedDate,
    cr.Carrier,
    u.Username AS CreatedBy,
    rh.CustomerReference AS ASN,
    rh.ID AS RMAHeaderID,
    'This tracking number exists in CarrierResult but has ZERO receipts' AS Issue,
    'All serials were mistakenly received with tracking number 792087270817 instead' AS Explanation
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
LEFT JOIN Plus.pls.[User] u ON u.ID = cr.UserID
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
  -- Only show tracking numbers with NO receipts during December 2025
  AND NOT EXISTS (
      SELECT 1 
      FROM Plus.pls.RODockLog dl 
      INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
      WHERE dl.ROHeaderID = rh.ID 
        AND dl.TrackingNo = cr.TrackingNo
        AND rec.ProgramID = 10068
        AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
        AND rec.CreateDate >= '2025-12-01'
  )
ORDER BY cr.CreateDate DESC;

-- ============================================================================
-- PART 3: Summary - What Actually Happened
-- ============================================================================
SELECT 
    'SUMMARY - What Actually Happened' AS AnalysisType,
    'Total Tracking Numbers for ASN' AS Metric,
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
    'SUMMARY - What Actually Happened' AS AnalysisType,
    'Tracking Numbers WITH Receipts' AS Metric,
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
      INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
      WHERE dl.ROHeaderID = rh.ID 
        AND dl.TrackingNo = cr.TrackingNo
        AND rec.ProgramID = 10068
        AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
        AND rec.CreateDate >= '2025-12-01'
  )

UNION ALL

SELECT 
    'SUMMARY - What Actually Happened' AS AnalysisType,
    'Tracking Numbers WITHOUT Receipts (Missing)' AS Metric,
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
      INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
      WHERE dl.ROHeaderID = rh.ID 
        AND dl.TrackingNo = cr.TrackingNo
        AND rec.ProgramID = 10068
        AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
        AND rec.CreateDate >= '2025-12-01'
  )

;

-- ============================================================================
-- PART 4: Detailed List of Missing Tracking Numbers
-- ============================================================================
SELECT 
    cr.TrackingNo AS MissingTrackingNumber,
    cr.CreateDate AS TrackingCreatedDate,
    cr.Carrier,
    u.Username AS CreatedBy,
    'This tracking number was never used for receiving' AS Status,
    'Should have been used instead of 792087270817' AS Note
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
LEFT JOIN Plus.pls.[User] u ON u.ID = cr.UserID
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND cr.CreateDate >= '2025-12-01'
  AND cr.TrackingNo != '792087270817'  -- Exclude the one that was actually used
  AND NOT EXISTS (
      SELECT 1 
      FROM Plus.pls.RODockLog dl 
      INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
      WHERE dl.ROHeaderID = rh.ID 
        AND dl.TrackingNo = cr.TrackingNo
        AND rec.ProgramID = 10068
        AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
        AND rec.CreateDate >= '2025-12-01'
  )
ORDER BY cr.CreateDate DESC;

-- ============================================================================
-- PART 5: Which Tracking Number Was Actually Used (The Mistake)
-- ============================================================================
SELECT 
    'Tracking Number Actually Used (Mistake)' AS AnalysisType,
    dl.TrackingNo AS TrackingNumberUsed,
    COUNT(DISTINCT rec.SerialNo) AS TotalSerialsReceived,
    MIN(rec.CreateDate) AS FirstReceiptDate,
    MAX(rec.CreateDate) AS LastReceiptDate,
    'All 20 serials were mistakenly received with this ONE tracking number' AS Issue
FROM Plus.pls.RODockLog dl
INNER JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
INNER JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
    AND rec.ProgramID = 10068
    AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND rec.CreateDate >= '2025-12-01'
  AND rec.SerialNo IN (
      '57161GZD629QL4',
      '2402DNG053451',
      '2402DNG052235',
      '2508DQA003617',
      '2504H50030795',
      'ADTRXTS2512220810081608491',
      'ADTRXTS2512220810496578491',
      'ADTRXTS2512220816235238491',
      '147F191B0153E186',
      'ADTRXTS2512220817576238491',
      'ADTRXTS2512220818177208491',
      '2009CTZ021182',
      '1704ACM005664',
      '2160E8',
      'ADTRXTS2512220821283278491',
      'ADTRXTS2512220822262208491',
      '1704ACM005752',
      '2311CTZ004643',
      '0057874',
      '147F193B015F98B4'
  )
GROUP BY dl.TrackingNo;

