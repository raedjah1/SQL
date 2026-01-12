CREATE OR ALTER                           VIEW [rpt].[ADTReceiptReport] AS

WITH Rectransactions AS ( 
     SELECT 
     rec.CreateDate AS DateReceived,
     dl.TrackingNo AS TrackingNumber,
     rec.CustomerReference AS ASN,
     rec.PartNo,
     rec.SerialNo,
     rec.Qty,
     dl.ID AS DockLogID,
     rec.ProgramID AS ProgramID,
     rec.OrderHeaderID AS RMANumber,
     rec.ID AS ReceiptTransactionID,
     rec.OrderLineID AS ROLineID,
     dl.CreateDate AS DockLogDate

     FROM Plus.pls.PartTransaction AS rec
     JOIN Plus.pls.CodePartTransaction AS rcd ON rcd.ID = rec.PartTransactionID AND rcd.Description = 'RO-RECEIVE'
     JOIN Plus.pls.RODockLog AS dl ON dl.ID = rec.RODockLogID

     WHERE rec.ProgramID IN (10068, 10072) 
      AND rec.PartTransactionID = 1
     ),

AttributeSort AS (
     SELECT 
	 MAX(CASE WHEN UPPER(AttributeName)='MACADDRESS'      THEN ID END) AS Attr_Mac_Result,
     MAX(CASE WHEN UPPER(AttributeName)='IMEI'            THEN ID END) AS Attr_IMEI_Result,
     MAX(CASE WHEN UPPER(AttributeName)='BATTERY'         THEN ID END) AS Attr_Battery_Result,
     MAX(CASE WHEN UPPER(AttributeName)='WARRANTY_STATUS' THEN ID END) AS Attr_WarrantyStatus_Result,
     MAX(CASE WHEN UPPER(AttributeName)='DISPOSITION'     THEN ID END) AS Attr_SerialDisposition_Result, 
     MAX(CASE WHEN UPPER(AttributeName)='WIPE'            THEN ID END) AS Attr_GoogleWipe_Result, 
     MAX(CASE WHEN UPPER(AttributeName)='TECH_ID'         THEN ID END) AS Attr_tch_Result, 
     MAX(CASE WHEN UPPER(AttributeName)='DATE_CODE'       THEN ID END) AS Attr_dtcd_Result, 
     MAX(CASE WHEN UPPER(AttributeName)='FLAGGED_BOXES'   THEN ID END) AS Attr_FlgBx_Result, 
     MAX(CASE WHEN UPPER(AttributeName)='CUSTOMERTYPE'    THEN ID END) AS Attr_CustType_Result, 
     MAX(CASE WHEN UPPER(AttributeName)='RETURNTYPE'      THEN ID END) AS Attr_ReturnType_Result, 
     MAX(CASE WHEN UPPER(AttributeName)='TOTAL_UNITS'     THEN ID END) AS Attr_TotalUnits_Result, 
     MAX(CASE WHEN UPPER(AttributeName)='BRANCHES'        THEN ID END) AS Attr_BRANCHES_Result, 
     MAX(CASE WHEN UPPER(AttributeName)='WARRANTY_TERM'   THEN ID END) AS Attr_WarrTerms_Result,
     MAX(CASE WHEN UPPER(AttributeName)='COST'            THEN ID END) AS Attr_Cost_Result
     FROM Plus.pls.CodeAttribute
	 ),

InStock AS (
     SELECT 
     ps.ProgramID, 
     ps.PartNo, 
     ps.SerialNo, 
     ps.ROHeaderID,
     'Primary' AS PartSerialType,
     ps.ID AS PartSerialID,
     ps.LastActivityDate,
     attr.*

     FROM Plus.pls.PartSerial AS ps
     CROSS JOIN AttributeSort attr 
     WHERE ps.ProgramID IN (10068, 10072)

     UNION ALL 

     SELECT 
     ps.ProgramID, 
     ps.PartNo, 
     ps.SerialNo, 
     ps.ROHeaderID,
     'Archive' AS PartSerialType,
     ps.ID AS PartSerialID, 
     ps.LastActivityDate,
     attr.* 

     FROM Plus.pls.PartSerialHistory AS ps
     CROSS JOIN AttributeSort attr 
     WHERE ps.ProgramID IN (10068, 10072)
     ),

InStockValues AS (
     SELECT 
     psa.PartSerialID,
     ps.PartSerialType,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_Mac_Result THEN psa.Value END) AS Mac,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_IMEI_Result THEN psa.Value END) AS IMEI,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_Battery_Result THEN psa.Value END) AS Battery,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_WarrantyStatus_Result THEN psa.Value END) AS WarrantyStatus,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_SerialDisposition_Result THEN psa.Value END) AS SerialDisposition,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_GoogleWipe_Result THEN psa.Value END) AS GoogleWipe,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_tch_Result THEN psa.Value END) AS tch,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_dtcd_Result THEN psa.Value END) AS dtcd
     FROM InStock ps
     JOIN Plus.pls.PartSerialAttribute psa ON psa.PartSerialID = ps.PartSerialID
     CROSS JOIN AttributeSort attr 
     WHERE ps.PartSerialType = 'Primary'
     GROUP BY psa.PartSerialID, ps.PartSerialType
     ),

