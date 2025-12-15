-- ============================================================================
-- GCF QUINCY TEST QUERIES - For Debugging and Validation
-- ============================================================================

-- ============================================================================
-- Query 1: Count attempts per serial number per date (SUMMARY)
-- ============================================================================
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    COUNT(*) AS [TotalAttempts],
    MIN(r.createDate) AS [FirstAttemptTime],
    MAX(r.createDate) AS [LastAttemptTime]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
GROUP BY r.serialNo, CAST(r.createDate AS DATE)
HAVING COUNT(*) > 1  -- Only show serial numbers with multiple attempts
ORDER BY COUNT(*) DESC, r.serialNo;

-- ============================================================================
-- Query 2: Show ALL attempts for a specific serial number (DETAIL)
-- ============================================================================
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate ASC) AS [AttemptNumber],
    r.createDate AS [AttemptTime],
    r.isSuccess,
    CASE 
        WHEN r.isSuccess = 1 THEN 'Success'
        ELSE 'Failed'
    END AS [Status],
    -- Show if initialError has XML or is plain text
    CASE 
        WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' THEN 'XML'
        WHEN r.initialError IS NOT NULL AND LEN(LTRIM(RTRIM(r.initialError))) > 0 THEN 'Plain Text'
        ELSE 'NULL'
    END AS [ErrorType],
    LEFT(r.initialError, 100) AS [InitialErrorPreview]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.serialNo = '27TG794'  -- <-- CHANGE THIS
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
ORDER BY r.createDate ASC;

-- ============================================================================
-- Query 3: Find serial numbers with plain text errors (no XML)
-- ============================================================================
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    r.createDate AS [AttemptTime],
    r.initialError AS [PlainTextError],
    r.isSuccess,
    r.log
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.initialError IS NOT NULL
    AND r.initialError NOT LIKE '%<STATUSREASON>%</STATUSREASON>%'
    AND LEN(LTRIM(RTRIM(r.initialError))) > 0
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
ORDER BY r.createDate DESC;

-- ============================================================================
-- Query 4: Compare first vs last attempt for serial numbers with multiple attempts
-- ============================================================================
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    CASE 
        WHEN RowNum_First = 1 THEN 'First'
        WHEN RowNum_Last = 1 THEN 'Last'
    END AS [AttemptType],
    r.createDate AS [AttemptTime],
    r.isSuccess,
    CASE 
        WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' THEN 'XML'
        WHEN r.initialError IS NOT NULL AND LEN(LTRIM(RTRIM(r.initialError))) > 0 THEN 'Plain Text'
        ELSE 'NULL'
    END AS [ErrorType],
    LEFT(r.initialError, 150) AS [InitialErrorPreview]
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate ASC) AS RowNum_First,
        ROW_NUMBER() OVER (PARTITION BY r.serialNo, CAST(r.createDate AS DATE) ORDER BY r.createDate DESC) AS RowNum_Last
    FROM ClarityWarehouse.agentlogs.repair r
    WHERE r.programID = 10053
        AND r.agentName = 'quincy'
        AND CAST(r.createDate AS DATE) >= '2025-11-19'
        AND CAST(r.createDate AS DATE) <= '2025-11-19'
) AS r
WHERE (RowNum_First = 1 OR RowNum_Last = 1)
    AND EXISTS (
        SELECT 1 
        FROM ClarityWarehouse.agentlogs.repair r2
        WHERE r2.programID = 10053
            AND r2.agentName = 'quincy'
            AND r2.serialNo = r.serialNo
            AND CAST(r2.createDate AS DATE) = CAST(r.createDate AS DATE)
        GROUP BY r2.serialNo, CAST(r2.createDate AS DATE)
        HAVING COUNT(*) > 1
    )
ORDER BY r.serialNo, CAST(r.createDate AS DATE), r.createDate ASC;

-- ============================================================================
-- Query 5: Check BizTalk errors for a specific serial number
-- ============================================================================
SELECT 
    obm.Customer_order_No AS [SerialNo],
    obm.Insert_Date AS [ErrorDate],
    obm.Message_Type,
    obm.Processed,
    -- Extract STATUSREASON
    CASE 
        WHEN obm.Message LIKE '%<STATUSREASON>%</STATUSREASON>%' 
             AND CHARINDEX('<STATUSREASON>', obm.Message) > 0
             AND CHARINDEX('</STATUSREASON>', obm.Message) > CHARINDEX('<STATUSREASON>', obm.Message) + 14 THEN
            LEFT(SUBSTRING(
                obm.Message,
                CHARINDEX('<STATUSREASON>', obm.Message) + 14,
                CHARINDEX('</STATUSREASON>', obm.Message) - CHARINDEX('<STATUSREASON>', obm.Message) - 14
            ), 200)
        ELSE NULL
    END AS [STATUSREASON]
