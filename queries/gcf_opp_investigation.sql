-- ============================================================================
-- GCF OPP CATEGORY INVESTIGATION
-- ============================================================================
-- Finding what "OPP" category actually means in the error messages
-- ============================================================================

-- Option 1: Check if OPP is in Error_Code (C01) field
SELECT 
    obm.C01 AS Error_Code,
    obm.Message AS Error_Description,
    obm.C20 AS Additional_Notes,
    COUNT(*) AS Error_Count,
    COUNT(DISTINCT obm.Customer_order_No) AS Unique_Work_Orders
FROM Biztalk.dbo.Outmessage_hdr obm
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND obm.Processed = 'F'
  AND (obm.C01 LIKE '%OPP%' OR obm.Message LIKE '%OPP%' OR obm.C20 LIKE '%OPP%')
GROUP BY obm.C01, obm.Message, obm.C20
ORDER BY Error_Count DESC;


-- Option 2: Check for "NON-REPLACEMENT" pattern (might be related to OPP)
SELECT 
    obm.Message AS Error_Description,
    obm.C01 AS Error_Code,
    obm.C20 AS Additional_Notes,
    COUNT(*) AS Error_Count,
    COUNT(DISTINCT obm.Customer_order_No) AS Unique_Work_Orders
FROM Biztalk.dbo.Outmessage_hdr obm
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND obm.Processed = 'F'
  AND obm.Message LIKE '%NON-REPLACEMENT%'
GROUP BY obm.Message, obm.C01, obm.C20
ORDER BY Error_Count DESC;


-- Option 3: Check for common error patterns that might map to OPP
SELECT 
    obm.Message AS Error_Description,
    obm.C01 AS Error_Code,
    obm.C20 AS Additional_Notes,
    COUNT(*) AS Error_Count,
    COUNT(DISTINCT obm.Customer_order_No) AS Unique_Work_Orders
FROM Biztalk.dbo.Outmessage_hdr obm
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND obm.Processed = 'F'
  AND (
      obm.Message LIKE '%invalid child element%'
      OR obm.Message LIKE '%lkm-order-hdr%'
      OR obm.Message LIKE '%element%expected%'
  )
GROUP BY obm.Message, obm.C01, obm.C20
ORDER BY Error_Count DESC;


-- Option 4: Sample all errors to see what's NOT categorized yet
SELECT TOP 100
    obm.Customer_order_No AS Work_Order,
    obm.Message AS Error_Description,
    obm.C01 AS Error_Code,
    obm.C20 AS Additional_Notes,
    obm.Message_Type AS GCF_Version,
    obm.Insert_Date
FROM Biztalk.dbo.Outmessage_hdr obm
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND obm.Processed = 'F'
  -- Exclude already categorized patterns
  AND obm.Message != 'Root element is missing.'
  AND obm.Message NOT LIKE '%Service tag is invalid%'
  AND obm.Message NOT LIKE '%DPK Status%'
  AND obm.Message NOT LIKE '%HTTP status%'
  AND obm.Message NOT LIKE '%Unauthorized%'
  AND obm.Message NOT LIKE '%CCN%'
ORDER BY obm.Insert_Date DESC;

