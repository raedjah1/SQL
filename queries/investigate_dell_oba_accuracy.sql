-- ================================================
-- INVESTIGATE DELL OBA REVIEW QUERY ACCURACY
-- ================================================
-- Purpose: Understand what data is being excluded
-- ================================================

-- ================================================
-- 1. CHECK WHAT ATTRIBUTE IDs 1394 AND 1395 MEAN
-- ================================================

SELECT ID, AttributeName, Description
FROM Plus.pls.CodeAttribute
WHERE ID IN (1394, 1395);


-- ================================================
-- 2. COUNT RECORDS BY ATTRIBUTE ID FOR OCT 20-24
-- ================================================
-- This shows: AttributeID 1394 = 206 records, 1395 = 82 records

SELECT 
    AttributeID,
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT SerialNo) as UniqueSerials,
    SUM(CASE WHEN Value = 'PASS' THEN 1 ELSE 0 END) as PassCount,
    SUM(CASE WHEN Value != 'PASS' THEN 1 ELSE 0 END) as FailCount
FROM Plus.pls.PartSerialAttribute psa
JOIN Plus.pls.PartSerial ps ON ps.ID = psa.PartSerialID
WHERE ps.ProgramID = 10053
  AND psa.AttributeID IN (1394, 1395)
  AND psa.CreateDate >= '2025-10-20 00:00:00.000000'
  AND psa.CreateDate < '2025-10-25 00:00:00.000000'
GROUP BY AttributeID
ORDER BY AttributeID;


-- ================================================
-- 3. CHECK IF SERIALS HAVE BOTH ATTRIBUTE IDs
-- ================================================
-- See if same serials appear with both 1394 and 1395

SELECT 
    ps.SerialNo,
    COUNT(DISTINCT psa.AttributeID) as DifferentAttributes,
    STRING_AGG(CONVERT(varchar, psa.AttributeID), ', ') as AttributeIDs,
    STRING_AGG(CONVERT(varchar, psa.Value), ', ') as Values,
    STRING_AGG(CONVERT(varchar, psa.CreateDate, 120), ', ') as Dates
FROM Plus.pls.PartSerial ps
JOIN Plus.pls.PartSerialAttribute psa ON psa.PartSerialID = ps.ID
WHERE ps.ProgramID = 10053
  AND psa.AttributeID IN (1394, 1395)
  AND psa.CreateDate >= '2025-10-20 00:00:00.000000'
  AND psa.CreateDate < '2025-10-25 00:00:00.000000'
GROUP BY ps.SerialNo
HAVING COUNT(DISTINCT psa.AttributeID) > 1;


-- ================================================
-- 4. CHECK WHAT PARTTRANSACTIONID 1 AND 47 ARE
-- ================================================

SELECT ID, Name, Description
FROM Plus.pls.CodePartTransaction
WHERE ID IN (1, 47);


-- ================================================
-- 5. CHECK RECEIVED DATE TRANSACTIONS EXIST
-- ================================================

SELECT 
    PartTransactionID,
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT SerialNo) as UniqueSerials,
    MIN(CreateDate) as EarliestTransaction,
    MAX(CreateDate) as LatestTransaction
FROM Plus.pls.PartTransaction
WHERE ProgramID = 10053
  AND PartTransactionID IN (1, 47)
  AND CreateDate >= '2025-10-20 00:00:00.000000'
  AND CreateDate < '2025-10-25 00:00:00.000000'
GROUP BY PartTransactionID;


-- ================================================
-- 6. CHECK DATAWIPERESULT TEST RESULTS EXIST
-- ================================================

SELECT 
    Program,
    TestArea,
    MachineName,
    COUNT(*) as RecordCount,
    COUNT(DISTINCT SerialNumber) as UniqueSerials
FROM redw.tia.DataWipeResult
WHERE Program = 'DELL_MEM'
  AND StartTime >= '2025-10-20 00:00:00.000000'
  AND StartTime < '2025-10-25 00:00:00.000000'
