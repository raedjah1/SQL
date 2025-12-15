-- Full lifecycle of ASNs across all RO tables with SHIPFROMORG and BRANCHES
SELECT 
    'ROHeader' AS TableSource,
    rh.CustomerReference AS ASN,
    rh.ID AS RecordID,
    rh.CreateDate AS EventDate,
    rs.Description AS Status,
    NULL AS PartNo,
    NULL AS SerialNo,
    NULL AS Location,
    NULL AS Operator,
    'ASN Created' AS EventDescription,
    (SELECT STRING_AGG(roa.Value, ', ') 
     FROM Plus.pls.ROHeaderAttribute roa
     WHERE roa.ROHeaderID = rh.ID
       AND roa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'SHIPFROMORG')
    ) AS SHIPFROMORG,
    (SELECT STRING_AGG(roa.Value, ', ') 
     FROM Plus.pls.ROHeaderAttribute roa
     WHERE roa.ROHeaderID = rh.ID
       AND roa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'BRANCHES')
    ) AS BRANCHES
FROM Plus.pls.ROHeader rh
JOIN Plus.pls.CodeStatus rs ON rs.ID = rh.StatusID
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference IN (
    'FSR2508858', 'X-405471218', 'FSR2509089', 'FSR2509225', 'FSR2509103',
    'FSR2509320', 'FSR2509334', 'FSR2509545', 'FSR2509390', 'X-312863912',
    'EX2506281', 'EX2506286', 'FSR2509594', 'FSR2509665', 'FSR2509663',
    'X-310575920', 'X-313308844', 'FSR2509945', 'FSR2509971', 'FSR2509960',
    'FSR2510002', 'FSR2509993', 'FSR2510249', 'FSR2510317', 'FSR2510459',
    'FSR2510606', 'FSR2510779', 'FSR2510658', 'FSR2510743', 'FSR2510619',
    'FSR2510661', 'FSR2510772', 'FSR2510729', 'FSR2510800', 'FSR2510689',
    'FSR2510818', 'FSR2510666', 'FSR2510824', 'FSR2510684', 'FSR2510826',
    'FSR2510823', 'FSR2510867', 'FSR2510813', 'FSR2510825', 'X-500629040',
    'FSR2510859', 'FSR2510860', 'FSR2510863', 'FSR2510858', 'FSR2510853',
    'FSR2510887', 'FSR2510870', 'FSR2510849', 'FSR2510836', 'FSR2510832',
    'FSR2510806', 'FSR2510845', 'X-500602926', 'FSR2510835', 'FSR2510833',
    'X-301274241', 'X-88408711'
  )

UNION ALL

-- RODockLog (Receiving/Delivery) - no PartNo/SerialNo
SELECT 
    'RODockLog' AS TableSource,
    rh.CustomerReference AS ASN,
    dl.ID AS RecordID,
    dl.CreateDate AS EventDate,
    NULL AS Status,
    NULL AS PartNo,
    NULL AS SerialNo,
    NULL AS Location,
    u.Username AS Operator,
    'Dock Log Entry - Tracking: ' + ISNULL(dl.TrackingNo, 'N/A') + ', Qty: ' + CAST(dl.Qty AS VARCHAR) AS EventDescription,
    (SELECT STRING_AGG(roa.Value, ', ') 
     FROM Plus.pls.ROHeaderAttribute roa
     WHERE roa.ROHeaderID = rh.ID
       AND roa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'SHIPFROMORG')
    ) AS SHIPFROMORG,
    (SELECT STRING_AGG(roa.Value, ', ') 
     FROM Plus.pls.ROHeaderAttribute roa
     WHERE roa.ROHeaderID = rh.ID
       AND roa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'BRANCHES')
    ) AS BRANCHES
