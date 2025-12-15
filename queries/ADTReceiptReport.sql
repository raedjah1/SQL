CREATE OR ALTER                   VIEW [rpt].[ADTReceiptReport] AS

SELECT 
    rec.CreateDate AS "Date Received",
    dl.TrackingNo AS "Tracking Number",
    rec.CustomerReference AS ASN,
    FlgBx.FlgBx AS "Flagged Box",
    COALESCE(prsr.tch,rosr.tch) AS "Tech ID",
    CASE WHEN SUBSTRING(Branch.Value,1,1)='0' THEN SUBSTRING(Branch.Value,2,10) ELSE Branch.Value END AS "Branch ID",
    rec.PartNo AS "Part No",
    rec.SerialNo AS "Serial No",
    COALESCE(prsr.Mac,rosr.Mac) AS Mac,
    COALESCE(prsr.IMEI,rosr.IMEI) AS IMEI,
    COALESCE(prsr.Battery,rosr.Battery) AS "Battery Removal",
    COALESCE(prsr.GoogleWipe,rosr.GoogleWipe) AS "Google Wipe",
    COALESCE(prsr.dtcd,rosr.dtcd) AS "Date Code",
    dl.ID AS "Dock Log ID",
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'RMA'
      ELSE COALESCE(clean.CleanSerialDisposition, clean.CleanPartDisposition)
    END AS Disposition,
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'IW'
      WHEN COALESCE(clean.CleanWarrantyStatus, '') = 'UKN' THEN 'UKN'
      ELSE 'OOW'
    END AS "Warranty Status",
    rec.ProgramID AS ProgramID,
    rh.ID AS RMANumber,
    FlgBx.CustType AS RMAType,
    FlgBx.ReturnType AS Dept,
    FlgBx.TotalUnits AS "Total Units",
    CASE 
        WHEN ISNUMERIC(prtatt.Cost) = 1 THEN CAST(prtatt.Cost AS DECIMAL(10,2))
        ELSE NULL
    END AS Cost

FROM Plus.pls.PartTransaction AS rec
JOIN Plus.pls.CodePartTransaction AS rcd ON rcd.ID = rec.PartTransactionID
JOIN Plus.pls.ROHeader AS rh ON rh.ID = rec.OrderHeaderID
JOIN Plus.pls.CodeAddress AS adr ON adr.ID = rh.AddressID
JOIN Plus.pls.CodeAddressDetails AS adt ON adt.AddressID = adr.ID
JOIN Plus.pls.RODockLog AS dl ON dl.ID = rec.RODockLogID
JOIN Plus.pls.PartNo AS prt ON prt.PartNo = rec.PartNo
JOIN Plus.pls.PartSerial AS ps
  ON ps.ProgramID = rec.ProgramID AND ps.PartNo = rec.PartNo AND ps.SerialNo = rec.SerialNo AND ps.ROHeaderID = rh.ID
