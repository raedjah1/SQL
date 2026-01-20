-- Analysis: Multiple Tracking Numbers for ASN X-500661125
-- ProgramID = 10068 (ADT)
-- This query helps determine which tracking number should have been used for each serial
--
-- IMPORTANT LIMITATION:
-- There is NO direct database link between a specific tracking number and specific serial numbers.
-- We can only determine:
-- 1. All serials that belong to the ASN (from ROUnit)
-- 2. Which serials were actually received with each tracking number (from PartTransaction)
-- We CANNOT definitively say which serials were "expected" for each tracking number.
-- Multiple tracking numbers for one ASN could mean:
--   - Multiple shipments of the same order
--   - Different parts shipped separately
--   - Or all tracking numbers could be for the same shipment

-- ============================================================================
-- PART 1: All Tracking Numbers for ASN X-500661125
-- ============================================================================
SELECT 
    'All Tracking Numbers for ASN' AS AnalysisType,
    rh.CustomerReference AS ASN,
    cr.TrackingNo AS TrackingNumber,
    cr.CreateDate AS TrackingCreatedDate,
    u.Username AS CreatedBy,
    cr.Carrier,
    cr.ID AS CarrierResultID,
    -- NOTE: This shows ALL serials in the ASN, not necessarily assigned to this specific tracking number
    (SELECT COUNT(DISTINCT ru2.SerialNo) 
     FROM Plus.pls.ROLine rl2 
     INNER JOIN Plus.pls.ROUnit ru2 ON ru2.ROLineID = rl2.ID 
     WHERE rl2.ROHeaderID = rh.ID) AS TotalSerialsInASN,
    (SELECT STRING_AGG(SerialNo, ', ') 
     FROM (SELECT DISTINCT ru2.SerialNo 
           FROM Plus.pls.ROLine rl2 
           INNER JOIN Plus.pls.ROUnit ru2 ON ru2.ROLineID = rl2.ID 
           WHERE rl2.ROHeaderID = rh.ID) AS distinct_serials) AS AllSerialsInASN
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
LEFT JOIN Plus.pls.[User] u ON u.ID = cr.UserID
LEFT JOIN Plus.pls.ROLine rl ON rl.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.ROUnit ru ON ru.ROLineID = rl.ID
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
GROUP BY 
    rh.CustomerReference,
    cr.TrackingNo,
    cr.CreateDate,
    u.Username,
    cr.Carrier,
    cr.ID
ORDER BY cr.CreateDate DESC, cr.TrackingNo;

-- ============================================================================
-- PART 2: Which Serial Numbers Were Received With Which Tracking Number
-- ============================================================================
SELECT 
    'Serial Receipt by Tracking' AS AnalysisType,
    rec.SerialNo,
    rec.PartNo,
    rec.CustomerReference AS ASN,
    dl.TrackingNo AS TrackingNumber_Used,
    rec.CreateDate AS ReceiptDate,
    u.Username AS ReceivedBy,
    -- Check if this tracking number matches any CarrierResult for this ASN
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Plus.pls.CarrierResult cr 
            WHERE cr.OrderHeaderID = rh.ID 
              AND cr.TrackingNo = dl.TrackingNo
        ) THEN 'VALID'
        ELSE 'NOT FOUND IN CARRIERRESULT'
    END AS TrackingValidation
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
LEFT JOIN Plus.pls.[User] u ON u.ID = rec.UserID
WHERE rec.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
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
ORDER BY rec.SerialNo;

