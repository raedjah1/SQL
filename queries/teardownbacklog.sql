-- Teardown ARB ARC Query - OPTIMIZED VERSION  
-- Shows ARC serials currently in Teardown.ARB.0.0.0
-- Uses PARENT SERIAL for LOB lookup (not current serial)

SELECT 
    CASE 
        WHEN c.SerialNo IS NOT NULL THEN 'IN Process' 
        ELSE 'Backlog' 
    END AS Status,
    pl.LocationNo,
    ps.SerialNo,
    cleaned_part.CleanPartNo AS PartNo,
    cleaned_part.CleanParentSN AS ParentSN,
    ps.PalletBoxNo,
    CONVERT(DATE, ps.CreateDate) AS CreatedDate,
    CONVERT(DATE, ps.LastActivityDate) AS LastActivityDate,
    pl.Warehouse,
    pl.Bin,
    pl.Bay,
    cpt_type.Description AS ProductType,
    ISNULL(psa_lob.Value, 'Unknown') AS LOB,
    ISNULL(lob_grouping.C02, 'CSG') AS LOB_Category
FROM Plus.pls.PartSerial ps
INNER JOIN Plus.pls.PartLocation pl ON pl.ID = ps.LocationID
    AND UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'TEARDOWN'
    AND pl.LocationNo = 'Teardown.ARB.0.0.0'
-- Pre-calculate cleaned strings to avoid repeated REPLACE operations
CROSS APPLY (
    SELECT 
        REPLACE(ps.PartNo, '-H', '') AS CleanPartNo,
        REPLACE(COALESCE(ps.ParentSerialNo, ''), 'KIT-', '') AS CleanParentSN
) cleaned_part
-- Check if child part exists (indicates IN Process)
LEFT JOIN Plus.pls.PartSerial c ON c.ParentSerialNo = 'KIT-' + ps.SerialNo
    AND c.ProgramID = ps.ProgramID
-- Product Type
LEFT JOIN Plus.pls.PartNo pn ON pn.PartNo = cleaned_part.CleanPartNo
LEFT JOIN Plus.pls.CodePartType cpt_type ON cpt_type.ID = pn.PartTypeID
-- LOB from PARENT Serial (optimized lookup)
LEFT JOIN Plus.pls.PartSerial ps_parent ON ps_parent.SerialNo = cleaned_part.CleanParentSN
LEFT JOIN Plus.pls.PartSerialAttribute psa_lob ON psa_lob.PartSerialID = ps_parent.ID
    AND psa_lob.AttributeID = 1345  -- TrckObjAttLOB AttributeID
LEFT JOIN Plus.pls.CodeGenericTable AS lob_grouping 
    ON lob_grouping.GenericTableDefinitionID = 228
    AND lob_grouping.C01 = ISNULL(psa_lob.Value, 'Unknown')
WHERE ps.ProgramID = 10053
    AND ps.SerialNo LIKE 'ARC%'  -- ONLY ARC serials