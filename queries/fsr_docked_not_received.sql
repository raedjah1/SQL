-- FSR ASNs that have been dock logged but not received yet
SELECT
    rh.CustomerReference AS ASN,
    rh.ID AS ROHeaderID,
    rh.CreateDate AS ASNCreateDate,
    cs.Description AS ASNStatus,
    
    -- Dock Log Info
    dl.ID AS DockLogID,
    dl.TrackingNo,
    dl.CreateDate AS DockLogDate,
    
    -- Expected quantities
    COUNT(DISTINCT rl.ID) AS ExpectedLineCount,
    SUM(rl.QtyToReceive) AS ExpectedTotalQty,
    
    -- Days since dock logged
    DATEDIFF(DAY, dl.CreateDate, GETDATE()) AS DaysSinceDockLogged

FROM Plus.pls.ROHeader rh
JOIN Plus.pls.CodeStatus cs ON cs.ID = rh.StatusID
JOIN Plus.pls.RODockLog dl ON dl.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.ROLine rl ON rl.ROHeaderID = rh.ID
WHERE rh.ProgramID = 10068
  AND rh.CustomerReference LIKE 'FSR%'
  -- Ensure NO receipt transactions exist at all (check all linking paths)
  AND NOT EXISTS (
      SELECT 1
      FROM Plus.pls.PartTransaction pt
      JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
      WHERE pt.ProgramID = 10068
        AND cpt.Description = 'RO-RECEIVE'
        AND (
            pt.OrderHeaderID = rh.ID  -- Linked via ROHeader
            OR pt.RODockLogID = dl.ID  -- Linked via DockLog
            OR pt.CustomerReference = rh.CustomerReference  -- Linked via ASN
        )
  )
GROUP BY 
    rh.CustomerReference,
    rh.ID,
    rh.CreateDate,
    cs.Description,
    dl.ID,
    dl.TrackingNo,
    dl.CreateDate
ORDER BY dl.CreateDate DESC;

