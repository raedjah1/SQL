/* =====================================================================================
   PERF NOTE (logic unchanged):
   This report was slow mainly because it repeatedly JOINed CodeAttribute inside multiple
   OUTER APPLY blocks (per row). We resolve AttributeIDs once, then pivot by AttributeID.
   ===================================================================================== */

-- NOTE: Removed unit-attribute output columns for performance (Mac/IMEI/Battery/Wipe/TechID/DateCode).
-- We keep only the attribute IDs still required for the existing disposition/warranty logic.
DECLARE @Attr_WARRANTY_STATUS INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'WARRANTY_STATUS');
DECLARE @Attr_DISPOSITION     INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'DISPOSITION');

DECLARE @Attr_FLAGGED_BOXES   INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'FLAGGED_BOXES');
DECLARE @Attr_CUSTOMERTYPE    INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'CUSTOMERTYPE');
DECLARE @Attr_RETURNTYPE      INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'RETURNTYPE');
DECLARE @Attr_TOTAL_UNITS     INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'TOTAL_UNITS');
DECLARE @Attr_BRANCHES        INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'BRANCHES');

DECLARE @Attr_WARRANTY_TERM   INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'WARRANTY_TERM');
DECLARE @Attr_COST            INT = (SELECT TOP 1 ID FROM Plus.pls.CodeAttribute WHERE UPPER(AttributeName) = 'COST');

-- Date window (keep CreateDate sargable: no CAST on rec.CreateDate)
DECLARE @StartDate DATETIME2(0) = '2025-11-01 00:00:00';
DECLARE @EndDateExclusive DATETIME2(0) = '2025-12-01 00:00:00';

-- Resolve RO-RECEIVE transaction type once (avoid join to CodePartTransaction)
DECLARE @RO_RECEIVE_ID INT = (
    SELECT TOP 1 ID
    FROM Plus.pls.CodePartTransaction
    WHERE UPPER([Description]) = 'RO-RECEIVE'
);

SELECT 
    rec.CreateDate AS "Date Received",
    dl.TrackingNo AS "Tracking Number",
    rec.CustomerReference AS ASN,
    FlgBx.FlgBx AS "Flagged Box",
    CASE WHEN SUBSTRING(Branch.Value,1,1)='0' THEN SUBSTRING(Branch.Value,2,10) ELSE Branch.Value END AS "Branch ID",
    rec.PartNo AS "Part No",
    rec.SerialNo AS "Serial No",
    dl.ID AS "Dock Log ID",
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'RMA'
      ELSE COALESCE(clean.CleanSerialDisposition, clean.CleanPartDisposition)
    END AS Disposition,
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'IW'
      WHEN COALESCE(clean.CleanWarrantyStatus, '') = 'UKN' THEN 'UKN'
      ELSE 'OOW'
    END AS "Warranty Status",
    rec.ProgramID AS ProgramID,
    rh.ID AS RMANumber,
    FlgBx.CustType AS RMAType,
    FlgBx.ReturnType AS Dept,
    FlgBx.TotalUnits AS "Total Units",
    CASE 
        WHEN ISNUMERIC(prtatt.Cost) = 1 THEN CAST(prtatt.Cost AS DECIMAL(10,2))
        ELSE NULL
    END AS Cost

FROM Plus.pls.PartTransaction AS rec
JOIN Plus.pls.ROHeader AS rh ON rh.ID = rec.OrderHeaderID
JOIN Plus.pls.CodeAddress AS adr ON adr.ID = rh.AddressID
JOIN Plus.pls.CodeAddressDetails AS adt ON adt.AddressID = adr.ID
JOIN Plus.pls.RODockLog AS dl ON dl.ID = rec.RODockLogID
JOIN Plus.pls.PartNo AS prt ON prt.PartNo = rec.PartNo
JOIN Plus.pls.PartSerial AS ps
  ON ps.ProgramID = rec.ProgramID AND ps.PartNo = rec.PartNo AND ps.SerialNo = rec.SerialNo AND ps.ROHeaderID = rh.ID
