-- ============================================================================
-- Quincy Interactions - Not Yet Trained to Resolve (Detail View)
-- ============================================================================
-- This query provides detailed records for drill-down functionality
-- Shows all interactions where Quincy was "Not yet trained to resolve"
-- Filter by Date in Power BI for drill-through
-- ============================================================================

SELECT 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) AS [Date],
    r.serialNo AS [SerialNumber],
    r.createDate AS [QuincyInteractionTime],
    r.initialErrorDate AS [InitialErrorDate],
    -- Extract initial error message for context
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
        WHEN r.initialError IS NOT NULL AND r.initialError NOT LIKE '%<%' THEN
            LTRIM(RTRIM(LEFT(r.initialError, 200)))
        ELSE NULL
    END AS [InitialError],
    -- Full log for reference (truncated if too long)
    CASE 
        WHEN LEN(r.log) > 500 THEN LEFT(r.log, 500) + '...'
        ELSE r.log
    END AS [LogPreview],
    r.isSuccess AS [IsSuccess],
    r.woHeaderID AS [WorkOrderID],
    r.partNo AS [PartNumber]
FROM ClarityWarehouse.agentlogs.repair r
WHERE r.programID = 10053
    AND r.agentName = 'quincy'
    AND r.isSuccess = 0  -- No resolution attempt
    AND r.log LIKE '%"error":"Unknown error, not trained to resolve."%'
    -- Date filter will be applied in Power BI via drill-through or slicer
ORDER BY 
    CAST(DATEADD(HOUR, -6, r.createDate) AS DATE) DESC,
    r.createDate DESC;

