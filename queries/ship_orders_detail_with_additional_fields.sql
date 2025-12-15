-- ================================================
-- SHIPORDERSDETAIL VIEW WITH ADDITIONAL FIELDS
-- ================================================
-- Added fields:
-- 1. Requestor (REQUESTOR_NAME from SOHeaderAttribute)
-- 2. OrgName (Name from CodeAddressDetails)
-- 3. NeedByDate (NEED_BY_DATE from SOLineAttribute)
-- ================================================

CREATE OR ALTER VIEW [rpt].[ShipOrdersDetail] AS
SELECT
    SOH.ProgramID,
    SOH.ID,
    P.Name AS Program,
    CustomerReference,
    SOL.PartNo,
    CC.Description AS Configuration,
    ThirdPartyReference,
    SOSI.TrackingNo,
    SUM(SOL.QtyToShip) AS QtyToShip,
    SUM(SOL.QtyReserved) AS QtyShipped,
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
    -- NEW FIELDS ADDED:
    MAX(CASE WHEN SOHA_Requestor.AttributeName = 'REQUESTOR_NAME' THEN SOHA_Requestor.Value END) AS Requestor,
    CAD.Name AS OrgName,
    MAX(CASE WHEN SOLA_NeedBy.AttributeName = 'NEED_BY_DATE' THEN SOLA_NeedBy.Value END) AS NeedByDate
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
-- NEW JOINS FOR ADDITIONAL FIELDS:
LEFT JOIN Plus.pls.CodeAttribute CA_Requestor  ON CA_Requestor.AttributeName = 'REQUESTOR_NAME'
LEFT JOIN Plus.pls.SOHeaderAttribute SOHA_Requestor  ON SOHA_Requestor.SOHeaderID = SOH.ID AND SOHA_Requestor.AttributeID = CA_Requestor.ID
LEFT JOIN Plus.pls.CodeAttribute CA_NeedBy  ON CA_NeedBy.AttributeName = 'NEED_BY_DATE'
LEFT JOIN Plus.pls.SOLineAttribute SOLA_NeedBy  ON SOLA_NeedBy.SOLineID = SOL.ID AND SOLA_NeedBy.AttributeID = CA_NeedBy.ID
GROUP BY
    SOH.ProgramID,
    SOH.ID,
    P.Name,
    CustomerReference,
    SOL.PartNo,
    CC.Description,
    ThirdPartyReference,
    SOSI.TrackingNo,
    CONCAT(CAD.Address1, ' ', CAD.Address2),
    CAD.City,
    CAD.State,
    CAD.Country,
    CAD.Zip,
    SOHA.Value,
    CS.Description,
    U.Username,
    SOH.CreateDate,
    SOH.LastActivityDate,
    CAD.Name

