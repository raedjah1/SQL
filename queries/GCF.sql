
SELECT 
    gcf.Outmessage_Hdr_Id AS [Msg. Id],
    gcf.Message_Type AS [Msg. Type],
    gcf.Customer_order_No AS [Customer Order No.],
    gcf.Message_Sub_Type AS [Msg. Sub Type],
    gcf.Message AS [Message],
    gcf.Insert_Date AS [Insert Date],
    gcf.Processed_Date AS [Processed Date],
    gcf.Source AS [Source],
    gcf.C01 AS [C01],
    gcf.C02 AS [C02],
    gcf.C03 AS [C03],
    CAST(gcf.Insert_Date AS DATE) AS [Date],
    -- EOW: Saturday to Friday week (ends on Friday)
    DATEADD(DAY, 
        CASE 
            WHEN DATEPART(WEEKDAY, CAST(gcf.Insert_Date AS DATE)) = 7 THEN 6  -- Saturday: add 6 days to get next Friday
            ELSE 6 - DATEPART(WEEKDAY, CAST(gcf.Insert_Date AS DATE))  -- Sunday-Friday: days to add to reach Friday
        END, 
        CAST(gcf.Insert_Date AS DATE)
    ) AS [EOW],
    
    -- Extract STATUSREASON from XML if present (for better error display)
    CASE 
        WHEN gcf.Message LIKE '%<STATUSREASON>%</STATUSREASON>%'
             AND CHARINDEX('<STATUSREASON>', gcf.Message) > 0
             AND CHARINDEX('</STATUSREASON>', gcf.Message) > CHARINDEX('<STATUSREASON>', gcf.Message) + 14 THEN
            SUBSTRING(gcf.Message,
                CHARINDEX('<STATUSREASON>', gcf.Message) + 14,
                CHARINDEX('</STATUSREASON>', gcf.Message) - CHARINDEX('<STATUSREASON>', gcf.Message) - 14
            )
        WHEN gcf.Message = 'Root element is missing.' THEN 'Root element is missing.'
        ELSE LEFT(gcf.Message, 200)
    END AS [ExtractedError],
    
    -- ✅ Comprehensive Fail Category (matches Excel logic - order matters!)
    CASE 
        -- Order matters - check most specific first
        WHEN LOWER(gcf.Message) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(gcf.Message) LIKE '%root element is missing%'
             OR gcf.Message = 'Root element is missing.' THEN 'Root Element Missing'
        WHEN LOWER(gcf.Message) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(gcf.Message) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag - Flip Win8Upgrade Attribute'
        WHEN LOWER(gcf.Message) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(gcf.Message) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(gcf.Message) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error. Check for corrupt/bad Mods'
        WHEN LOWER(gcf.Message) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator error. Check for duplicate/corrupt Mods'
        WHEN LOWER(gcf.Message) LIKE '%could not find an os part number for the order%' THEN 'Could not find an OS Part Number for the Order'
        WHEN LOWER(gcf.Message) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined, Check for SSDR Mod with correct INFO part'
        WHEN LOWER(gcf.Message) LIKE '%error, internal hd(s) have not been placed%' THEN 'Error, Internal HD(s) have not been placed - Check BASE and SMOD.'
        WHEN LOWER(gcf.Message) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD when a notebook Base is in the order'
        WHEN LOWER(gcf.Message) LIKE '%validation error in process: could not find the family for this order because the base part does not contain the family%'
             OR LOWER(gcf.Message) LIKE '%alidation error in process: could not find the family for this order because the base part does not contain the family%' THEN 'Missing Family: Check Base Mod'
        WHEN LOWER(gcf.Message) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found!(0) - Needs Memory MOD'
        WHEN LOWER(gcf.Message) LIKE '%error while processing for the memory container%' THEN 'Incorrect or Corrupt Memory Mod'
        WHEN LOWER(gcf.Message) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(gcf.Message) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(gcf.Message) LIKE '%os part number%'
             AND LOWER(gcf.Message) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(gcf.Message) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts in Order'
        WHEN LOWER(gcf.Message) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts in the Order'
        WHEN LOWER(gcf.Message) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(gcf.Message) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(gcf.Message) LIKE '%part number mn3fv not found in inventory%' THEN 'DPK Deviation - Needs to change to R3G96'
        WHEN LOWER(gcf.Message) LIKE '%dpk status attribute not configured%' THEN 'DPK Status attribute not configured for this service tag'
        WHEN LOWER(gcf.Message) LIKE '%part number r3g96 not found in inventory for service tag%' THEN 'Part Number R3G96 not found in inventory for service tag'
        WHEN LOWER(gcf.Message) LIKE '%part number unknown not found in inventory for service tag%' THEN 'Part Number UNKNOWN not found in inventory for service tag'
        WHEN LOWER(gcf.Message) LIKE '%not found in inventory for service tag%'
             AND LOWER(gcf.Message) NOT LIKE '%part number r3g96%'
             AND LOWER(gcf.Message) NOT LIKE '%part number unknown%' THEN 'DPK Part Number not found in inventory; Verify correct DPK in Plus'
        WHEN LOWER(gcf.Message) LIKE '%error from bes web service%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(gcf.Message) LIKE '%system.timeoutexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(gcf.Message) LIKE '%read timeout%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(gcf.Message) LIKE '%the request was aborted: the request was canceled%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(gcf.Message) LIKE '%system.servicemodel.communicationexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(gcf.Message) LIKE '%http status 401: unauthorized%' THEN 'Webservice Authentication Error'
        WHEN LOWER(gcf.Message) LIKE '%could not find partsfile from gafp wcf service or local copy%' THEN 'Could not find partsFile from GAFP Wcf service or local copy'
        WHEN gcf.C01 = 'OPP' OR LOWER(gcf.Message) LIKE '%opp%' THEN 'Other OPP Failure'
        WHEN LOWER(gcf.Message) LIKE '%msg sent ok%' THEN 'Msg Sent Ok'
        ELSE 'Other/Unknown'
    END AS [Fail Category],
    
    CASE WHEN gcf.Processed = 'T' OR gcf.Processed_Date IS NOT NULL THEN 'Resolved' ELSE 'Not Resolved' END AS [Resolved?],
    
    -- ✅ Family Lookup (same pattern as test activity query)
    ISNULL(psa_family.Value, 'Unknown') AS [Family Lookup]
