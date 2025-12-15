-- ============================================================================
-- COUNT: First GCF Transaction After Quincy Interaction
-- ============================================================================
-- This query provides counts and breakdowns for the first GCF transaction
-- after each Quincy interaction, matching the 192 "Resolved by Quincy" records
-- ============================================================================

-- 1. Total count of Quincy interactions with first GCF transaction
SELECT 
    'Total Quincy Interactions' AS [Metric],
    COUNT(*) AS [Count]
FROM ClarityWarehouse.agentlogs.repair r
OUTER APPLY (
    SELECT TOP 1
        obm.Insert_Date
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Customer_order_No = r.serialNo
      AND obm.Insert_Date > r.createDate
    ORDER BY obm.Insert_Date ASC
) AS firstGCF
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
    AND r.isSuccess = 1  -- Only fix attempts (matching the "Resolved by Quincy" query)

UNION ALL

-- 2. Count with GCF transaction vs without
SELECT 
    CASE 
        WHEN firstGCF.Insert_Date IS NOT NULL THEN 'Has First GCF Transaction After Interaction'
        ELSE 'No GCF Transaction After Interaction'
    END AS [Metric],
    COUNT(*) AS [Count]
FROM ClarityWarehouse.agentlogs.repair r
OUTER APPLY (
    SELECT TOP 1
        obm.Insert_Date
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Customer_order_No = r.serialNo
      AND obm.Insert_Date > r.createDate
    ORDER BY obm.Insert_Date ASC
) AS firstGCF
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
    AND r.isSuccess = 1
GROUP BY 
    CASE 
        WHEN firstGCF.Insert_Date IS NOT NULL THEN 'Has First GCF Transaction After Interaction'
        ELSE 'No GCF Transaction After Interaction'
    END

UNION ALL

-- 3. Breakdown by "Msg Sent Ok" vs Error
SELECT 
    CASE 
        WHEN firstGCF.Insert_Date IS NULL THEN 'No GCF Transaction'
        WHEN LOWER(firstGCF.Message) LIKE '%msg sent ok%' THEN 'First GCF is "Msg Sent Ok"'
        ELSE 'First GCF is Error Message'
    END AS [Metric],
    COUNT(*) AS [Count]
FROM ClarityWarehouse.agentlogs.repair r
OUTER APPLY (
    SELECT TOP 1
        obm.Insert_Date,
        obm.Message
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Customer_order_No = r.serialNo
      AND obm.Insert_Date > r.createDate
    ORDER BY obm.Insert_Date ASC
) AS firstGCF
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
    AND r.isSuccess = 1
GROUP BY 
    CASE 
        WHEN firstGCF.Insert_Date IS NULL THEN 'No GCF Transaction'
        WHEN LOWER(firstGCF.Message) LIKE '%msg sent ok%' THEN 'First GCF is "Msg Sent Ok"'
        ELSE 'First GCF is Error Message'
    END

UNION ALL

-- 4. Breakdown by GCF Error Category (for error messages)
SELECT 
    CASE 
        WHEN firstGCF.Insert_Date IS NULL THEN 'No GCF Transaction'
        WHEN LOWER(firstGCF.Message) LIKE '%msg sent ok%' THEN 'Msg Sent Ok'
        WHEN LOWER(firstGCF.Message) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(firstGCF.Message) LIKE '%root element is missing%'
             OR firstGCF.Message = 'Root element is missing.' THEN 'Root Element Missing'
        WHEN LOWER(firstGCF.Message) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(firstGCF.Message) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag'
        WHEN LOWER(firstGCF.Message) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(firstGCF.Message) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(firstGCF.Message) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error'
        WHEN LOWER(firstGCF.Message) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator unavailable'
        WHEN LOWER(firstGCF.Message) LIKE '%could not find an os part number for the order%' THEN 'Could not find OS Part Number'
        WHEN LOWER(firstGCF.Message) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined'
        WHEN LOWER(firstGCF.Message) LIKE '%error, internal hd(s) have not been placed%' THEN 'Internal HD(s) not placed'
        WHEN LOWER(firstGCF.Message) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD'
        WHEN LOWER(firstGCF.Message) LIKE '%validation error in process: could not find the family%' THEN 'Missing Family'
        WHEN LOWER(firstGCF.Message) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found'
        WHEN LOWER(firstGCF.Message) LIKE '%error while processing for the memory container%' THEN 'Incorrect Memory Mod'
        WHEN LOWER(firstGCF.Message) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(firstGCF.Message) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(firstGCF.Message) LIKE '%os part number%'
             AND LOWER(firstGCF.Message) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(firstGCF.Message) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts'
        WHEN LOWER(firstGCF.Message) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts'
        WHEN LOWER(firstGCF.Message) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed'
        WHEN LOWER(firstGCF.Message) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed'
        ELSE 'Other/Unknown Error'
    END AS [Metric],
    COUNT(*) AS [Count]
