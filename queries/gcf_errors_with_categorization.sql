-- ============================================================================
-- GCF ERRORS WITH FAIL CATEGORIZATION
-- ============================================================================
-- Categorizes GCF errors into the same categories as Power BI report:
-- - Root Element Missing
-- - OPP
-- - Invalid Service Tag
-- - DPK Quantity
-- - Missing Processor/Too Many Processors
-- - DPK Status
-- - API/Time Out
-- - DPK Deviation
-- - CCN
-- - Linux OS
-- - Unsupported Parts
-- - Other
-- ============================================================================

-- GCF Errors Query with Fail Category
SELECT 
    Test_Date,
    Work_Order,
    GCF_Version,
    Processed,
    Error_Description,
    Error_Code,
    Additional_Notes,
    Error_Timestamp,
    Outmessage_Hdr_Id,
    -- ✅ FAIL CATEGORY (matches Power BI report)
    CASE 
        -- Root Element Missing (highest priority - exact match)
        WHEN obm.Message = 'Root element is missing.' THEN 'Root Element Missing'
        
        -- CCN (exact pattern match)
        WHEN obm.Message LIKE '%List of possible elements expected: ''CCN''%' 
             OR obm.Message LIKE '%invalid child element ''NON-REPLACEMENT''%' THEN 'CCN'
        
        -- Invalid Service Tag (exact pattern match)
        WHEN obm.Message LIKE '%Service tag is invalid%' 
             OR obm.Message LIKE '%Service tag%invalid%' THEN 'Invalid Service Tag'
        
        -- DPK Status (exact pattern match)
        WHEN obm.Message LIKE '%DPK Status attribute not configured%' THEN 'DPK Status'
        
        -- API/Time Out (HTTP errors, timeouts, unauthorized)
        WHEN obm.Message LIKE '%HTTP status%' 
             OR obm.Message LIKE '%Unauthorized%'
             OR obm.Message LIKE '%timeout%'
             OR obm.Message LIKE '%Time Out%'
             OR obm.Message LIKE '%401%'
             OR obm.Message LIKE '%403%'
             OR obm.Message LIKE '%500%' THEN 'API/Time Out'
        
        -- DPK Quantity (look for quantity-related DPK errors)
        WHEN obm.Message LIKE '%DPK%Quantity%'
             OR obm.Message LIKE '%DPK%quantity%'
             OR obm.Message LIKE '%quantity%DPK%' THEN 'DPK Quantity'
        
        -- DPK Deviation (look for deviation-related DPK errors)
        WHEN obm.Message LIKE '%DPK%Deviation%'
             OR obm.Message LIKE '%DPK%deviation%'
             OR obm.Message LIKE '%deviation%DPK%' THEN 'DPK Deviation'
        
        -- Missing Processor/Too Many Processors
        WHEN obm.Message LIKE '%Processor%'
             OR obm.Message LIKE '%processor%'
             OR obm.Message LIKE '%Missing Processor%'
             OR obm.Message LIKE '%Too Many Processors%' THEN 'Missing Processor/Too Many Processors'
        
        -- Linux OS
        WHEN obm.Message LIKE '%Linux%'
             OR obm.Message LIKE '%linux%' THEN 'Linux OS'
        
        -- Unsupported Parts
        WHEN obm.Message LIKE '%Unsupported%'
             OR obm.Message LIKE '%unsupported%'
             OR obm.Message LIKE '%not supported%' THEN 'Unsupported Parts'
        
        -- OPP (need to identify pattern - checking Error_Code or specific message)
        WHEN obm.C01 = 'OPP' 
             OR obm.Message LIKE '%OPP%' THEN 'OPP'
        
        -- Other (catch-all)
        ELSE 'Other'
    END AS Fail_Category