OUTER APPLY (
    SELECT psa.PartSerialID,
           MAX(CASE WHEN wsa.AttributeName='MacAddress'       THEN Value END) AS Mac,
           MAX(CASE WHEN wsa.AttributeName='IMEI'             THEN Value END) AS IMEI,
           MAX(CASE WHEN wsa.AttributeName='BATTERY'          THEN Value END) AS Battery,
           MAX(CASE WHEN wsa.AttributeName='WARRANTY_STATUS'  THEN Value END) AS WarrantyStatus,
           MAX(CASE WHEN wsa.AttributeName='DISPOSITION'      THEN Value END) AS SerialDisposition,
           MAX(CASE WHEN wsa.AttributeName='WIPE'             THEN Value END) AS GoogleWipe,
           MAX(CASE WHEN wsa.AttributeName='TECH_ID'          THEN Value END) AS tch,
           MAX(CASE WHEN wsa.AttributeName='DATE_CODE'        THEN Value END) AS dtcd
    FROM Plus.pls.PartSerialAttribute AS psa
    JOIN Plus.pls.CodeAttribute AS wsa
      ON wsa.ID = psa.AttributeID
     AND wsa.AttributeName IN ('WARRANTY_STATUS','MacAddress','BATTERY','IMEI','DISPOSITION','WIPE','TECH_ID','DATE_CODE')
    WHERE psa.PartSerialID = ps.ID
    GROUP BY psa.PartSerialID
) AS prsr
OUTER APPLY (
    SELECT ru.ID AS ROUnitID,
           MAX(CASE WHEN wsa.AttributeName='MacAddress'       THEN Value END) AS Mac,
           MAX(CASE WHEN wsa.AttributeName='IMEI'             THEN Value END) AS IMEI,
           MAX(CASE WHEN wsa.AttributeName='BATTERY'          THEN Value END) AS Battery,
           MAX(CASE WHEN wsa.AttributeName='WARRANTY_STATUS'  THEN Value END) AS WarrantyStatus,
           MAX(CASE WHEN wsa.AttributeName='DISPOSITION'      THEN Value END) AS SerialDisposition,
           MAX(CASE WHEN wsa.AttributeName='WIPE'             THEN Value END) AS GoogleWipe,
           MAX(CASE WHEN wsa.AttributeName='TECH_ID'          THEN Value END) AS tch,
           MAX(CASE WHEN wsa.AttributeName='DATE_CODE'        THEN Value END) AS dtcd
    FROM Plus.pls.ROLine rl 
    JOIN Plus.pls.ROUnit ru ON ru.ROLineID = rl.ID AND ru.SerialNo = ps.SerialNo
    JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID 
    JOIN Plus.pls.CodeAttribute AS wsa ON wsa.ID = rua.AttributeID 
     AND wsa.AttributeName IN ('WARRANTY_STATUS','MacAddress','BATTERY','IMEI','DISPOSITION','WIPE','TECH_ID','DATE_CODE')
    WHERE rl.ROHeaderID = rh.ID  AND rl.ID = rec.OrderLineID 
    GROUP BY ru.ID 
) AS rosr
OUTER APPLY (
    SELECT fb.ROHeaderID,
    MAX(CASE WHEN fbtt.AttributeName = 'FLAGGED_BOXES' AND fb.Value='NO' THEN 'Good' ELSE 'Bad' END) AS FlgBx,
    MAX(CASE WHEN fbtt.AttributeName = 'CUSTOMERTYPE' THEN fb.Value ELSE NULL END) AS CustType,
    MAX(CASE WHEN fbtt.AttributeName = 'RETURNTYPE' THEN fb.Value ELSE NULL END) AS ReturnType,
    MAX(CASE WHEN fbtt.AttributeName = 'TOTAL_UNITS' THEN fb.Value ELSE NULL END) AS TotalUnits
    FROM Plus.pls.ROHeaderAttribute AS fb
    JOIN Plus.pls.CodeAttribute AS fbtt ON fbtt.ID = fb.AttributeID AND fbtt.AttributeName IN ('FLAGGED_BOXES','CUSTOMERTYPE','RETURNTYPE','TOTAL_UNITS')
    WHERE fb.ROHeaderID = rh.ID
    GROUP BY fb.ROHeaderID 
) AS FlgBx
OUTER APPLY (
    SELECT brc.Value
    FROM Plus.pls.CodeAddressDetailsAttribute AS brc
    JOIN Plus.pls.CodeAttribute AS brca ON brca.ID = brc.AttributeID AND brca.AttributeName = 'BRANCHES'
    WHERE brc.AddressDetailID = adt.ID
) AS Branch
OUTER APPLY (
    SELECT dc.PartNo,
           MAX(CASE WHEN dctt.AttributeName='WARRANTY_TERM' THEN Value END) AS DateCode,
           MAX(CASE WHEN dctt.AttributeName='DISPOSITION'   THEN Value END) AS PartDisposition,
           MAX(CASE WHEN dctt.AttributeName='Cost' THEN Value END) AS Cost
    FROM Plus.pls.PartNoAttribute AS dc
    JOIN Plus.pls.CodeAttribute AS dctt
      ON dctt.ID = dc.AttributeID
     AND dctt.AttributeName IN ('WARRANTY_TERM','DISPOSITION','Cost')
    WHERE dc.PartNo = prt.PartNo AND dc.ProgramID = rec.ProgramID
    GROUP BY dc.PartNo
) AS prtatt
/* CLEAN ONCE, USE EVERYWHERE */
OUTER APPLY (
    SELECT
      -- remove tabs/newlines, trim, upper, null blanks
      CleanWarrantyStatus =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.WarrantyStatus,rosr.WarrantyStatus), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanSerialDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.SerialDisposition,rosr.SerialDisposition), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanPartDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prtatt.PartDisposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),'')
) AS clean
WHERE rec.ProgramID IN (10068, 10072) 
  AND rec.PartTransactionID = 1
  AND rcd.Description = 'RO-RECEIVE'
  AND adt.AddressType = 'ShipFrom'

