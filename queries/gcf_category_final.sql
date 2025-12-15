-- ============================================================================
-- GCF QUINCY CATEGORIZATION - STARTING POINT
-- ============================================================================
-- This query provides a clean base for categorizing Quincy fix attempts into:
--   1. Encountered New Error
--   2. Resolved by Quincy
--   3. Same Error
--   4. GCF Request Trigger Failure
-- ============================================================================
-- STEP 1: Filter out "Msg Sent Ok" records (these are handled separately)
-- ============================================================================

SELECT 
    r.serialNo,
    r.woHeaderID,
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [QuincyInteractionDate],
    r.createDate AS [QuincyInteractionTime],
    r.isSuccess AS [QuincyIsSuccess],
    r.initialErrorDate,
    
    -- Initial error from repair table (extracted)
    CASE 
        WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%'
             AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
             AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14 THEN
            LTRIM(SUBSTRING(
                SUBSTRING(r.initialError, 
                    CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                    CASE 
                        WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                        THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                        ELSE 1
                    END
                ),
                CASE 
                    WHEN CHARINDEX('Failed :', 
                        SUBSTRING(r.initialError, 
                            CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                            CASE 
                                WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                ELSE 1
                            END
                        )) > 0 
                    THEN CHARINDEX('Failed :', 
                        SUBSTRING(r.initialError, 
                            CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                            CASE 
                                WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                ELSE 1
                            END
                        )) + 9
                    ELSE 1 
                END,
                200
            ))
        ELSE NULL
    END AS [InitialErrorMessage],
    
    -- Last GCF transaction from Quincy interaction date (excluding "Msg Sent Ok")
    lastGCF.Insert_Date AS [LastGCFTransactionTime],
    DATEDIFF(HOUR, r.createDate, lastGCF.Insert_Date) AS [HoursToLastGCF],
    
    -- Last GCF error message from the day (extracted, excluding "Msg Sent Ok")
    CASE 
        WHEN lastGCF.Message LIKE '%<STATUSREASON>%</STATUSREASON>%'
             AND CHARINDEX('<STATUSREASON>', lastGCF.Message) > 0
             AND CHARINDEX('</STATUSREASON>', lastGCF.Message) > CHARINDEX('<STATUSREASON>', lastGCF.Message) + 14 THEN
            LTRIM(SUBSTRING(
                SUBSTRING(lastGCF.Message, 
                    CHARINDEX('<STATUSREASON>', lastGCF.Message) + 14, 
                    CASE 
                        WHEN CHARINDEX('</STATUSREASON>', lastGCF.Message) - CHARINDEX('<STATUSREASON>', lastGCF.Message) - 14 > 0 
                        THEN CHARINDEX('</STATUSREASON>', lastGCF.Message) - CHARINDEX('<STATUSREASON>', lastGCF.Message) - 14
                        ELSE 1
                    END
                ),
                CASE 
                    WHEN CHARINDEX('Failed :', 
                        SUBSTRING(lastGCF.Message, 
                            CHARINDEX('<STATUSREASON>', lastGCF.Message) + 14, 
                            CASE 
                                WHEN CHARINDEX('</STATUSREASON>', lastGCF.Message) - CHARINDEX('<STATUSREASON>', lastGCF.Message) - 14 > 0 
                                THEN CHARINDEX('</STATUSREASON>', lastGCF.Message) - CHARINDEX('<STATUSREASON>', lastGCF.Message) - 14
                                ELSE 1
                            END
                        )) > 0 
                    THEN CHARINDEX('Failed :', 
                        SUBSTRING(lastGCF.Message, 
                            CHARINDEX('<STATUSREASON>', lastGCF.Message) + 14, 
                            CASE 
                                WHEN CHARINDEX('</STATUSREASON>', lastGCF.Message) - CHARINDEX('<STATUSREASON>', lastGCF.Message) - 14 > 0 
                                THEN CHARINDEX('</STATUSREASON>', lastGCF.Message) - CHARINDEX('<STATUSREASON>', lastGCF.Message) - 14
                                ELSE 1
                            END
                        )) + 9
                    ELSE 1 
                END,
                200
            ))
        WHEN lastGCF.Message = 'Root element is missing.' THEN 'Root element is missing.'
        ELSE LEFT(lastGCF.Message, 200)
    END AS [LastGCFErrorMessage],
    
    -- GCF Error Category (using existing categorization logic)
    CASE 
        WHEN LOWER(lastGCF.Message) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(lastGCF.Message) LIKE '%root element is missing%'
             OR lastGCF.Message = 'Root element is missing.' THEN 'Root Element Missing'
        WHEN LOWER(lastGCF.Message) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(lastGCF.Message) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag - Flip Win8Upgrade Attribute'
        WHEN LOWER(lastGCF.Message) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(lastGCF.Message) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(lastGCF.Message) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error. Check for corrupt/bad Mods'
        WHEN LOWER(lastGCF.Message) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator error. Check for duplicate/corrupt Mods'
        WHEN LOWER(lastGCF.Message) LIKE '%could not find an os part number for the order%' THEN 'Could not find an OS Part Number for the Order'
        WHEN LOWER(lastGCF.Message) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined, Check for SSDR Mod with correct INFO part'
        WHEN LOWER(lastGCF.Message) LIKE '%error, internal hd(s) have not been placed%' THEN 'Error, Internal HD(s) have not been placed - Check BASE and SMOD.'
        WHEN LOWER(lastGCF.Message) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD when a notebook Base is in the order'
        WHEN LOWER(lastGCF.Message) LIKE '%validation error in process: could not find the family for this order because the base part does not contain the family%'
             OR LOWER(lastGCF.Message) LIKE '%alidation error in process: could not find the family for this order because the base part does not contain the family%' THEN 'Missing Family: Check Base Mod'
        WHEN LOWER(lastGCF.Message) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found!(0) - Needs Memory MOD'
        WHEN LOWER(lastGCF.Message) LIKE '%error while processing for the memory container%' THEN 'Incorrect or Corrupt Memory Mod'
        WHEN LOWER(lastGCF.Message) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(lastGCF.Message) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(lastGCF.Message) LIKE '%os part number%'
             AND LOWER(lastGCF.Message) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(lastGCF.Message) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts in Order'
        WHEN LOWER(lastGCF.Message) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts in the Order'
        WHEN LOWER(lastGCF.Message) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(lastGCF.Message) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed - Check DPK Part'
        ELSE 'Other/Unknown'
    END AS [GCFErrorCategory],
    
    -- Helper fields for categorization logic
    CASE 
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'NO'
        WHEN r.initialErrorDate IS NULL THEN 'NO'
        ELSE 'YES'
    END AS [HasInitialError],
    
    CASE 
        WHEN lastGCF.Insert_Date IS NOT NULL THEN 'YES'
        ELSE 'NO'
    END AS [HasGCFFromSameDay],
    
    -- Last GCF message from the day (INCLUDING "Msg Sent Ok") - for reference only
    lastGCFIncludingMsgSentOk.Insert_Date AS [LastGCFTransactionTimeIncludingMsgSentOk],
    CASE 
        WHEN LOWER(lastGCFIncludingMsgSentOk.Message) LIKE '%msg sent ok%' THEN 'YES - Msg Sent Ok'
        ELSE 'NO - Error Message'
    END AS [IsLastMessageMsgSentOk],
    LEFT(lastGCFIncludingMsgSentOk.Message, 500) AS [LastGCFMessageIncludingMsgSentOk],
    
    -- Full messages for inspection
    LEFT(r.initialError, 500) AS [InitialErrorFull],
    LEFT(lastGCF.Message, 500) AS [LastGCFMessageFull]
    
