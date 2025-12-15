-- ============================================================================
-- GCF ERROR CATEGORIZATION INVESTIGATION
-- ============================================================================
-- Testing the Excel IFS formula logic against actual BizTalk GCF errors
-- Extracts STATUSREASON from Message XML and categorizes using Excel patterns
-- ============================================================================

SELECT TOP 100
    CAST(obm.Insert_Date AS DATE) AS [Date],
    obm.Customer_order_No AS [WorkOrder],
    obm.Insert_Date AS [ErrorTimestamp],
    -- Extract STATUSREASON from Message XML (this is what Excel is checking)
    -- Also handle plain text messages
    CASE 
        WHEN obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%' 
             AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
             AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14 THEN
            SUBSTRING(obm.Message, 
                CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
            )
        WHEN obm.Message = 'Root element is missing.' THEN 'Root element is missing.'
        ELSE obm.Message
    END AS [STATUSREASON_Extracted],
    -- Create a searchable text field (STATUSREASON if XML, otherwise full Message)
    CASE 
        WHEN obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%' 
             AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
             AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14 THEN
            LOWER(SUBSTRING(obm.Message, 
                CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
            ))
        ELSE LOWER(obm.Message)
    END AS [SearchableText],
    -- Test Excel categorization logic (matching IFS formula order) - CASE INSENSITIVE
    CASE 
        -- Order matters - check most specific first
        WHEN LOWER(obm.Message) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(obm.Message) LIKE '%root element is missing%' 
             OR obm.Message = 'Root element is missing.' THEN 'Root Element Missing'
        WHEN LOWER(obm.Message) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(obm.Message) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag - Flip Win8Upgrade Attribute'
        WHEN LOWER(obm.Message) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(obm.Message) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(obm.Message) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error. Check for corrupt/bad Mods'
        WHEN LOWER(obm.Message) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator error. Check for duplicate/corrupt Mods'
        WHEN LOWER(obm.Message) LIKE '%could not find an os part number for the order%' THEN 'Could not find an OS Part Number for the Order'
        WHEN LOWER(obm.Message) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined, Check for SSDR Mod with correct INFO part'
        WHEN LOWER(obm.Message) LIKE '%error, internal hd(s) have not been placed%' THEN 'Error, Internal HD(s) have not been placed - Check BASE and SMOD.'
        WHEN LOWER(obm.Message) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD when a notebook Base is in the order'
        WHEN LOWER(obm.Message) LIKE '%validation error in process: could not find the family for this order because the base part does not contain the family%' 
             OR LOWER(obm.Message) LIKE '%alidation error in process: could not find the family for this order because the base part does not contain the family%' THEN 'Missing Family: Check Base Mod'
        WHEN LOWER(obm.Message) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found!(0) - Needs Memory MOD'
        WHEN LOWER(obm.Message) LIKE '%error while processing for the memory container%' THEN 'Incorrect or Corrupt Memory Mod'
        WHEN LOWER(obm.Message) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(obm.Message) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(obm.Message) LIKE '%os part number%' 
             AND LOWER(obm.Message) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(obm.Message) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts in Order'
        WHEN LOWER(obm.Message) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts in the Order'
        WHEN LOWER(obm.Message) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(obm.Message) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(obm.Message) LIKE '%part number mn3fv not found in inventory%' THEN 'DPK Deviation - Needs to change to R3G96'
        WHEN LOWER(obm.Message) LIKE '%dpk status attribute not configured%' THEN 'DPK Status attribute not configured for this service tag'
        WHEN LOWER(obm.Message) LIKE '%part number r3g96 not found in inventory for service tag%' THEN 'Part Number R3G96 not found in inventory for service tag'
        WHEN LOWER(obm.Message) LIKE '%part number unknown not found in inventory for service tag%' THEN 'Part Number UNKNOWN not found in inventory for service tag'
        WHEN LOWER(obm.Message) LIKE '%not found in inventory for service tag%' 
             AND LOWER(obm.Message) NOT LIKE '%part number r3g96%'
             AND LOWER(obm.Message) NOT LIKE '%part number unknown%' THEN 'DPK Part Number not found in inventory; Verify correct DPK in Plus'
        WHEN LOWER(obm.Message) LIKE '%error from bes web service%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%system.timeoutexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%read timeout%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%the request was aborted: the request was canceled%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%system.servicemodel.communicationexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%http status 401: unauthorized%' THEN 'Webservice Authentication Error'
        WHEN LOWER(obm.Message) LIKE '%could not find partsfile from gafp wcf service or local copy%' THEN 'Could not find partsFile from GAFP Wcf service or local copy'
        WHEN obm.C01 = 'OPP' OR LOWER(obm.Message) LIKE '%opp%' THEN 'Other OPP Failure'
        WHEN LOWER(obm.Message) LIKE '%msg sent ok%' THEN 'Msg Sent Ok'
        ELSE 'No Message found'
    END AS [FailCategory_ExcelLogic],
    -- Also check if STATUSREASON contains these patterns (might be in XML)
    CASE 
        WHEN obm.Message LIKE '%<STATUSREASON>%DPK Quantity%</STATUSREASON>%' THEN 'DPK Quantity (in STATUSREASON)'
        WHEN obm.Message LIKE '%<STATUSREASON>%Root Element is Missing%</STATUSREASON>%' THEN 'Root Element Missing (in STATUSREASON)'
        WHEN obm.Message LIKE '%<STATUSREASON>%Too many processors%</STATUSREASON>%' THEN 'Too many processors (in STATUSREASON)'
        WHEN obm.Message LIKE '%<STATUSREASON>%No boot hard drive%</STATUSREASON>%' THEN 'No boot hard drive (in STATUSREASON)'
        ELSE NULL
    END AS [STATUSREASON_PatternCheck],
    obm.C01 AS [ErrorCode],
    obm.Message AS [FullMessage]