UNION

-- history fallback
SELECT 
    rec.CreateDate AS "Date Received",
    dl.TrackingNo AS "Tracking Number",
    rec.CustomerReference AS ASN,
    FlgBx.FlgBx AS "Flagged Box",
    COALESCE(prsr.tch,rosr.tch) AS "Tech ID",
    CASE WHEN SUBSTRING(Branch.Value,1,1)='0' THEN SUBSTRING(Branch.Value,2,10) ELSE Branch.Value END AS "Branch ID",
    rec.PartNo AS "Part No",
    rec.SerialNo AS "Serial No",
    COALESCE(prsr.Mac,rosr.Mac) AS Mac,
    COALESCE(prsr.IMEI,rosr.IMEI) AS IMEI,
    COALESCE(prsr.Battery,rosr.Battery) AS "Battery Removal",
    COALESCE(prsr.GoogleWipe,rosr.GoogleWipe) AS "Google Wipe",
    COALESCE(prsr.dtcd,rosr.dtcd) AS "Date Code",
    dl.ID AS "Dock Log ID",
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'RMA'
      ELSE COALESCE(clean.CleanSerialDisposition, clean.CleanPartDisposition)
    END AS Disposition,
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'IW'
      WHEN COALESCE(clean.CleanWarrantyStatus, '') = 'UKN' THEN 'UKN'
      ELSE 'OOW'
    END AS "Warranty Status",
    rec.ProgramID AS ProgramID,
    rh.ID AS RMANumber,
    FlgBx.CustType AS RMAType,
    FlgBx.ReturnType AS Dept,
    FlgBx.TotalUnits AS "Total Units",
    CASE 
        WHEN ISNUMERIC(prtatt.Cost) = 1 THEN CAST(prtatt.Cost AS DECIMAL(10,2))
        ELSE NULL
    END AS Cost

FROM Plus.pls.PartTransaction AS rec
JOIN Plus.pls.CodePartTransaction AS rcd ON rcd.ID = rec.PartTransactionID
JOIN Plus.pls.ROHeader AS rh ON rh.ID = rec.OrderHeaderID
JOIN Plus.pls.CodeAddress AS adr ON adr.ID = rh.AddressID
JOIN Plus.pls.CodeAddressDetails AS adt ON adt.AddressID = adr.ID
JOIN Plus.pls.RODockLog AS dl ON dl.ID = rec.RODockLogID
JOIN Plus.pls.PartSerialHistory AS ps
  ON ps.ProgramID = rec.ProgramID AND ps.PartNo = rec.PartNo AND ps.SerialNo = rec.SerialNo AND ps.ROHeaderID = rh.ID
