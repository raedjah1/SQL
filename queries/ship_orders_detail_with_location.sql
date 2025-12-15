

SELECT
    SOH.ProgramID,
    SOH.ID,
    P.Name AS Program,
    CustomerReference,
    SOL.PartNo,
    CC.Description AS Configuration,
    ThirdPartyReference,
    SOSI.TrackingNo,
    SUM(CAST(SOL.QtyToShip AS BIGINT)) AS QtyToShip,
    SUM(CAST(SOL.QtyReserved AS BIGINT)) AS QtyShipped,
    SOH.AddressID,
    CONCAT(CAD.Address1, ' ', CAD.Address2) AS Address,
    CAD.City,
    CAD.State,
    CAD.Country,
    CAD.Zip,
    SOHA.Value,
    CS.Description AS Status,
    U.Username,
    SOH.CreateDate,
    SOH.LastActivityDate,
    MAX(CASE WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate ELSE NULL END) AS [ShipDate],
    MAX(PL.LocationNo) AS LocationNo,
    (SELECT TOP 1 
        CASE 
            WHEN ISNUMERIC(PNA_Cost_Sub.Value) = 1 THEN CAST(PNA_Cost_Sub.Value AS DECIMAL(10,2))
            ELSE NULL
        END
     FROM Plus.pls.PartNoAttribute PNA_Cost_Sub
     INNER JOIN Plus.pls.CodeAttribute CA_Cost_Sub ON CA_Cost_Sub.ID = PNA_Cost_Sub.AttributeID
     WHERE PNA_Cost_Sub.PartNo = SOL.PartNo
       AND CA_Cost_Sub.AttributeName = 'Cost'
     ORDER BY PNA_Cost_Sub.CreateDate DESC) AS Cost,
    CASE 
        WHEN ThirdPartyReference LIKE 'REY%' OR U.Username = 'juan.cruz@reconext.com' OR SOH.AddressID = 1020559 THEN 'CR Program'
        WHEN ThirdPartyReference LIKE 'SCRAP%' THEN 'Scrap'
        WHEN ThirdPartyReference LIKE 'SP%' THEN 'Special Projects'
        WHEN MAX(PL.LocationNo) LIKE 'OEM%' THEN 'OEM RMA'
        WHEN CustomerReference LIKE '8%' THEN 'FWD'
        ELSE 'Other'
    END AS Category
FROM Plus.pls.SOHeader SOH 
INNER JOIN Plus.pls.SOLine SOL  ON SOL.SOHeaderID = SOH.ID
INNER JOIN Plus.pls.Program P  ON P.ID = SOH.ProgramID
INNER JOIN Plus.pls.CodeAddressDetails CAD  ON CAD.AddressID = SOH.AddressID AND CAD.AddressType = 'ShipTo'
INNER JOIN Plus.pls.CodeStatus CS  ON CS.ID = SOH.StatusID
INNER JOIN Plus.pls.[User] U  ON U.ID = SOH.UserID
LEFT JOIN Plus.pls.CodeConfiguration CC  ON CC.ID = SOL.ConfigurationID
LEFT JOIN Plus.pls.SOShipmentInfo SOSI  ON SOH.ID = SOSI.SOHeaderID
LEFT JOIN Plus.pls.CodeAttribute CA  ON CA.AttributeName = 'CUSTORDERTYPE'
LEFT JOIN Plus.pls.SOHeaderAttribute SOHA  ON SOHA.SOHeaderID = SOH.ID AND SOHA.AttributeID = CA.ID
LEFT JOIN Plus.pls.SOUnit SOU ON SOU.SOLineID = SOL.ID
LEFT JOIN Plus.pls.PartLocation PL ON PL.ID = SOU.FromLocationID
WHERE SOH.ProgramID IN (10068, 10072)
GROUP BY
    SOH.ProgramID,
    SOH.ID,
    P.Name,
    CustomerReference,
    SOL.PartNo,
    CC.Description,
    ThirdPartyReference,
    SOSI.TrackingNo,
    SOH.AddressID,
    CONCAT(CAD.Address1, ' ', CAD.Address2),
    CAD.City,
    CAD.State,
    CAD.Country,
    CAD.Zip,
    SOHA.Value,
    CS.Description,
    U.Username,
    SOH.CreateDate,
    SOH.LastActivityDate

