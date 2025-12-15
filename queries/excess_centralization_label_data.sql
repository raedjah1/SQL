-- ============================================
-- EXCESS CENTRALIZATION LABEL DATA QUERY
-- ============================================
-- Query to get all information needed for printing labels
-- for excess centralization items with EXADT serial numbers
-- 
-- ZPL Template requires:
-- - SerialNo (for QR code and display)
-- - PartNo (for part number display)
-- - Branch (for branch display)

-- ============================================
-- 1. GET ALL EXADT SERIAL NUMBERS WITH PART AND BRANCH INFO
-- ============================================
SELECT 
    'EXCESS_CENTRALIZATION_LABELS' as ReportType,
    pt.SerialNo,
    pt.PartNo,
    -- Extract branch from CustomerReference or other fields
    CASE 
        WHEN pt.CustomerReference LIKE 'EX%' THEN 
            SUBSTRING(pt.CustomerReference, 3, 10)  -- Extract from EX number
        WHEN pt.CustomerReference IS NOT NULL THEN pt.CustomerReference
        ELSE 'UNKNOWN'
    END as Branch,
    pt.Location,
    pt.ToLocation,
    pt.Username as Operator,
    pt.CreateDate as TransactionTime,
    pt.ProgramID,
    -- Additional info for verification
    pt.PartTransaction,
    pt.Qty,
    pt.Reason as Notes
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068  -- ADT Program (Excess Centralization)
  AND pt.SerialNo LIKE 'EXADT%'  -- EXADT serial numbers
  AND pt.PartNo IS NOT NULL
ORDER BY pt.SerialNo;

-- ============================================
-- 2. SPECIFIC SERIAL NUMBERS YOU MENTIONED
-- ============================================
SELECT 
    'SPECIFIC_SERIALS' as ReportType,
    pt.SerialNo,
    pt.PartNo,
    CASE 
        WHEN pt.CustomerReference LIKE 'EX%' THEN 
            SUBSTRING(pt.CustomerReference, 3, 10)
        WHEN pt.CustomerReference IS NOT NULL THEN pt.CustomerReference
        ELSE 'UNKNOWN'
    END as Branch,
    pt.Location,
    pt.ToLocation,
    pt.Username as Operator,
    pt.CreateDate as TransactionTime
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068
  AND pt.SerialNo IN (
    'EXADT1007202510073284776378187317',
    'EXADT1007202510073284776378187318',
    'EXADT1007202510073284776378187319',
    'EXADT1007202510073284776378187320',
    'EXADT1007202510073284776378187321',
    'EXADT1007202510073284776378187322'
  )
ORDER BY pt.SerialNo;

-- ============================================
-- 3. GET BRANCH INFO FROM RO HEADER (EX NUMBERS)
-- ============================================
SELECT 
    'RO_HEADER_BRANCH_INFO' as ReportType,
    roh.CustomerReference as EX_Number,
    roh.PartNo,
    roh.SerialNo,
    roh.StatusDescription,
    roh.Username as Operator,
    roh.CreateDate,
    roh.LastActivityDate,
    -- Try to extract branch from various fields
    CASE 
        WHEN roh.CustomerReference LIKE 'EX%' THEN 
            SUBSTRING(roh.CustomerReference, 3, 10)
        WHEN roh.Notes LIKE '%BRANCH%' THEN 
            SUBSTRING(roh.Notes, CHARINDEX('BRANCH', roh.Notes) + 7, 10)
        ELSE 'UNKNOWN'
    END as Branch
FROM pls.vROHeader roh
WHERE roh.ProgramID = 10068
  AND roh.OrderType = 'Return To Stock'  -- Excess returns
  AND roh.CustomerReference LIKE 'EX%'
ORDER BY roh.CreateDate DESC;

-- ============================================
-- 4. COMBINED VIEW WITH ALL LABEL DATA
-- ============================================
SELECT 
    'LABEL_DATA_COMBINED' as ReportType,
    pt.SerialNo,
    pt.PartNo,
    COALESCE(
        CASE 
            WHEN pt.CustomerReference LIKE 'EX%' THEN 
                SUBSTRING(pt.CustomerReference, 3, 10)
            WHEN pt.CustomerReference IS NOT NULL THEN pt.CustomerReference
            ELSE NULL
        END,
        CASE 
            WHEN roh.CustomerReference LIKE 'EX%' THEN 
                SUBSTRING(roh.CustomerReference, 3, 10)
            ELSE 'UNKNOWN'
        END
    ) as Branch,
    pt.Location,
    pt.ToLocation,
    pt.Username as Operator,
    pt.CreateDate as TransactionTime,
    pt.PartTransaction,
    pt.Qty,
    pt.Reason as Notes
FROM pls.vPartTransaction pt
LEFT JOIN pls.vROHeader roh ON pt.CustomerReference = roh.CustomerReference
WHERE pt.ProgramID = 10068
  AND pt.SerialNo LIKE 'EXADT%'
  AND pt.PartNo IS NOT NULL
ORDER BY pt.SerialNo;

-- ============================================
-- 5. ZPL LABEL FORMAT (READY FOR PRINTING)
-- ============================================
SELECT 
    'ZPL_LABEL_FORMAT' as ReportType,
    pt.SerialNo,
    pt.PartNo,
    COALESCE(
        CASE 
            WHEN pt.CustomerReference LIKE 'EX%' THEN 
                SUBSTRING(pt.CustomerReference, 3, 10)
            WHEN pt.CustomerReference IS NOT NULL THEN pt.CustomerReference
            ELSE NULL
        END,
        'UNKNOWN'
    ) as Branch,
    -- Generate ZPL command for each label
    '^XA' + CHAR(13) + CHAR(10) +
    '^LH350,0' + CHAR(13) + CHAR(10) +
    '^FO20,40^BQN,2,3,M,7^FDQA,' + pt.SerialNo + '^FS' + CHAR(13) + CHAR(10) +
    '^FO100,70^A0,30^FD' + pt.SerialNo + '^FS' + CHAR(13) + CHAR(10) +
    '^FO20,130^A0,30^FD' + TRIM(pt.PartNo) + '^FS' + CHAR(13) + CHAR(10) +
    '^FO20,160^A0,30^FDBRANCH: ^FS' + CHAR(13) + CHAR(10) +
    '^FO250,160^A0,30^FD' + COALESCE(
        CASE 
            WHEN pt.CustomerReference LIKE 'EX%' THEN 
                SUBSTRING(pt.CustomerReference, 3, 10)
            WHEN pt.CustomerReference IS NOT NULL THEN pt.CustomerReference
            ELSE NULL
        END,
        'UNKNOWN'
    ) + '^FS' + CHAR(13) + CHAR(10) +
    '^XZ' as ZPL_Command
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10068
  AND pt.SerialNo LIKE 'EXADT%'
  AND pt.PartNo IS NOT NULL
ORDER BY pt.SerialNo;
