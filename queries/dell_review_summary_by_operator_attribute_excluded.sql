-- ================================================
-- DELL REVIEW SUMMARY BY OPERATOR, DATE, ATTRIBUTE, AND EXCLUSION STATUS
-- ================================================
-- Shows how many reviews each operator did each day
-- Separated by AttributeID (1394 vs 1395)
-- Shows which records are excluded due to no test results
-- ================================================

WITH BaseData AS (
    SELECT
        ps.ID,
        ps.PartNo,
        ps.SerialNo,
        ps.ROHeaderID,
        prt.Description,
        u.Username AS AuditorName,
        oba.CreateDate AS ReviewDate,
        oba.AttributeID,
        oba.Value AS RawValue,
        CASE WHEN oba.Value = 'PASS' THEN 'Pass' ELSE 'Fail' END AS ReviewResult,
        oba.UserID,
        ps.ProgramID
    FROM Plus.pls.PartSerial AS ps
    JOIN Plus.pls.PartNo AS prt ON prt.PartNo = ps.PartNo
    JOIN Plus.pls.PartSerialAttribute AS oba ON oba.PartSerialID = ps.ID
    JOIN Plus.pls.[User] AS u ON u.ID = oba.UserID
    WHERE ps.ProgramID = 10053
      AND oba.AttributeID IN (1394, 1395)
      AND oba.CreateDate >= '2025-10-20 00:00:00.000000'
      AND oba.CreateDate < '2025-10-25 00:00:00.000000'
),
WithTestResults AS (
    SELECT 
        bd.SerialNo,
        bd.AuditorName,
        CAST(bd.ReviewDate AS DATE) AS ReviewDate,
        bd.AttributeID,
        bd.ReviewResult,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM redw.tia.DataWipeResult d
                WHERE d.SerialNumber = bd.SerialNo
                  AND d.Program = 'DELL_MEM'
                  AND d.StartTime >= '2025-10-20 00:00:00.000000'
                  AND d.StartTime < '2025-10-25 00:00:00.000000'
            ) THEN 'INCLUDED'
            ELSE 'EXCLUDED'
        END AS InclusionStatus,
        COUNT(*) OVER (PARTITION BY bd.SerialNo) AS TestResultCount
    FROM BaseData bd
)
SELECT
    wtr.AuditorName AS Operator,
    wtr.ReviewDate AS Date,
    wtr.AttributeID,
    CASE 
        WHEN wtr.AttributeID = 1394 THEN 'OBA Review'
        WHEN wtr.AttributeID = 1395 THEN 'CQM Review'
        ELSE 'Unknown'
    END AS ReviewType,
    wtr.InclusionStatus,
    COUNT(*) AS TotalReviews,
    SUM(CASE WHEN wtr.ReviewResult = 'Pass' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN wtr.ReviewResult = 'Fail' THEN 1 ELSE 0 END) AS FailCount,
    CAST(SUM(CASE WHEN wtr.ReviewResult = 'Pass' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS PassRate
FROM WithTestResults wtr
WHERE wtr.AuditorName IS NOT NULL
GROUP BY wtr.AuditorName, wtr.ReviewDate, wtr.AttributeID, wtr.InclusionStatus
ORDER BY wtr.AuditorName, wtr.ReviewDate, wtr.AttributeID, wtr.InclusionStatus;


-- ================================================
-- SIMPLER VERSION: JUST SHOW INCLUDED VS EXCLUDED
-- ================================================

WITH BaseData AS (
    SELECT
        ps.SerialNo,
        u.Username AS AuditorName,
        oba.CreateDate AS ReviewDate,
        oba.AttributeID,
        CASE WHEN oba.Value = 'PASS' THEN 'Pass' ELSE 'Fail' END AS ReviewResult
    FROM Plus.pls.PartSerial AS ps
    JOIN Plus.pls.PartSerialAttribute AS oba ON oba.PartSerialID = ps.ID
    JOIN Plus.pls.[User] AS u ON u.ID = oba.UserID
    WHERE ps.ProgramID = 10053
      AND oba.AttributeID IN (1394, 1395)
      AND oba.CreateDate >= '2025-10-20 00:00:00.000000'
      AND oba.CreateDate < '2025-10-25 00:00:00.000000'
)
SELECT
    bd.AuditorName AS Operator,
    CAST(bd.ReviewDate AS DATE) AS ReviewDate,
    bd.AttributeID,
    CASE 
        WHEN bd.AttributeID = 1394 THEN 'OBA Review'
        WHEN bd.AttributeID = 1395 THEN 'CQM Review'
        ELSE 'Unknown'
    END AS ReviewType,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM redw.tia.DataWipeResult d
            WHERE d.SerialNumber = bd.SerialNo
              AND d.Program = 'DELL_MEM'
              AND d.StartTime >= '2025-10-20 00:00:00.000000'
              AND d.StartTime < '2025-10-25 00:00:00.000000'
        ) THEN 'INCLUDED'
        ELSE 'EXCLUDED'
    END AS InclusionStatus,
    COUNT(*) AS TotalReviews,
    SUM(CASE WHEN bd.ReviewResult = 'Pass' THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN bd.ReviewResult = 'Fail' THEN 1 ELSE 0 END) AS FailCount,
    CAST(SUM(CASE WHEN bd.ReviewResult = 'Pass' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS PassRate
FROM BaseData bd
WHERE bd.AuditorName IS NOT NULL
GROUP BY bd.AuditorName, CAST(bd.ReviewDate AS DATE), bd.AttributeID,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM redw.tia.DataWipeResult d
            WHERE d.SerialNumber = bd.SerialNo
              AND d.Program = 'DELL_MEM'
              AND d.StartTime >= '2025-10-20 00:00:00.000000'
              AND d.StartTime < '2025-10-25 00:00:00.000000'
        ) THEN 'INCLUDED'
        ELSE 'EXCLUDED'
    END
ORDER BY bd.AuditorName, ReviewDate, bd.AttributeID, InclusionStatus;


-- ================================================
-- MOST SIMPLE VERSION: ALL DATA IN ONE PLACE
-- ================================================
-- This will show you exactly what's going on

WITH BaseData AS (
    SELECT
        ps.SerialNo,
        u.Username AS AuditorName,
        oba.CreateDate AS ReviewDate,
        oba.AttributeID,
        CASE WHEN oba.Value = 'PASS' THEN 'Pass' ELSE 'Fail' END AS ReviewResult
    FROM Plus.pls.PartSerial AS ps
    JOIN Plus.pls.PartSerialAttribute AS oba ON oba.PartSerialID = ps.ID
    JOIN Plus.pls.[User] AS u ON u.ID = oba.UserID
    WHERE ps.ProgramID = 10053
      AND oba.AttributeID IN (1394, 1395)
      AND oba.CreateDate >= '2025-10-20 00:00:00.000000'
      AND oba.CreateDate < '2025-10-25 00:00:00.000000'
),
WithStatus AS (
    SELECT 
        bd.SerialNo,
        bd.AuditorName,
        bd.ReviewDate,
        bd.AttributeID,
        bd.ReviewResult,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM redw.tia.DataWipeResult d
                WHERE d.SerialNumber = bd.SerialNo
                  AND d.Program = 'DELL_MEM'
                  AND d.StartTime >= '2025-10-20 00:00:00.000000'
                  AND d.StartTime < '2025-10-25 00:00:00.000000'
            ) THEN 'INCLUDED ✓'
            ELSE 'EXCLUDED ✗'
        END AS Status
    FROM BaseData bd
)
SELECT
    AuditorName AS Operator,
    CAST(ReviewDate AS DATE) AS Date,
    AttributeID,
    CASE 
        WHEN AttributeID = 1394 THEN 'OBA Review'
        WHEN AttributeID = 1395 THEN 'CQM Review'
        ELSE 'Unknown'
    END AS ReviewType,
    Status,
    COUNT(*) AS Total,
    SUM(CASE WHEN ReviewResult = 'Pass' THEN 1 ELSE 0 END) AS Pass,
    SUM(CASE WHEN ReviewResult = 'Fail' THEN 1 ELSE 0 END) AS Fail,
    CAST(SUM(CASE WHEN ReviewResult = 'Pass' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS PassRate
FROM WithStatus
GROUP BY AuditorName, CAST(ReviewDate AS DATE), AttributeID, Status
ORDER BY AuditorName, Date, AttributeID, Status;
