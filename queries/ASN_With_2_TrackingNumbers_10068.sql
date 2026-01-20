-- Receipt Report: ASNs with 2 Tracking Numbers Assigned
-- ProgramID = 10068 (ADT)
-- Shows cases where one ASN has exactly 2 different tracking numbers
-- Filtered for the last year from today

WITH ASN_TrackingSummary AS (
    SELECT 
        rec.CustomerReference AS ASN,
        COUNT(DISTINCT dl.TrackingNo) AS TrackingNumberCount,
        MIN(rec.CreateDate) AS FirstReceiptDate,
        MAX(rec.CreateDate) AS LastReceiptDate,
        COUNT(DISTINCT rec.PartNo) AS UniquePartCount,
        COUNT(DISTINCT rec.SerialNo) AS UniqueSerialCount,
        SUM(rec.Qty) AS TotalQuantityReceived,
        COUNT(*) AS TotalTransactions,
        rh.ID AS RMAHeaderID
    FROM Plus.pls.PartTransaction rec
    INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
    INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
    LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
    WHERE rec.ProgramID = 10068
      AND cpt.Description = 'RO-RECEIVE'
      AND dl.TrackingNo IS NOT NULL
      AND rec.CustomerReference IS NOT NULL
      AND rec.CreateDate >= DATEADD(YEAR, -1, GETDATE())  -- Last year from today
    GROUP BY 
        rec.CustomerReference,
        rh.ID
    HAVING COUNT(DISTINCT dl.TrackingNo) = 2  -- Exactly 2 tracking numbers per ASN
),
ASN_TrackingNumbers AS (
    SELECT 
        distinct_tracking.CustomerReference AS ASN,
        distinct_tracking.RMAHeaderID,
        STRING_AGG(distinct_tracking.TrackingNo, ', ') AS TrackingNumbers
    FROM (
        SELECT DISTINCT
            rec2.CustomerReference,
            rh2.ID AS RMAHeaderID,
            dl2.TrackingNo
        FROM Plus.pls.PartTransaction rec2
        INNER JOIN Plus.pls.CodePartTransaction cpt2 ON cpt2.ID = rec2.PartTransactionID
        INNER JOIN Plus.pls.RODockLog dl2 ON dl2.ID = rec2.RODockLogID
        LEFT JOIN Plus.pls.ROHeader rh2 ON rh2.ID = rec2.OrderHeaderID
        WHERE rec2.ProgramID = 10068
          AND cpt2.Description = 'RO-RECEIVE'
          AND dl2.TrackingNo IS NOT NULL
          AND rec2.CustomerReference IS NOT NULL
          AND rec2.CreateDate >= DATEADD(YEAR, -1, GETDATE())
    ) AS distinct_tracking
    GROUP BY 
        distinct_tracking.CustomerReference,
        distinct_tracking.RMAHeaderID
    HAVING COUNT(DISTINCT distinct_tracking.TrackingNo) = 2
),
ASN_Parts AS (
    SELECT 
        distinct_parts.CustomerReference AS ASN,
        distinct_parts.RMAHeaderID,
        STRING_AGG(distinct_parts.PartNo, ', ') AS PartNumbers
    FROM (
        SELECT DISTINCT
            rec3.CustomerReference,
            rh3.ID AS RMAHeaderID,
            rec3.PartNo
        FROM Plus.pls.PartTransaction rec3
        INNER JOIN Plus.pls.CodePartTransaction cpt3 ON cpt3.ID = rec3.PartTransactionID
        INNER JOIN Plus.pls.RODockLog dl3 ON dl3.ID = rec3.RODockLogID
        LEFT JOIN Plus.pls.ROHeader rh3 ON rh3.ID = rec3.OrderHeaderID
        WHERE rec3.ProgramID = 10068
          AND cpt3.Description = 'RO-RECEIVE'
          AND dl3.TrackingNo IS NOT NULL
          AND rec3.CustomerReference IS NOT NULL
          AND rec3.CreateDate >= DATEADD(YEAR, -1, GETDATE())
          AND rec3.CustomerReference IN (
              -- Only include ASNs with exactly 2 tracking numbers
              SELECT rec4.CustomerReference
              FROM Plus.pls.PartTransaction rec4
              INNER JOIN Plus.pls.CodePartTransaction cpt4 ON cpt4.ID = rec4.PartTransactionID
              INNER JOIN Plus.pls.RODockLog dl4 ON dl4.ID = rec4.RODockLogID
              WHERE rec4.ProgramID = 10068
                AND cpt4.Description = 'RO-RECEIVE'
                AND dl4.TrackingNo IS NOT NULL
                AND rec4.CustomerReference IS NOT NULL
                AND rec4.CreateDate >= DATEADD(YEAR, -1, GETDATE())
              GROUP BY rec4.CustomerReference
              HAVING COUNT(DISTINCT dl4.TrackingNo) = 2
          )
    ) AS distinct_parts
    GROUP BY 
        distinct_parts.CustomerReference,
        distinct_parts.RMAHeaderID
)
SELECT 
    s.ASN,
    s.TrackingNumberCount,
    t.TrackingNumbers,
    p.PartNumbers,
    s.FirstReceiptDate,
    s.LastReceiptDate,
    s.UniquePartCount,
    s.UniqueSerialCount,
    s.TotalQuantityReceived,
    s.TotalTransactions,
    s.RMAHeaderID