FROM Biztalk.dbo.Outmessage_hdr obm
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND obm.Processed = 'F'
  AND CAST(obm.Insert_Date AS DATE) >= '2025-11-08'
  AND CAST(obm.Insert_Date AS DATE) <= '2025-11-19'
ORDER BY obm.Insert_Date DESC;

-- Summary: Count by category to see distribution (CASE INSENSITIVE)
SELECT 
    CASE 
        WHEN LOWER(obm.Message) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(obm.Message) LIKE '%root element is missing%' 
             OR obm.Message = 'Root element is missing.' THEN 'Root Element Missing'
        WHEN LOWER(obm.Message) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(obm.Message) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag - Flip Win8Upgrade Attribute'
        WHEN LOWER(obm.Message) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(obm.Message) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(obm.Message) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error. Check for corrupt/bad Mods'
        WHEN LOWER(obm.Message) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator error. Check for duplicate/corrupt Mods'
        WHEN LOWER(obm.Message) LIKE '%could not find an os part number for the order%' THEN 'Could not find an OS Part Number for the Order'
        WHEN LOWER(obm.Message) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined, Check for SSDR Mod with correct INFO part'
        WHEN LOWER(obm.Message) LIKE '%error, internal hd(s) have not been placed%' THEN 'Error, Internal HD(s) have not been placed - Check BASE and SMOD.'
        WHEN LOWER(obm.Message) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD when a notebook Base is in the order'
        WHEN LOWER(obm.Message) LIKE '%validation error in process: could not find the family for this order because the base part does not contain the family%' 
             OR LOWER(obm.Message) LIKE '%alidation error in process: could not find the family for this order because the base part does not contain the family%' THEN 'Missing Family: Check Base Mod'
        WHEN LOWER(obm.Message) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found!(0) - Needs Memory MOD'
        WHEN LOWER(obm.Message) LIKE '%error while processing for the memory container%' THEN 'Incorrect or Corrupt Memory Mod'
        WHEN LOWER(obm.Message) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(obm.Message) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(obm.Message) LIKE '%os part number%' 
             AND LOWER(obm.Message) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(obm.Message) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts in Order'
        WHEN LOWER(obm.Message) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts in the Order'
        WHEN LOWER(obm.Message) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(obm.Message) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(obm.Message) LIKE '%part number mn3fv not found in inventory%' THEN 'DPK Deviation - Needs to change to R3G96'
        WHEN LOWER(obm.Message) LIKE '%dpk status attribute not configured%' THEN 'DPK Status attribute not configured for this service tag'
        WHEN LOWER(obm.Message) LIKE '%part number r3g96 not found in inventory for service tag%' THEN 'Part Number R3G96 not found in inventory for service tag'
        WHEN LOWER(obm.Message) LIKE '%part number unknown not found in inventory for service tag%' THEN 'Part Number UNKNOWN not found in inventory for service tag'
        WHEN LOWER(obm.Message) LIKE '%not found in inventory for service tag%' 
             AND LOWER(obm.Message) NOT LIKE '%part number r3g96%'
             AND LOWER(obm.Message) NOT LIKE '%part number unknown%' THEN 'DPK Part Number not found in inventory; Verify correct DPK in Plus'
        WHEN LOWER(obm.Message) LIKE '%error from bes web service%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%system.timeoutexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%read timeout%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%the request was aborted: the request was canceled%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%system.servicemodel.communicationexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%http status 401: unauthorized%' THEN 'Webservice Authentication Error'
        WHEN LOWER(obm.Message) LIKE '%could not find partsfile from gafp wcf service or local copy%' THEN 'Could not find partsFile from GAFP Wcf service or local copy'
        WHEN obm.C01 = 'OPP' OR LOWER(obm.Message) LIKE '%opp%' THEN 'Other OPP Failure'
        WHEN LOWER(obm.Message) LIKE '%msg sent ok%' THEN 'Msg Sent Ok'
        ELSE 'No Message found'
    END AS [FailCategory],
    COUNT(*) AS [Count]
