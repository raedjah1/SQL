-- Investigation: Find Correct Tracking Number and ASN for Serial Numbers
-- ProgramID = 10068 (ADT)
-- This query investigates multiple sources to find what the correct tracking number/ASN should be
-- Date Range: December 2025 to Now

-- ============================================================================
-- PART 1: What was actually received (current/wrong information)
-- ============================================================================
SELECT 
    'ACTUAL RECEIPT (May be wrong)' AS InvestigationType,
    rec.SerialNo,
    rec.PartNo,
    rec.CustomerReference AS ASN_Received,
    dl.TrackingNo AS TrackingNumber_Received,
    rec.CreateDate AS DateReceived,
    u.Username AS ReceivedBy,
    rh.ID AS RMAHeaderID_Received,
    rh.CustomerReference AS RMANumber_Received
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

UNION ALL

-- ============================================================================
-- PART 2: Expected ASN from ROUnit/ROLine (what ASN these serials should belong to)
-- ============================================================================
SELECT 
    'EXPECTED FROM ROUNIT' AS InvestigationType,
    ru.SerialNo,
    rl.PartNo,
    rh.CustomerReference AS ASN_Received,
    NULL AS TrackingNumber_Received,
    rh.CreateDate AS DateReceived,
    NULL AS ReceivedBy,
    rh.ID AS RMAHeaderID_Received,
    rh.CustomerReference AS RMANumber_Received
FROM Plus.pls.ROUnit ru
INNER JOIN Plus.pls.ROLine rl ON rl.ID = ru.ROLineID
INNER JOIN Plus.pls.ROHeader rh ON rh.ID = rl.ROHeaderID
WHERE rh.ProgramID = 10068
  AND ru.SerialNo IN (
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

UNION ALL

-- ============================================================================
-- PART 3: Tracking numbers from CarrierResult (what tracking was assigned to ASNs)
-- ============================================================================
SELECT 
    'TRACKING FROM CARRIERRESULT' AS InvestigationType,
    ru.SerialNo,
    rl.PartNo,
    rh.CustomerReference AS ASN_Received,
    cr.TrackingNo AS TrackingNumber_Received,
    cr.CreateDate AS DateReceived,
    u.Username AS ReceivedBy,
    rh.ID AS RMAHeaderID_Received,
    rh.CustomerReference AS RMANumber_Received
FROM Plus.pls.ROUnit ru
INNER JOIN Plus.pls.ROLine rl ON rl.ID = ru.ROLineID
INNER JOIN Plus.pls.ROHeader rh ON rh.ID = rl.ROHeaderID
LEFT JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
LEFT JOIN Plus.pls.[User] u ON u.ID = cr.UserID
WHERE rh.ProgramID = 10068
  AND ru.SerialNo IN (
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
  AND cr.TrackingNo IS NOT NULL

UNION ALL

-- ============================================================================
-- PART 4: All RODockLog entries for ASNs that contain these serials (other tracking numbers)
-- ============================================================================
SELECT DISTINCT
    'DOCKLOG FOR ASN' AS InvestigationType,
    NULL AS SerialNo,
    NULL AS PartNo,
    rh.CustomerReference AS ASN_Received,
    dl.TrackingNo AS TrackingNumber_Received,
    dl.CreateDate AS DateReceived,
    NULL AS ReceivedBy,
    rh.ID AS RMAHeaderID_Received,
    rh.CustomerReference AS RMANumber_Received
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rl ON rl.ROHeaderID = rh.ID
INNER JOIN Plus.pls.ROUnit ru ON ru.ROLineID = rl.ID
INNER JOIN Plus.pls.RODockLog dl ON dl.ROHeaderID = rh.ID
WHERE rh.ProgramID = 10068
  AND ru.SerialNo IN (
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
  AND dl.TrackingNo IS NOT NULL

UNION ALL

-- ============================================================================
-- PART 5: ASNs that are incomplete/unfulfilled (might be missing these serials)
-- ============================================================================
SELECT 
    'INCOMPLETE ASN (Check if should have these serials)' AS InvestigationType,
    NULL AS SerialNo,
    rl.PartNo,
    rh.CustomerReference AS ASN_Received,
    COALESCE(dl.TrackingNo, cr.TrackingNo) AS TrackingNumber_Received,
    rh.CreateDate AS DateReceived,
    NULL AS ReceivedBy,
    rh.ID AS RMAHeaderID_Received,
    rh.CustomerReference AS RMANumber_Received
FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.CodeStatus rs ON rs.ID = rh.StatusID
INNER JOIN Plus.pls.ROLine rl ON rl.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.RODockLog dl ON dl.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh.ID 
    AND cr.ProgramID = rh.ProgramID 
    AND cr.OrderType = 'RO'
WHERE rh.ProgramID = 10068
  AND rh.CreateDate >= '2025-12-01'
  AND rs.Description NOT IN ('RECEIVED', 'COMPLETE', 'CLOSED')
  AND rl.PartNo IN (
      -- Get PartNos from the serial numbers we're investigating
      SELECT DISTINCT rec.PartNo
      FROM Plus.pls.PartTransaction rec
      WHERE rec.ProgramID = 10068
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
  )

ORDER BY InvestigationType, SerialNo, ASN_Received;

-- ============================================================================
-- SUMMARY: Compare Actual vs Expected
-- ============================================================================
SELECT 
    rec.SerialNo,
    rec.PartNo,
    rec.CustomerReference AS ASN_ActuallyReceived,
    dl.TrackingNo AS Tracking_ActuallyReceived,
    rh_expected.CustomerReference AS ASN_Expected,
    COALESCE(dl_expected.TrackingNo, cr.TrackingNo) AS Tracking_Expected,
    CASE 
        WHEN rec.CustomerReference = rh_expected.CustomerReference THEN 'MATCH'
        ELSE 'MISMATCH'
    END AS ASN_Match,
    CASE 
        WHEN dl.TrackingNo = COALESCE(dl_expected.TrackingNo, cr.TrackingNo) THEN 'MATCH'
        ELSE 'MISMATCH'
    END AS Tracking_Match
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
-- Get expected ASN from ROUnit
LEFT JOIN Plus.pls.ROUnit ru ON ru.SerialNo = rec.SerialNo 
    AND ru.ROLineID IN (
        SELECT rl.ID 
        FROM Plus.pls.ROLine rl 
        WHERE rl.PartNo = rec.PartNo
    )
LEFT JOIN Plus.pls.ROLine rl_expected ON rl_expected.ID = ru.ROLineID
LEFT JOIN Plus.pls.ROHeader rh_expected ON rh_expected.ID = rl_expected.ROHeaderID
LEFT JOIN Plus.pls.RODockLog dl_expected ON dl_expected.ROHeaderID = rh_expected.ID
LEFT JOIN Plus.pls.CarrierResult cr ON cr.OrderHeaderID = rh_expected.ID 
    AND cr.ProgramID = rh_expected.ProgramID 
    AND cr.OrderType = 'RO'
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

