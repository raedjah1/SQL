-- Find Serial Numbers and Who Received Them
-- ProgramID = 10068 (ADT)
-- Shows receipt information including who received each serial number
-- Date Range: December 2025 to Now

SELECT 
    rec.SerialNo,
    rec.PartNo,
    rec.CreateDate AS DateReceived,
    rec.Qty AS QuantityReceived,
    rec.CustomerReference AS ASN,
    u.Username AS ReceivedBy,
    u.ID AS UserID,
    COALESCE(psa_tch.Value, rua_tch.Value) AS TechID,
    cpt.Description AS TransactionType,
    dl.TrackingNo AS TrackingNumber,
    dl.ID AS DockLogID,
    rh.ID AS RMAHeaderID,
    rh.CustomerReference AS RMANumber,
    rec.ToLocation AS ReceivingLocation,
    rec.ProgramID
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
LEFT JOIN Plus.pls.[User] u ON u.ID = rec.UserID
-- Tech ID from PartSerialAttribute
LEFT JOIN Plus.pls.PartSerial ps ON ps.SerialNo = rec.SerialNo 
    AND ps.ProgramID = rec.ProgramID 
    AND ps.PartNo = rec.PartNo
LEFT JOIN Plus.pls.PartSerialAttribute psa_tch ON psa_tch.PartSerialID = ps.ID
    AND psa_tch.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TECH_ID')
-- Tech ID from ROUnitAttribute (fallback)
LEFT JOIN Plus.pls.ROUnit ru ON ru.SerialNo = rec.SerialNo 
    AND ru.ROLineID IN (SELECT ID FROM Plus.pls.ROLine WHERE ROHeaderID = rh.ID AND PartNo = rec.PartNo)
LEFT JOIN Plus.pls.ROUnitAttribute rua_tch ON rua_tch.ROUnitID = ru.ID
    AND rua_tch.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TECH_ID')
WHERE rec.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND rec.CreateDate >= '2025-12-01'  -- December 2025 to now
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
ORDER BY rec.SerialNo, rec.CreateDate DESC;

-- ============================================================================
-- Summary: Who received each serial number (first receipt only)
-- ============================================================================
SELECT 
    rec.SerialNo,
    rec.PartNo,
    MIN(rec.CreateDate) AS FirstReceiptDate,
    MAX(rec.CreateDate) AS LastReceiptDate,
    COUNT(*) AS ReceiptTransactionCount,
    (SELECT STRING_AGG(Username, ', ') 
     FROM (
         SELECT DISTINCT u2.Username
         FROM Plus.pls.PartTransaction rec2
         INNER JOIN Plus.pls.CodePartTransaction cpt2 ON cpt2.ID = rec2.PartTransactionID
         LEFT JOIN Plus.pls.[User] u2 ON u2.ID = rec2.UserID
         WHERE rec2.ProgramID = 10068
           AND cpt2.Description = 'RO-RECEIVE'
           AND rec2.CreateDate >= '2025-12-01'
           AND rec2.SerialNo = rec.SerialNo
           AND rec2.PartNo = rec.PartNo
           AND u2.Username IS NOT NULL
     ) AS users) AS ReceivedByUsers,
    (SELECT STRING_AGG(ASN, ', ') 
     FROM (
         SELECT DISTINCT rec2.CustomerReference AS ASN
         FROM Plus.pls.PartTransaction rec2
         INNER JOIN Plus.pls.CodePartTransaction cpt2 ON cpt2.ID = rec2.PartTransactionID
         WHERE rec2.ProgramID = 10068
           AND cpt2.Description = 'RO-RECEIVE'
           AND rec2.CreateDate >= '2025-12-01'
           AND rec2.SerialNo = rec.SerialNo
           AND rec2.PartNo = rec.PartNo
           AND rec2.CustomerReference IS NOT NULL
     ) AS asns) AS ASNs,
    (SELECT STRING_AGG(TrackingNo, ', ') 
     FROM (
         SELECT DISTINCT dl2.TrackingNo
         FROM Plus.pls.PartTransaction rec2
         INNER JOIN Plus.pls.CodePartTransaction cpt2 ON cpt2.ID = rec2.PartTransactionID
         INNER JOIN Plus.pls.RODockLog dl2 ON dl2.ID = rec2.RODockLogID
         WHERE rec2.ProgramID = 10068
           AND cpt2.Description = 'RO-RECEIVE'
           AND rec2.CreateDate >= '2025-12-01'
           AND rec2.SerialNo = rec.SerialNo
           AND rec2.PartNo = rec.PartNo
           AND dl2.TrackingNo IS NOT NULL
     ) AS tracking) AS TrackingNumbers,
    (SELECT STRING_AGG(TechID, ', ') 
     FROM (
         SELECT DISTINCT COALESCE(psa2.Value, rua2.Value) AS TechID
         FROM Plus.pls.PartTransaction rec2
         INNER JOIN Plus.pls.CodePartTransaction cpt2 ON cpt2.ID = rec2.PartTransactionID
         LEFT JOIN Plus.pls.ROHeader rh2 ON rh2.ID = rec2.OrderHeaderID
         LEFT JOIN Plus.pls.PartSerial ps2 ON ps2.SerialNo = rec2.SerialNo 
             AND ps2.ProgramID = rec2.ProgramID 
             AND ps2.PartNo = rec2.PartNo
         LEFT JOIN Plus.pls.PartSerialAttribute psa2 ON psa2.PartSerialID = ps2.ID
             AND psa2.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TECH_ID')
         LEFT JOIN Plus.pls.ROUnit ru2 ON ru2.SerialNo = rec2.SerialNo 
             AND ru2.ROLineID IN (SELECT ID FROM Plus.pls.ROLine WHERE ROHeaderID = rh2.ID AND PartNo = rec2.PartNo)
         LEFT JOIN Plus.pls.ROUnitAttribute rua2 ON rua2.ROUnitID = ru2.ID
             AND rua2.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TECH_ID')
         WHERE rec2.ProgramID = 10068
           AND cpt2.Description = 'RO-RECEIVE'
           AND rec2.CreateDate >= '2025-12-01'
           AND rec2.SerialNo = rec.SerialNo
           AND rec2.PartNo = rec.PartNo
           AND (psa2.Value IS NOT NULL OR rua2.Value IS NOT NULL)
     ) AS tech) AS TechIDs
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
WHERE rec.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND rec.CreateDate >= '2025-12-01'  -- December 2025 to now
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
GROUP BY 
    rec.SerialNo,
    rec.PartNo
ORDER BY rec.SerialNo;

