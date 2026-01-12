

SELECT
    SOH.ProgramID,
    SOH.ID,
    P.Name AS Program,
    CustomerReference,
    SOL.PartNo,
    CC.Description AS Configuration,
    ThirdPartyReference,
    MAX(SOSI.TrackingNo) AS TrackingNo,
    SUM(CAST(SOL.QtyToShip AS BIGINT)) AS QtyToShip,
    SUM(CAST(SOL.QtyReserved AS BIGINT)) AS QtyShipped,
    SOH.AddressID,
    CONCAT(CAD.Address1, ' ', CAD.Address2) AS Address,
    CAD.City,
    CAD.State,
    CAD.Country,
    CAD.Zip,
        CAD.Phone,
    CAD.Name,
    SOHA.Value,
    CS.Description AS Status,
    U.Username,
    SOH.CreateDate,
    SOH.LastActivityDate,
    MAX(CASE WHEN SOL.StatusID = 18 THEN SOH.LastActivityDate ELSE NULL END) AS [ShipDate],
    (SELECT TOP 1 pl.LocationNo
     FROM Plus.pls.SOUnit sou
     INNER JOIN Plus.pls.PartLocation pl ON pl.ID = sou.FromLocationID
     WHERE sou.SOLineID = SOL.ID
     ORDER BY sou.ID DESC) AS LocationNo
FROM Plus.pls.SOHeader SOH 
INNER JOIN Plus.pls.SOLine SOL  ON SOL.SOHeaderID = SOH.ID
INNER JOIN Plus.pls.Program P  ON P.ID = SOH.ProgramID
INNER JOIN Plus.pls.CodeAddressDetails CAD  ON CAD.AddressID = SOH.AddressID AND CAD.AddressType = 'ShipTo' COLLATE Latin1_General_100_CI_AS
INNER JOIN Plus.pls.CodeStatus CS  ON CS.ID = SOH.StatusID
INNER JOIN Plus.pls.[User] U  ON U.ID = SOH.UserID
LEFT JOIN Plus.pls.CodeConfiguration CC  ON CC.ID = SOL.ConfigurationID
LEFT JOIN Plus.pls.SOShipmentInfo SOSI  ON SOH.ID = SOSI.SOHeaderID
LEFT JOIN Plus.pls.CodeAttribute CA  ON CA.AttributeName = 'CUSTORDERTYPE'
LEFT JOIN Plus.pls.SOHeaderAttribute SOHA  ON SOHA.SOHeaderID = SOH.ID AND SOHA.AttributeID = CA.ID
WHERE SOH.ProgramID = 10068  -- ADT Program only
    AND SOH.CustomerReference LIKE 'REY%'  -- CustomerReference must start with 'REY'
GROUP BY
    SOH.ProgramID,
    SOH.ID,
    P.Name,
    CustomerReference,
    SOL.PartNo,
    CC.Description,
    ThirdPartyReference,
    SOH.AddressID,
    CONCAT(CAD.Address1, ' ', CAD.Address2),
    CAD.City,
    CAD.State,
    CAD.Country,
    CAD.Zip,
        CAD.Phone,
    CAD.Name,
    SOHA.Value,
    CS.Description,
    U.Username,
    SOH.CreateDate,
    SOH.LastActivityDate,
    SOL.ID