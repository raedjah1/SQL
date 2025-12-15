
SELECT 
    Test_Date,  
    Work_Order,
    GCF_Version,
    CASE 
        WHEN GCF_Version = 'DellARB-GCF_V3' THEN 'ISG'
        ELSE 'CSG'
    END AS GCF_Type,
    Processed,
    Error_Description,
    Error_Code,
    Additional_Notes,
    Error_Timestamp,
    Outmessage_Hdr_Id
FROM (
    SELECT 
        CAST(obm.Insert_Date AS DATE) AS Test_Date,  -- ✅ Renamed
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
      AND obm.Processed = 'F'
      -- ✅ NO hardcoded date - let Power BI filter it
) AS RankedGCF
WHERE rn = 1
