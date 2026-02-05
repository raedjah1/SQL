SELECT
    ps.SerialNo,
    ps.PartNo,
    REPLACE(ps.PartNo, '-H', '') AS CleanedPartNo,
    REPLACE(COALESCE(ps.ParentSerialNo, ''), 'KIT-', '') AS ParentSN,
    ps.CreateDate,
    ps.LastActivityDate,
    pl.LocationNo,
    pl.Warehouse,
    pl.Bin,
    pl.Bay,
    cpt_type.Description AS ProductType,
    ISNULL(lob_lookup.Value, 'Unknown') AS LOB,
    ISNULL(lob_grouping.C02, 'CSG') AS LOB_Category,
    -- Check if this part has a corresponding transaction TO teardown
    CASE WHEN latest_tx.SerialNo IS NOT NULL THEN 'Has Transaction' ELSE 'No Transaction' END AS HasTeardownTransaction
FROM Plus.pls.PartSerial ps
INNER JOIN Plus.pls.PartLocation pl ON pl.ID = ps.LocationID
    AND UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'TEARDOWN'
LEFT JOIN Plus.pls.PartNo pn ON pn.PartNo = REPLACE(ps.PartNo, '-H', '')
LEFT JOIN Plus.pls.CodePartType cpt_type ON cpt_type.ID = pn.PartTypeID
-- LOB from Parent Serial
OUTER APPLY (
    SELECT TOP 1 psa_lob.Value
    FROM Plus.pls.PartSerial AS ps_service
    INNER JOIN Plus.pls.PartSerialAttribute AS psa_lob ON psa_lob.PartSerialID = ps_service.ID
        AND psa_lob.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB')
    WHERE ps_service.SerialNo = REPLACE(COALESCE(ps.ParentSerialNo, ''), 'KIT-', '')
    ORDER BY psa_lob.CreateDate DESC, psa_lob.ID DESC
) AS lob_lookup
LEFT JOIN Plus.pls.CodeGenericTable AS lob_grouping 
    ON lob_grouping.GenericTableDefinitionID = 228
    AND lob_grouping.C01 = ISNULL(lob_lookup.Value, 'Unknown')
-- Check for latest transaction TO teardown
LEFT JOIN (
    SELECT DISTINCT pt.SerialNo
    FROM Plus.pls.PartTransaction pt
    INNER JOIN Plus.pls.PartLocation pl_to ON pl_to.LocationNo = pt.ToLocation
        AND pl_to.ProgramID = pt.ProgramID
        AND UPPER(LTRIM(RTRIM(pl_to.Warehouse))) = 'TEARDOWN'
    WHERE pt.ProgramID = 10053
        AND NOT EXISTS (
            SELECT 1 
            FROM Plus.pls.PartTransaction pt2
            INNER JOIN Plus.pls.PartLocation pl_from2 ON pl_from2.LocationNo = pt2.Location
                AND pl_from2.ProgramID = pt2.ProgramID
                AND UPPER(LTRIM(RTRIM(pl_from2.Warehouse))) = 'TEARDOWN'
            WHERE pt2.SerialNo = pt.SerialNo
                AND pt2.CreateDate > pt.CreateDate
                AND pt2.ProgramID = 10053
        )
) AS latest_tx ON latest_tx.SerialNo = ps.SerialNo
WHERE ps.ProgramID = 10053
    AND UPPER(pl.LocationNo) != 'TEARDOWN.ARB.0.0.0'
ORDER BY ps.LastActivityDate DESC;