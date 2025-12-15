-- ============================================================================
-- INVESTIGATION: "Msg Sent Ok" Messages in BizTalk for 11/14/2025
-- ============================================================================
-- This query shows what "Msg Sent Ok" messages actually look like in BizTalk
-- to verify our pattern matching is correct
-- ============================================================================

-- Detail: All "Msg Sent Ok" messages for 11/14/2025
SELECT 
    CAST(obm.Insert_Date AS DATE) AS [Date],
    obm.Insert_Date AS [Timestamp],
    obm.Customer_order_No AS [WorkOrder],
    obm.Message_Type,
    obm.Processed,
    obm.C01 AS [ErrorCode],
    -- Check if our pattern matches
    CASE 
        WHEN LOWER(obm.Message) LIKE '%msg sent ok%' THEN 'YES - Matches pattern'
        ELSE 'NO - Does not match'
    END AS [PatternMatch],
    -- Show a preview of the message (first 500 chars)
    LEFT(obm.Message, 500) AS [MessagePreview],
    -- Show full message
    obm.Message AS [FullMessage]
FROM Biztalk.dbo.Outmessage_hdr obm
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND CAST(obm.Insert_Date AS DATE) = '2025-11-14'
  AND LOWER(obm.Message) LIKE '%msg sent ok%'
ORDER BY obm.Insert_Date DESC;

-- Summary: Count by different patterns to see variations
SELECT 
    CASE 
        WHEN LOWER(obm.Message) LIKE '%msg sent ok%' THEN 'Msg Sent Ok (our pattern)'
        WHEN LOWER(obm.Message) LIKE '%message sent ok%' THEN 'Message Sent Ok'
        WHEN LOWER(obm.Message) LIKE '%sent ok%' THEN 'Sent Ok (without Msg)'
        WHEN LOWER(obm.Message) LIKE '%ok%' AND obm.Message NOT LIKE '%fail%' THEN 'Contains OK (but not our pattern)'
        ELSE 'Other'
    END AS [PatternType],
    COUNT(*) AS [Count],
    -- Show a sample message for each pattern
    MAX(LEFT(obm.Message, 200)) AS [SampleMessage]
FROM Biztalk.dbo.Outmessage_hdr obm
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND CAST(obm.Insert_Date AS DATE) = '2025-11-14'
  AND (
      LOWER(obm.Message) LIKE '%msg sent ok%'
      OR LOWER(obm.Message) LIKE '%message sent ok%'
      OR LOWER(obm.Message) LIKE '%sent ok%'
      OR (LOWER(obm.Message) LIKE '%ok%' AND LOWER(obm.Message) NOT LIKE '%fail%')
  )
GROUP BY 
    CASE 
        WHEN LOWER(obm.Message) LIKE '%msg sent ok%' THEN 'Msg Sent Ok (our pattern)'
        WHEN LOWER(obm.Message) LIKE '%message sent ok%' THEN 'Message Sent Ok'
        WHEN LOWER(obm.Message) LIKE '%sent ok%' THEN 'Sent Ok (without Msg)'
        WHEN LOWER(obm.Message) LIKE '%ok%' AND obm.Message NOT LIKE '%fail%' THEN 'Contains OK (but not our pattern)'
        ELSE 'Other'
    END
ORDER BY [Count] DESC;

-- Check: How many "Msg Sent Ok" messages correspond to Quincy fix attempts on 11/14/2025?
SELECT 
    'Msg Sent Ok for 11/14/2025 Quincy Fix Attempts' AS [Check],
    COUNT(*) AS [TotalMsgSentOk],
    COUNT(DISTINCT obm.Customer_order_No) AS [DistinctWorkOrders],
    -- Show breakdown by time
    MIN(obm.Insert_Date) AS [EarliestMsgSentOk],
    MAX(obm.Insert_Date) AS [LatestMsgSentOk]
FROM Biztalk.dbo.Outmessage_hdr obm
INNER JOIN ClarityWarehouse.agentlogs.repair r
    ON r.serialNo = obm.Customer_order_No
    AND r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 1
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
WHERE obm.Source = 'Plus'
  AND obm.Contract = '10053'
  AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
  AND obm.Processed = 'F'
  AND LOWER(obm.Message) LIKE '%msg sent ok%'
  AND obm.Insert_Date > r.createDate;  -- After Quincy attempt time

-- Detail: Show the relationship between Quincy attempts and "Msg Sent Ok" messages
SELECT 
    r.serialNo AS [WorkOrder],
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [QuincyResolutionDate],
    r.createDate AS [QuincyAttemptTime],
    r.initialErrorDate AS [InitialErrorDate],
    obm.Insert_Date AS [MsgSentOkTime],
    DATEDIFF(HOUR, r.createDate, obm.Insert_Date) AS [HoursAfterQuincyAttempt],
    LEFT(obm.Message, 300) AS [MsgSentOkPreview]
FROM ClarityWarehouse.agentlogs.repair r
INNER JOIN Biztalk.dbo.Outmessage_hdr obm
    ON obm.Customer_order_No = r.serialNo
    AND obm.Source = 'Plus'
    AND obm.Contract = '10053'
    AND obm.Message_Type IN ('DellARB-GCF_V4', 'DellARB-GCF_V3')
    AND obm.Processed = 'F'
    AND LOWER(obm.Message) LIKE '%msg sent ok%'
    AND obm.Insert_Date > r.createDate
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 1
    AND CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) = '2025-11-14'
ORDER BY r.createDate, obm.Insert_Date;

