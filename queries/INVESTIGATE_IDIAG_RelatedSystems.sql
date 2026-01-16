-- INVESTIGATIVE QUERY 4: What other systems/tables relate to IDIAG?
-- Purpose: Find connections to other parts of the system

-- 4.1: Are there work orders related to IDIAG?
SELECT TOP 50
    wo.ID,
    wo.SerialNo,
    wo.Workstation,
    wo.Status,
    wo.CreateDate,
    dwr.Result AS IDIAGResult,
    dwr.EndTime AS IDIAGEndTime
FROM Plus.pls.WorkOrder AS wo
LEFT JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.SerialNumber = wo.SerialNo
    AND dwr.Contract = '10053'
    AND dwr.TestArea = 'MEMPHIS'
    AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
WHERE wo.ProgramID = 10053
  AND (wo.Workstation LIKE '%IDIAG%' OR wo.Workstation LIKE '%DIAG%')
ORDER BY wo.CreateDate DESC;

-- 4.2: Are there PartTransactions related to IDIAG testing?
SELECT TOP 50
    pt.SerialNo,
    pt.PartTransaction,
    pt.Location,
    pt.ToLocation,
    pt.CreateDate,
    cpt.Description,
    dwr.Result AS IDIAGResult,
    dwr.EndTime AS IDIAGEndTime
FROM Plus.pls.PartTransaction AS pt
LEFT JOIN Plus.pls.CodePartTransaction AS cpt ON cpt.ID = pt.PartTransactionID
LEFT JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.SerialNumber = pt.SerialNo
    AND dwr.Contract = '10053'
    AND dwr.TestArea = 'MEMPHIS'
    AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
WHERE pt.ProgramID = 10053
  AND (pt.Location LIKE '%IDIAG%' 
       OR pt.ToLocation LIKE '%IDIAG%'
       OR pt.Location LIKE '%DIAG%'
       OR pt.ToLocation LIKE '%DIAG%')
ORDER BY pt.CreateDate DESC;

-- 4.3: What locations are related to IDIAG?
SELECT DISTINCT
    pl.LocationNo,
    pl.Warehouse,
    COUNT(DISTINCT ps.SerialNumber) AS SerialCount
FROM Plus.pls.PartLocation AS pl
INNER JOIN Plus.pls.PartSerial AS ps ON ps.LocationID = pl.ID
INNER JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.SerialNumber = ps.SerialNumber
WHERE ps.ProgramID = 10053
  AND dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND (pl.LocationNo LIKE '%IDIAG%' OR pl.LocationNo LIKE '%DIAG%' OR pl.Warehouse LIKE '%IDIAG%' OR pl.Warehouse LIKE '%DIAG%')
GROUP BY pl.LocationNo, pl.Warehouse
ORDER BY SerialCount DESC;

-- 4.4: Are there attributes on PartSerial related to IDIAG?
SELECT DISTINCT
    ca.AttributeName,
    COUNT(*) AS AttributeCount,
    COUNT(DISTINCT psa.PartSerialID) AS UniqueSerials
FROM Plus.pls.PartSerialAttribute AS psa
INNER JOIN Plus.pls.CodeAttribute AS ca ON ca.ID = psa.AttributeID
INNER JOIN Plus.pls.PartSerial AS ps ON ps.ID = psa.PartSerialID
INNER JOIN [redw].[tia].[DataWipeResult] AS dwr ON dwr.SerialNumber = ps.SerialNumber
WHERE ps.ProgramID = 10053
  AND dwr.Contract = '10053'
  AND dwr.TestArea = 'MEMPHIS'
  AND (dwr.MachineName = 'IDIAGS' OR dwr.MachineName = 'IDIAGS-MB-RESET')
  AND (ca.AttributeName LIKE '%IDIAG%' 
       OR ca.AttributeName LIKE '%DIAG%'
       OR ca.AttributeName LIKE '%TEST%'
       OR psa.Value LIKE '%IDIAG%'
       OR psa.Value LIKE '%DIAG%')
GROUP BY ca.AttributeName
ORDER BY AttributeCount DESC;