FROM ClarityWarehouse.agentlogs.repair r
OUTER APPLY (
    -- Get the LAST GCF transaction from the Quincy interaction date (EXCLUDING "Msg Sent Ok")
    -- This gives us the end-of-day state for that specific date
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
      -- Filter to same day as Quincy interaction (CST date)
      AND CAST(DATEADD(HOUR, -6, obm.Insert_Date) AS DATE) = CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
      AND LOWER(obm.Message) NOT LIKE '%msg sent ok%'  -- EXCLUDE "Msg Sent Ok"
    ORDER BY obm.Insert_Date DESC  -- Last one chronologically from that day
) AS lastGCF
OUTER APPLY (
    -- Get the LAST GCF transaction from the Quincy interaction date (INCLUDING "Msg Sent Ok")
    -- This is for reference to see if the last message of the day was "Msg Sent Ok"
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
      -- Filter to same day as Quincy interaction (CST date)
      AND CAST(DATEADD(HOUR, -6, obm.Insert_Date) AS DATE) = CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)
      -- NO filter for "Msg Sent Ok" - include everything
    ORDER BY obm.Insert_Date DESC  -- Last one chronologically from that day
) AS lastGCFIncludingMsgSentOk
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 1  -- Only fix attempts
    -- Filter by date if needed (uncomment and adjust)
    -- AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
ORDER BY r.createDate DESC, r.serialNo;
