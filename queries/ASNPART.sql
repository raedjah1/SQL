CREATE OR ALTER         VIEW [rpt].[ADTPartDetailReport] AS

SELECT
    CASE WHEN SUBSTRING(Branch.Value,1,1) = '0'
	     THEN SUBSTRING(Branch.Value,2,10)
		 ELSE Branch.Value
		 END "Branch ID",
    rh.CustomerReference AS ASN,
    CASE 
        WHEN rh.CustomerReference LIKE 'X%' THEN 
            CASE CustomerType.Value
                WHEN 'DIY' THEN 'CDR - DIY'
                WHEN 'DIFM' THEN 'CDR - DIFM'
                ELSE 'CDR'
            END
        WHEN rh.CustomerReference LIKE 'EX%' THEN 'Excess Centralization'
        WHEN rh.CustomerReference LIKE 'FSR%' THEN 'FSR'
        WHEN rh.CustomerReference LIKE 'SP%' THEN 'Special Projects'
        ELSE 'Other'
    END AS ASNCategory,
    dl.TrackingNo AS Tracking,
    FlgBx.FlgBx AS "Flagged Box",
    COALESCE(prsr.Battery, rosr.Battery) AS "Battery Received",
    dl.CreateDate AS "Date Delivered",
    ps.CreateDate AS "Date Catalogged",
    COALESCE(prsr.tch,rosr.tch) AS "Tech Code",
    prtatt.Mfg AS Manufacturer,
    CASE 
        WHEN ISNUMERIC(prtatt.Cost) = 1 THEN CAST(prtatt.Cost AS DECIMAL(10,2))
        ELSE NULL
    END AS Cost,
    ps.PartNo AS "Part No",
    ps.SerialNo AS "Serial Number",
    COALESCE(prsr.Mac,rosr.Mac) AS "Mac ID",
    COALESCE(prsr.IMEI,rosr.IMEI) AS IMEI,
    COALESCE(prsr.dtcd,rosr.dtcd) AS "Date Code", 
    CASE 
        WHEN ISNULL(UPPER(COALESCE(prsr.WarrantyStatus,rosr.WarrantyStatus)), '') IN ('IN WARRANTY', 'IW', 'IN_WARRANTY') THEN 'IW'
        WHEN ISNULL(UPPER(COALESCE(prsr.WarrantyStatus,rosr.WarrantyStatus)), '') = 'UKN' THEN 'UKN'
        ELSE 'OOW'
        END "Warranty Status",
    dl.ID AS "Dock Log",
    CASE 
        WHEN ISNULL(UPPER(COALESCE(prsr.WarrantyStatus,rosr.WarrantyStatus)), '') IN ('IN WARRANTY', 'IW', 'IN_WARRANTY') THEN 'RMA'
        ELSE ISNULL(COALESCE(prsr.SerialDisposition,rosr.SerialDisposition), prtatt.PartDisposition)
    END AS Disposition,
'' AS "RMA Number",
loc.LocationNo AS ReconextLocationNo, 
loc.Warehouse AS ReconextWarehouse,
CASE WHEN loc.LocationNo LIKE 'DGI.HOLD.%' THEN 'DGI Hold'
     WHEN loc.LocationNo LIKE 'DGI.REY.%' THEN 'DGI REY'
     WHEN loc.LocationNo LIKE 'FGI.REY.%' THEN 'FGI REY'
     WHEN loc.LocationNo LIKE 'REY-SUPERMARKET.CRPRG.MEM.SM%' THEN 'CR Program'
     WHEN loc.LocationNo LIKE '%CRPRG%' THEN 'CR Program'
     WHEN loc.LocationNo LIKE 'SCRAP.STAGE.%' THEN 'Awaiting Scrap Shipment'
     WHEN loc.LocationNo LIKE 'REY-CD.CROSS.MEM.REY%' THEN 'Cross Docked to Reynosa'
     WHEN loc.LocationNo LIKE '%CD-CROSS%' THEN 'Cross Docked to Reynosa'
     WHEN loc.LocationNo LIKE 'STAGING.REY.%' THEN 'Reynosa Staging'
     WHEN loc.LocationNo LIKE 'OEM-SUPERMARKET%' THEN 'RMA'
     WHEN loc.LocationNo LIKE '%OEM%' THEN 'RMA'
     WHEN loc.LocationNo LIKE 'DGI.%' THEN 'DGI'
     WHEN loc.LocationNo LIKE 'FGI.%' THEN 'FGI'
     WHEN loc.LocationNo LIKE 'FLOORSTOCK.%' THEN 'Floor Stock'
     WHEN loc.LocationNo LIKE 'HOLD.%' THEN 'Hold'
     /* Issue locations */
     WHEN loc.LocationNo LIKE 'ISSUE.%' THEN 'Issue'
     /* Reserve locations */
     WHEN loc.LocationNo LIKE 'RESERVE.%' THEN 'Reserve'
     WHEN loc.LocationNo LIKE 'REY-SUPERMARKET.%' THEN 'REY Supermarket'
     /* Scrap locations */
     WHEN loc.LocationNo LIKE 'SCRAP.%' THEN 'Scrap'
     /* Work In Progress locations */
     WHEN loc.LocationNo LIKE 'WIP.%' THEN 'Work In Progress'
     /* Default case - return original location */
     ELSE loc.LocationNo
     END AS Locations,
