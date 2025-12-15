
CREATE OR ALTER VIEW rpt.ADTCategories AS
SELECT 
    CASE 
        -- Handle piped categories: If FirstCategory is 'Other' or 'Communications', use SecondCategory
        WHEN (CASE 
                WHEN pna_cat.Value LIKE '%|%' THEN 
                    LEFT(pna_cat.Value, CHARINDEX('|', pna_cat.Value) - 1)
                ELSE pna_cat.Value
            END) IN ('Other', 'Communications') THEN
            (CASE 
                WHEN pna_cat.Value LIKE '%|%' AND CHARINDEX('|', pna_cat.Value, CHARINDEX('|', pna_cat.Value) + 1) > 0 THEN
                    SUBSTRING(
                        pna_cat.Value, 
                        CHARINDEX('|', pna_cat.Value) + 1,
                        CHARINDEX('|', pna_cat.Value, CHARINDEX('|', pna_cat.Value) + 1) - CHARINDEX('|', pna_cat.Value) - 1
                    )
                WHEN pna_cat.Value LIKE '%|%' THEN
                    SUBSTRING(pna_cat.Value, CHARINDEX('|', pna_cat.Value) + 1, LEN(pna_cat.Value))
                ELSE NULL
            END)
        -- Use FirstCategory (or 'Other' if no pipes)
        ELSE 
            (CASE 
                WHEN pna_cat.Value LIKE '%|%' THEN 
                    LEFT(pna_cat.Value, CHARINDEX('|', pna_cat.Value) - 1)
                ELSE 'Other'
            END)
    END AS Category,
    COUNT(*) AS PartsReceived,
    COUNT(DISTINCT rh.CustomerReference) AS ASNCount,
    -- Additional details for Power BI
    pt.PartNo,
    pna_cat.Value AS FullPartCategory,
    rh.CustomerReference,
    pt.CreateDate AS ReceivedDate
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
INNER JOIN Plus.pls.ROHeader rh ON rh.ID = pt.OrderHeaderID
OUTER APPLY (
    SELECT TOP 1 pna.Value
    FROM Plus.pls.PartNoAttribute pna
    INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
    WHERE pna.PartNo = pt.PartNo 
      AND pna.ProgramID = pt.ProgramID
      AND ca.AttributeName = 'PartCategory'
    ORDER BY pna.LastActivityDate DESC  -- Get most recent category
) pna_cat
WHERE pt.ProgramID = 10068
  AND pt.PartTransactionID = 1  -- RO-RECEIVE
  AND cpt.Description = 'RO-RECEIVE'
  AND rh.CustomerReference LIKE 'FSR%'
GROUP BY 
    CASE 
        WHEN (CASE 
                WHEN pna_cat.Value LIKE '%|%' THEN 
                    LEFT(pna_cat.Value, CHARINDEX('|', pna_cat.Value) - 1)
                ELSE pna_cat.Value
            END) IN ('Other', 'Communications') THEN
            (CASE 
                WHEN pna_cat.Value LIKE '%|%' AND CHARINDEX('|', pna_cat.Value, CHARINDEX('|', pna_cat.Value) + 1) > 0 THEN
                    SUBSTRING(
                        pna_cat.Value, 
                        CHARINDEX('|', pna_cat.Value) + 1,
                        CHARINDEX('|', pna_cat.Value, CHARINDEX('|', pna_cat.Value) + 1) - CHARINDEX('|', pna_cat.Value) - 1
                    )
                WHEN pna_cat.Value LIKE '%|%' THEN
                    SUBSTRING(pna_cat.Value, CHARINDEX('|', pna_cat.Value) + 1, LEN(pna_cat.Value))
                ELSE NULL
            END)
        ELSE 
            (CASE 
                WHEN pna_cat.Value LIKE '%|%' THEN 
                    LEFT(pna_cat.Value, CHARINDEX('|', pna_cat.Value) - 1)
                ELSE 'Other'
            END)
    END,
    pt.PartNo,
    pna_cat.Value,
    rh.CustomerReference,
    pt.CreateDate
ORDER BY PartsReceived DESC;


