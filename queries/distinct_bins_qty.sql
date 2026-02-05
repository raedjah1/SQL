-- Distinct bins with occupancy flag (ADT default).
-- Returns:
-- - 'Occupied' if total AvailableQty in the bin > 0
-- - 'Empty' otherwise

DECLARE @ProgramID INT = 10068; -- ADT

SELECT
    b.Bin,
    CASE WHEN q.TotalQty > 0 THEN 'Occupied' ELSE 'Empty' END AS BinStatus
FROM (
    SELECT DISTINCT
        LTRIM(RTRIM(pl.Bin)) AS Bin
    FROM Plus.pls.PartLocation pl
    WHERE pl.ProgramID = @ProgramID
      AND pl.Bin IS NOT NULL
      AND LTRIM(RTRIM(pl.Bin)) <> ''
) b
LEFT JOIN (
    SELECT
        LTRIM(RTRIM(pl.Bin)) AS Bin,
        SUM(pq.AvailableQty) AS TotalQty
    FROM Plus.pls.PartLocation pl
    INNER JOIN Plus.pls.PartQty pq
        ON pq.LocationID = pl.ID
       AND pq.ProgramID = @ProgramID
    WHERE pl.ProgramID = @ProgramID
      AND pl.Bin IS NOT NULL
      AND LTRIM(RTRIM(pl.Bin)) <> ''
    GROUP BY LTRIM(RTRIM(pl.Bin))
) q
    ON q.Bin = b.Bin
ORDER BY
    b.Bin;


