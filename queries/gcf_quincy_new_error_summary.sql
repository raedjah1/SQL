-- ============================================================================
-- NEW ERROR ENCOUNTERED SUMMARY
-- ============================================================================
-- Shows which GCF error categories appear as "new errors" after Quincy attempts
-- Matches Excel pivot: "New Error Encountered Summary"
-- ============================================================================
-- Filters for:
--   - isSuccess = 1 (Quincy attempted a fix)
--   - ErrorStatus = 'Encountered New Error' (a different error appeared after the attempt)
-- Groups by:
--   - Quincy Resolution Date Attempt (date)
--   - GCF Error Category (categorized latest error message)
-- ============================================================================

SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Quincy Resolution Date Attempt],
    -- Apply GCF error categorization to the latest error message
    CASE 
        -- Order matters - check most specific first (matching Excel IFS formula)
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%root element is missing%' 
             OR r.LatestErrorFullMessage = 'Root element is missing.' THEN 'Root Element Missing'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag - Flip Win8Upgrade Attribute'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error. Check for corrupt/bad Mods'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator error. Check for duplicate/corrupt Mods'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%could not find an os part number for the order%' THEN 'Could not find an OS Part Number for the Order'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined, Check for SSDR Mod with correct INFO part'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error, internal hd(s) have not been placed%' THEN 'Error, Internal HD(s) have not been placed - Check BASE and SMOD.'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD when a notebook Base is in the order'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%validation error in process: could not find the family for this order because the base part does not contain the family%' 
             OR LOWER(r.LatestErrorFullMessage) LIKE '%alidation error in process: could not find the family for this order because the base part does not contain the family%' THEN 'Missing Family: Check Base Mod'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found!(0) - Needs Memory MOD'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error while processing for the memory container%' THEN 'Incorrect or Corrupt Memory Mod'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%os part number%' 
             AND LOWER(r.LatestErrorFullMessage) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts in Order'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts in the Order'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%part number mn3fv not found in inventory%' THEN 'DPK Deviation - Needs to change to R3G96'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%dpk status attribute not configured%' THEN 'DPK Status attribute not configured for this service tag'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%part number r3g96 not found in inventory for service tag%' THEN 'Part Number R3G96 not found in inventory for service tag'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%part number unknown not found in inventory for service tag%' THEN 'Part Number UNKNOWN not found in inventory for service tag'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%not found in inventory for service tag%' 
             AND LOWER(r.LatestErrorFullMessage) NOT LIKE '%part number r3g96%'
             AND LOWER(r.LatestErrorFullMessage) NOT LIKE '%part number unknown%' THEN 'DPK Part Number not found in inventory; Verify correct DPK in Plus'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error from bes web service%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%system.timeoutexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%read timeout%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%the request was aborted: the request was canceled%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%system.servicemodel.communicationexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%http status 401: unauthorized%' THEN 'Webservice Authentication Error'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%could not find partsfile from gafp wcf service or local copy%' THEN 'Could not find partsFile from GAFP Wcf service or local copy'
        WHEN r.LatestErrorCode = 'OPP' OR LOWER(r.LatestErrorFullMessage) LIKE '%opp%' THEN 'Other OPP Failure'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%msg sent ok%' THEN 'Msg Sent Ok'
        ELSE 'No Message found'
    END AS [Latest Message Lookup],
    COUNT(DISTINCT r.serialNo) AS [Count of serialNo],
    -- Calculate percentage (as decimal, multiply by 100 in Power BI if needed)
    CAST(ROUND(CAST(COUNT(DISTINCT r.serialNo) AS FLOAT) / NULLIF(SUM(COUNT(DISTINCT r.serialNo)) OVER (), 0), 4) AS DECIMAL(5,4)) AS [Percentage]