FROM ASN_TrackingSummary s
INNER JOIN ASN_TrackingNumbers t ON t.ASN = s.ASN AND (t.RMAHeaderID = s.RMAHeaderID OR (t.RMAHeaderID IS NULL AND s.RMAHeaderID IS NULL))
LEFT JOIN ASN_Parts p ON p.ASN = s.ASN AND (p.RMAHeaderID = s.RMAHeaderID OR (p.RMAHeaderID IS NULL AND s.RMAHeaderID IS NULL))
ORDER BY s.ASN, s.FirstReceiptDate DESC;

-- ============================================================================
-- Detailed View: Show all receipt transactions for ASNs with 2 tracking numbers
-- ============================================================================
SELECT 
    rec.CustomerReference AS ASN,
    dl.TrackingNo AS TrackingNumber,
    rec.CreateDate AS DateReceived,
    rec.PartNo,
    rec.SerialNo,
    rec.Qty AS QuantityReceived,
    cpt.Description AS TransactionType,
    dl.ID AS DockLogID,
    rh.ID AS RMAHeaderID,
    rh.CustomerReference AS RMANumber,
    u.Username AS ReceivedBy,
    rec.ToLocation AS ReceivingLocation
FROM Plus.pls.PartTransaction rec
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
INNER JOIN Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = rec.OrderHeaderID
LEFT JOIN Plus.pls.[User] u ON u.ID = rec.UserID
WHERE rec.ProgramID = 10068
  AND cpt.Description = 'RO-RECEIVE'
  AND dl.TrackingNo IS NOT NULL
  AND rec.CustomerReference IS NOT NULL
  AND rec.CreateDate >= DATEADD(YEAR, -1, GETDATE())
  AND rec.CustomerReference IN (
      -- Subquery to find ASNs with exactly 2 tracking numbers
      SELECT rec2.CustomerReference
      FROM Plus.pls.PartTransaction rec2
      INNER JOIN Plus.pls.CodePartTransaction cpt2 ON cpt2.ID = rec2.PartTransactionID
      INNER JOIN Plus.pls.RODockLog dl2 ON dl2.ID = rec2.RODockLogID
      WHERE rec2.ProgramID = 10068
        AND cpt2.Description = 'RO-RECEIVE'
        AND dl2.TrackingNo IS NOT NULL
        AND rec2.CustomerReference IS NOT NULL
        AND rec2.CreateDate >= DATEADD(YEAR, -1, GETDATE())
      GROUP BY rec2.CustomerReference
      HAVING COUNT(DISTINCT dl2.TrackingNo) = 2
  )
ORDER BY rec.CustomerReference, dl.TrackingNo, rec.CreateDate DESC, rec.PartNo;