OUTER APPLY (
    SELECT psa.PartSerialID,
           MAX(CASE WHEN psa.AttributeID = @Attr_WARRANTY_STATUS THEN psa.Value END) AS WarrantyStatus,
           MAX(CASE WHEN psa.AttributeID = @Attr_DISPOSITION     THEN psa.Value END) AS SerialDisposition
    FROM Plus.pls.PartSerialAttribute AS psa
    WHERE psa.PartSerialID = ps.ID
      AND psa.AttributeID IN (@Attr_WARRANTY_STATUS,@Attr_DISPOSITION)
    GROUP BY psa.PartSerialID
) AS prsr
OUTER APPLY (
    SELECT ru.ID AS ROUnitID,
           MAX(CASE WHEN rua.AttributeID = @Attr_WARRANTY_STATUS THEN rua.Value END) AS WarrantyStatus,
           MAX(CASE WHEN rua.AttributeID = @Attr_DISPOSITION     THEN rua.Value END) AS SerialDisposition
    FROM Plus.pls.ROLine rl 
    JOIN Plus.pls.ROUnit ru ON ru.ROLineID = rl.ID AND ru.SerialNo = ps.SerialNo
    JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID 
    WHERE rl.ROHeaderID = rh.ID  AND rl.ID = rec.OrderLineID 
      AND rua.AttributeID IN (@Attr_WARRANTY_STATUS,@Attr_DISPOSITION)
    GROUP BY ru.ID 
) AS rosr
OUTER APPLY (
    SELECT fb.ROHeaderID,
    MAX(CASE WHEN fb.AttributeID = @Attr_FLAGGED_BOXES AND fb.Value='NO' THEN 'Good' ELSE 'Bad' END) AS FlgBx,
    MAX(CASE WHEN fb.AttributeID = @Attr_CUSTOMERTYPE THEN fb.Value ELSE NULL END) AS CustType,
    MAX(CASE WHEN fb.AttributeID = @Attr_RETURNTYPE THEN fb.Value ELSE NULL END) AS ReturnType,
    MAX(CASE WHEN fb.AttributeID = @Attr_TOTAL_UNITS THEN fb.Value ELSE NULL END) AS TotalUnits
    FROM Plus.pls.ROHeaderAttribute AS fb
    WHERE fb.ROHeaderID = rh.ID
      AND fb.AttributeID IN (@Attr_FLAGGED_BOXES,@Attr_CUSTOMERTYPE,@Attr_RETURNTYPE,@Attr_TOTAL_UNITS)
    GROUP BY fb.ROHeaderID 
) AS FlgBx
OUTER APPLY (
    SELECT brc.Value
    FROM Plus.pls.CodeAddressDetailsAttribute AS brc
    WHERE brc.AddressDetailID = adt.ID
      AND brc.AttributeID = @Attr_BRANCHES
) AS Branch
OUTER APPLY (
    SELECT dc.PartNo,
           MAX(CASE WHEN dc.AttributeID = @Attr_WARRANTY_TERM THEN dc.Value END) AS DateCode,
           MAX(CASE WHEN dc.AttributeID = @Attr_DISPOSITION   THEN dc.Value END) AS PartDisposition,
           MAX(CASE WHEN dc.AttributeID = @Attr_COST          THEN dc.Value END) AS Cost
    FROM Plus.pls.PartNoAttribute AS dc
    WHERE dc.PartNo = prt.PartNo AND dc.ProgramID = rec.ProgramID
      AND dc.AttributeID IN (@Attr_WARRANTY_TERM,@Attr_DISPOSITION,@Attr_COST)
    GROUP BY dc.PartNo
) AS prtatt
/* CLEAN ONCE, USE EVERYWHERE */
OUTER APPLY (
    SELECT
      -- remove tabs/newlines, trim, upper, null blanks
      CleanWarrantyStatus =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.WarrantyStatus,rosr.WarrantyStatus), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanSerialDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.SerialDisposition,rosr.SerialDisposition), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanPartDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prtatt.PartDisposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),'')
) AS clean
WHERE rec.ProgramID IN (10068, 10072) 
  AND rec.PartTransactionID = @RO_RECEIVE_ID
  AND adt.AddressType = 'ShipFrom'
  AND rec.CreateDate >= @StartDate
  AND rec.CreateDate <  @EndDateExclusive

