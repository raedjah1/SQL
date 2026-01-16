-- All transactions for ProgramID 10053 from Jan 1, 2025 to Jan 1, 2026
-- Filtered for transactions going TO Discrepancy or Finished Goods locations

SELECT
    pt.ID,
    pt.ProgramID,
    cpt.Description AS PartTransaction,
    pt.PartNo,
    pt.SerialNo,
    pt.Qty,
    pt.Source,
    pt.Condition,
    pt.Configuration,
    pt.Location,
    pt.ToLocation,
    pt.PalletBoxNo,
    pt.ToPalletBoxNo,
    pt.LotNo,
    pt.Reason,
    pt.CustomerReference,
    pt.OrderType,
    pt.OrderHeaderID,
    pt.OrderLineID,
    pt.RODockLogID,
    u.Username,
    pt.CreateDate,
    pt.ForDate,
    pt.ForYear,
    pt.ForMonth,
    pt.ForWeek,
    pt.ForQuarter,
    -- Flag for Discrepancy
    CASE 
        WHEN cpt.Description = 'WH-DISCREPANCYRECEIVE' 
             OR UPPER(pt.ToLocation) LIKE 'DISCREPANCY%'
             OR UPPER(pt.ToLocation) LIKE 'DISCRE.%'
        THEN 1 
        ELSE 0 
    END AS IsDiscrepancy,
    -- Flag for Finished Goods
    CASE 
        WHEN UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS%'
             OR UPPER(pt.ToLocation) LIKE 'FGI%'
        THEN 1 
        ELSE 0 
    END AS IsFinishedGoods
FROM Plus.pls.PartTransaction AS pt
INNER JOIN Plus.pls.CodePartTransaction AS cpt 
    ON cpt.ID = pt.PartTransactionID
LEFT JOIN Plus.pls.[User] AS u 
    ON u.ID = pt.UserID
WHERE pt.ProgramID = 10053
  AND pt.CreateDate >= '2025-01-01'
  AND pt.CreateDate < '2026-01-02'  -- Up to and including Jan 1, 2026
  AND (
      -- Discrepancy transactions (going TO discrepancy)
      cpt.Description = 'WH-DISCREPANCYRECEIVE'
      OR UPPER(pt.ToLocation) LIKE 'DISCREPANCY%'
      OR UPPER(pt.ToLocation) LIKE 'DISCRE.%'
      -- Finished Goods transactions (going TO finished goods)
      OR UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS%'
      OR UPPER(pt.ToLocation) LIKE 'FGI%'
  )
ORDER BY pt.CreateDate DESC;