JOIN Plus.pls.PartNo AS prt ON prt.PartNo = rec.PartNo
OUTER APPLY (
    SELECT fb.ROHeaderID,
    MAX(CASE WHEN fbtt.AttributeName = 'FLAGGED_BOXES' AND fb.Value='NO' THEN 'Good' ELSE 'Bad' END) AS FlgBx,
    MAX(CASE WHEN fbtt.AttributeName = 'CUSTOMERTYPE' THEN fb.Value ELSE NULL END) AS CustType,
    MAX(CASE WHEN fbtt.AttributeName = 'RETURNTYPE' THEN fb.Value ELSE NULL END) AS ReturnType,
    MAX(CASE WHEN fbtt.AttributeName = 'TOTAL_UNITS' THEN fb.Value ELSE NULL END) AS TotalUnits
    FROM Plus.pls.ROHeaderAttribute AS fb
    JOIN Plus.pls.CodeAttribute AS fbtt ON fbtt.ID = fb.AttributeID AND fbtt.AttributeName IN ('FLAGGED_BOXES','CUSTOMERTYPE','RETURNTYPE','TOTAL_UNITS')
    WHERE fb.ROHeaderID = rh.ID
    GROUP BY fb.ROHeaderID 
) AS FlgBx
OUTER APPLY (
    SELECT brc.Value
    FROM Plus.pls.CodeAddressDetailsAttribute AS brc
    JOIN Plus.pls.CodeAttribute AS brca ON brca.ID = brc.AttributeID AND brca.AttributeName = 'BRANCHES'
    WHERE brc.AddressDetailID = adt.ID
) AS Branch
OUTER APPLY (
    SELECT psa.PartSerialHistoryID,
           MAX(CASE WHEN wsa.AttributeName='MacAddress'       THEN Value END) AS Mac,
           MAX(CASE WHEN wsa.AttributeName='IMEI'             THEN Value END) AS IMEI,
           MAX(CASE WHEN wsa.AttributeName='BATTERY'          THEN Value END) AS Battery,
           MAX(CASE WHEN wsa.AttributeName='WARRANTY_STATUS'  THEN Value END) AS WarrantyStatus,
           MAX(CASE WHEN wsa.AttributeName='DISPOSITION'      THEN Value END) AS SerialDisposition,
           MAX(CASE WHEN wsa.AttributeName='WIPE'             THEN Value END) AS GoogleWipe,
           MAX(CASE WHEN wsa.AttributeName='TECH_ID'          THEN Value END) AS tch,
           MAX(CASE WHEN wsa.AttributeName='DATE_CODE'        THEN Value END) AS dtcd
    FROM Plus.pls.PartSerialAttributeHistory AS psa
    JOIN Plus.pls.CodeAttribute AS wsa
      ON wsa.ID = psa.AttributeID
     AND wsa.AttributeName IN ('WARRANTY_STATUS','MacAddress','BATTERY','IMEI','DISPOSITION','WIPE','TECH_ID','DATE_CODE')
    WHERE psa.PartSerialHistoryID = ps.ID
    GROUP BY psa.PartSerialHistoryID
) AS prsr
OUTER APPLY (
    SELECT ru.ID AS ROUnitID,
           MAX(CASE WHEN wsa.AttributeName='MacAddress'       THEN Value END) AS Mac,
           MAX(CASE WHEN wsa.AttributeName='IMEI'             THEN Value END) AS IMEI,
           MAX(CASE WHEN wsa.AttributeName='BATTERY'          THEN Value END) AS Battery,
           MAX(CASE WHEN wsa.AttributeName='WARRANTY_STATUS'  THEN Value END) AS WarrantyStatus,
           MAX(CASE WHEN wsa.AttributeName='DISPOSITION'      THEN Value END) AS SerialDisposition,
           MAX(CASE WHEN wsa.AttributeName='WIPE'             THEN Value END) AS GoogleWipe,
           MAX(CASE WHEN wsa.AttributeName='TECH_ID'          THEN Value END) AS tch,
           MAX(CASE WHEN wsa.AttributeName='DATE_CODE'        THEN Value END) AS dtcd
    FROM Plus.pls.ROLine rl 
    JOIN Plus.pls.ROUnit ru ON ru.ROLineID = rl.ID AND ru.SerialNo = ps.SerialNo
    JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID 
    JOIN Plus.pls.CodeAttribute AS wsa ON wsa.ID = rua.AttributeID 
     AND wsa.AttributeName IN ('WARRANTY_STATUS','MacAddress','BATTERY','IMEI','DISPOSITION','WIPE','TECH_ID','DATE_CODE')
    WHERE rl.ROHeaderID = rh.ID AND rl.ID = rec.OrderLineID
    GROUP BY ru.ID 
) AS rosr
OUTER APPLY (
    SELECT dc.PartNo,
           MAX(CASE WHEN dctt.AttributeName='WARRANTY_TERM' THEN Value END) AS DateCode,
           MAX(CASE WHEN dctt.AttributeName='DISPOSITION'   THEN Value END) AS PartDisposition,
           MAX(CASE WHEN dctt.AttributeName='Cost' THEN Value END) AS Cost
    FROM Plus.pls.PartNoAttribute AS dc
    JOIN Plus.pls.CodeAttribute AS dctt
      ON dctt.ID = dc.AttributeID
     AND dctt.AttributeName IN ('WARRANTY_TERM','DISPOSITION','Cost')
    WHERE dc.PartNo = prt.PartNo AND dc.ProgramID = rec.ProgramID
    GROUP BY dc.PartNo
) AS prtatt
/* CLEAN ONCE, USE EVERYWHERE */
OUTER APPLY (
SELECT 
      CleanWarrantyStatus =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.WarrantyStatus,rosr.WarrantyStatus), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanSerialDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.SerialDisposition,rosr.SerialDisposition), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanPartDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prtatt.PartDisposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),'')
) AS clean
WHERE rec.ProgramID IN (10068, 10072)
  AND rec.PartTransactionID = 1
  AND rcd.Description = 'RO-RECEIVE'
  AND adt.AddressType = 'ShipFrom'

