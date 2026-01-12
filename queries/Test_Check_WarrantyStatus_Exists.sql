-- Test: Check if WARRANTY_STATUS is actually being saved/issued
-- This verifies that warranty status calculation and saving is working

-- Check if WARRANTY_STATUS exists in PartSerialAttribute for recent receipts
SELECT 
    'PartSerialAttribute' AS Source,
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT psa.Value) AS DistinctValues,
    STRING_AGG(DISTINCT psa.Value, ', ') AS WarrantyStatusValues
FROM pls.PartSerial ps
INNER JOIN pls.PartSerialAttribute psa ON psa.PartSerialID = ps.ID
INNER JOIN pls.CodeAttribute ca ON ca.ID = psa.AttributeID
INNER JOIN pls.PartTransaction pt ON pt.PartNo = ps.PartNo 
    AND pt.SerialNo = ps.SerialNo 
    AND pt.ProgramID = ps.ProgramID
INNER JOIN pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE ps.ProgramID = 10068
    AND ca.AttributeName = 'WARRANTY_STATUS'
    AND cpt.Description = 'RO-RECEIVE'
    AND pt.CreateDate >= DATEADD(DAY, -30, GETDATE()) -- Last 30 days

UNION ALL

-- Check if WARRANTY_STATUS exists in ROUnitAttribute for recent receipts
SELECT 
    'ROUnitAttribute' AS Source,
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT rua.Value) AS DistinctValues,
    STRING_AGG(DISTINCT rua.Value, ', ') AS WarrantyStatusValues
FROM pls.ROUnit ru
INNER JOIN pls.ROLine rl ON rl.ID = ru.ROLineID
INNER JOIN pls.ROHeader roh ON roh.ID = rl.ROHeaderID
INNER JOIN pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID
INNER JOIN pls.CodeAttribute ca ON ca.ID = rua.AttributeID
INNER JOIN pls.PartTransaction pt ON pt.OrderHeaderID = roh.ID
    AND pt.OrderLineID = rl.ID
    AND pt.SerialNo = ru.SerialNo
INNER JOIN pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
WHERE roh.ProgramID = 10068
    AND ca.AttributeName = 'WARRANTY_STATUS'
    AND cpt.Description = 'RO-RECEIVE'
    AND pt.CreateDate >= DATEADD(DAY, -30, GETDATE()); -- Last 30 days

-- Sample records showing WARRANTY_STATUS values
SELECT TOP 20
    'PartSerialAttribute' AS Source,
    ps.PartNo,
    ps.SerialNo,
    psa.Value AS WarrantyStatus,
    pt.CreateDate AS ReceiveDate,
    roh.CustomerReference AS RMA
FROM pls.PartSerial ps
INNER JOIN pls.PartSerialAttribute psa ON psa.PartSerialID = ps.ID
INNER JOIN pls.CodeAttribute ca ON ca.ID = psa.AttributeID
INNER JOIN pls.PartTransaction pt ON pt.PartNo = ps.PartNo 
    AND pt.SerialNo = ps.SerialNo 
    AND pt.ProgramID = ps.ProgramID
INNER JOIN pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
LEFT JOIN pls.ROHeader roh ON roh.ID = pt.OrderHeaderID
WHERE ps.ProgramID = 10068
    AND ca.AttributeName = 'WARRANTY_STATUS'
    AND cpt.Description = 'RO-RECEIVE'
    AND pt.CreateDate >= DATEADD(DAY, -30, GETDATE())
ORDER BY pt.CreateDate DESC;