GROUP BY Program, TestArea, MachineName
ORDER BY RecordCount DESC;


-- ================================================
-- 7. CHECK WHICH SERIALS ARE EXCLUDED DUE TO NO TESTS
-- ================================================
-- IMPORTANT: Shows what data is MISSING due to INNER JOIN

WITH BaseData AS (
    SELECT
        ps.ID,
        ps.PartNo,
        ps.SerialNo,
        ps.ROHeaderID,
        prt.Description,
        u.Username AS AuditorName,
        oba.CreateDate AS CQMDate,
        oba.Value AS RawValue,
        ps.ProgramID
    FROM Plus.pls.PartSerial AS ps
    JOIN Plus.pls.PartNo AS prt ON prt.PartNo = ps.PartNo
    JOIN Plus.pls.PartSerialAttribute AS oba ON oba.PartSerialID = ps.ID
                                            AND oba.AttributeID = 1394
    JOIN Plus.pls.[User] AS u ON u.ID = oba.UserID
    WHERE ps.ProgramID = 10053
      AND oba.CreateDate >= '2025-10-20 00:00:00.000000'
      AND oba.CreateDate < '2025-10-25 00:00:00.000000'
)
SELECT 
    'Serials WITH test results (SHOWS IN QUERY)' AS Category,
    COUNT(DISTINCT b.SerialNo) AS Count
FROM BaseData b
INNER JOIN redw.tia.DataWipeResult d 
    ON b.SerialNo = d.SerialNumber
    AND d.Program = 'DELL_MEM'
    AND d.StartTime >= '2025-10-20 00:00:00.000000'
    AND d.StartTime < '2025-10-25 00:00:00.000000'

UNION ALL

SELECT 
    'Serials WITHOUT test results (EXCLUDED!)' AS Category,
    COUNT(DISTINCT b.SerialNo) AS Count
FROM BaseData b
LEFT JOIN redw.tia.DataWipeResult d 
    ON b.SerialNo = d.SerialNumber
    AND d.Program = 'DELL_MEM'
    AND d.StartTime >= '2025-10-20 00:00:00.000000'
    AND d.StartTime < '2025-10-25 00:00:00.000000'
WHERE d.SerialNumber IS NULL;

