-- Find all serial numbers in FinishedGoods and Reserve locations for program 10053
-- Checks current location (PartSerial) and transaction locations (FromLocation/ToLocation from PartTransaction)
SELECT DISTINCT
    ps.SerialNo,
    ps.PartNo,
    pn.Description,
    pl.LocationNo AS Current_Location,
    pl.Warehouse,
    pl.Building,
    pl.Bin,
    cc.Description AS Configuration,
    ps.CreateDate AS SerialCreatedDate,
    ps.LastActivityDate,
    
    -- Transaction From/To Locations
    pt.Location AS From_Location,
    pt.ToLocation AS To_Location,
    pt.PartTransactionType,
    pt.CreateDate AS Transaction_Date,
    pt.Username AS Transaction_User
FROM Plus.pls.PartSerial ps
    INNER JOIN Plus.pls.PartLocation pl ON pl.ID = ps.LocationID
    LEFT JOIN Plus.pls.PartNo pn ON pn.PartNo = ps.PartNo
    LEFT JOIN Plus.pls.CodeConfiguration cc ON cc.ID = ps.ConfigurationID
    
    -- Join to transaction that moved FROM FinishedGoods.ARB.0.0.0 TO FinishedGoods/Reserve
    LEFT JOIN (
        SELECT 
            pt_inner.SerialNo,
            pt_inner.ProgramID,
            pt_inner.Location,
            pt_inner.ToLocation,
            pt_inner.PartTransactionType,
            pt_inner.CreateDate,
            pt_inner.Username,
            ROW_NUMBER() OVER (
                PARTITION BY pt_inner.SerialNo, pt_inner.ProgramID
                ORDER BY pt_inner.CreateDate DESC
            ) AS rn
        FROM rpt.PartTransaction pt_inner
        WHERE pt_inner.ProgramID = 10053
          -- FromLocation = FinishedGoods.ARB.0.0.0 (case-insensitive)
          AND UPPER(pt_inner.Location) = UPPER('FinishedGoods.ARB.0.0.0')
          -- ToLocation = any FinishedGoods or Reserve location (case-insensitive)
          AND (
              UPPER(pt_inner.ToLocation) LIKE UPPER('FinishedGoods%')
              OR UPPER(pt_inner.ToLocation) LIKE UPPER('Reserve%')
          )
    ) pt ON pt.SerialNo = ps.SerialNo 
        AND pt.ProgramID = ps.ProgramID
        AND pt.rn = 1  -- Get most recent matching transaction
WHERE ps.ProgramID = 10053
  AND ps.SerialNo IS NOT NULL
  AND (
      -- Current location checks (PartLocation)
      UPPER(pl.LocationNo) = UPPER('FinishedGoods.ARB.0.0.0')
      OR UPPER(pl.LocationNo) LIKE UPPER('FinishedGoods%')
      OR UPPER(pl.LocationNo) LIKE UPPER('Reserve%')
      
      -- OR serial has transactions FROM FinishedGoods.ARB.0.0.0 TO any FinishedGoods or Reserve location
      OR EXISTS (
          SELECT 1
          FROM rpt.PartTransaction pt
          WHERE pt.SerialNo = ps.SerialNo
            AND pt.ProgramID = 10053
            -- FromLocation = FinishedGoods.ARB.0.0.0 (case-insensitive)
            AND UPPER(pt.Location) = UPPER('FinishedGoods.ARB.0.0.0')
            -- ToLocation = any FinishedGoods or Reserve location (case-insensitive)
            AND (
                UPPER(pt.ToLocation) LIKE UPPER('FinishedGoods%')
                OR UPPER(pt.ToLocation) LIKE UPPER('Reserve%')
            )
      )
  )
ORDER BY ps.SerialNo;

