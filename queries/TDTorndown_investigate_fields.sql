-- ============================================
-- INVESTIGATE ALL AVAILABLE FIELDS
-- For TDTorndown Query - See what other useful data is available
-- ============================================

-- 1. PartTransaction Table - All Available Fields
SELECT 
    'PartTransaction Fields' AS Source,
    pt.ID,
    pt.ProgramID,
    pt.PartNo,
    pt.SerialNo,
    pt.ParentSerialNo,  -- ⭐ Available but not currently used
    pt.Qty,
    pt.PartTransactionID,
    pt.Location,  -- FromLocation
    pt.ToLocation,
    pt.CustomerReference,
    pt.OrderHeaderID,  -- ⭐ ROHeaderID or SOHeaderID
    pt.OrderLineID,  -- ⭐ ROLineID or SOLineID
    pt.RODockLogID,  -- ⭐ Dock log reference
    pt.UserID,
    pt.CreateDate,
    pt.Reason,  -- ⭐ Notes/reason for transaction
    pt.PalletBoxNo,  -- ⭐ Pallet/Box number
    pt.ToPalletBoxNo,  -- ⭐ Destination pallet/box
    pt.LotNo,  -- ⭐ Lot number
    pt.Source,  -- ⭐ Source field
    pt.Condition,  -- ⭐ Condition field
    pt.Configuration,  -- ⭐ Configuration field
    pt.OrderType,  -- ⭐ Order type (RO/SO)
    pt.SourcePartNo,  -- ⭐ Source part number
    pt.SourceSerialNo  -- ⭐ Source serial number
FROM Plus.pls.PartTransaction pt
WHERE UPPER(pt.ToLocation) LIKE '%TORNDOWN%'
    AND pt.ProgramID = 10053
ORDER BY pt.CreateDate DESC;

-- 2. PartSerial (Current Serial) - Additional Available Fields
SELECT 
    'PartSerial (Current) Fields' AS Source,
    ps.ID,
    ps.SerialNo,
    ps.PartNo,
    ps.ParentSerialNo,
    ps.LocationID,
    ps.StatusID,  -- ⭐ Status (NEW, RECEIVED, WIP, etc.)
    ps.ConfigurationID,  -- ⭐ Good/Bad configuration
    ps.WorkStationID,  -- ⭐ Workstation
    ps.ROHeaderID,  -- ⭐ Return order reference
    ps.SOHeaderID,  -- ⭐ Sales order reference
    ps.WOHeaderID,  -- ⭐ Work order reference
    ps.PalletBoxNo,
    ps.LotNo,
    ps.RODate,  -- ⭐ RO date
    ps.SODate,  -- ⭐ SO date
    ps.WOStartDate,  -- ⭐ Work order start
    ps.WOEndDate,  -- ⭐ Work order end
    ps.WOPass,  -- ⭐ Work order pass/fail
    ps.Shippable,  -- ⭐ Shippable flag
    ps.UserID,
    ps.CreateDate,
    ps.LastActivityDate
FROM Plus.pls.PartSerial ps
INNER JOIN Plus.pls.PartTransaction pt ON pt.SerialNo = ps.SerialNo
WHERE UPPER(pt.ToLocation) LIKE '%TORNDOWN%'
    AND pt.ProgramID = 10053
ORDER BY pt.CreateDate DESC;

-- 3. PartSerial (Parent Serial) - Additional Available Fields
SELECT 
    'PartSerial (Parent) Fields' AS Source,
    ps_parent.ID,
    ps_parent.SerialNo AS ParentSerialNo,
    ps_parent.PartNo AS ParentPartNo,
    ps_parent.LocationID AS ParentLocationID,
    ps_parent.StatusID AS ParentStatusID,
    ps_parent.ROHeaderID AS ParentROHeaderID,
    ps_parent.SOHeaderID AS ParentSOHeaderID,
    ps_parent.WOHeaderID AS ParentWOHeaderID,
    ps_parent.CreateDate AS ParentCreateDate,
    ps_parent.LastActivityDate AS ParentLastActivityDate
FROM Plus.pls.PartTransaction pt
LEFT JOIN Plus.pls.PartSerial ps ON ps.SerialNo = pt.SerialNo
CROSS APPLY (
    SELECT REPLACE(COALESCE(pt.ParentSerialNo, ps.ParentSerialNo, ''), 'KIT-', '') AS CleanParentSN
) cleaned_part
LEFT JOIN Plus.pls.PartSerial ps_parent ON ps_parent.SerialNo = cleaned_part.CleanParentSN
WHERE UPPER(pt.ToLocation) LIKE '%TORNDOWN%'
    AND pt.ProgramID = 10053
ORDER BY pt.CreateDate DESC;