-- ================================================
-- 8. SHOW DETAILED LIST OF EXCLUDED SERIALS
-- ================================================
-- Lists all serials that have NO test results (and thus don't show in query)

WITH BaseData AS (
    SELECT
        ps.PartNo,
        ps.SerialNo,
        u.Username AS AuditorName,
        oba.CreateDate AS ReviewDate,
        oba.Value AS ReviewResult
    FROM Plus.pls.PartSerial AS ps
    JOIN Plus.pls.PartSerialAttribute AS oba ON oba.PartSerialID = ps.ID
                                            AND oba.AttributeID = 1394
    JOIN Plus.pls.[User] AS u ON u.ID = oba.UserID
    WHERE ps.ProgramID = 10053
      AND oba.CreateDate >= '2025-10-20 00:00:00.000000'
      AND oba.CreateDate < '2025-10-25 00:00:00.000000'
)
SELECT 
    'EXCLUDED RECORDS (no test results)' AS Status,
    b.PartNo,
    b.SerialNo,
    b.AuditorName,
    b.ReviewDate,
    b.ReviewResult
FROM BaseData b
LEFT JOIN redw.tia.DataWipeResult d 
    ON b.SerialNo = d.SerialNumber
    AND d.Program = 'DELL_MEM'
    AND d.StartTime >= '2025-10-20 00:00:00.000000'
    AND d.StartTime < '2025-10-25 00:00:00.000000'
WHERE d.SerialNumber IS NULL
ORDER BY b.ReviewDate;


-- ================================================
-- 9. COMPARE ALL ATTRIBUTE IDs TO SHOW FULL PICTURE
-- ================================================
-- Shows attribute 1394 vs 1395 side by side

WITH AllAttributes AS (
    SELECT
        ps.SerialNo,
        ps.PartNo,
        u.Username AS AuditorName,
        oba.CreateDate AS ReviewDate,
        oba.AttributeID,
        oba.Value AS RawValue,
        CASE WHEN oba.Value = 'PASS' THEN 'Pass' ELSE 'Fail' END AS Result,
        -- Check if serial has test results
        (SELECT COUNT(*) 
         FROM redw.tia.DataWipeResult d 
         WHERE d.SerialNumber = ps.SerialNo 
           AND d.Program = 'DELL_MEM'
           AND d.StartTime >= '2025-10-20 00:00:00.000000'
           AND d.StartTime < '2025-10-25 00:00:00.000000'
        ) as HasTestResults
    FROM Plus.pls.PartSerial AS ps
    JOIN Plus.pls.PartNo AS prt ON prt.PartNo = ps.PartNo
    JOIN Plus.pls.PartSerialAttribute AS oba ON oba.PartSerialID = ps.ID
    JOIN Plus.pls.[User] AS u ON u.ID = oba.UserID
    WHERE ps.ProgramID = 10053
      AND oba.AttributeID IN (1394, 1395)
      AND oba.CreateDate >= '2025-10-20 00:00:00.000000'
      AND oba.CreateDate < '2025-10-25 00:00:00.000000'
)
SELECT 
    AttributeID,
    CASE WHEN AttributeID = 1394 THEN 'OBA' ELSE 'CQM' END AS ReviewType,
    PartNo,
    SerialNo,
    AuditorName,
    ReviewDate,
    Result,
    HasTestResults,
    CASE 
        WHEN HasTestResults > 0 THEN 'SHOWS IN QUERY ✓'
        WHEN AttributeID = 1394 THEN 'EXCLUDED (no tests) ✗'
        WHEN AttributeID = 1395 THEN 'EXCLUDED (wrong AttributeID) ✗'
        ELSE 'EXCLUDED ✗'
    END AS InQuery
FROM AllAttributes
ORDER BY AttributeID, SerialNo;


-- ================================================
-- 10. SUMMARY: WHAT IS EXCLUDED AND WHY
-- ================================================

SELECT 
    'Total Attribute 1394 Records' AS Metric,
    COUNT(*) as Count
FROM Plus.pls.PartSerialAttribute psa
JOIN Plus.pls.PartSerial ps ON ps.ID = psa.PartSerialID
WHERE ps.ProgramID = 10053
  AND psa.AttributeID = 1394
  AND psa.CreateDate >= '2025-10-20 00:00:00.000000'
  AND psa.CreateDate < '2025-10-25 00:00:00.000000'

UNION ALL

SELECT 
    'Total Attribute 1395 Records (EXCLUDED by filter)',
    COUNT(*)
FROM Plus.pls.PartSerialAttribute psa
JOIN Plus.pls.PartSerial ps ON ps.ID = psa.PartSerialID
WHERE ps.ProgramID = 10053
  AND psa.AttributeID = 1395
  AND psa.CreateDate >= '2025-10-20 00:00:00.000000'
  AND psa.CreateDate < '2025-10-25 00:00:00.000000'

UNION ALL

SELECT 
    'Records with no test data (EXCLUDED by JOIN)',
    COUNT(*)
FROM (
    SELECT ps.SerialNo
    FROM Plus.pls.PartSerial ps
    JOIN Plus.pls.PartSerialAttribute psa ON psa.PartSerialID = ps.ID
    WHERE ps.ProgramID = 10053
      AND psa.AttributeID = 1394
      AND psa.CreateDate >= '2025-10-20 00:00:00.000000'
      AND psa.CreateDate < '2025-10-25 00:00:00.000000'
) base
LEFT JOIN redw.tia.DataWipeResult d 
    ON base.SerialNo = d.SerialNumber
    AND d.Program = 'DELL_MEM'
    AND d.StartTime >= '2025-10-20 00:00:00.000000'
    AND d.StartTime < '2025-10-25 00:00:00.000000'
WHERE d.SerialNumber IS NULL;
