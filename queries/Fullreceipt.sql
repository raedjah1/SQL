SELECT 
    ps.PartNo, 
    ps.SerialNo, 
    pl.LocationNo,
    MAX(CASE WHEN ca.AttributeName = 'TrckObjAttFamily' THEN psa.Value END) AS TrckObjAttFamily,
    MAX(CASE WHEN ca.AttributeName = 'TrckObjAttLOB' THEN psa.Value END) AS TrckObjAttLOB,
    MAX(CASE WHEN ca.AttributeName = 'ConditionCode' THEN psa.Value END) AS ConditionCode,
    ps.CreateDate,
    ps.LastActivityDate,
    CASE 
        WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
        ELSE 0
    END AS Standard_Cost,
    ps.PalletBoxNo
FROM pls.PartSerial ps
LEFT JOIN pls.PartLocation pl ON pl.ID = ps.LocationID
LEFT JOIN pls.PartSerialAttribute psa ON ps.ID = psa.PartSerialID 
LEFT JOIN pls.CodeAttribute ca ON ca.ID = psa.AttributeID
LEFT JOIN pls.PartNoAttribute pna ON ps.PartNo = pna.PartNo 
    AND pna.AttributeID = (SELECT ID FROM pls.CodeAttribute WHERE AttributeName = 'STANDARDCOST')
    AND pna.ProgramID = 10053
WHERE ps.ProgramID = 10053
    AND ps.SerialNo NOT LIKE 'rxt%'
GROUP BY 
    ps.PartNo, 
    ps.SerialNo, 
    pl.LocationNo, 
    ps.CreateDate,
    ps.LastActivityDate,
    pna.Value,
    ps.PalletBoxNo