UNION

-- history fallback
SELECT 
    rec.CreateDate AS "Date Received",
    dl.TrackingNo AS "Tracking Number",
    rec.CustomerReference AS ASN,
    FlgBx.FlgBx AS "Flagged Box",
    CASE WHEN SUBSTRING(Branch.Value,1,1)='0' THEN SUBSTRING(Branch.Value,2,10) ELSE Branch.Value END AS "Branch ID",
    rec.PartNo AS "Part No",
    rec.SerialNo AS "Serial No",
    dl.ID AS "Dock Log ID",
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'RMA'
      ELSE COALESCE(clean.CleanSerialDisposition, clean.CleanPartDisposition)
    END AS Disposition,
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'IW'
      WHEN COALESCE(clean.CleanWarrantyStatus, '') = 'UKN' THEN 'UKN'
      ELSE 'OOW'
    END AS "Warranty Status",
    rec.ProgramID AS ProgramID,
    rh.ID AS RMANumber,
    FlgBx.CustType AS RMAType,
    FlgBx.ReturnType AS Dept,
    FlgBx.TotalUnits AS "Total Units",
    CASE 
        WHEN ISNUMERIC(prtatt.Cost) = 1 THEN CAST(prtatt.Cost AS DECIMAL(10,2))
        ELSE NULL
    END AS Cost

FROM Plus.pls.PartTransaction AS rec
JOIN Plus.pls.ROHeader AS rh ON rh.ID = rec.OrderHeaderID
JOIN Plus.pls.CodeAddress AS adr ON adr.ID = rh.AddressID
JOIN Plus.pls.CodeAddressDetails AS adt ON adt.AddressID = adr.ID
JOIN Plus.pls.RODockLog AS dl ON dl.ID = rec.RODockLogID
JOIN Plus.pls.PartSerialHistory AS ps
  ON ps.ProgramID = rec.ProgramID AND ps.PartNo = rec.PartNo AND ps.SerialNo = rec.SerialNo AND ps.ROHeaderID = rh.ID
