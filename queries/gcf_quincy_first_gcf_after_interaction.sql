-- ============================================================================
-- FIRST GCF TRANSACTION AFTER QUINCY INTERACTION
-- ============================================================================
-- This query captures the FIRST GCF transaction (date/time) that occurs
-- AFTER each Quincy interaction. This helps understand the timing of when
-- errors appear after Quincy attempts a fix.
-- ============================================================================

SELECT 
    r.serialNo,
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [QuincyInteractionDate],
    r.createDate AS [QuincyInteractionTime],
    r.isSuccess AS [QuincyIsSuccess],
    -- First GCF transaction after Quincy interaction
    firstGCF.Insert_Date AS [FirstGCFTransactionTime],
    -- Hours from Quincy interaction to first GCF transaction
    DATEDIFF(HOUR, r.createDate, firstGCF.Insert_Date) AS [HoursToFirstGCF],
    -- Days from Quincy interaction to first GCF transaction
    DATEDIFF(DAY, r.createDate, firstGCF.Insert_Date) AS [DaysToFirstGCF],
    -- GCF transaction details
    firstGCF.Message_Type AS [GCFMessageType],
    firstGCF.Processed AS [GCFProcessed],
    firstGCF.C01 AS [ErrorCode],
    -- Extract STATUSREASON from Message XML
    CASE 
        WHEN firstGCF.Message LIKE '%<STATUSREASON>%</STATUSREASON>%'
             AND CHARINDEX('<STATUSREASON>', firstGCF.Message) > 0
             AND CHARINDEX('</STATUSREASON>', firstGCF.Message) > CHARINDEX('<STATUSREASON>', firstGCF.Message) + 14 THEN
            SUBSTRING(firstGCF.Message,
                CHARINDEX('<STATUSREASON>', firstGCF.Message) + 14,
                CHARINDEX('</STATUSREASON>', firstGCF.Message) - CHARINDEX('<STATUSREASON>', firstGCF.Message) - 14
            )
        WHEN firstGCF.Message = 'Root element is missing.' THEN 'Root element is missing.'
        ELSE LEFT(firstGCF.Message, 200) -- First 200 chars if not XML
    END AS [GCFStatusReason],
    -- Check if it's "Msg Sent Ok"
    CASE 
        WHEN LOWER(firstGCF.Message) LIKE '%msg sent ok%' THEN 'YES - Msg Sent Ok'
        ELSE 'NO - Error Message'
    END AS [IsMsgSentOk],
    -- Categorize the GCF error (using the same logic from GCF error categorization)
    CASE 
        -- Order matters - check most specific first
        WHEN LOWER(firstGCF.Message) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(firstGCF.Message) LIKE '%root element is missing%'
             OR firstGCF.Message = 'Root element is missing.' THEN 'Root Element Missing'
        WHEN LOWER(firstGCF.Message) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(firstGCF.Message) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag - Flip Win8Upgrade Attribute'
        WHEN LOWER(firstGCF.Message) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(firstGCF.Message) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(firstGCF.Message) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error. Check for corrupt/bad Mods'
        WHEN LOWER(firstGCF.Message) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator error. Check for duplicate/corrupt Mods'
        WHEN LOWER(firstGCF.Message) LIKE '%could not find an os part number for the order%' THEN 'Could not find an OS Part Number for the Order'
        WHEN LOWER(firstGCF.Message) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined, Check for SSDR Mod with correct INFO part'
        WHEN LOWER(firstGCF.Message) LIKE '%error, internal hd(s) have not been placed%' THEN 'Error, Internal HD(s) have not been placed - Check BASE and SMOD.'
        WHEN LOWER(firstGCF.Message) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD when a notebook Base is in the order'
        WHEN LOWER(firstGCF.Message) LIKE '%validation error in process: could not find the family for this order because the base part does not contain the family%'
             OR LOWER(firstGCF.Message) LIKE '%alidation error in process: could not find the family for this order because the base part does not contain the family%' THEN 'Missing Family: Check Base Mod'
        WHEN LOWER(firstGCF.Message) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found!(0) - Needs Memory MOD'
        WHEN LOWER(firstGCF.Message) LIKE '%error while processing for the memory container%' THEN 'Incorrect or Corrupt Memory Mod'
        WHEN LOWER(firstGCF.Message) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(firstGCF.Message) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(firstGCF.Message) LIKE '%os part number%'
             AND LOWER(firstGCF.Message) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(firstGCF.Message) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts in Order'
        WHEN LOWER(firstGCF.Message) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts in the Order'
        WHEN LOWER(firstGCF.Message) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(firstGCF.Message) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(firstGCF.Message) LIKE '%msg sent ok%' THEN 'Msg Sent Ok'
        ELSE 'Other/Unknown'
    END AS [GCFErrorCategory],
    -- Full message (truncated for display)
    LEFT(firstGCF.Message, 500) AS [GCFMessagePreview]
FROM ClarityWarehouse.agentlogs.repair r
OUTER APPLY (
    -- Get the FIRST GCF transaction after Quincy interaction
    SELECT TOP 1
        obm.Insert_Date,
        obm.Message_Type,
        obm.Processed,
        obm.C01,
        obm.Message
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Customer_order_No = r.serialNo
      AND obm.Insert_Date > r.createDate  -- After Quincy interaction time
    ORDER BY obm.Insert_Date ASC  -- First one chronologically
) AS firstGCF
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    -- Filter by date if needed (uncomment and adjust)
    -- AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
ORDER BY r.createDate DESC, r.serialNo;