ArchiveValues AS (
     SELECT 
     psa.PartSerialHistoryID AS PartSerialID,
     ps.PartSerialType,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_Mac_Result THEN psa.Value END) AS Mac,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_IMEI_Result THEN psa.Value END) AS IMEI,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_Battery_Result THEN psa.Value END) AS Battery,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_WarrantyStatus_Result THEN psa.Value END) AS WarrantyStatus,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_SerialDisposition_Result THEN psa.Value END) AS SerialDisposition,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_GoogleWipe_Result THEN psa.Value END) AS GoogleWipe,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_tch_Result THEN psa.Value END) AS tch,
     MAX(CASE WHEN psa.AttributeID = ps.Attr_dtcd_Result THEN psa.Value END) AS dtcd
     FROM InStock ps
     JOIN Plus.pls.PartSerialAttributeHistory AS psa ON psa.PartSerialHistoryID = ps.PartSerialID
     CROSS JOIN AttributeSort attr 
     WHERE ps.PartSerialType = 'Archive'
     GROUP BY psa.PartSerialHistoryID, ps.PartSerialType
     ),

ROData AS (
     SELECT rh.ID AS ROHeaderID, rh.CustomerReference, rh.AddressID, attr.* 
     FROM Plus.pls.ROHeader AS rh 
     CROSS APPLY (
          SELECT TOP 1 rc.RMANumber 
          FROM Rectransactions rc
          WHERE rh.ID = rc.RMANumber 
          ORDER BY rc.ReceiptTransactionID DESC
          ) rcpt 
     CROSS JOIN AttributeSort attr
     ),

ROAttribute AS (
     SELECT 
     rd.ROHeaderID, 
     rl.PartNo,
     rl.ID AS ROLineID,
     ru.SerialNo,
     ru.ID AS ROUnitID,
     MAX(CASE WHEN rua.AttributeID = rd.Attr_Mac_Result THEN rua.Value END) AS Mac,
     MAX(CASE WHEN rua.AttributeID = rd.Attr_IMEI_Result THEN rua.Value END) AS IMEI,
     MAX(CASE WHEN rua.AttributeID = rd.Attr_Battery_Result THEN rua.Value END) AS Battery,
     MAX(CASE WHEN rua.AttributeID = rd.Attr_WarrantyStatus_Result THEN rua.Value END) AS WarrantyStatus,
     MAX(CASE WHEN rua.AttributeID = rd.Attr_SerialDisposition_Result THEN rua.Value END) AS SerialDisposition,
     MAX(CASE WHEN rua.AttributeID = rd.Attr_GoogleWipe_Result THEN rua.Value END) AS GoogleWipe,
     MAX(CASE WHEN rua.AttributeID = rd.Attr_tch_Result THEN rua.Value END) AS tch,
     MAX(CASE WHEN rua.AttributeID = rd.Attr_dtcd_Result THEN rua.Value END) AS dtcd
     FROM ROData rd
     JOIN Plus.pls.ROLine rl ON rl.ROHeaderID = rd.ROHeaderID 
    JOIN Plus.pls.ROUnit ru ON ru.ROLineID = rl.ID 
    JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID 
    GROUP BY rd.ROHeaderID, rl.PartNo, rl.ID, ru.SerialNo, ru.ID
    ),

ROAttr2 AS (
     SELECT fb.ROHeaderID,
     MAX(CASE WHEN fb.AttributeID = rd.Attr_FlgBx_Result THEN fb.Value END) AS FlgBx,
     MAX(CASE WHEN fb.AttributeID = rd.Attr_CustType_Result THEN fb.Value END) AS CustType,
     MAX(CASE WHEN fb.AttributeID = rd.Attr_ReturnType_Result THEN fb.Value END) AS ReturnType,
     MAX(CASE WHEN fb.AttributeID = rd.Attr_TotalUnits_Result THEN fb.Value END) AS TotalUnits

     FROM ROData rd
     JOIN Plus.pls.ROHeaderAttribute fb ON fb.ROHeaderID = rd.ROHeaderID 
     GROUP BY fb.ROHeaderID 
     ),

Branch AS (
     SELECT adr.ID AS AddressID,
     MAX(CASE WHEN brc.AttributeID = rd.Attr_BRANCHES_Result THEN brc.Value END) AS Branch
     FROM Plus.pls.CodeAddress adr 
     JOIN Plus.pls.CodeAddressDetails adt ON adt.AddressID = adr.ID
     JOIN Plus.pls.CodeAddressDetailsAttribute brc ON brc.AddressDetailID = adt.ID
     CROSS APPLY (
         SELECT TOP 1 rod.AddressID, rod.Attr_BRANCHES_Result
         FROM ROData rod 
         WHERE rod.AddressID = adr.ID 
         ORDER BY rod.AddressID ASC
         ) rd
     GROUP BY adr.ID 
     ),

