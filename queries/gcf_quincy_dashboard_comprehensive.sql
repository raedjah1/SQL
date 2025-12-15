-- ============================================================================
-- GCF QUINCY DASHBOARD - Comprehensive Detail View
-- Matching Excel Detail View with All Calculated Fields
-- ============================================================================
-- Includes:
-- - All Quincy repair fields
-- - STATUSREASON extraction from XML
-- - Date conversions (CST)
-- - End of Week calculations
-- - Lookup Key (serialNo | date)
-- - Latest GCF error from BizTalk
-- - Error comparison (Same Error, Different Error, Resolved)
-- - Log Translation categorization
-- ============================================================================

SELECT 
    r.agentName,
    r.programID,
    r.woHeaderID,
    r.partNo,
    r.serialNo,
    r.createDate,
    r.initialError,
    r.initialErrorDate,
    r.isSuccess,
    r.log,
    -- Convert to CST (assuming createDate is in UTC, subtract 6 hours for CST)
    DATEADD(HOUR, -6, r.createDate) AS [Convert to CST],
    -- Quincy Resolution Date Attempt (date only, in CST)
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Quincy Resolution Date Attempt],
    -- Quincy Attempt EOW (End of Week - Friday of that week, in CST)
    -- Calculate Friday of the week (week starts Monday, Friday is day 5)
    DATEADD(DAY, (5 - (DATEPART(WEEKDAY, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)) + 5) % 7), CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)) AS [Quincy Attempt EOW],
    -- Extract Fail Category from STATUSREASON in initialError XML (just the error message after "Failed :")
    -- If no XML, use the plain text error message (like "Root element is missing.")
    CASE 
        WHEN r.initialError IS NOT NULL
             AND r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
             AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
             AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14 THEN
            -- Extract STATUSREASON content safely (XML format)
            LTRIM(
                CASE 
                    WHEN CHARINDEX('Failed :', 
                        SUBSTRING(r.initialError, 
                            CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                            CASE 
                                WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                ELSE 1
                            END
                        )) > 0 THEN
                        SUBSTRING(
                            SUBSTRING(r.initialError, 
                                CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                                CASE 
                                    WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                    THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                    ELSE 1
                                END
                            ),
                            CHARINDEX('Failed :', 
                                SUBSTRING(r.initialError, 
                                    CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                                    CASE 
                                        WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                        THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                        ELSE 1
                                    END
                                )
                            ) + 9,
                            200
                        )
                    ELSE 
                        SUBSTRING(r.initialError, 
                            CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                            CASE 
                                WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                ELSE 1
                            END
                        )
                END
            )
        WHEN r.initialError IS NOT NULL 
             AND LEN(LTRIM(RTRIM(r.initialError))) > 0 
             AND r.initialError NOT LIKE '%<%' THEN
            -- Plain text error (no XML tags) - use the text itself, clean it up
            LTRIM(RTRIM(
                CASE 
                    WHEN LEN(r.initialError) > 100 THEN LEFT(r.initialError, 100) + '...'
                    ELSE r.initialError
                END
            ))
        ELSE NULL
    END AS [Fail Category],
    -- Log Translation (matching Excel formula)
    CASE 
        WHEN r.isSuccess = 1 THEN 'Quincy Resolution Attempt'
        WHEN r.log LIKE '%Not trained to resolve%' THEN 'Not yet trained to resolve'
        WHEN r.log LIKE '%No repair parts found%' THEN 'No repair parts found'
        WHEN r.log LIKE '%Unit does not have a work order created yet%' THEN 'Unit does not have a work order created yet'
        WHEN r.log LIKE '%Could not find any GCF errors in B2B outbound data%' THEN 'Could not find any GCF errors in B2B outbound data'
        WHEN r.log LIKE '%No inventory parts were found%' THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
        WHEN r.log LIKE '%Attempted too many times to fix%' THEN 'Attempted too many times'
        WHEN r.log LIKE '%Unit does not have PartSerial entry%' THEN 'Unable to locate a unit for reference'
        WHEN r.log LIKE '%No required MODs found from pre-existing family%' THEN 'Unable to locate a unit for reference'
        WHEN r.log LIKE '%No pre-existing family found%' THEN 'Unit does not have PartSerial entry'
        WHEN r.log LIKE '%Unit is not in%' THEN 'Routing Errors'
        WHEN r.log LIKE '%Could not find route/location%' THEN 'Routing Errors'
        WHEN r.log LIKE '%Unit is not in correct ReImage%' THEN 'Routing Errors'
        WHEN r.log LIKE '%No route found%' THEN 'Routing Errors'
        ELSE 'Error not yet defined'
    END AS [Log Translation],
    -- Lookup Key (serialNo | date in Excel serial number format, using CST date)
    r.serialNo + ' | ' + CAST(CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS VARCHAR) AS [Lookup Key],
    -- Latest Error Date - Get date of latest GCF error from BizTalk (after initial error)
    (SELECT TOP 1 CAST(obm.Insert_Date AS DATE)
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Processed = 'F'
       AND obm.Customer_order_No = r.serialNo
       AND obm.Insert_Date > r.initialErrorDate
     ORDER BY obm.Insert_Date DESC
    ) AS [Latest Error Date],
    -- Latest Message Lookup - Get latest GCF error message (after "Failed :") from BizTalk
    (SELECT TOP 1
        CASE 
            WHEN obm.Message IS NOT NULL
                 AND obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                 AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
                 AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14 THEN
                -- Extract STATUSREASON content safely
                LTRIM(
                    CASE 
                        WHEN CHARINDEX('Failed :', 
                            SUBSTRING(obm.Message, 
                                CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                CASE 
                                    WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                    THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                    ELSE 1
                                END
                            )) > 0 THEN
                            SUBSTRING(
                                SUBSTRING(obm.Message, 
                                    CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                    CASE 
                                        WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                        THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                        ELSE 1
                                    END
                                ),
                                CHARINDEX('Failed :', 
                                    SUBSTRING(obm.Message, 
                                        CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                        CASE 
                                            WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                            THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                            ELSE 1
                                        END
                                    )
                                ) + 9,
                                200
                            )
                        ELSE 
                            SUBSTRING(obm.Message, 
                                CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                CASE 
                                    WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                    THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                    ELSE 1
                                END
                            )
                    END
                )
            ELSE NULL
        END
     FROM Biztalk.dbo.Outmessage_hdr obm
     WHERE obm.Source = 'Plus'
       AND obm.Contract = '10053'
       AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
       AND obm.Processed = 'F'
       AND obm.Customer_order_No = r.serialNo
       AND obm.Insert_Date > r.initialErrorDate  -- Only errors after initial error
     ORDER BY obm.Insert_Date DESC
    ) AS [Latest Message Lookup],
    -- New Error Check - Simple flag if there's a new error after initial error
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Biztalk.dbo.Outmessage_hdr obm
            WHERE obm.Source = 'Plus'
              AND obm.Contract = '10053'
              AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
              AND obm.Processed = 'F'
              AND obm.Customer_order_No = r.serialNo
              AND obm.Insert_Date > r.initialErrorDate
        ) THEN 'New Error'
        ELSE 'No New Error'
    END AS [New Error Check],
    -- Same Error, Different Error or Resolved
    -- Excel logic: Get latest error from BizTalk, compare to initial error
    -- If latest error is different → "Encountered New Error"
    -- If latest error is same → "Same Error"  
    -- If no latest error or latest is before initial → "Resolved"
    CASE 
        -- If no initial error at all, can't compare
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'Cannot Determine'
        
        ELSE
            -- Check if there's a new error in BizTalk after initial error date
            CASE 
                WHEN EXISTS (
                    SELECT 1
                    FROM Biztalk.dbo.Outmessage_hdr obm
                    WHERE obm.Source = 'Plus'
                      AND obm.Contract = '10053'
                      AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
                      AND obm.Processed = 'F'
                      AND obm.Customer_order_No = r.serialNo
                      AND obm.Insert_Date > r.initialErrorDate  -- Check by datetime, not just date
                ) THEN
                    -- Compare initial error vs latest error
                    -- If initial error is XML, extract and compare error messages
                    -- If initial error is plain text, any new error = "Encountered New Error"
                    CASE 
                        -- If initial error has XML STATUSREASON, compare extracted error messages
                        WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                             AND CHARINDEX('<STATUSREASON>', r.initialError) > 0
                             AND CHARINDEX('</STATUSREASON>', r.initialError) > CHARINDEX('<STATUSREASON>', r.initialError) + 14 THEN
                            -- Compare extracted error messages
                            CASE 
                                WHEN (
                            -- Initial error message (after "Failed :")
                            LTRIM(
                                CASE 
                                    WHEN CHARINDEX('Failed :', 
                                        SUBSTRING(r.initialError, 
                                            CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                                            CASE 
                                                WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                                THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                                ELSE 1
                                            END
                                        )) > 0 THEN
                                        SUBSTRING(
                                            SUBSTRING(r.initialError, 
                                                CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                                                CASE 
                                                    WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                                    THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                                    ELSE 1
                                                END
                                            ),
                                            CHARINDEX('Failed :', 
                                                SUBSTRING(r.initialError, 
                                                    CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                                                    CASE 
                                                        WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                                        THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                                        ELSE 1
                                                    END
                                                )
                                            ) + 9,
                                            200
                                        )
                                    ELSE 
                                        SUBSTRING(r.initialError, 
                                            CHARINDEX('<STATUSREASON>', r.initialError) + 14, 
                                            CASE 
                                                WHEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14 > 0 
                                                THEN CHARINDEX('</STATUSREASON>', r.initialError) - CHARINDEX('<STATUSREASON>', r.initialError) - 14
                                                ELSE 1
                                            END
                                        )
                                END
                            ) = 
                            -- Latest error message (after "Failed :")
                            (SELECT TOP 1
                                LTRIM(
                                    CASE 
                                        WHEN obm.Message IS NOT NULL
                                             AND CHARINDEX('Failed :', 
                                                SUBSTRING(obm.Message, 
                                                    CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                                    CASE 
                                                        WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                                        THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                                        ELSE 1
                                                    END
                                                )) > 0 THEN
                                            SUBSTRING(
                                                SUBSTRING(obm.Message, 
                                                    CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                                    CASE 
                                                        WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                                        THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                                        ELSE 1
                                                    END
                                                ),
                                                CHARINDEX('Failed :', 
                                                    SUBSTRING(obm.Message, 
                                                        CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                                        CASE 
                                                            WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                                            THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                                            ELSE 1
                                                        END
                                                    )
                                                ) + 9,
                                                200
                                            )
                                        ELSE 
                                            SUBSTRING(obm.Message, 
                                                CHARINDEX('<STATUSREASON>', obm.Message) + 14, 
                                                CASE 
                                                    WHEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14 > 0 
                                                    THEN CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
                                                    ELSE 1
                                                END
                                            )
                                    END
                                )
                             FROM Biztalk.dbo.Outmessage_hdr obm
                             WHERE obm.Source = 'Plus'
                               AND obm.Contract = '10053'
                               AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
                               AND obm.Processed = 'F'
                               AND obm.Customer_order_No = r.serialNo
                               AND obm.Insert_Date > r.initialErrorDate  -- After initial error time
                             ORDER BY obm.Insert_Date DESC
                            )
                        ) THEN 'Same Error'
                        ELSE 'Encountered New Error'
                    END
                        -- If initial error is plain text (not XML), any new error = "Encountered New Error"
                        ELSE 'Encountered New Error'
                    END
                ELSE 'Resolved'
            END
    END AS [Same Error, Different Error or Resolved],
    -- Indicate if this is the first or last attempt for this serial number on this date
    r.AttemptType
