-- ESSENTIAL Receipt Report (FAST-ish, set-based enrichment)
-- NOTE: Some environments (reports/PowerBI) block DDL (temp tables, CREATE INDEX).
-- This version uses ONLY CTEs + set-based GROUP BY (no temp tables, no CREATE INDEX).

SET NOCOUNT ON;

DECLARE @ProgramID INT = 10068; -- ADT (change if needed)
DECLARE @StartDate DATETIME2(0) = '2025-11-01 00:00:00';
DECLARE @EndDateExclusive DATETIME2(0) = '2025-12-01 00:00:00';

DECLARE @RO_RECEIVE_ID INT = (
    SELECT TOP 1 ID
    FROM Plus.pls.CodePartTransaction
    WHERE UPPER([Description]) = 'RO-RECEIVE'
);

-- Attribute IDs (resolve once)
DECLARE @Attr_FLAGGED_BOXES   INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'FLAGGED_BOXES');
DECLARE @Attr_CUSTOMERTYPE    INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'CUSTOMERTYPE');
DECLARE @Attr_RETURNTYPE      INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'RETURNTYPE');
DECLARE @Attr_TOTAL_UNITS     INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'TOTAL_UNITS');
DECLARE @Attr_BRANCHES        INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'BRANCHES');

DECLARE @Attr_WARRANTY_STATUS INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'WARRANTY_STATUS');
DECLARE @Attr_DISPOSITION     INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'DISPOSITION');
DECLARE @Attr_WARRANTY_TERM   INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'WARRANTY_TERM');
DECLARE @Attr_COST            INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'COST');

