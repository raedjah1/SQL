
SELECT 
    -- FEDEX MANIFEST DATA
    fm.C01 as TrackingNumber,
    CAST(fm.C02 AS DATE) as EntryDate,
    fm.CreateDate as ManifestUploadDate,
    fm.ID as ManifestID,
    
    -- DOCK LOG DATA  
    dl.ID as DockLogID,
    dl.CreateDate as DockLogDate,
    cs.Description as DockLogStatus,
    
    -- RECEIVING DATA
    pt.CreateDate as ReceiptDate,
    pt.ID as ReceiptTransactionID,
    pt.Qty as ReceivedQty,
    
    -- CALCULATED FIELDS
    DATEDIFF(hour, dl.CreateDate, pt.CreateDate) as HoursToProcess,
    CASE 
        WHEN pt.ID IS NOT NULL THEN 'Completed'
        WHEN dl.ID IS NOT NULL THEN 'Docked But Not Received' 
        ELSE 'Missing From Dock Log'
    END as Status,
    
    -- SLA COMPLIANCE
    CASE 
        WHEN pt.ID IS NOT NULL AND DATEDIFF(hour, dl.CreateDate, pt.CreateDate) <= 48 THEN 1
        ELSE 0
    END as SLA_Met

FROM Plus.pls.CodeGenericTable fm  -- FEDEX MANIFEST
    LEFT JOIN Plus.pls.RODockLog dl ON dl.TrackingNo = fm.C01  -- Link by tracking number
    LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = dl.StatusID  -- Get status description
    LEFT JOIN Plus.pls.PartTransaction pt ON pt.RODockLogID = dl.ID AND pt.PartTransactionID = 1  -- Receipt txns
WHERE fm.GenericTableDefinitionID = 233  -- FEDEXMANIFEST
