SELECT 
    ps.*,
    CASE 
        WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'TEARDOWN' THEN ' Teardown BackLog'
        WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'TAGTORNDOWN' THEN 'Torn Down'
        ELSE UPPER(LTRIM(RTRIM(pl.Warehouse)))
    END AS Warehouse,
    pl.LocationNo AS PartLocationNo,
    ISNULL(lob_lookup.Value, 'Unknown') AS LOB,
    ISNULL(lob_grouping.C02, 'CSG') AS LOB_Category
FROM Plus.pls.PartSerial ps
    INNER JOIN Plus.pls.PartLocation pl ON pl.ID = ps.LocationID
    -- Get LOB from PartSerialAttribute
OUTER APPLY (
        SELECT TOP 1 psa_lob.Value
        FROM Plus.pls.PartSerialAttribute AS psa_lob
        WHERE psa_lob.PartSerialID = ps.ID
            AND psa_lob.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB')
    ) AS lob_lookup
    -- Get LOB category (CSG/ISG) from LOB_GROUPING table
    LEFT JOIN Plus.pls.CodeGenericTable AS lob_grouping 
        ON lob_grouping.GenericTableDefinitionID = 228  -- LOB_GROUPING
        AND lob_grouping.C01 = ISNULL(lob_lookup.Value, 'Unknown')
WHERE ps.ProgramID = 10053
    AND (UPPER(pl.Warehouse) = 'TEARDOWN' OR UPPER(pl.Warehouse) = 'TAGTORNDOWN')
    AND UPPER(pl.LocationNo) != 'TEARDOWN.ARB.0.0.0'
