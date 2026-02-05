
-- ============================================
-- ALL PARTS AND QUANTITIES IN OEM LOCATIONS (MONDAY TO FRIDAY)
-- GROUPED/KEYED BY WEEK (WeekID) BASED ON QtyCreateDate
-- WITH VENDOR MAPPING FROM VENDORLOCATION TABLE (NO VENDOR CONTACTS)
-- ProgramID: 10068 (ADT)
-- ============================================
SELECT
    -- Week key: numeric id based on Monday-of-week (unique across years)
    DATEDIFF(
        WEEK,
        0,
        DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(pq.CreateDate AS DATE)) + 5) % 7, CAST(pq.CreateDate AS DATE))
    ) AS WeekID,
    DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(pq.CreateDate AS DATE)) + 5) % 7, CAST(pq.CreateDate AS DATE)) AS WeekMonday,
    DATEADD(DAY, 4, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(pq.CreateDate AS DATE)) + 5) % 7, CAST(pq.CreateDate AS DATE))) AS WeekFriday,
    pl.LocationNo,
    pl.Warehouse,
    pl.Bin,
    vlm.Vendor,  -- Vendor from VENDORLOCATION table (NULL = no vendor mapping, needs to be added)
    pq.PartNo,
    pn.Description AS PartDescription,
    cc.Description AS Configuration,
    pq.AvailableQty,
    pq.PalletBoxNo,
    pq.LotNo,
    pq.CreateDate AS QtyCreateDate,
    pq.LastActivityDate AS QtyLastActivity
FROM Plus.pls.PartLocation pl
INNER JOIN Plus.pls.PartQty pq ON pq.LocationID = pl.ID
INNER JOIN Plus.pls.PartNo pn ON pn.PartNo = pq.PartNo
INNER JOIN Plus.pls.CodeConfiguration cc ON cc.ID = pq.ConfigurationID
OUTER APPLY (
    -- Get one vendor per location (most recent record) from VENDORLOCATION (GenericTableDefinitionID = 247)
    SELECT TOP 1
        cgt.C01 AS Vendor
    FROM Plus.pls.CodeGenericTable cgt
    WHERE cgt.GenericTableDefinitionID = 247
      AND cgt.C03 = pl.LocationNo
      AND cgt.C01 IS NOT NULL
    ORDER BY cgt.LastActivityDate DESC, cgt.ID DESC
) vlm
WHERE pl.ProgramID = 10068
    AND pq.ProgramID = 10068
    AND pl.LocationNo LIKE 'OEM%'
    -- Keep only Monday-Friday of each row's week (exclude Sat/Sun)
    AND CAST(pq.CreateDate AS DATE) >= DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(pq.CreateDate AS DATE)) + 5) % 7, CAST(pq.CreateDate AS DATE))
    AND CAST(pq.CreateDate AS DATE) <= DATEADD(DAY, 4, DATEADD(DAY, -(DATEPART(WEEKDAY, CAST(pq.CreateDate AS DATE)) + 5) % 7, CAST(pq.CreateDate AS DATE)))
ORDER BY
    WeekID DESC,
    pl.LocationNo,
    pq.PartNo,
    cc.Description;