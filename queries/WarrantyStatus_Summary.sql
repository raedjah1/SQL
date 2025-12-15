-- Summary of all Warranty Status values and their categorization
-- Shows counts and unique values

WITH WarrantyData AS (
    -- PartNoAttribute warranty status
    SELECT 
        pna.Value AS RawWarrantyStatus,
        UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(pna.Value, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))) AS CleanedWarrantyStatus,
        pna.PartNo,
        NULL AS SerialNo,
        'PartNoAttribute' AS Source
    FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE ca.AttributeName = 'WARRANTY_STATUS'
      AND pna.ProgramID IN (10068, 10072)
    
    UNION ALL
    
    -- PartSerialAttribute warranty status
    SELECT 
        psa.Value AS RawWarrantyStatus,
        UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(psa.Value, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))) AS CleanedWarrantyStatus,
        ps.PartNo,
        ps.SerialNo,
        'PartSerialAttribute' AS Source
    FROM Plus.pls.PartSerialAttribute psa
    INNER JOIN Plus.pls.PartSerial ps ON ps.ID = psa.PartSerialID
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
    WHERE ca.AttributeName = 'WARRANTY_STATUS'
      AND ps.ProgramID IN (10068, 10072)
)
SELECT 
    RawWarrantyStatus,
    CleanedWarrantyStatus,
    CASE 
        WHEN CleanedWarrantyStatus IN ('IN WARRANTY', 'IW', 'IN_WARRANTY') THEN 'IW'
        WHEN CleanedWarrantyStatus = 'UKN' THEN 'UKN'
        ELSE 'OOW'
    END AS CategorizedStatus,
    Source,
    COUNT(*) AS RecordCount,
    COUNT(DISTINCT PartNo) AS UniqueParts,
    COUNT(DISTINCT SerialNo) AS UniqueSerials
FROM WarrantyData
GROUP BY RawWarrantyStatus, CleanedWarrantyStatus, Source,
    CASE 
        WHEN CleanedWarrantyStatus IN ('IN WARRANTY', 'IW', 'IN_WARRANTY') THEN 'IW'
        WHEN CleanedWarrantyStatus = 'UKN' THEN 'UKN'
        ELSE 'OOW'
    END
ORDER BY CategorizedStatus, Source, RecordCount DESC;