FROM Plus.pls.RODockLog dl
JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
LEFT JOIN Plus.pls.[User] u ON u.ID = dl.UserID
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference IN (
    'FSR2508858', 'X-405471218', 'FSR2509089', 'FSR2509225', 'FSR2509103',
    'FSR2509320', 'FSR2509334', 'FSR2509545', 'FSR2509390', 'X-312863912',
    'EX2506281', 'EX2506286', 'FSR2509594', 'FSR2509665', 'FSR2509663',
    'X-310575920', 'X-313308844', 'FSR2509945', 'FSR2509971', 'FSR2509960',
    'FSR2510002', 'FSR2509993', 'FSR2510249', 'FSR2510317', 'FSR2510459',
    'FSR2510606', 'FSR2510779', 'FSR2510658', 'FSR2510743', 'FSR2510619',
    'FSR2510661', 'FSR2510772', 'FSR2510729', 'FSR2510800', 'FSR2510689',
    'FSR2510818', 'FSR2510666', 'FSR2510824', 'FSR2510684', 'FSR2510826',
    'FSR2510823', 'FSR2510867', 'FSR2510813', 'FSR2510825', 'X-500629040',
    'FSR2510859', 'FSR2510860', 'FSR2510863', 'FSR2510858', 'FSR2510853',
    'FSR2510887', 'FSR2510870', 'FSR2510849', 'FSR2510836', 'FSR2510832',
    'FSR2510806', 'FSR2510845', 'X-500602926', 'FSR2510835', 'FSR2510833',
    'X-301274241', 'X-88408711'
  )

UNION ALL

-- ROLine (Line Items) - has PartNo, no SerialNo
SELECT 
    'ROLine' AS TableSource,
    rh.CustomerReference AS ASN,
    rol.ID AS RecordID,
    rol.CreateDate AS EventDate,
    NULL AS Status,
    rol.PartNo,
    NULL AS SerialNo,
    NULL AS Location,
    u.Username AS Operator,
    'RO Line Created - QtyToReceive: ' + CAST(rol.QtyToReceive AS VARCHAR) + ', QtyReceived: ' + CAST(rol.QtyReceived AS VARCHAR) AS EventDescription,
    (SELECT STRING_AGG(roa.Value, ', ') 
     FROM Plus.pls.ROHeaderAttribute roa
     WHERE roa.ROHeaderID = rh.ID
       AND roa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'SHIPFROMORG')
    ) AS SHIPFROMORG,
    (SELECT STRING_AGG(roa.Value, ', ') 
     FROM Plus.pls.ROHeaderAttribute roa
     WHERE roa.ROHeaderID = rh.ID
       AND roa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'BRANCHES')
    ) AS BRANCHES
FROM Plus.pls.ROLine rol
JOIN Plus.pls.ROHeader rh ON rh.ID = rol.ROHeaderID
LEFT JOIN Plus.pls.[User] u ON u.ID = rol.UserID
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference IN (
    'FSR2508858', 'X-405471218', 'FSR2509089', 'FSR2509225', 'FSR2509103',
    'FSR2509320', 'FSR2509334', 'FSR2509545', 'FSR2509390', 'X-312863912',
    'EX2506281', 'EX2506286', 'FSR2509594', 'FSR2509665', 'FSR2509663',
    'X-310575920', 'X-313308844', 'FSR2509945', 'FSR2509971', 'FSR2509960',
    'FSR2510002', 'FSR2509993', 'FSR2510249', 'FSR2510317', 'FSR2510459',
    'FSR2510606', 'FSR2510779', 'FSR2510658', 'FSR2510743', 'FSR2510619',
    'FSR2510661', 'FSR2510772', 'FSR2510729', 'FSR2510800', 'FSR2510689',
    'FSR2510818', 'FSR2510666', 'FSR2510824', 'FSR2510684', 'FSR2510826',
    'FSR2510823', 'FSR2510867', 'FSR2510813', 'FSR2510825', 'X-500629040',
    'FSR2510859', 'FSR2510860', 'FSR2510863', 'FSR2510858', 'FSR2510853',
    'FSR2510887', 'FSR2510870', 'FSR2510849', 'FSR2510836', 'FSR2510832',
    'FSR2510806', 'FSR2510845', 'X-500602926', 'FSR2510835', 'FSR2510833',
    'X-301274241', 'X-88408711'
  )

UNION ALL