UNION ALL 

SELECT 
    rec.CreateDate AS "Date Received",
    dl.TrackingNo AS "Tracking Number",
    rec.CustomerReference AS ASN,
    FlgBx.FlgBx AS "Flagged Box",
    prsr.tch AS "Tech ID",
    CASE WHEN SUBSTRING(Branch.Value,1,1)='0' THEN SUBSTRING(Branch.Value,2,10) ELSE Branch.Value END AS "Branch ID",
    rec.PartNo AS "Part No",
    rec.SerialNo AS "Serial No",
    prsr.Mac AS Mac,
    prsr.IMEI AS IMEI,
    prsr.Battery AS "Battery Removal",
    prsr.GoogleWipe AS "Google Wipe",
    prsr.dtcd AS "Date Code",
    dl.ID AS "Dock Log ID",
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'RMA'
      ELSE COALESCE(clean.CleanSerialDisposition, clean.CleanPartDisposition)
    END AS Disposition,
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'IW'
      WHEN COALESCE(clean.CleanWarrantyStatus, '') = 'UKN' THEN 'UKN'
      ELSE 'OOW'
    END AS "Warranty Status",
    rec.ProgramID AS ProgramID,
    rh.ID AS RMANumber,
    FlgBx.CustType AS RMAType,
    FlgBx.ReturnType AS Dept,
    FlgBx.TotalUnits AS "Total Units",
    CASE 
        WHEN ISNUMERIC(prtatt.Cost) = 1 THEN CAST(prtatt.Cost AS DECIMAL(10,2))
        ELSE NULL
    END AS Cost

FROM Plus.pls.PartTransaction AS rec
JOIN Plus.pls.CodePartTransaction AS rcd ON rcd.ID = rec.PartTransactionID
JOIN Plus.pls.ROHeader AS rh ON rh.ID = rec.OrderHeaderID
JOIN Plus.pls.CodeAddress AS adr ON adr.ID = rh.AddressID
JOIN Plus.pls.CodeAddressDetails AS adt ON adt.AddressID = adr.ID
JOIN Plus.pls.RODockLog AS dl ON dl.ID = rec.RODockLogID
JOIN Plus.pls.PartNo AS prt ON prt.PartNo = rec.PartNo
JOIN Plus.pls.ROLine AS rl ON rl.ROHeaderID = rh.ID AND rl.PartNo = rec.PartNo AND rl.ID = rec.OrderLineID 

