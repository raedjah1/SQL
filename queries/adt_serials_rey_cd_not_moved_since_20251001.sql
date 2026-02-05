-- ADT: Serials currently in REY-CD warehouse that have not moved since a cutoff date.
-- "Not moved" is interpreted as PartSerial.LastActivityDate < @CutoffDate.

DECLARE @ProgramID INT = 10068;          -- ADT
DECLARE @CutoffDate DATETIME = '2025-10-01T00:00:00';

SELECT
    ps.SerialNo,
    ps.PartNo,
    pl.LocationNo        AS PartLocationNo,
    pl.Warehouse         AS PartLocationWarehouse,
    cs.Description       AS StatusDescription,
    ps.CreateDate,
    ps.LastActivityDate,
    DATEDIFF(DAY, ps.LastActivityDate, GETDATE()) AS DaysSinceLastActivity
FROM Plus.pls.PartSerial ps
INNER JOIN Plus.pls.PartLocation pl
    ON pl.ID = ps.LocationID
INNER JOIN Plus.pls.CodeStatus cs
    ON cs.ID = ps.StatusID
WHERE ps.ProgramID = @ProgramID
  AND pl.ProgramID = @ProgramID
  AND UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'REY-CD'
  AND ps.LastActivityDate < @CutoffDate
ORDER BY
    ps.LastActivityDate ASC,
    ps.SerialNo;




