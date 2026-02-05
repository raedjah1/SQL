SELECT
    pt.SerialNo,
    REPLACE(pt.PartNo, '-H', '') AS PartNo,
    pt.CreateDate AS TransactionDate,
    -- DateOnly column for centralized relationship slicer
    CAST(COALESCE(pt.CreateDate, (SELECT MIN(CreateDate) FROM Plus.pls.PartTransaction WHERE ProgramID = 10053)) AS DATE) AS DateOnly,
    pt.Location AS FromLocation,
    pt.ToLocation,
    pl_from.Warehouse AS FromWarehouse,
    pl_to.Warehouse AS ToWarehouse,
    -- Essential additional fields
    REPLACE(COALESCE(pt.ParentSerialNo, ps.ParentSerialNo, ''), 'KIT-', '') AS ParentSN,
    ISNULL(family_lookup.Value, 'Unknown') AS Family,
    cpt_type.Description AS ProductType,
    ISNULL(lob_lookup.Value, 'Unknown') AS LOB,
    ISNULL(lob_grouping.C02, 'CSG') AS LOB_Category,
    -- Part Cost and Category from TEARDOWN_DEMANDLIST
    ISNULL(demandlist.C08, 0) AS PartCost,
    ISNULL(demandlist.C07, 'Unknown') AS PartCategory,
    -- GIT Number and Tracking (optimized single lookup)
    git_lookup.GIT_Number,
    git_lookup.TrackingNo,
    -- Shipment Status and Date
    git_lookup.ShipmentStatus,
    git_lookup.ShipmentDate
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.PartLocation pl_to ON pl_to.LocationNo = pt.ToLocation
    AND pl_to.ProgramID = pt.ProgramID
    AND UPPER(LTRIM(RTRIM(pl_to.Warehouse))) = 'INDEMANDBADPARTS'
LEFT JOIN Plus.pls.PartLocation pl_from ON pl_from.LocationNo = pt.Location
    AND pl_from.ProgramID = pt.ProgramID
LEFT JOIN Plus.pls.PartSerial ps ON ps.SerialNo = pt.SerialNo AND ps.ProgramID = pt.ProgramID
LEFT JOIN Plus.pls.PartNo pn ON pn.PartNo = REPLACE(pt.PartNo, '-H', '')
LEFT JOIN Plus.pls.CodePartType cpt_type ON cpt_type.ID = pn.PartTypeID
-- Pre-calculate cleaned parent serial once
CROSS APPLY (
    SELECT REPLACE(COALESCE(pt.ParentSerialNo, ps.ParentSerialNo, ''), 'KIT-', '') AS CleanParentSN
) cleaned_parent
-- Join to parent serial once
LEFT JOIN Plus.pls.PartSerial ps_parent ON ps_parent.SerialNo = cleaned_parent.CleanParentSN
-- Family from Parent Serial (optimized - single lookup)
OUTER APPLY (
    SELECT TOP 1 psa_family.Value
    FROM Plus.pls.PartSerialAttribute psa_family
    WHERE psa_family.PartSerialID = ps_parent.ID
        AND psa_family.AttributeID = 1343  -- TrckObjAttFamily AttributeID
    ORDER BY psa_family.CreateDate DESC, psa_family.ID DESC
) AS family_lookup
-- LOB from Parent Serial (optimized - single lookup)
OUTER APPLY (
    SELECT TOP 1 psa_lob.Value
    FROM Plus.pls.PartSerialAttribute psa_lob
    WHERE psa_lob.PartSerialID = ps_parent.ID
        AND psa_lob.AttributeID = 1345  -- TrckObjAttLOB AttributeID
    ORDER BY psa_lob.CreateDate DESC, psa_lob.ID DESC
) AS lob_lookup
LEFT JOIN Plus.pls.CodeGenericTable AS lob_grouping 
    ON lob_grouping.GenericTableDefinitionID = 228
    AND lob_grouping.C01 = ISNULL(lob_lookup.Value, 'Unknown')
-- Part Cost and Category from TEARDOWN_DEMANDLIST (get latest by PartNo)
OUTER APPLY (
    SELECT TOP 1 
        cgt.C07 AS C07,
        CASE 
            WHEN ISNUMERIC(cgt.C08) = 1 THEN CAST(cgt.C08 AS DECIMAL(10,2))
            ELSE 0
        END AS C08
    FROM Plus.pls.CodeGenericTable cgt
    WHERE cgt.GenericTableDefinitionID = 258  -- TEARDOWN_DEMANDLIST
        AND cgt.C01 = REPLACE(pt.PartNo, '-H', '')
    ORDER BY cgt.LastActivityDate DESC, cgt.ID DESC
) demandlist
-- GIT Number, Tracking, Shipment Status and Date (optimized - filter SOHeader FIRST, then join)
OUTER APPLY (
    SELECT TOP 1
        sh.CustomerReference AS GIT_Number,
        sos.TrackingNo,
        CASE 
            WHEN sh.StatusID = 18 THEN 'SHIPPED'
            ELSE 'NEW'
        END AS ShipmentStatus,
        sos.ShipmentDate
    FROM Plus.pls.SOHeader sh
    INNER JOIN Plus.pls.SOShipmentInfo sos ON sos.SOHeaderID = sh.ID
    INNER JOIN Plus.pls.SOUnit su ON su.SOShipmentInfoID = sos.ID
    WHERE sh.ProgramID = 10053
        AND sh.CustomerReference LIKE 'GIT%'
        AND su.SerialNo = pt.SerialNo
    ORDER BY sos.ShipmentDate DESC, sos.ID DESC
) git_lookup
WHERE pt.ProgramID = 10053
    AND pt.ToLocation IS NOT NULL