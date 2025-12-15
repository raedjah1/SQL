SELECT 
    t0.ID, 
    t0.ProgramID, 
    t0.PartNo, 
    codeConfiguration.Description AS ConfigurationDescription, 
    t0.ParentSerialNo, 
    t0.SerialNo, 
    partLocation.LocationNo AS PartLocationNo, 
    partLocation.Warehouse,
    CASE 
        WHEN partLocation.Warehouse = 'RESERVE' AND codeStatus.Description = 'RESERVED' THEN 'RESERVED'
        WHEN partLocation.Warehouse = 'RESERVE' AND codeStatus.Description = 'SHIPPED'  THEN 'SHIPPED'
        ELSE partLocation.Warehouse
    END AS ReservationValidation,
    prtatt.CartonNo,
    t0.PalletBoxNo, 
    t0.LotNo,                     
    codeStatus.Description AS StatusDescription, 
    t0.ROHeaderID, 
    rh.CustomerReference,
    t0.RODate, 
    t0.WOHeaderID, 
    codeWorkstation.Description AS WorkstationDescription, 
    t0.WOStartDate, 
    t0.WOEndDate, 
    t0.WOPass, 
    t0.Shippable, 
    t0.SOHeaderID, 
    t0.SODate, 
    u.Username, 
    t0.CreateDate, 
    t0.LastActivityDate,
    prtatt.TrckObjAttFamily AS Family,
    prtatt.TrckObjAttLOB AS LOB,
    CASE 
        WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
        ELSE 0
    END AS Standard_Cost
FROM Plus.pls.PartSerial t0 
JOIN Plus.pls.[User]              u   ON u.ID = t0.UserID 
JOIN Plus.pls.PartLocation        partLocation ON t0.LocationID = partLocation.ID  
JOIN Plus.pls.CodeStatus          codeStatus   ON t0.StatusID   = codeStatus.ID 
LEFT JOIN Plus.pls.CodeConfiguration codeConfiguration ON t0.ConfigurationID = codeConfiguration.ID 
LEFT JOIN Plus.pls.CodeWorkStation   codeWorkstation  ON t0.WorkStationID   = codeWorkstation.ID 
LEFT JOIN Plus.pls.ROHeader          rh               ON rh.ID              = t0.ROHeaderID
LEFT JOIN Plus.pls.PartNoAttribute   pna              ON t0.PartNo = pna.PartNo 
    AND pna.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'STANDARDCOST')
OUTER APPLY (
    SELECT 
        psa.PartSerialID,
        MAX(CASE WHEN att.AttributeName = 'CartonNo'                 THEN Value END) AS CartonNo,
        MAX(CASE WHEN att.AttributeName = 'ReceiveConfiguration'     THEN Value END) AS RecConfg,
        MAX(CASE WHEN att.AttributeName = 'RepairCloseConfiguration' THEN Value END) AS RepClsCnfg,
        MAX(CASE WHEN att.AttributeName = 'BOUNCE'                   THEN Value END) AS BOUNCE,
        MAX(CASE WHEN att.AttributeName = 'PreviousStatus'           THEN Value END) AS PreviousStatus,
        MAX(CASE WHEN att.AttributeName = 'DISPOSITION_RECEIVING'    THEN Value END) AS RecDisposition,
        MAX(CASE WHEN att.AttributeName = 'TrckObjAttFamily'         THEN Value END) AS TrckObjAttFamily,
        MAX(CASE WHEN att.AttributeName = 'TrckObjAttLOB'            THEN Value END) AS TrckObjAttLOB
    FROM Plus.pls.PartSerialAttribute psa
    JOIN Plus.pls.CodeAttribute att ON att.ID = psa.AttributeID 
    WHERE psa.PartSerialID = t0.ID
    GROUP BY psa.PartSerialID
) prtatt