-- 4. PartLocation - Additional Available Fields
SELECT 
    'PartLocation Fields' AS Source,
    pl.ID,
    pl.LocationNo,
    pl.Warehouse,
    pl.Bin,  -- ⭐ Available but not currently used
    pl.Bay,  -- ⭐ Available but not currently used
    pl.ProgramID,
    pl.CreateDate,
    pl.LastActivityDate
FROM Plus.pls.PartLocation pl
INNER JOIN Plus.pls.PartTransaction pt ON pt.ToLocation = pl.LocationNo
WHERE UPPER(pt.ToLocation) LIKE '%TORNDOWN%'
    AND pt.ProgramID = 10053
ORDER BY pt.CreateDate DESC;

-- 5. Available Attributes from PartSerialAttribute (Parent Serial)
SELECT DISTINCT
    'Parent Serial Attributes' AS Source,
    ca.AttributeName,
    ca.ID AS AttributeID,
    COUNT(*) AS UsageCount
FROM Plus.pls.PartTransaction pt
LEFT JOIN Plus.pls.PartSerial ps ON ps.SerialNo = pt.SerialNo
CROSS APPLY (
    SELECT REPLACE(COALESCE(pt.ParentSerialNo, ps.ParentSerialNo, ''), 'KIT-', '') AS CleanParentSN
) cleaned_part
LEFT JOIN Plus.pls.PartSerial ps_parent ON ps_parent.SerialNo = cleaned_part.CleanParentSN
INNER JOIN Plus.pls.PartSerialAttribute psa ON psa.PartSerialID = ps_parent.ID
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
WHERE UPPER(pt.ToLocation) LIKE '%TORNDOWN%'
    AND pt.ProgramID = 10053
GROUP BY ca.AttributeName, ca.ID
ORDER BY UsageCount DESC;

-- 6. Available Attributes from PartSerialAttribute (Current Serial)
SELECT DISTINCT
    'Current Serial Attributes' AS Source,
    ca.AttributeName,
    ca.ID AS AttributeID,
    COUNT(*) AS UsageCount
FROM Plus.pls.PartTransaction pt
LEFT JOIN Plus.pls.PartSerial ps ON ps.SerialNo = pt.SerialNo
INNER JOIN Plus.pls.PartSerialAttribute psa ON psa.PartSerialID = ps.ID
INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
WHERE UPPER(pt.ToLocation) LIKE '%TORNDOWN%'
    AND pt.ProgramID = 10053
GROUP BY ca.AttributeName, ca.ID
ORDER BY UsageCount DESC;

-- 7. ROHeader/SOHeader References - If Available
SELECT 
    'Order Header References' AS Source,
    pt.SerialNo,
    pt.OrderHeaderID,
    pt.OrderLineID,
    rh.CustomerReference AS ROCustomerReference,  -- ⭐ RO ASN
    soh.CustomerReference AS SOCustomerReference,  -- ⭐ SO Reference
    rh.CreateDate AS ROCreateDate,
    soh.CreateDate AS SOCreateDate
FROM Plus.pls.PartTransaction pt
LEFT JOIN Plus.pls.ROHeader rh ON rh.ID = pt.OrderHeaderID
LEFT JOIN Plus.pls.SOHeader soh ON soh.ID = pt.OrderHeaderID
WHERE UPPER(pt.ToLocation) LIKE '%TORNDOWN%'
    AND pt.ProgramID = 10053
ORDER BY pt.CreateDate DESC;

-- 8. Summary: Most Useful Additional Fields to Consider
SELECT 
    'SUMMARY - Recommended Additional Fields' AS Info,
    'PartTransaction.ParentSerialNo' AS FieldName,
    'Parent serial from transaction (if different from PartSerial)' AS Description
UNION ALL
SELECT 
    'SUMMARY',
    'PartTransaction.OrderHeaderID',
    'ROHeaderID or SOHeaderID - links to order'
UNION ALL
SELECT 
    'SUMMARY',
    'PartTransaction.RODockLogID',
    'Dock log reference for receiving'
UNION ALL
SELECT 
    'SUMMARY',
    'PartTransaction.PalletBoxNo / ToPalletBoxNo',
    'Pallet/Box tracking'
UNION ALL
SELECT 
    'SUMMARY',
    'PartTransaction.Reason',
    'Notes/reason for transaction'
UNION ALL
SELECT 
    'SUMMARY',
    'PartTransaction.Source / Condition / Configuration',
    'Source, condition, and configuration fields'
UNION ALL
SELECT 
    'SUMMARY',
    'PartSerial.StatusID',
    'Current status (NEW, RECEIVED, WIP, etc.)'
UNION ALL
SELECT 
    'SUMMARY',
    'PartSerial.ROHeaderID / SOHeaderID',
    'Order references from PartSerial'
UNION ALL
SELECT 
    'SUMMARY',
    'PartLocation.Bin / Bay',
    'Location bin and bay details'
UNION ALL
SELECT 
    'SUMMARY',
    'PartSerialAttribute (various)',
    'Many attributes available - see queries 5 & 6 above';