CASE WHEN loc.LocationNo LIKE 'DGI.REY.%' THEN 'Reynosa'
     WHEN loc.LocationNo LIKE 'FGI.REY.%' THEN 'Reynosa'
     WHEN loc.LocationNo LIKE 'REY-CD.CROSS.MEM.REY%' THEN 'In Transit'
     WHEN loc.LocationNo LIKE '%CD-CROSS%' THEN 'In Transit'
     WHEN loc.LocationNo LIKE 'STAGING.REY.%' THEN 'Reynosa'
     ELSE 'Memphis'
     END Site,
     ps.ProgramID,
     ps.LastActivityDate

FROM Plus.pls.PartSerial ps 
JOIN Plus.pls.CodeStatus st ON st.ID = ps.StatusID AND st.Description NOT IN ('SHIPPED', 'CANCELLED', 'CANCELED', 'REID')
JOIN Plus.pls.ROHeader rh ON rh.ID = ps.ROHeaderID
JOIN Plus.pls.CodeAddress adr ON adr.ID = rh.AddressID
JOIN Plus.pls.CodeAddressDetails adt ON adt.AddressID = adr.ID AND adt.AddressType = 'ShipFrom'
JOIN Plus.pls.RODockLog dl ON dl.ROHeaderID = rh.ID AND dl.ID = (SELECT MAX(dlx.ID) FROM Plus.pls.RODockLog dlx WHERE dlx.ROHeaderID = rh.ID)
JOIN Plus.pls.PartNo prt ON prt.PartNo = ps.PartNo 
JOIN Plus.pls.PartLocation loc ON loc.ID = ps.LocationID

OUTER APPLY (
    SELECT psa.PartSerialID,
	       MAX(CASE WHEN wsa.AttributeName = 'MacAddress' THEN Value ELSE Null END) Mac, 
	       MAX(CASE WHEN wsa.AttributeName = 'IMEI' THEN Value ELSE Null END) IMEI,
		   MAX(CASE WHEN wsa.AttributeName = 'BATTERY' THEN Value ELSE Null END) Battery,
		   MAX(CASE WHEN wsa.AttributeName = 'WARRANTY_STATUS' THEN Value ELSE Null END) WarrantyStatus,
		   MAX(CASE WHEN wsa.AttributeName = 'DISPOSITION' THEN Value ELSE Null END) SerialDisposition,
		   MAX(CASE WHEN wsa.AttributeName = 'WIPE' THEN Value ELSE Null END) GoogleWipe,
		   MAX(CASE WHEN wsa.AttributeName = 'TECH_ID' THEN Value ELSE Null END) tch,
		   MAX(CASE WHEN wsa.AttributeName = 'DATE_CODE' THEN Value ELSE Null END) dtcd
    FROM Plus.pls.PartSerialAttribute psa
	JOIN Plus.pls.CodeAttribute wsa ON wsa.ID = psa.AttributeID AND wsa.AttributeName IN ('WARRANTY_STATUS', 'MacAddress', 
	  'BATTERY', 'IMEI', 'DISPOSITION', 'WIPE', 'TECH_ID', 'DATE_CODE')
    WHERE psa.PartSerialID = ps.ID GROUP BY psa.PartSerialID 
) prsr

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
    WHERE rl.ROHeaderID = rh.ID  AND rl.PartNo = ps.PartNo
    GROUP BY ru.ID 
) AS rosr

OUTER APPLY (
    SELECT brc.Value
    FROM Plus.pls.CodeAddressDetailsAttribute brc
    JOIN Plus.pls.CodeAttribute brca ON brca.ID = brc.AttributeID AND brca.AttributeName = 'BRANCHES'
    WHERE brc.AddressDetailID = adt.ID
) Branch

OUTER APPLY (
    SELECT dc.PartNo, 
	       MAX(CASE WHEN dctt.AttributeName = 'WARRANTY_TERM' THEN Value ELSE Null END) DateCode,
		   MAX(CASE WHEN dctt.AttributeName = 'DISPOSITION' THEN Value ELSE Null END) PartDisposition,
           MAX(CASE WHEN dctt.AttributeName = 'SUPPLIER_NO' THEN Value ELSE Null END) Mfg,
           MAX(CASE WHEN dctt.AttributeName = 'Cost' THEN Value ELSE Null END) Cost
    FROM Plus.pls.PartNoAttribute dc
    JOIN Plus.pls.CodeAttribute dctt ON dctt.ID = dc.AttributeID AND dctt.AttributeName IN ('WARRANTY_TERM', 'DISPOSITION', 'SUPPLIER_NO', 'Cost')
    WHERE dc.PartNo = prt.PartNo AND dc.ProgramID = ps.ProgramID GROUP BY dc.PartNo 
) prtatt

OUTER APPLY (
    SELECT CASE WHEN fb.Value = 'NO' THEN 'Good' ELSE 'Bad' END AS FlgBx
    FROM Plus.pls.ROHeaderAttribute fb
    JOIN Plus.pls.CodeAttribute fbtt ON fbtt.ID = fb.AttributeID AND fbtt.AttributeName = 'FLAGGED_BOXES'
    WHERE fb.ROHeaderID = rh.ID
) FlgBx

OUTER APPLY (
    SELECT TOP 1 rha2.Value
    FROM Plus.pls.ROHeaderAttribute rha2
    JOIN Plus.pls.CodeAttribute att2 ON att2.ID = rha2.AttributeID 
    WHERE rha2.ROHeaderID = rh.ID AND att2.AttributeName = 'CUSTOMERTYPE'
    ORDER BY rha2.ID DESC
) CustomerType

WHERE ps.ProgramID IN (10068, 10072) 