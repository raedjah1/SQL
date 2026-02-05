-- Simple query: Everything in RPLPTS warehouse with cost
SELECT 
    pq.PartNo,
    pq.AvailableQty,
    pl.LocationNo,
    pl.Warehouse,
    cc.Description AS Configuration,
    pq.PalletBoxNo,
    pq.LotNo,
    CASE 
        WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
        ELSE 0
    END AS Cost,
    pq.AvailableQty * CASE 
        WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
        ELSE 0
    END AS TotalCost
FROM Plus.pls.PartQty pq
INNER JOIN Plus.pls.PartLocation pl ON pl.ID = pq.LocationID
LEFT JOIN Plus.pls.CodeConfiguration cc ON cc.ID = pq.ConfigurationID
LEFT JOIN Plus.pls.PartNoAttribute pna ON pna.PartNo = pq.PartNo 
    AND pna.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'Cost')
    AND pna.ProgramID = 10068
WHERE pq.ProgramID = 10068
  AND pl.Warehouse = 'RPLPTS'
ORDER BY pq.PartNo, pl.LocationNo;








