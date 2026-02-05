

SELECT 
    -- FEDEX MANIFEST DATA
    fm.C01 as TrackingNumber,
    CAST(fm.C02 AS DATE) as EntryDate,
    fm.CreateDate as ManifestUploadDate,
    fm.ID as ManifestID,
    
    -- PROGRAM ID
    COALESCE(dl.ProgramID, pt.ProgramID) AS ProgramID,
    CASE 
        WHEN dl.ProgramID IS NOT NULL AND pt.ProgramID IS NOT NULL AND dl.ProgramID != pt.ProgramID THEN 'MISMATCH'
        WHEN dl.ProgramID IS NOT NULL THEN 'From DockLog'
        WHEN pt.ProgramID IS NOT NULL THEN 'From Transaction'
        ELSE 'Unknown - No DockLog or Transaction'
    END AS ProgramIDSource,
    
    -- DOCK LOG DATA  
    dl.ID as DockLogID,
    dl.CreateDate as DockLogDate,
    cs.Description as DockLogStatus,
    
    -- ASN DATA
    COALESCE(rh_dl.CustomerReference, rh_pt.CustomerReference) AS ASN,
    
    -- Customer category based on ASN number (CustomerReference)
    CASE
        WHEN COALESCE(rh_dl.CustomerReference, rh_pt.CustomerReference) LIKE 'X%'   THEN 'CDR'
        WHEN COALESCE(rh_dl.CustomerReference, rh_pt.CustomerReference) LIKE 'EX%'  THEN 'Excess Centralization'
        WHEN COALESCE(rh_dl.CustomerReference, rh_pt.CustomerReference) LIKE 'FSR%' THEN 'FSR'
        WHEN COALESCE(rh_dl.CustomerReference, rh_pt.CustomerReference) LIKE 'SP%'  THEN 'Special Projects'
        ELSE 'Other'
    END AS CustomerCategory,
    
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
    LEFT JOIN Plus.pls.ROHeader rh_dl ON rh_dl.ID = dl.ROHeaderID  -- Get ASN from DockLog
    LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = dl.StatusID  -- Get status description
    LEFT JOIN Plus.pls.PartTransaction pt ON pt.RODockLogID = dl.ID AND pt.PartTransactionID = 1  -- Receipt txns
    LEFT JOIN Plus.pls.ROHeader rh_pt ON rh_pt.ID = pt.OrderHeaderID  -- Get ASN from PartTransaction (fallback)
WHERE fm.GenericTableDefinitionID = 233  -- FEDEXMANIFEST