FROM (
    SELECT 
        r.*,
        CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [CSTDate],
        -- Get latest error from BizTalk (full message for categorization)
        latestError.LatestErrorFullMessage,
        latestError.LatestErrorCode,
        latestError.LatestErrorMessage,
        -- Determine error status: "Encountered New Error", "Same Error", or "Resolved"
        CASE 
            -- If no initial error, can't determine
            WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
            WHEN r.initialErrorDate IS NULL THEN 'Cannot Determine'
            
            -- Check if there's ANY new error in BizTalk (not just XML)
            WHEN EXISTS (
                SELECT 1
                FROM Biztalk.dbo.Outmessage_hdr obm
                WHERE obm.Source = 'Plus'
                  AND obm.Contract = '10053'
                  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
                  AND obm.Processed = 'F'
                  AND obm.Customer_order_No = r.serialNo
                  AND obm.Insert_Date > r.initialErrorDate
            ) THEN
                -- There's a new error - try to extract and compare
                CASE 
                    -- If we successfully extracted both initial and latest error messages, compare them
                    WHEN latestError.LatestErrorMessage IS NOT NULL 
                         AND r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                         AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
                         AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14 THEN
                        -- Both are XML - extract and compare error messages (after "Failed :")
                        CASE 
                            WHEN LTRIM(SUBSTRING(
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
                            )) = latestError.LatestErrorMessage THEN 'Same Error'
                            ELSE 'Encountered New Error'
                        END
                    -- If initial error is plain text OR we can't extract latest error, any new error = "Encountered New Error"
                    ELSE 'Encountered New Error'
                END
            -- No new error = "Resolved"
            ELSE 'Resolved'
        END AS [ErrorStatus]
    FROM ClarityWarehouse.agentlogs.repair r
    OUTER APPLY (
        -- Get latest error from BizTalk (full message + extracted message)
        SELECT TOP 1
            obm.Message AS LatestErrorFullMessage,
            obm.C01 AS LatestErrorCode,
            -- Extract error message after "Failed :" for comparison
            CASE 
                WHEN obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                     AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
                     AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14 THEN
                    LTRIM(SUBSTRING(
                        SUBSTRING(obm.Message, 
                            CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                            CASE 
                                WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                ELSE 1
                            END
                        ),
                        CASE 
                            WHEN CHARINDEX('Failed :', 
                                SUBSTRING(obm.Message, 
                                    CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                    CASE 
                                        WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                        THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                        ELSE 1
                                    END
                                )) > 0 
                            THEN CHARINDEX('Failed :', 
                                SUBSTRING(obm.Message, 
                                    CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                    CASE 
                                        WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                        THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                        ELSE 1
                                    END
                                )) + 9
                            ELSE 1 
                        END,
                        200
                    ))
                WHEN obm.Message = 'Root element is missing.' THEN 'Root element is missing.'
                ELSE obm.Message
            END AS LatestErrorMessage
        FROM Biztalk.dbo.Outmessage_hdr obm
        WHERE obm.Source = 'Plus'
          AND obm.Contract = '10053'
          AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
          AND obm.Processed = 'F'
          AND obm.Customer_order_No = r.serialNo
          AND obm.Insert_Date > r.initialErrorDate
        ORDER BY obm.Insert_Date DESC
    ) AS latestError
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND r.isSuccess = 1  -- Only resolution attempts
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'
) AS r
WHERE r.ErrorStatus = 'Encountered New Error'  -- Only show cases where a new error appeared
GROUP BY 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE),
    CASE 
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%dpk quantity%' THEN 'DPK Quantity'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%root element is missing%' 
             OR r.LatestErrorFullMessage = 'Root element is missing.' THEN 'Root Element Missing'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error is 100%' THEN 'Invalid Service Tag - Error is 100'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%service tag is invalid%' THEN 'Invalid Service Tag - Flip Win8Upgrade Attribute'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%system does not contain a processor%' THEN 'Missing Processor'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%no base mod found%' THEN 'Missing Base MOD'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%ops code did not complete execution%' THEN 'SDR Generator error. Check for corrupt/bad Mods'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%sdrgenerator is unavailable%' THEN 'SDR Generator error. Check for duplicate/corrupt Mods'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%could not find an os part number for the order%' THEN 'Could not find an OS Part Number for the Order'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%no boot hard drive can be determined%' THEN 'No boot hard drive can be determined, Check for SSDR Mod with correct INFO part'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error, internal hd(s) have not been placed%' THEN 'Error, Internal HD(s) have not been placed - Check BASE and SMOD.'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%could not find an lcd for this order item when a notebook base was found%' THEN 'Missing LCD when a notebook Base is in the order'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%validation error in process: could not find the family for this order because the base part does not contain the family%' 
             OR LOWER(r.LatestErrorFullMessage) LIKE '%alidation error in process: could not find the family for this order because the base part does not contain the family%' THEN 'Missing Family: Check Base Mod'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%no memory dimms found!(0)%' THEN 'No Memory Dimms found!(0) - Needs Memory MOD'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error while processing for the memory container%' THEN 'Incorrect or Corrupt Memory Mod'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%too many processors for available sockets%' THEN 'Too many processors'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error is available quantity less than the required quantity%' THEN 'DPK Quantity'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%os part number%' 
             AND LOWER(r.LatestErrorFullMessage) NOT LIKE '%could not find an os part number for the order%' THEN 'Missing OS Part Number'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%unsupported parts found in the order level%' THEN 'Unsupported OS Parts in Order'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%there are multiple os parts in the order%' THEN 'Multiple OS Parts in the Order'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error is dpk/service tag status is invalid%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%lkm did not provided dpk%' THEN 'DPK Request Failed - Check DPK Part'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%part number mn3fv not found in inventory%' THEN 'DPK Deviation - Needs to change to R3G96'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%dpk status attribute not configured%' THEN 'DPK Status attribute not configured for this service tag'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%part number r3g96 not found in inventory for service tag%' THEN 'Part Number R3G96 not found in inventory for service tag'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%part number unknown not found in inventory for service tag%' THEN 'Part Number UNKNOWN not found in inventory for service tag'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%not found in inventory for service tag%' 
             AND LOWER(r.LatestErrorFullMessage) NOT LIKE '%part number r3g96%'
             AND LOWER(r.LatestErrorFullMessage) NOT LIKE '%part number unknown%' THEN 'DPK Part Number not found in inventory; Verify correct DPK in Plus'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%error from bes web service%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%system.timeoutexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%read timeout%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%the request was aborted: the request was canceled%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%system.servicemodel.communicationexception%' THEN 'Webservice Timeout/Request New GCF'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%http status 401: unauthorized%' THEN 'Webservice Authentication Error'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%could not find partsfile from gafp wcf service or local copy%' THEN 'Could not find partsFile from GAFP Wcf service or local copy'
        WHEN r.LatestErrorCode = 'OPP' OR LOWER(r.LatestErrorFullMessage) LIKE '%opp%' THEN 'Other OPP Failure'
        WHEN LOWER(r.LatestErrorFullMessage) LIKE '%msg sent ok%' THEN 'Msg Sent Ok'
        ELSE 'No Message found'
    END
ORDER BY 
    [Quincy Resolution Date Attempt] DESC,
    [Count of serialNo] DESC;