FROM ClarityWarehouse.agentlogs.repair r
OUTER APPLY (
    SELECT TOP 1
        obm.Insert_Date,
        obm.Message
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Customer_order_No = r.serialNo
      AND obm.Insert_Date > r.createDate
    ORDER BY obm.Insert_Date ASC
) AS firstGCF
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
    AND r.isSuccess = 1
GROUP BY 
    CASE 
        WHEN firstGCF.Insert_Date IS NULL THEN 'No GCF Transaction'
        WHEN LOWER(firstGCF.Message) LIKE '%msg sent ok%' THEN 'Msg Sent Ok'
        WHEN LOWER(firstGCF.Message) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(firstGCF.Message) LIKE '%root element is missing%'
             OR firstGCF.Message = 'Root element is missing.' THEN 'Root Element Missing'
        WHEN LOWER(firstGCF.Message) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(firstGCF.Message) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag'
        WHEN LOWER(firstGCF.Message) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(firstGCF.Message) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(firstGCF.Message) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error'
        WHEN LOWER(firstGCF.Message) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator unavailable'
        WHEN LOWER(firstGCF.Message) LIKE '%could not find an os part number for the order%' THEN 'Could not find OS Part Number'
        WHEN LOWER(firstGCF.Message) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined'
        WHEN LOWER(firstGCF.Message) LIKE '%error, internal hd(s) have not been placed%' THEN 'Internal HD(s) not placed'
        WHEN LOWER(firstGCF.Message) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD'
        WHEN LOWER(firstGCF.Message) LIKE '%validation error in process: could not find the family%' THEN 'Missing Family'
        WHEN LOWER(firstGCF.Message) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found'
        WHEN LOWER(firstGCF.Message) LIKE '%error while processing for the memory container%' THEN 'Incorrect Memory Mod'
        WHEN LOWER(firstGCF.Message) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(firstGCF.Message) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(firstGCF.Message) LIKE '%os part number%'
             AND LOWER(firstGCF.Message) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(firstGCF.Message) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts'
        WHEN LOWER(firstGCF.Message) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts'
        WHEN LOWER(firstGCF.Message) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed'
        WHEN LOWER(firstGCF.Message) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed'
        ELSE 'Other/Unknown Error'
    END
ORDER BY [Count] DESC, [Metric];

-- 5. Detail view: All 192 records (or however many match the criteria)
SELECT 
    r.serialNo,
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [QuincyInteractionDate],
    r.createDate AS [QuincyInteractionTime],
    firstGCF.Insert_Date AS [FirstGCFTransactionTime],
    DATEDIFF(HOUR, r.createDate, firstGCF.Insert_Date) AS [HoursToFirstGCF],
    CASE 
        WHEN firstGCF.Insert_Date IS NULL THEN 'No GCF Transaction'
        WHEN LOWER(firstGCF.Message) LIKE '%msg sent ok%' THEN 'Msg Sent Ok'
        ELSE 'Error Message'
    END AS [FirstGCFType],
    LEFT(firstGCF.Message, 200) AS [FirstGCFMessagePreview]
FROM ClarityWarehouse.agentlogs.repair r
OUTER APPLY (
    SELECT TOP 1
        obm.Insert_Date,
        obm.Message
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Customer_order_No = r.serialNo
      AND obm.Insert_Date > r.createDate
    ORDER BY obm.Insert_Date ASC
) AS firstGCF
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
    AND r.isSuccess = 1  -- Only fix attempts (matching the "Resolved by Quincy" query)
ORDER BY r.createDate DESC, r.serialNo;