-- PartSerial (Cataloging)
SELECT 
    'PartSerial' AS TableSource,
    rh.CustomerReference AS ASN,
    ps.ID AS RecordID,
    ps.CreateDate AS EventDate,
    ps_status.Description AS Status,
    ps.PartNo,
    ps.SerialNo,
    loc.LocationNo AS Location,
    u.Username AS Operator,
    'Part Catalogged' AS EventDescription,
    (SELECT STRING_AGG(roa.Value, ', ') 
     FROM Plus.pls.ROHeaderAttribute roa
     WHERE roa.ROHeaderID = rh.ID
       AND roa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'SHIPFROMORG')
    ) AS SHIPFROMORG,
    (SELECT STRING_AGG(roa.Value, ', ') 
     FROM Plus.pls.ROHeaderAttribute roa
     WHERE roa.ROHeaderID = rh.ID
       AND roa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'BRANCHES')
    ) AS BRANCHES
FROM Plus.pls.PartSerial ps
JOIN Plus.pls.ROHeader rh ON rh.ID = ps.ROHeaderID
LEFT JOIN Plus.pls.CodeStatus ps_status ON ps_status.ID = ps.StatusID
LEFT JOIN Plus.pls.PartLocation loc ON loc.ID = ps.LocationID
LEFT JOIN Plus.pls.[User] u ON u.ID = ps.UserID
WHERE ps.ProgramID = 10068
  AND rh.CustomerReference IN (
    'FSR2508858', 'X-405471218', 'FSR2509089', 'FSR2509225', 'FSR2509103',
    'FSR2509320', 'FSR2509334', 'FSR2509545', 'FSR2509390', 'X-312863912',
    'EX2506281', 'EX2506286', 'FSR2509594', 'FSR2509665', 'FSR2509663',
    'X-310575920', 'X-313308844', 'FSR2509945', 'FSR2509971', 'FSR2509960',
    'FSR2510002', 'FSR2509993', 'FSR2510249', 'FSR2510317', 'FSR2510459',
    'FSR2510606', 'FSR2510779', 'FSR2510658', 'FSR2510743', 'FSR2510619',
    'FSR2510661', 'FSR2510772', 'FSR2510729', 'FSR2510800', 'FSR2510689',
    'FSR2510818', 'FSR2510666', 'FSR2510824', 'FSR2510684', 'FSR2510826',
    'FSR2510823', 'FSR2510867', 'FSR2510813', 'FSR2510825', 'X-500629040',
    'FSR2510859', 'FSR2510860', 'FSR2510863', 'FSR2510858', 'FSR2510853',
    'FSR2510887', 'FSR2510870', 'FSR2510849', 'FSR2510836', 'FSR2510832',
    'FSR2510806', 'FSR2510845', 'X-500602926', 'FSR2510835', 'FSR2510833',
    'X-301274241', 'X-88408711'
  )

UNION ALL

-- PartTransaction (All movements/transactions)
SELECT 
    'PartTransaction' AS TableSource,
    COALESCE(rh.CustomerReference, pt.CustomerReference) AS ASN,
    pt.ID AS RecordID,
    pt.CreateDate AS EventDate,
    cpt.Description AS Status,
    pt.PartNo,
    pt.SerialNo,
    pt.ToLocation AS Location,
    u.Username AS Operator,
    cpt.Description + 
    CASE 
        WHEN pt.Location IS NOT NULL AND pt.ToLocation IS NOT NULL 
        THEN ' (' + pt.Location + ' -> ' + pt.ToLocation + ')'
        WHEN pt.ToLocation IS NOT NULL 
        THEN ' (-> ' + pt.ToLocation + ')'
        WHEN pt.Location IS NOT NULL
        THEN ' (from ' + pt.Location + ')'
        ELSE ''
    END AS EventDescription,
    (SELECT STRING_AGG(roa.Value, ', ') 
     FROM Plus.pls.ROHeaderAttribute roa
     WHERE roa.ROHeaderID = COALESCE(rh.ID, 
         (SELECT TOP 1 rh_lookup.ID 
          FROM Plus.pls.ROHeader rh_lookup
          WHERE rh_lookup.CustomerReference = COALESCE(rh.CustomerReference, pt.CustomerReference)
            AND rh_lookup.ProgramID = 10068))
       AND roa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'SHIPFROMORG')
    ) AS SHIPFROMORG,
    (SELECT STRING_AGG(roa.Value, ', ') 
     FROM Plus.pls.ROHeaderAttribute roa
     WHERE roa.ROHeaderID = COALESCE(rh.ID,
         (SELECT TOP 1 rh_lookup.ID 
          FROM Plus.pls.ROHeader rh_lookup
          WHERE rh_lookup.CustomerReference = COALESCE(rh.CustomerReference, pt.CustomerReference)
            AND rh_lookup.ProgramID = 10068))
       AND roa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'BRANCHES')
    ) AS BRANCHES
