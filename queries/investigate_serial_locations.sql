-- Quick investigation: Find locations for specific serial numbers
SELECT 
    ps.SerialNo,
    ps.PartNo,
    
    -- Current Location
    pl.LocationNo AS Current_LocationNo,
    pl.Warehouse AS Current_Warehouse,
    pl.Building AS Current_Building,
    pl.Bin AS Current_Bin,
    
    -- Receipt Location
    pt_receive.ToLocation AS Receipt_LocationNo,
    pl_receive.LocationNo AS Receipt_Location_Full,
    pl_receive.Warehouse AS Receipt_Warehouse,
    pl_receive.Building AS Receipt_Building,
    pt_receive.CreateDate AS Receipt_Date,
    cpt_receive.Description AS Receipt_TransactionType,
    u_receive.Username AS Received_By,
    
    -- Location Group and Configuration
    clg.Description AS LocationGroup,
    cc.Description AS Configuration,
    ps.CreateDate AS SerialCreatedDate,
    ps.LastActivityDate
FROM Plus.pls.PartSerial ps
    LEFT JOIN Plus.pls.PartLocation pl ON pl.ID = ps.LocationID
    LEFT JOIN Plus.pls.CodeLocationGroup clg ON clg.ID = pl.LocationGroupID
    LEFT JOIN Plus.pls.CodeConfiguration cc ON cc.ID = ps.ConfigurationID
    
    -- Receipt Transaction (RO-RECEIVE) - Get first receipt only
    LEFT JOIN (
        SELECT 
            pt.SerialNo,
            pt.ProgramID,
            pt.ToLocation,
            pt.CreateDate,
            pt.UserID,
            pt.PartTransactionID,
            ROW_NUMBER() OVER (
                PARTITION BY pt.SerialNo, pt.ProgramID 
                ORDER BY pt.CreateDate ASC
            ) AS rn
        FROM Plus.pls.PartTransaction pt
        WHERE pt.PartTransactionID = 1  -- Receipt transaction type
    ) pt_receive 
        ON pt_receive.SerialNo = ps.SerialNo
        AND pt_receive.ProgramID = ps.ProgramID
        AND pt_receive.rn = 1  -- First receipt only
    
    LEFT JOIN Plus.pls.CodePartTransaction cpt_receive 
        ON cpt_receive.ID = pt_receive.PartTransactionID
    
    LEFT JOIN Plus.pls.[User] u_receive 
        ON u_receive.ID = pt_receive.UserID
    
    -- Receipt Location Details
    LEFT JOIN Plus.pls.PartLocation pl_receive 
        ON pl_receive.LocationNo = pt_receive.ToLocation
        AND pl_receive.ProgramID = ps.ProgramID
WHERE ps.SerialNo IN (
    '10KNWB4',
    '10KTSW3',
    '10L0YB4',
    '10L7574',
    '10L7V94',
    '10LGXB4',
    '10M2T44',
    '10M75C4',
    '10MLW74',
    '10N9G94'
)
ORDER BY ps.SerialNo;

