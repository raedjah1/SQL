-- ============================================================================
-- ALL SCREENS FOR PROGRAM 10068 - USING DataEntryScript TABLE
-- Shows all screen details for DataEntryScriptIDs used in program 10068
-- ============================================================================
SELECT 
    des.ID,
    des.Name,
    des.InputFields,
    des.ExecuteQuery,
    des.Info,
    des.CreateDate,
    des.LastActivityDate,
    usage.UsageCount,
    usage.LastUsed
FROM pls.DataEntryScript des
INNER JOIN (
    SELECT DISTINCT 
        DataEntryScriptID,
        COUNT(*) AS UsageCount,
        MAX(CreateDate) AS LastUsed
    FROM pls.DataEntry 
    WHERE ProgramID = 10068
    GROUP BY DataEntryScriptID
) usage ON usage.DataEntryScriptID = des.ID
ORDER BY usage.UsageCount DESC, des.Name;