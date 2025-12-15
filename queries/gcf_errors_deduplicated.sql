-- ============================================================================
-- GCF ERROR ANALYSIS - DEDUPLICATED
-- ============================================================================
-- Definition: GCF (Good Case Fail) errors from Biztalk with deduplication
-- Deduplication: Keeps only the LATEST timestamp per work order per date
-- Use Case: Identifying pre-test inspection failures without double-counting
-- 
-- Notes:
-- - Processed = 'F' means GCF FAIL (pre-test failure)
-- - Processed = 'T' means GCF PASS (not included here)
-- - Duplicate work orders on same date are reduced to one (latest timestamp)
-- ============================================================================

-- GCF Errors for 10/29/2025 - DEDUPLICATED (Latest timestamp only per work order)
WITH RankedGCF AS (
    SELECT 
        CAST(obm.Insert_Date AS DATE) AS GCF_Date,
        obm.Customer_order_No AS Work_Order,
        obm.Message_Type AS GCF_Version,
        obm.Processed,
        obm.Message AS Error_Description,
        obm.C01 AS Error_Code,
        obm.C20 AS Additional_Notes,
        obm.Insert_Date AS Error_Timestamp,
        obm.Outmessage_Hdr_Id,
        ROW_NUMBER() OVER (
            PARTITION BY obm.Customer_order_No, CAST(obm.Insert_Date AS DATE) 
            ORDER BY obm.Insert_Date DESC
        ) AS rn
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Processed = 'F'  -- FAIL only
      AND CAST(obm.Insert_Date AS DATE) = '2025-10-29'
)
SELECT 
    GCF_Date,
    Work_Order,
    GCF_Version,
    Processed,
    Error_Description,
    Error_Code,
    Additional_Notes,
    Error_Timestamp,
    Outmessage_Hdr_Id
FROM RankedGCF
WHERE rn = 1  -- Keep only the latest timestamp per work order
ORDER BY Error_Timestamp DESC;


-- ============================================================================
-- SUMMARY COUNT VERSION
-- ============================================================================

WITH RankedGCF AS (
    SELECT 
        CAST(obm.Insert_Date AS DATE) AS GCF_Date,
        obm.Customer_order_No AS Work_Order,
        obm.Message_Type AS GCF_Version,
        obm.Processed,
        obm.Insert_Date AS Error_Timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY obm.Customer_order_No, CAST(obm.Insert_Date AS DATE) 
            ORDER BY obm.Insert_Date DESC
        ) AS rn
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Processed = 'F'
      AND CAST(obm.Insert_Date AS DATE) = '2025-10-29'
)
SELECT 
    GCF_Date,
    GCF_Version,
    Processed,
    COUNT(*) AS Total_Unique_Work_Orders,
    MIN(Error_Timestamp) AS First_Error,
    MAX(Error_Timestamp) AS Last_Error
FROM RankedGCF
WHERE rn = 1
GROUP BY GCF_Date, GCF_Version, Processed
ORDER BY Total_Unique_Work_Orders DESC;
