FROM (
    SELECT 
        obm.*,
        ROW_NUMBER() OVER (
            PARTITION BY obm.Customer_order_No, CAST(obm.Insert_Date AS DATE) 
            ORDER BY obm.Insert_Date DESC
        ) AS rn
    FROM Biztalk.dbo.Outmessage_hdr obm
    WHERE obm.Source = 'Plus'
      AND obm.Contract = '10053'
      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
      AND obm.Processed = 'F'
) AS gcf
-- ✅ Join to SOHeader to get to PartSerial
LEFT JOIN Plus.pls.SOHeader sh ON sh.CustomerReference = gcf.Customer_order_No AND sh.ProgramID = 10053
-- ✅ Use OUTER APPLY to get PartSerial (same pattern as test activity query)
OUTER APPLY (
    SELECT TOP 1 ps.ID, ps.PartNo
    FROM Plus.pls.PartSerial ps
    WHERE ps.SOHeaderID = sh.ID
      AND ps.ProgramID = 10053
    ORDER BY ps.ID DESC
) AS ps
-- ✅ Get Family from PartSerialAttribute (same pattern as test activity query)
OUTER APPLY (
    SELECT TOP 1 psa.Value
    FROM Plus.pls.PartSerialAttribute psa
    WHERE psa.PartSerialID = ps.ID
      AND psa.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttFamily')
    ORDER BY psa.ID DESC
) AS psa_family
WHERE gcf.rn = 1

