CREATE OR ALTER VIEW [pls].[vPartLocation] AS
SELECT 
    pl.ID,
    pl.ProgramID,
    pl.LocationNo,
    pl.Warehouse,
    pl.Bin,
    pl.Building,
    pl.Bay,
    pl.Row,
    pl.Tier,
    cs.Description AS Status,
    clg.Description AS LocationGroup,
    pl.Width,
    pl.Height,
    pl.Length,
    pl.Volume,
    pl.PickOrder,
    u.Username,
    pl.CreateDate,
    pl.LastActivityDate
FROM [Plus].[pls].PartLocation AS pl
INNER JOIN [Plus].[pls].CodeStatus AS cs ON pl.StatusID = cs.ID
INNER JOIN [Plus].[pls].CodeLocationGroup AS clg ON pl.LocationGroupID = clg.ID
INNER JOIN [Plus].[pls].[User] AS u ON u.ID = pl.UserID