FROM Biztalk.dbo.Outmessage_hdr obm
WHERE obm.Source = 'Plus'
    AND obm.Contract = '10053'
    AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
    AND obm.Processed = 'F'
    AND obm.Customer_order_No = '27TG794'  -- <-- CHANGE THIS
ORDER BY obm.Insert_Date DESC;

-- ============================================================================
-- Query 6: Find serial numbers where initialErrorDate is NULL
-- ============================================================================
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    r.createDate AS [AttemptTime],
    r.initialError,
    r.initialErrorDate,
    r.isSuccess
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.initialErrorDate IS NULL
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
ORDER BY r.createDate DESC;

-- ============================================================================
-- Query 7: Find serial numbers with "Cannot Determine" status (for debugging)
-- ============================================================================
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    r.createDate AS [AttemptTime],
    r.initialError,
    r.initialErrorDate,
    CASE 
        WHEN r.initialError IS NULL OR LEN(LTRIM(RTRIM(r.initialError))) = 0 THEN 'NULL or Empty'
        WHEN r.initialError NOT LIKE '%<STATUSREASON>%</STATUSREASON>%' THEN 'No XML Tags'
        WHEN CHARINDEX('<STATUSREASON>', r.initialError) = 0 THEN 'STATUSREASON tag not found'
        WHEN CHARINDEX('</STATUSREASON>', r.initialError) <= CHARINDEX('<STATUSREASON>', r.initialError) THEN 'Invalid tag order'
        ELSE 'Other'
    END AS [ReasonForCannotDetermine]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND (
        r.initialError IS NULL 
        OR LEN(LTRIM(RTRIM(r.initialError))) = 0
        OR r.initialError NOT LIKE '%<STATUSREASON>%</STATUSREASON>%'
        OR CHARINDEX('<STATUSREASON>', r.initialError) = 0
        OR CHARINDEX('</STATUSREASON>', r.initialError) <= CHARINDEX('<STATUSREASON>', r.initialError)
    )
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
ORDER BY r.createDate DESC;

-- ============================================================================
-- Query 8: Summary by Log Translation category
-- ============================================================================
SELECT 
    CAST(r.createDate AS DATE) AS [Date],
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
    END AS [LogTranslation],
    COUNT(DISTINCT r.serialNo) AS [DistinctSerialNumbers],
    COUNT(*) AS [TotalAttempts]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
GROUP BY CAST(r.createDate AS DATE),
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
    END
ORDER BY [Date] DESC, [LogTranslation];

-- ============================================================================
-- Query 9: Find serial numbers with most attempts (top 20)
-- ============================================================================
SELECT TOP 20
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    COUNT(*) AS [TotalAttempts],
    MIN(r.createDate) AS [FirstAttempt],
    MAX(r.createDate) AS [LastAttempt],
    DATEDIFF(MINUTE, MIN(r.createDate), MAX(r.createDate)) AS [MinutesBetweenFirstAndLast]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
GROUP BY r.serialNo, CAST(r.createDate AS DATE)
ORDER BY COUNT(*) DESC;

-- ============================================================================
-- Query 10: Check for serial numbers with both XML and plain text errors on same date
-- ============================================================================
SELECT 
    r.serialNo,
    CAST(r.createDate AS DATE) AS [Date],
    COUNT(*) AS [TotalAttempts],
    SUM(CASE WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' THEN 1 ELSE 0 END) AS [XMLErrors],
    SUM(CASE WHEN r.initialError IS NOT NULL 
             AND r.initialError NOT LIKE '%<STATUSREASON>%</STATUSREASON>%' 
             AND LEN(LTRIM(RTRIM(r.initialError))) > 0 THEN 1 ELSE 0 END) AS [PlainTextErrors]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND CAST(r.createDate AS DATE) >= '2025-11-19'
    AND CAST(r.createDate AS DATE) <= '2025-11-19'
GROUP BY r.serialNo, CAST(r.createDate AS DATE)
HAVING SUM(CASE WHEN r.initialError LIKE '%<STATUSREASON>%</STATUSREASON>%' THEN 1 ELSE 0 END) > 0
   AND SUM(CASE WHEN r.initialError IS NOT NULL 
                AND r.initialError NOT LIKE '%<STATUSREASON>%</STATUSREASON>%' 
                AND LEN(LTRIM(RTRIM(r.initialError))) > 0 THEN 1 ELSE 0 END) > 0
ORDER BY r.serialNo;

