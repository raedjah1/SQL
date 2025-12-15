-- Comprehensive query to see all Warranty Status data (IW, OOW, UKN)
-- Shows warranty status from all sources: PartNoAttribute, PartSerialAttribute
-- Converted to SELECT (no CTE) for Power BI compatibility
-- GROUPED BY PartNo

SELECT 
    warranty_detail.PartNo,
    warranty_detail.ProgramID,
    warranty_detail.Vendor,
    COUNT(DISTINCT warranty_detail.SerialNo) AS TotalSerials,
    COUNT(DISTINCT CASE WHEN warranty_detail.CategorizedStatus = 'IW' THEN warranty_detail.SerialNo END) AS IW_Count,
    COUNT(DISTINCT CASE WHEN warranty_detail.CategorizedStatus = 'UKN' THEN warranty_detail.SerialNo END) AS UKN_Count,
    COUNT(DISTINCT CASE WHEN warranty_detail.CategorizedStatus LIKE 'OOW%' THEN warranty_detail.SerialNo END) AS OOW_Count,
    MAX(warranty_detail.CategorizedStatus) AS MostCommonStatus,
    STRING_AGG(DISTINCT warranty_detail.CategorizedStatus, ', ') AS AllStatuses
FROM (
    SELECT 
        warranty.Source,
        warranty.PartNo,
        warranty.SerialNo,
        warranty.RawWarrantyStatus,
        -- Get all fallback warranty status sources (matching Receipt Report logic)
        COALESCE(warranty.RawWarrantyStatus, archive_warranty.WarrantyStatus, ro_warranty.WarrantyStatus) AS AllSourcesWarrantyStatus,
        -- Match Receipt Report logic: Clean with LTRIM/RTRIM/REPLACE, then categorize using all fallbacks
        CASE 
            WHEN COALESCE(NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(warranty.RawWarrantyStatus, archive_warranty.WarrantyStatus, ro_warranty.WarrantyStatus, ''), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''), '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'IW'
            WHEN COALESCE(NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(warranty.RawWarrantyStatus, archive_warranty.WarrantyStatus, ro_warranty.WarrantyStatus, ''), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''), '') = 'UKN' THEN 'UKN'
            WHEN disposition.DispositionValue IS NOT NULL THEN 'OOW - ' + disposition.DispositionValue
            ELSE 'OOW'
        END AS CategorizedStatus,
        -- Get Vendor (SUPPLIER_NO) from PartNoAttribute
        vendor.SupplierNo AS Vendor,
        warranty.ProgramID,
        warranty.CreateDate,
        warranty.LastActivityDate
FROM (
    -- PartNoAttribute warranty status
    SELECT 
        'PartNoAttribute' AS Source,
        pna.PartNo,
        NULL AS SerialNo,
        pna.Value AS RawWarrantyStatus,
        pna.ProgramID,
        pna.CreateDate,
        pna.LastActivityDate
    FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE ca.AttributeName = 'WARRANTY_STATUS'
      AND pna.ProgramID IN (10068, 10072)
    
    UNION ALL
    
    -- PartSerialAttribute warranty status
    SELECT 
        'PartSerialAttribute' AS Source,
        ps.PartNo,
        ps.SerialNo,
        psa.Value AS RawWarrantyStatus,
        ps.ProgramID,
        psa.CreateDate,
        psa.LastActivityDate
    FROM Plus.pls.PartSerialAttribute psa
    INNER JOIN Plus.pls.PartSerial ps ON ps.ID = psa.PartSerialID
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
    WHERE ca.AttributeName = 'WARRANTY_STATUS'
      AND ps.ProgramID IN (10068, 10072)
) warranty
OUTER APPLY (
    SELECT TOP 1 pna.Value AS SupplierNo
    FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE pna.PartNo = warranty.PartNo
      AND ca.AttributeName = 'SUPPLIER_NO'
      AND pna.ProgramID IN (10068, 10072)
    ORDER BY pna.LastActivityDate DESC
) vendor
OUTER APPLY (
    SELECT TOP 1 pna.Value AS DispositionValue
    FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE pna.PartNo = warranty.PartNo
      AND ca.AttributeName = 'DISPOSITION'
      AND pna.ProgramID IN (10068, 10072)
    ORDER BY pna.LastActivityDate DESC
) disposition
-- Fallback 1: PartSerialAttributeHistory (Archive)
OUTER APPLY (
    SELECT TOP 1 psa.Value AS WarrantyStatus
    FROM Plus.pls.PartSerialHistory psh
    INNER JOIN Plus.pls.PartSerialAttributeHistory psa ON psa.PartSerialHistoryID = psh.ID
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
    WHERE psh.PartNo = warranty.PartNo
      AND psh.SerialNo = warranty.SerialNo
      AND psh.ProgramID IN (10068, 10072)
      AND ca.AttributeName = 'WARRANTY_STATUS'
    ORDER BY psa.LastActivityDate DESC
) archive_warranty
-- Fallback 2: ROUnitAttribute (RO Unit attributes)
OUTER APPLY (
    SELECT TOP 1 rua.Value AS WarrantyStatus
    FROM Plus.pls.ROHeader rh
    INNER JOIN Plus.pls.ROLine rl ON rl.ROHeaderID = rh.ID
    INNER JOIN Plus.pls.ROUnit ru ON ru.ROLineID = rl.ID
    INNER JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = rua.AttributeID
    WHERE rh.ProgramID IN (10068, 10072)
      AND rl.PartNo = warranty.PartNo
      AND ru.SerialNo = warranty.SerialNo
      AND ca.AttributeName = 'WARRANTY_STATUS'
    ORDER BY rua.LastActivityDate DESC
) ro_warranty
) warranty_detail
GROUP BY warranty_detail.PartNo, warranty_detail.ProgramID, warranty_detail.Vendor
ORDER BY warranty_detail.PartNo;
