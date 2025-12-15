-- FIND USER WHO CREATED LABEL FOR ASN (CustomerReference)
-- Based on ADTASNReport view logic
-- Replace 'ASN_NUMBER_HERE' with the actual ASN number
SELECT
    rh.ID AS ROHeaderID,
    rh.CustomerReference AS ASN,
    u.ID AS UserID,
    u.Username,
    crst.ID AS CarrierResultID,
    crst.TrackingNo,
    crst.CreateDate AS CarrierResultCreateDate,
    rh.CreateDate AS ASNCreateDate,
    rh.ProgramID,
    p.Name AS ProgramName
FROM
    Plus.pls.ROHeader rh
CROSS APPLY (
    SELECT TOP 1 crst1.ProgramID, crst1.TrackingNo, crst1.UserID, crst1.ID, crst1.CreateDate
    FROM Plus.pls.CarrierResult crst1 
    WHERE crst1.OrderHeaderID = rh.ID 
      AND crst1.ProgramID = rh.ProgramID 
      AND crst1.OrderType = 'RO' 
    ORDER BY crst1.ID DESC
) crst
LEFT JOIN
    Plus.pls.[User] u ON u.ID = crst.UserID
LEFT JOIN
    Plus.pls.Program p ON p.ID = rh.ProgramID
WHERE
    rh.ProgramID IN (10068, 10072)
    AND rh.CustomerReference = 'ASN_NUMBER_HERE';  -- Replace with actual ASN number

