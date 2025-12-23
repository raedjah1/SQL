WITH Base AS (
    SELECT
        s.ID                         AS PartSerialID,
        s.ParentSerialNo,
        s.SerialNo,
        s.PartNo,
        s.CreateDate,
        s.LastActivityDate,
        s.LocationID,
        s.UserID                    AS LastUserID
    FROM Plus.pls.PartSerial AS s
    WHERE s.ParentSerialNo LIKE 'KIT-%'
),
Shipped AS (
    SELECT
        u.SerialNo,
        h.CustomerReference
    FROM Plus.pls.SOUnit AS u
    JOIN Plus.pls.SOShipmentInfo AS si ON si.ID = u.SOShipmentInfoID
    JOIN Plus.pls.SOHeader       AS h  ON h.ID  = si.SOHeaderID
),
Attrs AS (
   
    SELECT
        p.PartSerialID,
        p.UserID,
        p.Value
    FROM Plus.pls.PartSerialAttribute AS p
    JOIN Plus.pls.CodeAttribute       AS c
      ON c.ID = p.AttributeID
     AND c.AttributeName COLLATE Latin1_General_100_CI_AS = 'APPID'
),
AttrsAgg AS (
    /* De-duplicate values per PartSerial and aggregate */
    SELECT
        a.PartSerialID,
        STRING_AGG(a.Value, ';') AS Attributes
    FROM (
        SELECT DISTINCT PartSerialID, Value
        FROM Attrs
    ) AS a
    GROUP BY a.PartSerialID
)
SELECT
    ca.ParentSN,
    REPLACE(b.ParentSerialNo, 'KIT-', '')      AS ServiceTag,
    b.SerialNo,
    ca.CreatedDate,
    ca.LastActivityDate,
    ca.PN,
    ISNULL(aa.Attributes, '')                  AS Attributes,
    sh.CustomerReference                        AS GIT_Numbers,
    pl.LocationNo,
    pl.Warehouse,
    CASE 
        WHEN pl.Warehouse = 'Teardown' THEN 'TD Pending'
        WHEN pl.Warehouse = 'ServicesRepair' THEN 'TD Bad'
        WHEN pl.Warehouse = 'ServicesFinGoods' THEN 'TD Good'
        WHEN pl.Warehouse = 'InDemandGoodParts' THEN 'InDemandGood'
        WHEN pl.Warehouse = 'InDemandBadParts' THEN 'InDemandBad'
        ELSE pl.Warehouse
    END AS TD_Status,
    ISNULL(us.Username, 'No PPID Recorded')     AS RemovedUserName,
    uu.Username                                 AS LastUserName,
    ISNULL(lob_lookup.Value, 'Unknown')        AS LOB,
    ISNULL(lob_grouping.C02, 'CSG')            AS LOB_Category,
    CASE 
        WHEN ISNUMERIC(pna_cost.Value) = 1 THEN CAST(pna_cost.Value AS DECIMAL(10,2))
        ELSE 0
    END AS Standard_Cost
FROM Base AS b
CROSS APPLY (
    SELECT
        REPLACE(b.ParentSerialNo, 'KIT-', '')       AS ParentSN,
        REPLACE(b.PartNo, '-H', '')                 AS PN,
        CONVERT(date, b.CreateDate)                 AS CreatedDate,
        CONVERT(date, b.LastActivityDate)           AS LastActivityDate
) AS ca
LEFT JOIN AttrsAgg        AS aa ON aa.PartSerialID = b.PartSerialID
LEFT JOIN Attrs           AS a1 ON a1.PartSerialID = b.PartSerialID  -- for RemovedUserName (user who set APPID)
LEFT JOIN Plus.pls.PartLocation AS pl ON pl.ID     = b.LocationID
LEFT JOIN Shipped         AS sh ON sh.SerialNo     = b.SerialNo
LEFT JOIN Plus.pls.[User] AS us ON us.ID           = a1.UserID
LEFT JOIN Plus.pls.[User] AS uu ON uu.ID           = b.LastUserID
-- Get LOB from service tag's PartSerial (same pattern as Picklist) - get one LOB per service tag
OUTER APPLY (
    SELECT TOP 1 psa_lob.Value
    FROM Plus.pls.PartSerial AS ps_service
    INNER JOIN Plus.pls.PartSerialAttribute AS psa_lob ON psa_lob.PartSerialID = ps_service.ID
        AND psa_lob.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB')
    WHERE ps_service.SerialNo = REPLACE(b.ParentSerialNo, 'KIT-', '')
    ORDER BY psa_lob.CreateDate DESC, psa_lob.ID DESC
) AS lob_lookup
-- Get LOB category (CSG/ISG) from LOB_GROUPING table
LEFT JOIN Plus.pls.CodeGenericTable AS lob_grouping 
    ON lob_grouping.GenericTableDefinitionID = 228  -- LOB_GROUPING
    AND lob_grouping.C01 = ISNULL(lob_lookup.Value, 'Unknown')
-- Get Standard Cost from PartNoAttribute (use cleaned PartNo without '-H' suffix)
OUTER APPLY (
    SELECT TOP 1 pna.Value
    FROM Plus.pls.PartNoAttribute pna
    WHERE pna.PartNo = REPLACE(b.PartNo, '-H', '')
      AND pna.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'STANDARDCOST')
      AND pna.ProgramID = 10053
    ORDER BY pna.LastActivityDate DESC
) AS pna_cost
WHERE pl.Warehouse IN ('Teardown', 'ServicesRepair', 'ServicesFinGoods', 'InDemandGoodParts', 'InDemandBadParts')
GROUP BY
    ca.ParentSN,
    REPLACE(b.ParentSerialNo, 'KIT-', ''),
    b.SerialNo,
    ca.CreatedDate,
    ca.LastActivityDate,
    ca.PN,
    ISNULL(aa.Attributes, ''),
    sh.CustomerReference,
    pl.LocationNo,
    pl.Warehouse,
    CASE 
        WHEN pl.Warehouse = 'Teardown' THEN 'TD Pending'
        WHEN pl.Warehouse = 'ServicesRepair' THEN 'TD Bad'
        WHEN pl.Warehouse = 'ServicesFinGoods' THEN 'TD Good'
        WHEN pl.Warehouse = 'InDemandGoodParts' THEN 'InDemandGood'
        WHEN pl.Warehouse = 'InDemandBadParts' THEN 'InDemandBad'
        ELSE pl.Warehouse
    END,
    ISNULL(us.Username, 'No PPID Recorded'),
    uu.Username,
    ISNULL(lob_lookup.Value, 'Unknown'),
    ISNULL(lob_grouping.C02, 'CSG'),
    CASE 
        WHEN ISNUMERIC(pna_cost.Value) = 1 THEN CAST(pna_cost.Value AS DECIMAL(10,2))
        ELSE 0
    END;