WITH BaseReceipts AS (
    SELECT
        rec.ID AS ReceiptTransactionID,
        rec.ProgramID,
        rec.CreateDate AS DateReceived,
        rec.RODockLogID,
        rec.CustomerReference AS ASN,
        rec.OrderHeaderID AS RMANumber,
        rec.OrderLineID AS ROLineID,
        rec.PartNo,
        rec.SerialNo,
        rec.Qty,
        rh.AddressID
    FROM Plus.pls.PartTransaction AS rec
    INNER JOIN Plus.pls.ROHeader AS rh
        ON rh.ID = rec.OrderHeaderID
    WHERE rec.ProgramID = @ProgramID
      AND rec.PartTransactionID = @RO_RECEIVE_ID
      AND rec.CreateDate >= @StartDate
      AND rec.CreateDate <  @EndDateExclusive
),
DockLog AS (
    SELECT
        br.ReceiptTransactionID,
        dl.ID AS DockLogID,
        dl.CreateDate AS DockLogCreateDate,
        dl.TrackingNo AS TrackingNumber
    FROM BaseReceipts br
    INNER JOIN Plus.pls.RODockLog dl
        ON dl.ID = br.RODockLogID
),
HdrAttr AS (
    SELECT
        br.RMANumber,
        MAX(CASE WHEN fb.AttributeID = @Attr_FLAGGED_BOXES AND fb.Value = 'NO' THEN 'Good' ELSE 'Bad' END) AS FlaggedBox,
        MAX(CASE WHEN fb.AttributeID = @Attr_CUSTOMERTYPE THEN fb.Value END) AS CustomerType,
        MAX(CASE WHEN fb.AttributeID = @Attr_RETURNTYPE THEN fb.Value END) AS ReturnType,
        MAX(CASE WHEN fb.AttributeID = @Attr_TOTAL_UNITS THEN fb.Value END) AS TotalUnits
    FROM (SELECT DISTINCT RMANumber FROM BaseReceipts) br
    LEFT JOIN Plus.pls.ROHeaderAttribute fb
        ON fb.ROHeaderID = br.RMANumber
       AND fb.AttributeID IN (@Attr_FLAGGED_BOXES, @Attr_CUSTOMERTYPE, @Attr_RETURNTYPE, @Attr_TOTAL_UNITS)
    GROUP BY br.RMANumber
),
RankedBranch AS (
    SELECT
        br.RMANumber,
        brc.Value AS BranchValue,
        ROW_NUMBER() OVER (PARTITION BY br.RMANumber ORDER BY brc.ID DESC) AS rn
    FROM (SELECT DISTINCT RMANumber, AddressID FROM BaseReceipts) br
    INNER JOIN Plus.pls.CodeAddressDetails adt
        ON adt.AddressID = br.AddressID
       AND adt.AddressType = 'ShipFrom'
    INNER JOIN Plus.pls.CodeAddressDetailsAttribute brc
        ON brc.AddressDetailID = adt.ID
       AND brc.AttributeID = @Attr_BRANCHES
),
Branch AS (
    SELECT RMANumber, BranchValue
    FROM RankedBranch
    WHERE rn = 1
),
PartNoAttr AS (
    SELECT
        bp.ProgramID,
        bp.PartNo,
        MAX(CASE WHEN pna.AttributeID = @Attr_WARRANTY_TERM THEN pna.Value END) AS WarrantyTerm,
        MAX(CASE WHEN pna.AttributeID = @Attr_DISPOSITION   THEN pna.Value END) AS PartDisposition,
        MAX(CASE WHEN pna.AttributeID = @Attr_COST          THEN pna.Value END) AS CostRaw
    FROM (SELECT DISTINCT ProgramID, PartNo FROM BaseReceipts) bp
    LEFT JOIN Plus.pls.PartNoAttribute pna
        ON pna.ProgramID = bp.ProgramID
       AND pna.PartNo = bp.PartNo
       AND pna.AttributeID IN (@Attr_WARRANTY_TERM, @Attr_DISPOSITION, @Attr_COST)
    GROUP BY bp.ProgramID, bp.PartNo
),
PSA AS (
    SELECT
        br.ReceiptTransactionID,
        MAX(CASE WHEN psa.AttributeID = @Attr_WARRANTY_STATUS THEN psa.Value END) AS WarrantyStatus,
        MAX(CASE WHEN psa.AttributeID = @Attr_DISPOSITION     THEN psa.Value END) AS SerialDisposition
    FROM BaseReceipts br
    LEFT JOIN Plus.pls.PartSerial ps
        ON ps.ProgramID = br.ProgramID
       AND ps.PartNo = br.PartNo
       AND ps.SerialNo = br.SerialNo
    LEFT JOIN Plus.pls.PartSerialAttribute psa
        ON psa.PartSerialID = ps.ID
       AND psa.AttributeID IN (@Attr_WARRANTY_STATUS, @Attr_DISPOSITION)
    GROUP BY br.ReceiptTransactionID
),
RUA AS (
    SELECT
        br.ReceiptTransactionID,
        MAX(CASE WHEN rua.AttributeID = @Attr_WARRANTY_STATUS THEN rua.Value END) AS WarrantyStatus,
        MAX(CASE WHEN rua.AttributeID = @Attr_DISPOSITION     THEN rua.Value END) AS SerialDisposition
    FROM BaseReceipts br
    LEFT JOIN Plus.pls.ROLine rl
        ON rl.ROHeaderID = br.RMANumber
       AND rl.ID = br.ROLineID
    LEFT JOIN Plus.pls.ROUnit ru
        ON ru.ROLineID = rl.ID
       AND ru.SerialNo = br.SerialNo
    LEFT JOIN Plus.pls.ROUnitAttribute rua
        ON rua.ROUnitID = ru.ID
       AND rua.AttributeID IN (@Attr_WARRANTY_STATUS, @Attr_DISPOSITION)
    GROUP BY br.ReceiptTransactionID
)
SELECT
    br.DateReceived,
    dl.DockLogID,
    dl.DockLogCreateDate,
    dl.TrackingNumber,
    br.ASN,
    br.RMANumber,
    br.ROLineID,
    br.PartNo,
    br.SerialNo,
    br.Qty,
    CASE
        WHEN b.BranchValue IS NULL THEN NULL
        WHEN LEFT(b.BranchValue, 1) = '0' THEN SUBSTRING(b.BranchValue, 2, 10)
        ELSE b.BranchValue
    END AS BranchID,
    ha.FlaggedBox,
    ha.CustomerType,
    ha.ReturnType,
    ha.TotalUnits,
    pna.WarrantyTerm,
    pna.PartDisposition,
    CASE WHEN ISNUMERIC(pna.CostRaw) = 1 THEN CAST(pna.CostRaw AS DECIMAL(10,2)) ELSE NULL END AS Cost,
    COALESCE(psa.WarrantyStatus, rua.WarrantyStatus) AS WarrantyStatusRaw,
    COALESCE(psa.SerialDisposition, rua.SerialDisposition) AS SerialDispositionRaw,
    CASE
        WHEN UPPER(LTRIM(RTRIM(COALESCE(psa.WarrantyStatus, rua.WarrantyStatus, '')))) IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'IW'
        WHEN UPPER(LTRIM(RTRIM(COALESCE(psa.WarrantyStatus, rua.WarrantyStatus, '')))) = 'UKN' THEN 'UKN'
        ELSE 'OOW'
    END AS [Warranty Status],
    CASE
        WHEN UPPER(LTRIM(RTRIM(COALESCE(psa.WarrantyStatus, rua.WarrantyStatus, '')))) IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'RMA'
        ELSE COALESCE(
            NULLIF(UPPER(LTRIM(RTRIM(COALESCE(psa.SerialDisposition, rua.SerialDisposition)))), ''),
            NULLIF(UPPER(LTRIM(RTRIM(pna.PartDisposition))), '')
        )
    END AS Disposition
FROM BaseReceipts br
INNER JOIN DockLog dl ON dl.ReceiptTransactionID = br.ReceiptTransactionID
LEFT JOIN HdrAttr ha ON ha.RMANumber = br.RMANumber
LEFT JOIN Branch b ON b.RMANumber = br.RMANumber
LEFT JOIN PartNoAttr pna ON pna.ProgramID = br.ProgramID AND pna.PartNo = br.PartNo
LEFT JOIN PSA psa ON psa.ReceiptTransactionID = br.ReceiptTransactionID
LEFT JOIN RUA rua ON rua.ReceiptTransactionID = br.ReceiptTransactionID
ORDER BY br.DateReceived DESC, br.PartNo, br.SerialNo;


