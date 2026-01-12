-- Investigate all FICORE and Spectrum results for serial number 1Y64D44
-- Shows all test results, not just the latest

SELECT 
    'FICORE - MEMPHIS' AS TestType,
    dwr.SerialNumber,
    dwr.Result,
    dwr.StartTime,
    dwr.EndTime,
    dwr.MachineName,
    dwr.TestArea,
    dwr.Program,
    dwr.ID
FROM redw.tia.DataWipeResult AS dwr
WHERE dwr.SerialNumber = '1Y64D44'
    AND dwr.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
    AND dwr.TestArea = 'MEMPHIS' COLLATE Latin1_General_100_CI_AS
    AND dwr.MachineName = 'FICORE' COLLATE Latin1_General_100_CI_AS

UNION ALL

SELECT 
    'FICORE - FICORE' AS TestType,
    dwr.SerialNumber,
    dwr.Result,
    dwr.StartTime,
    dwr.EndTime,
    dwr.MachineName,
    dwr.TestArea,
    dwr.Program,
    dwr.ID
FROM redw.tia.DataWipeResult AS dwr
WHERE dwr.SerialNumber = '1Y64D44'
    AND dwr.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
    AND dwr.TestArea = 'FICORE' COLLATE Latin1_General_100_CI_AS

UNION ALL

SELECT 
    'SPECTRUM' AS TestType,
    dwr.SerialNumber,
    dwr.Result,
    dwr.StartTime,
    dwr.EndTime,
    dwr.MachineName,
    dwr.TestArea,
    dwr.Program,
    dwr.ID
FROM redw.tia.DataWipeResult AS dwr
WHERE dwr.SerialNumber = '1Y64D44'
    AND dwr.Program = 'DELL_MEM' COLLATE Latin1_General_100_CI_AS
    AND dwr.TestArea = 'Memphis' COLLATE Latin1_General_100_CI_AS
    AND dwr.MachineName = 'SPECTRUMX' COLLATE Latin1_General_100_CI_AS

ORDER BY TestType, StartTime DESC;