FROM Biztalk.dbo.Outmessage_hdr obm
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND obm.Processed = 'F'
  AND CAST(obm.Insert_Date AS DATE) >= '2025-11-08'
  AND CAST(obm.Insert_Date AS DATE) <= '2025-11-19'
GROUP BY 
    CASE 
        WHEN LOWER(obm.Message) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(obm.Message) LIKE '%root element is missing%' 
             OR obm.Message = 'Root element is missing.' THEN 'Root Element Missing'
        WHEN LOWER(obm.Message) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(obm.Message) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag - Flip Win8Upgrade Attribute'
        WHEN LOWER(obm.Message) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(obm.Message) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(obm.Message) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error. Check for corrupt/bad Mods'
        WHEN LOWER(obm.Message) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator error. Check for duplicate/corrupt Mods'
        WHEN LOWER(obm.Message) LIKE '%could not find an os part number for the order%' THEN 'Could not find an OS Part Number for the Order'
        WHEN LOWER(obm.Message) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined, Check for SSDR Mod with correct INFO part'
        WHEN LOWER(obm.Message) LIKE '%error, internal hd(s) have not been placed%' THEN 'Error, Internal HD(s) have not been placed - Check BASE and SMOD.'
        WHEN LOWER(obm.Message) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD when a notebook Base is in the order'
        WHEN LOWER(obm.Message) LIKE '%validation error in process: could not find the family for this order because the base part does not contain the family%' 
             OR LOWER(obm.Message) LIKE '%alidation error in process: could not find the family for this order because the base part does not contain the family%' THEN 'Missing Family: Check Base Mod'
        WHEN LOWER(obm.Message) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found!(0) - Needs Memory MOD'
        WHEN LOWER(obm.Message) LIKE '%error while processing for the memory container%' THEN 'Incorrect or Corrupt Memory Mod'
        WHEN LOWER(obm.Message) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(obm.Message) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(obm.Message) LIKE '%os part number%' 
             AND LOWER(obm.Message) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(obm.Message) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts in Order'
        WHEN LOWER(obm.Message) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts in the Order'
        WHEN LOWER(obm.Message) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(obm.Message) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(obm.Message) LIKE '%part number mn3fv not found in inventory%' THEN 'DPK Deviation - Needs to change to R3G96'
        WHEN LOWER(obm.Message) LIKE '%dpk status attribute not configured%' THEN 'DPK Status attribute not configured for this service tag'
        WHEN LOWER(obm.Message) LIKE '%part number r3g96 not found in inventory for service tag%' THEN 'Part Number R3G96 not found in inventory for service tag'
        WHEN LOWER(obm.Message) LIKE '%part number unknown not found in inventory for service tag%' THEN 'Part Number UNKNOWN not found in inventory for service tag'
        WHEN LOWER(obm.Message) LIKE '%not found in inventory for service tag%' 
             AND LOWER(obm.Message) NOT LIKE '%part number r3g96%'
             AND LOWER(obm.Message) NOT LIKE '%part number unknown%' THEN 'DPK Part Number not found in inventory; Verify correct DPK in Plus'
        WHEN LOWER(obm.Message) LIKE '%error from bes web service%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%system.timeoutexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%read timeout%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%the request was aborted: the request was canceled%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%system.servicemodel.communicationexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(obm.Message) LIKE '%http status 401: unauthorized%' THEN 'Webservice Authentication Error'
        WHEN LOWER(obm.Message) LIKE '%could not find partsfile from gafp wcf service or local copy%' THEN 'Could not find partsFile from GAFP Wcf service or local copy'
        WHEN obm.C01 = 'OPP' OR LOWER(obm.Message) LIKE '%opp%' THEN 'Other OPP Failure'
        WHEN LOWER(obm.Message) LIKE '%msg sent ok%' THEN 'Msg Sent Ok'
        ELSE 'No Message found'
    END
ORDER BY [Count] DESC;