FROM (
    SELECT 
        r.*,
        -- Convert to CST for date partitioning
        CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [CSTDate],
        -- Get FIRST record per serial number per CST date
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) ORDER BY r.createDate ASC) AS RowNum_First,
        -- Get LAST record per serial number per CST date
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) ORDER BY r.createDate DESC) AS RowNum_Last,
        -- Calculate total attempts for this serial number on this CST date
        COUNT(*) OVER (PARTITION BY r.serialNo, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE)) AS TotalAttempts,
        -- Indicate attempt type
        CASE 
            WHEN ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) ORDER BY r.createDate ASC) = 1 
                 AND ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) ORDER BY r.createDate DESC) = 1 
            THEN 'Only Attempt'
            WHEN ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) ORDER BY r.createDate ASC) = 1 
            THEN 'First Attempt'
            WHEN ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) ORDER BY r.createDate DESC) = 1 
            THEN 'Last Attempt'
            ELSE 'Middle Attempt'
        END AS AttemptType
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'  -- Filter by CST date
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'  -- Filter by CST date
) AS r
WHERE r.RowNum_First = 1 OR r.RowNum_Last = 1  -- Show both first AND last record per serial number per CST date
ORDER BY r.CSTDate DESC, r.serialNo, 
    CASE WHEN r.AttemptType = 'First Attempt' THEN 1 WHEN r.AttemptType = 'Last Attempt' THEN 2 ELSE 3 END;

