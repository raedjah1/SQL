-- Find the exact row structure matching the image data
-- Image shows: FSR25063, 4757541, 6/27/2025, NEW, 3726117, 79182272627.00, 7/7/2025, 0, NULL, 200

-- Check if this matches docklog.sql structure
SELECT
    rh.CustomerReference AS ASN,
    dl.ID AS DockLogID,
    CAST(dl.CreateDate AS DATE) AS DockLogDate,
    cs.Description AS ASNStatus,
    rh.ID AS ROHeaderID,
    dl.TrackingNo,
    CAST(COALESCE(lastROLine.CreateDate, GETDATE()) AS DATE) AS ASNProcessedDate,
    CASE WHEN lastROLine.CreateDate IS NULL THEN 0 ELSE 1 END AS WasProcessed,
    NULL AS SomeField,
    SUM(rl.QtyToReceive) AS ExpectedQty
FROM Plus.pls.ROHeader rh
JOIN Plus.pls.CodeStatus cs ON cs.ID = rh.StatusID
JOIN Plus.pls.RODockLog dl ON dl.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.ROLine rl ON rl.ROHeaderID = rh.ID
OUTER APPLY (
    SELECT TOP 1 rl_last.CreateDate
    FROM Plus.pls.ROLine rl_last
    WHERE rl_last.ROHeaderID = rh.ID
    ORDER BY rl_last.ID DESC
) lastROLine
WHERE rh.CustomerReference = 'FSR25063'
  AND rh.ProgramID = 10068
GROUP BY 
    rh.CustomerReference,
    dl.ID,
    dl.CreateDate,
    cs.Description,
    rh.ID,
    dl.TrackingNo,
    lastROLine.CreateDate;