FROM Plus.pls.PartTransaction pt
JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = pt.OrderHeaderID AND pt.OrderType = 'RO'
LEFT JOIN Plus.pls.[User] u ON u.ID = pt.UserID
WHERE pt.ProgramID = 10068
  AND (
    pt.CustomerReference IN (
      'FSR2508858', 'X-405471218', 'FSR2509089', 'FSR2509225', 'FSR2509103',
      'FSR2509320', 'FSR2509334', 'FSR2509545', 'FSR2509390', 'X-312863912',
      'EX2506281', 'EX2506286', 'FSR2509594', 'FSR2509665', 'FSR2509663',
      'X-310575920', 'X-313308844', 'FSR2509945', 'FSR2509971', 'FSR2509960',
      'FSR2510002', 'FSR2509993', 'FSR2510249', 'FSR2510317', 'FSR2510459',
      'FSR2510606', 'FSR2510779', 'FSR2510658', 'FSR2510743', 'FSR2510619',
      'FSR2510661', 'FSR2510772', 'FSR2510729', 'FSR2510800', 'FSR2510689',
      'FSR2510818', 'FSR2510666', 'FSR2510824', 'FSR2510684', 'FSR2510826',
      'FSR2510823', 'FSR2510867', 'FSR2510813', 'FSR2510825', 'X-500629040',
      'FSR2510859', 'FSR2510860', 'FSR2510863', 'FSR2510858', 'FSR2510853',
      'FSR2510887', 'FSR2510870', 'FSR2510849', 'FSR2510836', 'FSR2510832',
      'FSR2510806', 'FSR2510845', 'X-500602926', 'FSR2510835', 'FSR2510833',
      'X-301274241', 'X-88408711'
    )
    OR rh.CustomerReference IN (
      'FSR2508858', 'X-405471218', 'FSR2509089', 'FSR2509225', 'FSR2509103',
      'FSR2509320', 'FSR2509334', 'FSR2509545', 'FSR2509390', 'X-312863912',
      'EX2506281', 'EX2506286', 'FSR2509594', 'FSR2509665', 'FSR2509663',
      'X-310575920', 'X-313308844', 'FSR2509945', 'FSR2509971', 'FSR2509960',
      'FSR2510002', 'FSR2509993', 'FSR2510249', 'FSR2510317', 'FSR2510459',
      'FSR2510606', 'FSR2510779', 'FSR2510658', 'FSR2510743', 'FSR2510619',
      'FSR2510661', 'FSR2510772', 'FSR2510729', 'FSR2510800', 'FSR2510689',
      'FSR2510818', 'FSR2510666', 'FSR2510824', 'FSR2510684', 'FSR2510826',
      'FSR2510823', 'FSR2510867', 'FSR2510813', 'FSR2510825', 'X-500629040',
      'FSR2510859', 'FSR2510860', 'FSR2510863', 'FSR2510858', 'FSR2510853',
      'FSR2510887', 'FSR2510870', 'FSR2510849', 'FSR2510836', 'FSR2510832',
      'FSR2510806', 'FSR2510845', 'X-500602926', 'FSR2510835', 'FSR2510833',
      'X-301274241', 'X-88408711'
    )
  )

ORDER BY ASN, EventDate, TableSource;