-- ============================================================================
-- SUMMARY QUERY - By Date and Category (for pivot table)
-- NOTE: Summary uses CST date filtering and DISTINCT serialNo to match Excel
-- ============================================================================
SELECT 
    CAST(DATEADD(HOUR, -6, createDate) AS DATE) AS [Quincy Resolution Date Attempt],
    CASE 
        WHEN isSuccess = 1 THEN 'Quincy Resolution Attempt'
        WHEN log LIKE '%Not trained to resolve%' OR log LIKE '%not trained to resolve%' THEN 'Not yet trained to resolve'
        WHEN log LIKE '%No repair parts found%' THEN 'No repair parts found'
        WHEN log LIKE '%Unit does not have a work order created yet%' THEN 'Unit does not have a work order created yet'
        WHEN log LIKE '%Could not find any GCF errors in B2B outbound data%' THEN 'Could not find any GCF errors in B2B outbound data'
        WHEN log LIKE '%No inventory parts were found%' THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
        WHEN log LIKE '%Attempted too many times to fix%' THEN 'Attempted too many times'
        WHEN log LIKE '%Unit does not have PartSerial entry%' THEN 'Unable to locate a unit for reference'
        WHEN log LIKE '%No required MODs found from pre-existing family%' THEN 'Unable to locate a unit for reference'
        WHEN log LIKE '%No pre-existing family found%' THEN 'Unit does not have PartSerial entry'
        WHEN log LIKE '%Unit is not in%' THEN 'Routing Errors'
        WHEN log LIKE '%Could not find route/location%' THEN 'Routing Errors'
        WHEN log LIKE '%Unit is not in correct ReImage%' THEN 'Routing Errors'
        WHEN log LIKE '%No route found%' THEN 'Routing Errors'
        ELSE 'Error not yet defined'
    END AS [Log Translation],
    COUNT(DISTINCT CASE WHEN isSuccess = 1 THEN serialNo END) AS [Fix Attempt],
    COUNT(DISTINCT CASE WHEN isSuccess != 1 THEN serialNo END) AS [No Fix Attempt],
    COUNT(DISTINCT serialNo) AS [Grand Total]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) ORDER BY r.createDate ASC) AS RowNum
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) >= '2025-11-08'  -- Filter by CST date
        AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) <= '2025-11-19'  -- Filter by CST date
) AS RankedRecords
WHERE RowNum = 1  -- Only first attempt per serial number per CST date
GROUP BY CAST(DATEADD(HOUR, -6, createDate) AS DATE),
    CASE 
        WHEN isSuccess = 1 THEN 'Quincy Resolution Attempt'
        WHEN log LIKE '%Not trained to resolve%' OR log LIKE '%not trained to resolve%' THEN 'Not yet trained to resolve'
        WHEN log LIKE '%No repair parts found%' THEN 'No repair parts found'
        WHEN log LIKE '%Unit does not have a work order created yet%' THEN 'Unit does not have a work order created yet'
        WHEN log LIKE '%Could not find any GCF errors in B2B outbound data%' THEN 'Could not find any GCF errors in B2B outbound data'
        WHEN log LIKE '%No inventory parts were found%' THEN 'No inventory parts were found, likely incorrect route location or failed GTO call'
        WHEN log LIKE '%Attempted too many times to fix%' THEN 'Attempted too many times'
        WHEN log LIKE '%Unit does not have PartSerial entry%' THEN 'Unable to locate a unit for reference'
        WHEN log LIKE '%No required MODs found from pre-existing family%' THEN 'Unable to locate a unit for reference'
        WHEN log LIKE '%No pre-existing family found%' THEN 'Unit does not have PartSerial entry'
        WHEN log LIKE '%Unit is not in%' THEN 'Routing Errors'
        WHEN log LIKE '%Could not find route/location%' THEN 'Routing Errors'
        WHEN log LIKE '%Unit is not in correct ReImage%' THEN 'Routing Errors'
        WHEN log LIKE '%No route found%' THEN 'Routing Errors'
        ELSE 'Error not yet defined'
    END
ORDER BY [Quincy Resolution Date Attempt] DESC, [Log Translation];

