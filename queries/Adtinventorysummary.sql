CREATE OR ALTER   VIEW rpt.ADTInventorySummaryReport AS
SELECT 
    Program,
    SKU,
    Manufacturer,
    Description,
    Facility,
    Location,
    LocationGroup,
    LocationType,
    Quantity,
    Status,
    SUM(Quantity) OVER (PARTITION BY SKU) as TotalQuantity
FROM (
    SELECT 
        'FWD' as Program,
        ps.PartNo as SKU,
        COALESCE(pna.Value, 'Unknown') as Manufacturer,  
        pn.Description,
        'MEM' as Facility,
        pl.LocationNo as Location,
        clg.Description as LocationGroup,
        CASE 
            WHEN clg.Description = 'MAIN' THEN 'MAIN'
            WHEN clg.Description = 'ALT' THEN 'ALT'
            ELSE 'MAIN'
        END as LocationType,
        1 as Quantity,
        cs.Description as Status
    FROM PLUS.pls.PartSerial ps
    JOIN PLUS.pls.PartNo pn ON ps.PartNo = pn.PartNo
    INNER JOIN PLUS.pls.PartLocation pl ON ps.LocationID = pl.ID
    INNER JOIN PLUS.pls.CodeLocationGroup clg ON pl.LocationGroupID = clg.ID
    INNER JOIN PLUS.pls.CodeStatus cs ON ps.StatusID = cs.ID
    LEFT JOIN PLUS.pls.PartNoAttribute pna ON ps.PartNo = pna.PartNo 
        AND pna.AttributeID = (SELECT ID FROM PLUS.pls.CodeAttribute WHERE AttributeName = 'SUPPLIER_NO')
        AND pna.ProgramID = 10068
    WHERE ps.ProgramID = 10068
      AND pl.LocationNo LIKE 'FGI%'
      AND pl.LocationNo NOT IN ('FGI.CDR.CSR.0.0', 'FGI.STAGE.CDR.CSR.0')
      AND cs.Description = 'ACTIVE'

    UNION ALL

    SELECT 
        'FWD' as Program,
        pq.PartNo as SKU,
        COALESCE(pna.Value, 'Unknown') as Manufacturer,
        pn.Description,
        'MEM' as Facility,
        pl.LocationNo as Location,
        clg.Description as LocationGroup,
        CASE 
            WHEN clg.Description = 'MAIN' THEN 'MAIN'
            WHEN clg.Description = 'ALT' THEN 'ALT'
            ELSE 'MAIN'
        END as LocationType,
        pq.AvailableQty as Quantity,
        cs.Description as Status
    FROM PLUS.pls.PartQty pq
    JOIN PLUS.pls.PartNo pn ON pq.PartNo = pn.PartNo
    INNER JOIN PLUS.pls.PartLocation pl ON pq.LocationID = pl.ID
    INNER JOIN PLUS.pls.CodeLocationGroup clg ON pl.LocationGroupID = clg.ID
    INNER JOIN PLUS.pls.CodeStatus cs ON pl.StatusID = cs.ID
    LEFT JOIN PLUS.pls.PartNoAttribute pna ON pq.PartNo = pna.PartNo 
        AND pna.AttributeID = (SELECT ID FROM PLUS.pls.CodeAttribute WHERE AttributeName = 'SUPPLIER_NO')
        AND pna.ProgramID = 10068
    WHERE pq.ProgramID = 10068
      AND pl.LocationNo LIKE 'FGI%'
      AND pl.LocationNo NOT IN ('FGI.CDR.CSR.0.0', 'FGI.STAGE.CDR.CSR.0')
      AND pq.AvailableQty > 0
) InventoryData