-- ============================================================================
-- PART 3: RODockLog Entries for ASN X-500661125 (All Tracking Numbers)
-- ============================================================================
SELECT 
    'DockLog Tracking Numbers' AS AnalysisType,
    dl.TrackingNo AS TrackingNumber,
    dl.CreateDate AS DockLogDate,
    COUNT(DISTINCT rec.SerialNo) AS SerialCount_ReceivedWithThisTracking,
    (SELECT STRING_AGG(SerialNo, ', ') 
     FROM (SELECT DISTINCT rec2.SerialNo 
           FROM Plus.pls.PartTransaction rec2 
           WHERE rec2.RODockLogID = dl.ID 
             AND rec2.ProgramID = 10068
             AND rec2.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')) AS distinct_received) AS SerialNumbers_Received,
    MIN(rec.CreateDate) AS FirstReceiptDate,
    MAX(rec.CreateDate) AS LastReceiptDate
FROM Plus.pls.RODockLog dl
INNER JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
LEFT JOIN Plus.pls.PartTransaction rec ON rec.RODockLogID = dl.ID
    AND rec.ProgramID = 10068
    AND rec.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
  AND dl.TrackingNo IS NOT NULL
GROUP BY 
    dl.TrackingNo,
    dl.CreateDate
ORDER BY dl.CreateDate DESC;

-- ============================================================================
-- PART 4: Summary - Tracking Number Usage (What We Can Actually Determine)
-- ============================================================================
-- NOTE: There's no direct link between tracking numbers and specific serials
-- We can only show:
-- 1. All serials in the ASN (total)
-- 2. Which serials were actually received with each tracking number
SELECT 
    'SUMMARY' AS AnalysisType,
    cr.TrackingNo AS TrackingNumber_FromCarrierResult,
    cr.CreateDate AS CarrierResultDate,
    cr.Carrier,
    -- Total serials in the ASN (all of them, not per tracking number)
    (SELECT COUNT(DISTINCT ru2.SerialNo) 
     FROM Plus.pls.ROLine rl2 
     INNER JOIN Plus.pls.ROUnit ru2 ON ru2.ROLineID = rl2.ID 
     WHERE rl2.ROHeaderID = rh.ID) AS TotalSerialsInASN,
    -- How many serials were actually received with THIS tracking number
    (SELECT COUNT(DISTINCT rec2.SerialNo) 
     FROM Plus.pls.RODockLog dl2 
     INNER JOIN Plus.pls.PartTransaction rec2 ON rec2.RODockLogID = dl2.ID
     WHERE dl2.ROHeaderID = rh.ID 
       AND dl2.TrackingNo = cr.TrackingNo
       AND rec2.ProgramID = 10068
       AND rec2.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
    ) AS SerialsReceivedWithThisTracking,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Plus.pls.RODockLog dl_check 
            INNER JOIN Plus.pls.PartTransaction rec_check ON rec_check.RODockLogID = dl_check.ID
            WHERE dl_check.ROHeaderID = rh.ID 
              AND dl_check.TrackingNo = cr.TrackingNo
              AND rec_check.ProgramID = 10068
              AND rec_check.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
        ) THEN 'USED'
        ELSE 'NOT USED'
    END AS WasThisTrackingUsed,
    -- All serials in ASN (for reference - not "expected" for this tracking)
    (SELECT STRING_AGG(SerialNo, ', ') 
     FROM (
         SELECT DISTINCT ru2.SerialNo 
         FROM Plus.pls.ROLine rl2 
         INNER JOIN Plus.pls.ROUnit ru2 ON ru2.ROLineID = rl2.ID 
         WHERE rl2.ROHeaderID = rh.ID
     ) AS all_serials) AS AllSerialsInASN,
    -- Serials actually received with this tracking number
    (SELECT STRING_AGG(SerialNo, ', ') 
     FROM (
         SELECT DISTINCT rec2.SerialNo 
         FROM Plus.pls.RODockLog dl2 
         INNER JOIN Plus.pls.PartTransaction rec2 ON rec2.RODockLogID = dl2.ID
         WHERE dl2.ROHeaderID = rh.ID 
           AND dl2.TrackingNo = cr.TrackingNo
           AND rec2.ProgramID = 10068
           AND rec2.PartTransactionID = (SELECT ID FROM Plus.pls.CodePartTransaction WHERE Description = 'RO-RECEIVE')
     ) AS received_serials) AS SerialsReceivedWithThisTracking
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference = 'X-500661125'
GROUP BY 
    cr.TrackingNo,
    cr.CreateDate,
    cr.Carrier,
    rh.ID
ORDER BY cr.CreateDate DESC;

