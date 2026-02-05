SELECT
    pt.SerialNo,
    cleaned_part.CleanPartNo AS PartNo,
    pt.CreateDate AS TransactionDate,
    pt.Location AS FromLocation,
    pt.ToLocation,
    pl_from.Warehouse AS FromWarehouse,
    pl_to.Warehouse AS ToWarehouse,
    -- Essential additional fields
    cleaned_part.CleanParentSN AS ParentSN,
    ISNULL(psa_family.Value, 'Unknown') AS Family,
    cpt_type_parent.Description AS ProductType,
    ISNULL(psa_lob.Value, 'Unknown') AS LOB,
    ISNULL(lob_grouping.C02, 'CSG') AS LOB_Category,
    CASE 
        WHEN ISNULL(psa_lob.Value, 'Unknown') IN ('POWER', 'PVAULT') THEN 'ISG'
        ELSE 'CSG'
    END AS CSG_ISG,
    -- Additional fields from original query
    pt.Qty,
    dwr.MachineName
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.PartLocation pl_to ON pl_to.LocationNo = pt.ToLocation
    AND pl_to.ProgramID = pt.ProgramID
LEFT JOIN Plus.pls.PartLocation pl_from ON pl_from.LocationNo = pt.Location
    AND pl_from.ProgramID = pt.ProgramID
LEFT JOIN Plus.pls.PartSerial ps ON ps.SerialNo = pt.SerialNo AND ps.ProgramID = pt.ProgramID
-- Pre-calculate cleaned strings to avoid repeated REPLACE operations
CROSS APPLY (
    SELECT 
        REPLACE(pt.PartNo, '-H', '') AS CleanPartNo,
        REPLACE(COALESCE(pt.ParentSerialNo, ps.ParentSerialNo, ''), 'KIT-', '') AS CleanParentSN
) cleaned_part
-- Family from CURRENT Serial (optimized lookup - gets latest value)
OUTER APPLY (
    SELECT TOP 1 psa_family.Value
    FROM Plus.pls.PartSerialAttribute psa_family
    WHERE psa_family.PartSerialID = ps.ID
        AND psa_family.AttributeID = 1343  -- TrckObjAttFamily AttributeID
    ORDER BY psa_family.CreateDate DESC, psa_family.ID DESC
) psa_family
-- Product Type from CURRENT Serial's PartNo
LEFT JOIN Plus.pls.PartNo pn ON pn.PartNo = cleaned_part.CleanPartNo
LEFT JOIN Plus.pls.CodePartType cpt_type_parent ON cpt_type_parent.ID = pn.PartTypeID
-- LOB from CURRENT Serial (optimized lookup - gets latest value)
OUTER APPLY (
    SELECT TOP 1 psa_lob.Value
    FROM Plus.pls.PartSerialAttribute psa_lob
    WHERE psa_lob.PartSerialID = ps.ID
        AND psa_lob.AttributeID = 1345  -- TrckObjAttLOB AttributeID
    ORDER BY psa_lob.CreateDate DESC, psa_lob.ID DESC
) psa_lob
LEFT JOIN Plus.pls.CodeGenericTable AS lob_grouping 
    ON lob_grouping.GenericTableDefinitionID = 228
    AND lob_grouping.C01 = ISNULL(psa_lob.Value, 'Unknown')
-- DataWipeResult lookup
LEFT JOIN (
    SELECT 
        dwr.SerialNumber,
        dwr.MachineName,
        dwr.ID
    FROM [redw].[tia].[DataWipeResult] dwr
    WHERE dwr.TestArea = 'MEMPHIS'
        AND dwr.ID = (
            SELECT MAX(ID)
            FROM [redw].[tia].[DataWipeResult]
            WHERE TestArea = 'MEMPHIS'
                AND SerialNumber = dwr.SerialNumber
        )
) dwr ON dwr.SerialNumber = pt.SerialNo
WHERE UPPER(pt.ToLocation) LIKE '%TORNDOWN%'
    AND pt.ProgramID = 10053
ORDER BY pt.CreateDate DESC;