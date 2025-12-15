-- ================================================
-- INVESTIGATE DUMMY PART NUMBER LINE ITEM
-- ================================================
-- Purpose: Find out what the "PART" / "Dummy Part Number" line item should actually be
-- Order: TEMPRO25082713252402, ROLineID: 6146430, ROHeaderID: 5062569
-- ================================================

-- ================================================
-- 1. DETAILED ROLINE INFORMATION
-- ================================================
SELECT 
    'ROLINE DETAILS' AS ReportSection,
    rh.ID AS ROHeaderID,
    rh.CustomerReference AS FusionDetail,
    rol.ID AS ROLineID,
    rol.PartNo,
    rol.QtyToReceive AS ExpectedQty,
    rol.QtyReceived AS ReceivedQty,
    rol.StatusID,
    cs.Description AS LineStatus,
    rol.CreateDate AS LineCreateDate,
    rol.LastActivityDate AS LineLastActivity,
    rol.ConfigurationID,
    cc.Description AS Configuration,
    rol.Notes,
    rol.SerialNo AS LineSerialNo

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = rol.StatusID
LEFT JOIN Plus.pls.CodeConfiguration cc ON cc.ID = rol.ConfigurationID

WHERE rh.ProgramID = 10053
  AND (
      rh.CustomerReference = 'TEMPRO25082713252402'
      OR rh.ID = 5062569
      OR rol.ID = 6146430
  )

ORDER BY rol.ID;

-- ================================================
-- 2. ROLINE ATTRIBUTES (Custom attributes on the line)
-- ================================================
SELECT 
    'ROLINE ATTRIBUTES' AS ReportSection,
    rh.ID AS ROHeaderID,
    rh.CustomerReference AS FusionDetail,
    rol.ID AS ROLineID,
    rol.PartNo,
    ca.AttributeName,
    rla.Value AS AttributeValue,
    rla.CreateDate AS AttributeDate

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
INNER JOIN Plus.pls.ROLineAttribute rla ON rla.ROLineID = rol.ID
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = rla.AttributeID

WHERE rh.ProgramID = 10053
  AND (
      rh.CustomerReference = 'TEMPRO25082713252402'
      OR rh.ID = 5062569
      OR rol.ID = 6146430
  )

ORDER BY rol.ID, ca.AttributeName;

-- ================================================
-- 3. ROUNIT INFORMATION (Individual units on the line)
-- ================================================
SELECT 
    'ROUNIT DETAILS' AS ReportSection,
    rh.ID AS ROHeaderID,
    rh.CustomerReference AS FusionDetail,
    rol.ID AS ROLineID,
    rol.PartNo AS LinePartNo,
    ru.ID AS ROUnitID,
    ru.SerialNo AS UnitSerialNo,
    ru.Qty AS UnitQty,
    ru.StatusID,
    cs.Description AS UnitStatus,
    ru.CreateDate AS UnitCreateDate

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.ROUnit ru ON ru.ROLineID = rol.ID
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = ru.StatusID

WHERE rh.ProgramID = 10053
  AND (
      rh.CustomerReference = 'TEMPRO25082713252402'
      OR rh.ID = 5062569
      OR rol.ID = 6146430
  )

ORDER BY rol.ID, ru.ID;

-- ================================================
-- 4. ROUNIT ATTRIBUTES (Attributes on individual units)
-- ================================================
SELECT 
    'ROUNIT ATTRIBUTES' AS ReportSection,
    rh.ID AS ROHeaderID,
    rh.CustomerReference AS FusionDetail,
    rol.ID AS ROLineID,
    rol.PartNo AS LinePartNo,
    ru.ID AS ROUnitID,
    ru.SerialNo AS UnitSerialNo,
    ca.AttributeName,
    rua.Value AS AttributeValue,
    rua.CreateDate AS AttributeDate

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
INNER JOIN Plus.pls.ROUnit ru ON ru.ROLineID = rol.ID
INNER JOIN Plus.pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = rua.AttributeID

WHERE rh.ProgramID = 10053
  AND (
      rh.CustomerReference = 'TEMPRO25082713252402'
      OR rh.ID = 5062569
      OR rol.ID = 6146430
  )

ORDER BY rol.ID, ru.ID, ca.AttributeName;

-- ================================================
-- 5. ALL PART TRANSACTIONS FOR THIS ORDER (What was actually received)
-- ================================================
SELECT 
    'PART TRANSACTIONS' AS ReportSection,
    rh.ID AS ROHeaderID,
    rh.CustomerReference AS FusionDetail,
    rol.ID AS ROLineID,
    rol.PartNo AS ExpectedPartNo,
    pt.ID AS TransactionID,
    pt.PartNo AS TransactionPartNo,
    pt.SerialNo AS TransactionSerialNo,
    pt.Qty AS TransactionQty,
    cpt.Description AS TransactionType,
    pt.CreateDate AS TransactionDate,
    pt.Username AS TransactionUser,
    pt.Notes AS TransactionNotes,
    pt.PalletBoxNo AS BoxNumber

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.PartTransaction pt ON pt.OrderHeaderID = rh.ID 
    AND (pt.OrderLineID = rol.ID OR pt.OrderLineID IS NULL)
INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID

WHERE rh.ProgramID = 10053
  AND (
      rh.CustomerReference = 'TEMPRO25082713252402'
      OR rh.ID = 5062569
  )

ORDER BY pt.CreateDate DESC, rol.ID;

-- ================================================
-- 6. ROHEADER ATTRIBUTES (Order-level attributes that might have part info)
-- ================================================
SELECT 
    'ROHEADER ATTRIBUTES' AS ReportSection,
    rh.ID AS ROHeaderID,
    rh.CustomerReference AS FusionDetail,
    ca.AttributeName,
    rha.Value AS AttributeValue,
    rha.CreateDate AS AttributeDate

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROHeaderAttribute rha ON rha.ROHeaderID = rh.ID
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = rha.AttributeID

WHERE rh.ProgramID = 10053
  AND (
      rh.CustomerReference = 'TEMPRO25082713252402'
      OR rh.ID = 5062569
  )

ORDER BY ca.AttributeName;

-- ================================================
-- 7. COMPARE WITH OTHER LINES IN SAME ORDER
-- ================================================
SELECT 
    'ALL LINES COMPARISON' AS ReportSection,
    rh.ID AS ROHeaderID,
    rh.CustomerReference AS FusionDetail,
    rol.ID AS ROLineID,
    rol.PartNo,
    pn.Description AS PartDescription,
    rol.QtyToReceive AS ExpectedQty,
    (SELECT SUM(CAST(pt.Qty AS BIGINT))
     FROM Plus.pls.PartTransaction pt
     INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
     WHERE pt.OrderHeaderID = rh.ID
       AND pt.OrderLineID = rol.ID
       AND pt.ProgramID = rh.ProgramID
       AND cpt.Description = 'RO-RECEIVE'
    ) AS ActualReceivedQty,
    rol.QtyToReceive - COALESCE((SELECT SUM(CAST(pt.Qty AS BIGINT))
     FROM Plus.pls.PartTransaction pt
     INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
     WHERE pt.OrderHeaderID = rh.ID
       AND pt.OrderLineID = rol.ID
       AND pt.ProgramID = rh.ProgramID
       AND cpt.Description = 'RO-RECEIVE'
    ), 0) AS QtyDifference,
    CASE 
        WHEN rol.PartNo = 'PART' OR rol.PartNo LIKE '%DUMMY%' OR pn.Description LIKE '%DUMMY%' THEN 'DUMMY/PART'
        ELSE 'REAL PART'
    END AS PartType

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID
LEFT JOIN Plus.pls.PartNo pn ON pn.PartNo = rol.PartNo

WHERE rh.ProgramID = 10053
  AND (
      rh.CustomerReference = 'TEMPRO25082713252402'
      OR rh.ID = 5062569
  )

ORDER BY 
    CASE 
        WHEN rol.PartNo = 'PART' OR rol.PartNo LIKE '%DUMMY%' THEN 1
        ELSE 2
    END,
    rol.ID;

-- ================================================
-- 8. CHECK FOR SIMILAR ORDERS WITH SAME TRACKING
-- ================================================
SELECT 
    'SIMILAR ORDERS SAME TRACKING' AS ReportSection,
    rh.ID AS ROHeaderID,
    rh.CustomerReference AS FusionDetail,
    COALESCE(dl.TrackingNo, crst.TrackingNo, 'N/A') AS Tracking,
    COUNT(DISTINCT rol.ID) AS TotalLineItems,
    COUNT(DISTINCT CASE WHEN rol.PartNo = 'PART' OR rol.PartNo LIKE '%DUMMY%' THEN rol.ID END) AS DummyPartLines,
    COUNT(DISTINCT CASE WHEN rol.PartNo <> 'PART' AND rol.PartNo NOT LIKE '%DUMMY%' THEN rol.ID END) AS RealPartLines

FROM Plus.pls.ROHeader rh
INNER JOIN Plus.pls.ROLine rol ON rol.ROHeaderID = rh.ID

OUTER APPLY (
    SELECT TOP 1 dlx.TrackingNo
    FROM Plus.pls.RODockLog dlx 
    WHERE dlx.ROHeaderID = rh.ID 
    ORDER BY dlx.ID DESC
) AS dl

OUTER APPLY (
    SELECT TOP 1 crst1.TrackingNo
    FROM Plus.pls.CarrierResult crst1 
    WHERE crst1.OrderHeaderID = rh.ID 
      AND crst1.ProgramID = rh.ProgramID 
      AND crst1.OrderType = 'RO' 
    ORDER BY crst1.ID DESC
) AS crst

WHERE rh.ProgramID = 10053
  AND COALESCE(dl.TrackingNo, crst.TrackingNo) = '791907810771'

GROUP BY 
    rh.ID,
    rh.CustomerReference,
    COALESCE(dl.TrackingNo, crst.TrackingNo)

ORDER BY rh.CreateDate DESC;