JOIN Plus.pls.PartNo AS prt ON prt.PartNo = rec.PartNo
OUTER APPLY (
    SELECT fb.ROHeaderID,
    MAX(CASE WHEN fb.AttributeID = @Attr_FLAGGED_BOXES AND fb.Value='NO' THEN 'Good' ELSE 'Bad' END) AS FlgBx,
    MAX(CASE WHEN fb.AttributeID = @Attr_CUSTOMERTYPE THEN fb.Value ELSE NULL END) AS CustType,
    MAX(CASE WHEN fb.AttributeID = @Attr_RETURNTYPE THEN fb.Value ELSE NULL END) AS ReturnType,
    MAX(CASE WHEN fb.AttributeID = @Attr_TOTAL_UNITS THEN fb.Value ELSE NULL END) AS TotalUnits
    FROM Plus.pls.ROHeaderAttribute AS fb
    WHERE fb.ROHeaderID = rh.ID
      AND fb.AttributeID IN (@Attr_FLAGGED_BOXES,@Attr_CUSTOMERTYPE,@Attr_RETURNTYPE,@Attr_TOTAL_UNITS)
    GROUP BY fb.ROHeaderID 
) AS FlgBx
OUTER APPLY (
    SELECT brc.Value
    FROM Plus.pls.CodeAddressDetailsAttribute AS brc
    WHERE brc.AddressDetailID = adt.ID
      AND brc.AttributeID = @Attr_BRANCHES
) AS Branch
OUTER APPLY (
    SELECT psa.PartSerialHistoryID,
           MAX(CASE WHEN psa.AttributeID = @Attr_WARRANTY_STATUS THEN psa.Value END) AS WarrantyStatus,
           MAX(CASE WHEN psa.AttributeID = @Attr_DISPOSITION     THEN psa.Value END) AS SerialDisposition
    FROM Plus.pls.PartSerialAttributeHistory AS psa
    WHERE psa.PartSerialHistoryID = ps.ID
      AND psa.AttributeID IN (@Attr_WARRANTY_STATUS,@Attr_DISPOSITION)
    GROUP BY psa.PartSerialHistoryID
) AS prsr
OUTER APPLY (
    SELECT ru.ID AS ROUnitID,
           MAX(CASE WHEN rua.AttributeID = @Attr_WARRANTY_STATUS THEN rua.Value END) AS WarrantyStatus,
           MAX(CASE WHEN rua.AttributeID = @Attr_DISPOSITION     THEN rua.Value END) AS SerialDisposition
    FROM Plus.pls.ROLine rl 
    JOIN Plus.pls.ROUnit ru ON ru.ROLineID = rl.ID AND ru.SerialNo = ps.SerialNo
    JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID 
    WHERE rl.ROHeaderID = rh.ID AND rl.ID = rec.OrderLineID
      AND rua.AttributeID IN (@Attr_WARRANTY_STATUS,@Attr_DISPOSITION)
    GROUP BY ru.ID 
) AS rosr
OUTER APPLY (
    SELECT dc.PartNo,
           MAX(CASE WHEN dc.AttributeID = @Attr_WARRANTY_TERM THEN dc.Value END) AS DateCode,
           MAX(CASE WHEN dc.AttributeID = @Attr_DISPOSITION   THEN dc.Value END) AS PartDisposition,
           MAX(CASE WHEN dc.AttributeID = @Attr_COST          THEN dc.Value END) AS Cost
    FROM Plus.pls.PartNoAttribute AS dc
    WHERE dc.PartNo = prt.PartNo AND dc.ProgramID = rec.ProgramID
      AND dc.AttributeID IN (@Attr_WARRANTY_TERM,@Attr_DISPOSITION,@Attr_COST)
    GROUP BY dc.PartNo
) AS prtatt
/* CLEAN ONCE, USE EVERYWHERE */
OUTER APPLY (
SELECT 
      CleanWarrantyStatus =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.WarrantyStatus,rosr.WarrantyStatus), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanSerialDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(COALESCE(prsr.SerialDisposition,rosr.SerialDisposition), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanPartDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prtatt.PartDisposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),'')
) AS clean
WHERE rec.ProgramID IN (10068, 10072)
  AND rec.PartTransactionID = @RO_RECEIVE_ID
  AND adt.AddressType = 'ShipFrom'
  AND rec.CreateDate >= @StartDate
  AND rec.CreateDate <  @EndDateExclusive

UNION ALL 

SELECT 
    rec.CreateDate AS "Date Received",
    dl.TrackingNo AS "Tracking Number",
    rec.CustomerReference AS ASN,
    FlgBx.FlgBx AS "Flagged Box",
    CASE WHEN SUBSTRING(Branch.Value,1,1)='0' THEN SUBSTRING(Branch.Value,2,10) ELSE Branch.Value END AS "Branch ID",
    rec.PartNo AS "Part No",
    rec.SerialNo AS "Serial No",
    dl.ID AS "Dock Log ID",
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'RMA'
      ELSE COALESCE(clean.CleanSerialDisposition, clean.CleanPartDisposition)
    END AS Disposition,
    CASE
      WHEN COALESCE(clean.CleanWarrantyStatus, '') IN ('IN WARRANTY','IW','IN_WARRANTY') THEN 'IW'
      WHEN COALESCE(clean.CleanWarrantyStatus, '') = 'UKN' THEN 'UKN'
      ELSE 'OOW'
    END AS "Warranty Status",
    rec.ProgramID AS ProgramID,
    rh.ID AS RMANumber,
    FlgBx.CustType AS RMAType,
    FlgBx.ReturnType AS Dept,
    FlgBx.TotalUnits AS "Total Units",
    CASE 
        WHEN ISNUMERIC(prtatt.Cost) = 1 THEN CAST(prtatt.Cost AS DECIMAL(10,2))
        ELSE NULL
    END AS Cost