PartAttribute AS (
     SELECT dc.PartNo,
     MAX(CASE WHEN dc.AttributeID = rd.Attr_WarrTerms_Result THEN dc.Value END) AS DateCode,
     MAX(CASE WHEN dc.AttributeID = rd.Attr_SerialDisposition_Result THEN dc.Value END) AS PartDisposition,
     MAX(CASE WHEN dc.AttributeID = rd.Attr_Cost_Result THEN dc.Value END) AS Cost
     FROM Plus.pls.PartNoAttribute AS dc
     CROSS APPLY (
          SELECT TOP 1 ist.PartNo, ist.Attr_WarrTerms_Result, ist.Attr_SerialDisposition_Result, ist.Attr_Cost_Result
          FROM InStock ist
          WHERE ist.PartNo = dc.PartNo 
          ORDER BY ist.PartNo ASC
          ) rd
     WHERE dc.ProgramID IN (10068, 10072)
     GROUP BY dc.PartNo 
     )

SELECT 
rec.DateReceived AS "Date Received",
rec.TrackingNumber AS "Tracking Number",
rec.ASN,

FlgBx.FlgBx AS "Flagged Box",
COALESCE(prsr.tch,arcv.tch,rosr.tch) AS "Tech ID",
CASE WHEN SUBSTRING(br.Branch,1,1)='0' THEN SUBSTRING(br.Branch,2,10) ELSE br.Branch END AS "Branch ID",
rec.PartNo AS "Part No",
rec.SerialNo AS "Serial No",
rec.Qty AS "Qty",
COALESCE(prsr.Mac,arcv.Mac,rosr.Mac) AS Mac,
COALESCE(prsr.IMEI,arcv.IMEI,rosr.IMEI) AS IMEI,
COALESCE(prsr.Battery,arcv.Battery,rosr.Battery) AS "Battery Removal",
COALESCE(prsr.GoogleWipe,arcv.GoogleWipe,rosr.GoogleWipe) AS "Google Wipe",
COALESCE(prsr.dtcd,arcv.dtcd,rosr.dtcd) AS "Date Code",
rec.DockLogID AS "Dock Log ID",
CASE
      WHEN COALESCE(NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.WarrantyStatus,arcv.WarrantyStatus,rosr.WarrantyStatus), CHAR(9), ' ')
             , CHAR(10), ' '), CHAR(13), ' ')))),''), '') IN ('IN WARRANTY','IW','IN_WARRANTY') 
      THEN 'RMA'
      ELSE COALESCE(NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.SerialDisposition,arcv.SerialDisposition,rosr.SerialDisposition)
            , CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''), 
            NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prtatt.PartDisposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''))
    END AS Disposition,

/*
OUTER APPLY (
    SELECT
      -- remove tabs/newlines, trim, upper, null blanks
      CleanWarrantyStatus =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.WarrantyStatus,arcv.WarrantyStatus,rosr.WarrantyStatus), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanSerialDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.SerialDisposition,arc.SerialDisposition,rosr.SerialDisposition), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanPartDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prtatt.PartDisposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),'')
) AS clean
*/

CASE
     WHEN COALESCE(NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.WarrantyStatus,arcv.WarrantyStatus,rosr.WarrantyStatus), CHAR(9), ' ')
             , CHAR(10), ' '), CHAR(13), ' ')))),''), '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'IW'
     WHEN COALESCE(NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.WarrantyStatus,arcv.WarrantyStatus,rosr.WarrantyStatus), CHAR(9), ' ')
             , CHAR(10), ' '), CHAR(13), ' ')))),''), '') = 'UKN' THEN 'UKN'
     ELSE 'OOW'
     END "Warranty Status",
rec.ProgramID AS ProgramID,
rec.RMANumber,
FlgBx.CustType AS RMAType,
FlgBx.ReturnType AS Dept,
ISNULL(FlgBx.TotalUnits,1) AS "Total Units",
CASE 
        WHEN ISNUMERIC(prtatt.Cost) = 1 THEN CAST(prtatt.Cost AS DECIMAL(10,2))
        ELSE NULL
    END AS Cost,
rec.DockLogDate

FROM Rectransactions rec
LEFT JOIN InStock istk ON istk.ProgramID = rec.ProgramID AND istk.PartNo = rec.PartNo AND istk.SerialNo = rec.SerialNo AND istk.ROHeaderID = rec.RMANumber 
LEFT JOIN InStockValues prsr ON prsr.PartSerialID = istk.PartSerialID AND prsr.PartSerialType = istk.PartSerialType 
LEFT JOIN ArchiveValues arcv ON arcv.PartSerialID = istk.PartSerialID AND arcv.PartSerialType = istk.PartSerialType
LEFT JOIN ROAttribute rosr ON rosr.ROHeaderID = rec.RMANumber AND rosr.ROLineID = rec.ROLineID AND rosr.SerialNo = rec.SerialNo 
LEFT JOIN PartAttribute prtatt ON prtatt.PartNo = rec.PartNo 
LEFT JOIN ROAttr2 FlgBx ON FlgBx.ROHeaderID = rec.RMANumber
LEFT JOIN ROData rod ON rod.ROHeaderID = rec.RMANumber
LEFT JOIN Branch br ON br.AddressID = rod.AddressID