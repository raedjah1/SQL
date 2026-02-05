-- Investigate ASN FSR25063 to find where this data row is coming from
-- Based on the image data: FSR25063, 4757541, 6/27/2025, NEW, 3726117, 79182272627.00, 7/7/2025, 0, NULL, 200

-- Check ROHeader
SELECT 
    'ROHeader' AS Source,
    rh.ID AS ROHeaderID,
    rh.CustomerReference AS ASN,
    rh.CreateDate AS ASNCreateDate,
    rh.StatusID,
    cs.Description AS Status,
    rh.ProgramID
FROM Plus.pls.ROHeader rh
JOIN Plus.pls.CodeStatus cs ON cs.ID = rh.StatusID
WHERE rh.CustomerReference = 'FSR25063'
  AND rh.ProgramID = 10068

UNION ALL

-- Check DockLog
SELECT 
    'DockLog' AS Source,
    dl.ID AS DockLogID,
    rh.CustomerReference AS ASN,
    dl.CreateDate AS DockLogDate,
    NULL AS StatusID,
    NULL AS Status,
    dl.ProgramID
FROM Plus.pls.RODockLog dl
JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID
WHERE rh.CustomerReference = 'FSR25063'
  AND dl.ProgramID = 10068

UNION ALL

-- Check PartTransaction (receipts)
SELECT 
    'PartTransaction' AS Source,
    pt.ID AS TransactionID,
    pt.CustomerReference AS ASN,
    pt.CreateDate AS TransactionDate,
    NULL AS StatusID,
    cpt.Description AS Status,
    pt.ProgramID
FROM Plus.pls.PartTransaction pt
JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE pt.CustomerReference = 'FSR25063'
  AND pt.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'

UNION ALL

-- Check ROLine
SELECT 
    'ROLine' AS Source,
    rl.ID AS ROLineID,
    rh.CustomerReference AS ASN,
    rl.CreateDate AS LineDate,
    rl.StatusID,
    cs.Description AS Status,
    rh.ProgramID
FROM Plus.pls.ROLine rl
JOIN Plus.pls.ROHeader rh ON rh.ID = rl.ROHeaderID
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = rl.StatusID
WHERE rh.CustomerReference = 'FSR25063'
  AND rh.ProgramID = 10068

ORDER BY Source, ASNCreateDate;