-- ============================================================================
-- INVESTIGATE: What are the "No Message found" cases?
-- ============================================================================
-- Simple query to see the raw messages that don't match any pattern
SELECT 
    CAST(obm.Insert_Date AS DATE) AS [Date],
    obm.Customer_order_No AS [WorkOrder],
    obm.Insert_Date AS [ErrorTimestamp],
    obm.C01 AS [ErrorCode],
    obm.Message AS [FullMessage],
    -- Show extracted STATUSREASON if it's XML
    CASE 
        WHEN obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%' 
             AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
             AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14 THEN
            SUBSTRING(obm.Message, 
                CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
            )
        ELSE NULL
    END AS [STATUSREASON_Extracted]
FROM Biztalk.dbo.Outmessage_hdr obm
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND obm.Processed = 'F'
  AND CAST(obm.Insert_Date AS DATE) >= '2025-11-08'
  AND CAST(obm.Insert_Date AS DATE) <= '2025-11-19'
  -- Only show records that don't match any pattern (No Message found)
  AND NOT (
    LOWER(obm.Message) LIKE '%dpk quantity%'
    OR LOWER(obm.Message) LIKE '%root element is missing%'
    OR obm.Message = 'Root element is missing.'
    OR LOWER(obm.Message) LIKE '%error is 100%'
    OR LOWER(obm.Message) LIKE '%service tag is invalid%'
    OR LOWER(obm.Message) LIKE '%system does not contain a processor%'
    OR LOWER(obm.Message) LIKE '%no base mod found%'
    OR LOWER(obm.Message) LIKE '%ops code did not complete execution%'
    OR LOWER(obm.Message) LIKE '%sdrgenerator is unavailable%'
    OR LOWER(obm.Message) LIKE '%could not find an os part number for the order%'
    OR LOWER(obm.Message) LIKE '%no boot hard drive can be determined%'
    OR LOWER(obm.Message) LIKE '%error, internal hd(s) have not been placed%'
    OR LOWER(obm.Message) LIKE '%could not find an lcd for this order item when a notebook base was found%'
    OR LOWER(obm.Message) LIKE '%validation error in process: could not find the family for this order because the base part does not contain the family%'
    OR LOWER(obm.Message) LIKE '%alidation error in process: could not find the family for this order because the base part does not contain the family%'
    OR LOWER(obm.Message) LIKE '%no memory dimms found!(0)%'
    OR LOWER(obm.Message) LIKE '%error while processing for the memory container%'
    OR LOWER(obm.Message) LIKE '%too many processors for available sockets%'
    OR LOWER(obm.Message) LIKE '%error is available quantity less than the required quantity%'
    OR (LOWER(obm.Message) LIKE '%os part number%' 
        AND LOWER(obm.Message) NOT LIKE '%could not find an os part number for the order%')
    OR LOWER(obm.Message) LIKE '%unsupported parts found in the order level%'
    OR LOWER(obm.Message) LIKE '%there are multiple os parts in the order%'
    OR LOWER(obm.Message) LIKE '%error is dpk/service tag status is invalid%'
    OR LOWER(obm.Message) LIKE '%lkm did not provided dpk%'
    OR LOWER(obm.Message) LIKE '%part number mn3fv not found in inventory%'
    OR LOWER(obm.Message) LIKE '%dpk status attribute not configured%'
    OR LOWER(obm.Message) LIKE '%part number r3g96 not found in inventory for service tag%'
    OR LOWER(obm.Message) LIKE '%part number unknown not found in inventory for service tag%'
    OR (LOWER(obm.Message) LIKE '%not found in inventory for service tag%' 
        AND LOWER(obm.Message) NOT LIKE '%part number r3g96%'
        AND LOWER(obm.Message) NOT LIKE '%part number unknown%')
    OR LOWER(obm.Message) LIKE '%error from bes web service%'
    OR LOWER(obm.Message) LIKE '%system.timeoutexception%'
    OR LOWER(obm.Message) LIKE '%read timeout%'
    OR LOWER(obm.Message) LIKE '%the request was aborted: the request was canceled%'
    OR LOWER(obm.Message) LIKE '%system.servicemodel.communicationexception%'
    OR LOWER(obm.Message) LIKE '%http status 401: unauthorized%'
    OR LOWER(obm.Message) LIKE '%could not find partsfile from gafp wcf service or local copy%'
    OR obm.C01 = 'OPP'
    OR LOWER(obm.Message) LIKE '%opp%'
    OR LOWER(obm.Message) LIKE '%msg sent ok%'
  )
ORDER BY obm.Insert_Date DESC;