CROSS APPLY (

    SELECT ru.ID AS ROUnitID,
           MAX(CASE WHEN wsa.AttributeName='MacAddress'       THEN Value END) AS Mac,
           MAX(CASE WHEN wsa.AttributeName='IMEI'             THEN Value END) AS IMEI,
           MAX(CASE WHEN wsa.AttributeName='BATTERY'          THEN Value END) AS Battery,
           MAX(CASE WHEN wsa.AttributeName='WARRANTY_STATUS'  THEN Value END) AS WarrantyStatus,
           MAX(CASE WHEN wsa.AttributeName='DISPOSITION'      THEN Value END) AS SerialDisposition,
           MAX(CASE WHEN wsa.AttributeName='WIPE'             THEN Value END) AS GoogleWipe,
           MAX(CASE WHEN wsa.AttributeName='TECH_ID'          THEN Value END) AS tch,
           MAX(CASE WHEN wsa.AttributeName='DATE_CODE'        THEN Value END) AS dtcd

    FROM Plus.pls.ROUnit ru 
    JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID 
    JOIN Plus.pls.CodeAttribute AS wsa ON wsa.ID = rua.AttributeID 

     AND wsa.AttributeName IN ('WARRANTY_STATUS','MacAddress','BATTERY','IMEI','DISPOSITION','WIPE','TECH_ID','DATE_CODE')
    WHERE ru.ROLineID = rl.ID AND ru.SerialNo = rec.SerialNo
    GROUP BY ru.ID 
) AS prsr
OUTER APPLY (
    SELECT fb.ROHeaderID,
    MAX(CASE WHEN fbtt.AttributeName = 'FLAGGED_BOXES' AND fb.Value='NO' THEN 'Good' ELSE 'Bad' END) AS FlgBx,
    MAX(CASE WHEN fbtt.AttributeName = 'CUSTOMERTYPE' THEN fb.Value ELSE NULL END) AS CustType,
    MAX(CASE WHEN fbtt.AttributeName = 'RETURNTYPE' THEN fb.Value ELSE NULL END) AS ReturnType,
    MAX(CASE WHEN fbtt.AttributeName = 'TOTAL_UNITS' THEN fb.Value ELSE NULL END) AS TotalUnits
    FROM Plus.pls.ROHeaderAttribute AS fb
    JOIN Plus.pls.CodeAttribute AS fbtt ON fbtt.ID = fb.AttributeID AND fbtt.AttributeName IN ('FLAGGED_BOXES','CUSTOMERTYPE','RETURNTYPE','TOTAL_UNITS')
    WHERE fb.ROHeaderID = rh.ID
    GROUP BY fb.ROHeaderID 
) AS FlgBx
OUTER APPLY (
    SELECT brc.Value
    FROM Plus.pls.CodeAddressDetailsAttribute AS brc
    JOIN Plus.pls.CodeAttribute AS brca ON brca.ID = brc.AttributeID AND brca.AttributeName = 'BRANCHES'
    WHERE brc.AddressDetailID = adt.ID
) AS Branch
OUTER APPLY (
    SELECT dc.PartNo,
           MAX(CASE WHEN dctt.AttributeName='WARRANTY_TERM' THEN Value END) AS DateCode,
           MAX(CASE WHEN dctt.AttributeName='DISPOSITION'   THEN Value END) AS PartDisposition,
           MAX(CASE WHEN dctt.AttributeName='Cost' THEN Value END) AS Cost
    FROM Plus.pls.PartNoAttribute AS dc
    JOIN Plus.pls.CodeAttribute AS dctt
      ON dctt.ID = dc.AttributeID
     AND dctt.AttributeName IN ('WARRANTY_TERM','DISPOSITION','Cost')
    WHERE dc.PartNo = prt.PartNo AND dc.ProgramID = rec.ProgramID
    GROUP BY dc.PartNo
) AS prtatt
/* CLEAN ONCE, USE EVERYWHERE */
OUTER APPLY (
    SELECT
      -- remove tabs/newlines, trim, upper, null blanks
      CleanWarrantyStatus =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prsr.WarrantyStatus, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanSerialDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prsr.SerialDisposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanPartDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prtatt.PartDisposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),'')
) AS clean

WHERE rec.ProgramID IN (10068, 10072) 
  AND rec.PartTransactionID = 1
  AND rcd.Description = 'RO-RECEIVE'
  AND adt.AddressType = 'ShipFrom'
  AND rec.SerialNo = '*'