FROM (
    SELECT 
        CAST(obm.Insert_Date AS DATE) AS Test_Date,
        obm.Customer_order_No AS Work_Order,
        obm.Message_Type AS GCF_Version,
        obm.Processed,
        obm.Message AS Error_Description,
        obm.C01 AS Error_Code,
        obm.C20 AS Additional_Notes,
        obm.Insert_Date AS Error_Timestamp,
        obm.Outmessage_Hdr_Id,
        obm.Message,  -- Keep original for CASE statement
        obm.C01,       -- Keep original for CASE statement
        ROW_NUMBER() OVER (
            PARTITION BY obm.Customer_order_No, CAST(obm.Insert_Date AS DATE) 
            ORDER BY obm.Insert_Date DESC
        ) AS rn
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Processed = 'F'
) AS RankedGCF
WHERE rn = 1
ORDER BY Test_Date DESC, Error_Timestamp DESC;


-- ============================================================================
-- SUMMARY BY CATEGORY (for Power BI matrix)
-- ============================================================================

SELECT 
    Test_Date,
    Fail_Category,
    COUNT(*) AS Error_Count,
    COUNT(DISTINCT Work_Order) AS Unique_Work_Orders,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Test_Date) AS DECIMAL(5,2)) AS Percent_Of_Total
FROM (
    SELECT 
        CAST(obm.Insert_Date AS DATE) AS Test_Date,
        obm.Customer_order_No AS Work_Order,
        CASE 
            WHEN obm.Message = 'Root element is missing.' THEN 'Root Element Missing'
            WHEN obm.Message LIKE '%List of possible elements expected: ''CCN''%' 
                 OR obm.Message LIKE '%invalid child element ''NON-REPLACEMENT''%' THEN 'CCN'
            WHEN obm.Message LIKE '%Service tag is invalid%' 
                 OR obm.Message LIKE '%Service tag%invalid%' THEN 'Invalid Service Tag'
            WHEN obm.Message LIKE '%DPK Status attribute not configured%' THEN 'DPK Status'
            WHEN obm.Message LIKE '%HTTP status%' 
                 OR obm.Message LIKE '%Unauthorized%'
                 OR obm.Message LIKE '%timeout%'
                 OR obm.Message LIKE '%Time Out%'
                 OR obm.Message LIKE '%401%'
                 OR obm.Message LIKE '%403%'
                 OR obm.Message LIKE '%500%' THEN 'API/Time Out'
            WHEN obm.Message LIKE '%DPK%Quantity%'
                 OR obm.Message LIKE '%DPK%quantity%'
                 OR obm.Message LIKE '%quantity%DPK%' THEN 'DPK Quantity'
            WHEN obm.Message LIKE '%DPK%Deviation%'
                 OR obm.Message LIKE '%DPK%deviation%'
                 OR obm.Message LIKE '%deviation%DPK%' THEN 'DPK Deviation'
            WHEN obm.Message LIKE '%Processor%'
                 OR obm.Message LIKE '%processor%'
                 OR obm.Message LIKE '%Missing Processor%'
                 OR obm.Message LIKE '%Too Many Processors%' THEN 'Missing Processor/Too Many Processors'
            WHEN obm.Message LIKE '%Linux%'
                 OR obm.Message LIKE '%linux%' THEN 'Linux OS'
            WHEN obm.Message LIKE '%Unsupported%'
                 OR obm.Message LIKE '%unsupported%'
                 OR obm.Message LIKE '%not supported%' THEN 'Unsupported Parts'
            WHEN obm.C01 = 'OPP' 
                 OR obm.Message LIKE '%OPP%' THEN 'OPP'
            ELSE 'Other'
        END AS Fail_Category,
        ROW_NUMBER() OVER (
            PARTITION BY obm.Customer_order_No, CAST(obm.Insert_Date AS DATE) 
            ORDER BY obm.Insert_Date DESC
        ) AS rn
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Processed = 'F'
) AS RankedGCF
WHERE rn = 1
GROUP BY Test_Date, Fail_Category
ORDER BY Test_Date DESC, Error_Count DESC;

