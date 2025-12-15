CREATE OR ALTER   VIEW [rpt].[ADTASNReport] AS

SELECT 
    (SELECT TOP 1 rha1.Value 
     FROM Plus.pls.ROHeaderAttribute rha1
     JOIN Plus.pls.CodeAttribute att ON att.ID = rha1.AttributeID 
     WHERE rha1.ROHeaderID = rh.ID AND att.AttributeName = 'SHIPFROMORG'
     ORDER BY rha1.ID DESC) AS Branch,
    rh.CustomerReference AS ASN,
    CASE 
        WHEN rh.CustomerReference LIKE 'X%' THEN 'CDR'
        WHEN rh.CustomerReference LIKE 'EX%' THEN 'Excess Centralization'
        WHEN rh.CustomerReference LIKE 'FSR%' THEN 'FSR'
        WHEN rh.CustomerReference LIKE 'SP%' THEN 'Special Projects'
        ELSE 'Other'
    END AS ASNCategory,
    (SELECT TOP 1 rha2.Value 
     FROM Plus.pls.ROHeaderAttribute rha2
     JOIN Plus.pls.CodeAttribute att2 ON att2.ID = rha2.AttributeID 
     WHERE rha2.ROHeaderID = rh.ID AND att2.AttributeName = 'CUSTOMERTYPE'
     ORDER BY rha2.ID DESC) AS CustomerType,
    (SELECT TOP 1 rha3.Value 
     FROM Plus.pls.ROHeaderAttribute rha3
     JOIN Plus.pls.CodeAttribute att3 ON att3.ID = rha3.AttributeID 
     WHERE rha3.ROHeaderID = rh.ID AND att3.AttributeName = 'RETURNTYPE'
     ORDER BY rha3.ID DESC) AS ReturnType,
    COALESCE(dl.TrackingNo,crst.TrackingNo) AS TrackingNo,
    rs.Description AS ASNStatus,
    rh.CreateDate AS ASNCreateDate,
    dl.CreateDate AS ASNDeliveryDate,
    LastROLine.CreateDate AS ASNProcessedDate,
    crst.Username AS UserID,

/* removed CarrierStatus during Fabric workspace refresh problems - Mathieu - Sep-19-2025 
 readded to correct Power BI reporting - Sep-23-2025

*/
    CASE WHEN rs.Description IN ('RECEIVED','PARTIALLYRECEIVED')
         THEN COALESCE(fapi.CarrierStatus,'Delivered')
         ELSE fapi.CarrierStatus 
         END CarrierStatus,
    rh.ProgramID

FROM Plus.pls.ROHeader rh 
JOIN Plus.pls.CodeStatus rs ON rs.ID = rh.StatusID 
CROSS APPLY (
     SELECT TOP 1 crst1.ProgramID, crst1.TrackingNo, aus.Username
     FROM Plus.pls.CarrierResult crst1 
     JOIN Plus.pls.[User] aus ON aus.ID = crst1.UserID
     WHERE crst1.OrderHeaderID = rh.ID AND crst1.ProgramID = rh.ProgramID AND crst1.OrderType = 'RO' 
     ORDER BY crst1.ID DESC
) crst
OUTER APPLY (
    SELECT TOP 1 dlx.TrackingNo, dlx.CreateDate
    FROM Plus.pls.RODockLog dlx 
    WHERE dlx.ROHeaderID = rh.ID 
    ORDER BY dlx.ID DESC
) AS dl
OUTER APPLY (
    SELECT TOP 1 rl.CreateDate 
    FROM Plus.pls.ROLine rl 
    WHERE rl.ROHeaderID = rh.ID 
    ORDER BY rl.ID DESC
) AS LastROLine
OUTER APPLY (
SELECT TOP 1 th.EventDescription AS CarrierStatus
  FROM Plus.pls.TrackingHeader th
  WHERE th.ProgramID = crst.ProgramID 
   AND th.TrackingNo = crst.TrackingNo
   AND th.EventDescription <> 'Error'
  ORDER BY ID DESC
) AS fapi

WHERE rh.ProgramID IN (10068, 10072) 
AND  rh.CreateDate >= CAST(CONCAT(YEAR(CONVERT(date, DATEADD(MONTH, -3, GETDATE()))), '-', MONTH(CONVERT(date, DATEADD(MONTH, -3, GETDATE()))), '-1') AS date)
AND  (rh.CustomerReference LIKE 'X%' 
      OR rh.CustomerReference LIKE 'EX%' 
      OR rh.CustomerReference LIKE 'FSR%' 
      OR rh.CustomerReference LIKE 'SP%')