FROM Plus.pls.PartTransaction AS rec
JOIN Plus.pls.CodePartTransaction AS rcd ON rcd.ID = rec.PartTransactionID
JOIN Plus.pls.ROHeader AS rh ON rh.ID = rec.OrderHeaderID
JOIN Plus.pls.CodeAddress AS adr ON adr.ID = rh.AddressID
JOIN Plus.pls.CodeAddressDetails AS adt ON adt.AddressID = adr.ID
JOIN Plus.pls.RODockLog AS dl ON dl.ID = rec.RODockLogID
JOIN Plus.pls.PartNo AS prt ON prt.PartNo = rec.PartNo
JOIN Plus.pls.ROLine AS rl ON rl.ROHeaderID = rh.ID AND rl.PartNo = rec.PartNo AND rl.ID = rec.OrderLineID 

CROSS APPLY (

    SELECT ru.ID AS ROUnitID,
           MAX(CASE WHEN rua.AttributeID = @Attr_WARRANTY_STATUS THEN rua.Value END) AS WarrantyStatus,
           MAX(CASE WHEN rua.AttributeID = @Attr_DISPOSITION     THEN rua.Value END) AS SerialDisposition

    FROM Plus.pls.ROUnit ru 
    JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID 
    WHERE ru.ROLineID = rl.ID AND ru.SerialNo = rec.SerialNo
      AND rua.AttributeID IN (@Attr_WARRANTY_STATUS,@Attr_DISPOSITION)
    GROUP BY ru.ID 
) AS prsr
OUTER APPLY (
    SELECT fb.ROHeaderID,
    MAX(CASE WHEN fb.AttributeID = @Attr_FLAGGED_BOXES AND fb.Value='NO' THEN 'Good' ELSE 'Bad' END) AS FlgBx,
    MAX(CASE WHEN fb.AttributeID = @Attr_CUSTOMERTYPE THEN fb.Value ELSE NULL END) AS CustType,
    MAX(CASE WHEN fb.AttributeID = @Attr_RETURNTYPE THEN fb.Value ELSE NULL END) AS ReturnType,
    MAX(CASE WHEN fb.AttributeID = @Attr_TOTAL_UNITS THEN fb.Value ELSE NULL END) AS TotalUnits
    FROM Plus.pls.ROHeaderAttribute AS fb
    WHERE fb.ROHeaderID = rh.ID
      AND fb.AttributeID IN (@Attr_FLAGGED_BOXES,@Attr_CUSTOMERTYPE,@Attr_RETURNTYPE,@Attr_TOTAL_UNITS)
    GROUP BY fb.ROHeaderID 
) AS FlgBx
OUTER APPLY (
    SELECT brc.Value
    FROM Plus.pls.CodeAddressDetailsAttribute AS brc
    WHERE brc.AddressDetailID = adt.ID
      AND brc.AttributeID = @Attr_BRANCHES
) AS Branch
OUTER APPLY (
    SELECT dc.PartNo,
           MAX(CASE WHEN dc.AttributeID = @Attr_WARRANTY_TERM THEN dc.Value END) AS DateCode,
           MAX(CASE WHEN dc.AttributeID = @Attr_DISPOSITION   THEN dc.Value END) AS PartDisposition,
           MAX(CASE WHEN dc.AttributeID = @Attr_COST          THEN dc.Value END) AS Cost
    FROM Plus.pls.PartNoAttribute AS dc
    WHERE dc.PartNo = prt.PartNo AND dc.ProgramID = rec.ProgramID
      AND dc.AttributeID IN (@Attr_WARRANTY_TERM,@Attr_DISPOSITION,@Attr_COST)
    GROUP BY dc.PartNo
) AS prtatt
/* CLEAN ONCE, USE EVERYWHERE */
OUTER APPLY (
    SELECT
      -- remove tabs/newlines, trim, upper, null blanks
      CleanWarrantyStatus =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prsr.WarrantyStatus, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanSerialDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prsr.SerialDisposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),''),
      CleanPartDisposition =
        NULLIF(UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(prtatt.PartDisposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' ')))),'')
) AS clean

WHERE rec.ProgramID IN (10068, 10072) 
  AND rec.PartTransactionID = @RO_RECEIVE_ID
  AND adt.AddressType = 'ShipFrom'
  AND rec.SerialNo = '*'
  AND rec.CreateDate >= @StartDate
  AND rec.CreateDate <  @EndDateExclusive