-- Query to link PartSerialAttribute to CodeAttribute
-- Shows attribute names along with serial-level attribute values

SELECT TOP (1000) 
    psa.[ID]
    ,psa.[PartSerialID]
    ,psa.[AttributeID]
    ,ca.[AttributeName]
    ,psa.[Value]
    ,psa.[UserID]
    ,psa.[CreateDate]
    ,psa.[LastActivityDate]
FROM [pls].[PartSerialAttribute] psa
INNER JOIN [pls].[CodeAttribute] ca 
    ON psa.[AttributeID] = ca.[ID]
ORDER BY psa.[CreateDate] DESC;



















