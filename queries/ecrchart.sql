CREATE OR ALTER     VIEW rpt.ADTExcessCentralizationReport AS
SELECT 
    -- Organization - DYNAMIC from BRANCHES (just the code)
    ISNULL(branch.BranchCode, 'Unknown') AS [Organization],
    
    -- Category field based on CustomerReference prefix
    CASE 
        WHEN ro.CustomerReference LIKE 'EX%' THEN 'Excess Centralization'
        WHEN ro.CustomerReference LIKE 'SP%' THEN 'Special Projects'
        ELSE 'Other'
    END AS [Category],
    
    -- Subinventory Code
    '160EX009' AS [Subinventory_Code],
    
    -- Item Details
    pn.Description AS [Item_Description],
    rol.PartNo AS [Item_No],
    
    -- Quantities
    rol.QtyToReceive AS [Qty_to_Return],
    rol.QtyReceived AS [Qty_Actually_Returned],
    (rol.QtyToReceive - rol.QtyReceived) AS [Delta],
    
    -- Cost Data with Dollar Signs
    '$' + CAST(
        CASE 
            WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
            ELSE 0.00
        END AS VARCHAR(20)
    ) AS [Item_Cost],
    
    '$' + CAST(
        CASE 
            WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2)) * rol.QtyToReceive
            ELSE 0.00
        END AS VARCHAR(20)
    ) AS [Ext_Cost],
    
    '$' + CAST(
        CASE 
            WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2)) * rol.QtyReceived
            ELSE 0.00
        END AS VARCHAR(20)
    ) AS [Returned_Ext_Cost],
    
    -- SCRAP Data
    ISNULL(scrap.ScrapQty, 0) AS [SCRAP],
    '$' + CAST(ISNULL(scrap.ScrapExtCost, 0.00) AS VARCHAR(20)) AS [SCRAP_EXT_COST],
    
    -- INBOUND_GOOD = Anything not scrapped
    (rol.QtyReceived - ISNULL(scrap.ScrapQty, 0)) AS [INBOUND_GOOD],
    
    -- TOTAL = INBOUND_GOOD + SCRAP
    (rol.QtyReceived - ISNULL(scrap.ScrapQty, 0)) + ISNULL(scrap.ScrapQty, 0) AS [TOTAL],
    
    -- VARIANCE = Qty_to_Return - TOTAL
    rol.QtyToReceive - ((rol.QtyReceived - ISNULL(scrap.ScrapQty, 0)) + ISNULL(scrap.ScrapQty, 0)) AS [VARIANCE],
    
    -- VARIANCE_EXT_COST = (Qty_to_Return - TOTAL) * Item_Cost
    '$' + CAST(
        (rol.QtyToReceive - ((rol.QtyReceived - ISNULL(scrap.ScrapQty, 0)) + ISNULL(scrap.ScrapQty, 0))) * 
        CASE 
            WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(10,2))
            ELSE 0.00
        END AS VARCHAR(20)
    ) AS [VARIANCE_EXT_COST],
    
    -- Status and Configuration
    cs.Description AS [Status],
    cc.Description AS [Configuration], 
    
    -- EX Reference
    ro.CustomerReference AS [EX_Reference],
    ro.CreateDate AS [EX_Created],
    u.Username AS [Operator],
    
    -- RECEIVED DATE
    received.ReceivedDate AS [Received_Date],
    
    -- Attribute Data - Extract only Box#1 part
    CASE 
        WHEN box_info.Value IS NOT NULL 
        THEN SUBSTRING(box_info.Value, 1, CHARINDEX('-', box_info.Value) - 1)
        ELSE ''
    END AS [Box_Number],
    
    -- FedEx Tracking
    tracking.TrackingNo AS [FedEx_Tracking],
    tracking.CarrierName AS [Carrier],
    
    '' AS [Notes]
    
FROM [PLUS].pls.ROHeader ro
JOIN [PLUS].pls.ROLine rol ON ro.ID = rol.ROHeaderID
LEFT JOIN [PLUS].pls.PartNo pn ON rol.PartNo = pn.PartNo
LEFT JOIN [PLUS].pls.PartNoAttribute pna ON rol.PartNo = pna.PartNo 
    AND pna.AttributeID = (SELECT ID FROM [PLUS].pls.CodeAttribute WHERE AttributeName = 'Cost')
    AND pna.ProgramID = 10068

LEFT JOIN (
    SELECT 
        pt.CustomerReference,
        pt.PartNo,
        MIN(pt.CreateDate) as ReceivedDate
    FROM [PLUS].pls.PartTransaction pt
    INNER JOIN [PLUS].pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    WHERE cpt.Description = 'RO-RECEIVE'
      AND pt.ProgramID = 10068
      AND (pt.CustomerReference LIKE 'EX%' OR pt.CustomerReference LIKE 'SP%')
    GROUP BY pt.CustomerReference, pt.PartNo
) received ON ro.CustomerReference = received.CustomerReference 
    AND rol.PartNo = received.PartNo

-- SCRAP subquery - UPDATED to use ToLocation instead of transaction type
LEFT JOIN (
    SELECT
        pt.PartNo,
        pt.CustomerReference,
        COUNT(*) AS [ScrapQty],
        SUM(CASE
            WHEN ISNUMERIC(pna2.Value) = 1 THEN CAST(pna2.Value AS DECIMAL(10,2))
            ELSE 0.00
        END) AS [ScrapExtCost]
    FROM [PLUS].pls.PartTransaction pt
    INNER JOIN [PLUS].pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    LEFT JOIN [PLUS].pls.PartNoAttribute pna2 ON pt.PartNo = pna2.PartNo
        AND pna2.AttributeID = (SELECT ID FROM [PLUS].pls.CodeAttribute WHERE AttributeName = 'Cost')
        AND pna2.ProgramID = 10068
    WHERE cpt.Description = 'RO-RECEIVE'
      AND pt.ToLocation LIKE 'SCRAP%'  -- KEY CHANGE: Identify scrap by location
      AND pt.ProgramID = 10068
      AND (pt.CustomerReference LIKE 'EX%' OR pt.CustomerReference LIKE 'SP%')
    GROUP BY pt.PartNo, pt.CustomerReference
) scrap ON rol.PartNo = scrap.PartNo
    AND ro.CustomerReference = scrap.CustomerReference

-- Box Number attribute
LEFT JOIN (
    SELECT 
        [ROHeaderID],
        [Value]
    FROM [PLUS].pls.ROHeaderAttribute
    WHERE [AttributeID] = (SELECT ID FROM [PLUS].pls.CodeAttribute WHERE AttributeName = 'ATTR01')
) box_info ON ro.ID = box_info.ROHeaderID

-- FedEx Tracking
LEFT JOIN (
    SELECT 
        [ROHeaderID],
        [TrackingNo],
        [CarrierName]
    FROM [PLUS].pls.RODockLog
    WHERE [ProgramID] = 10068
) tracking ON ro.ID = tracking.ROHeaderID

-- Branch information from BRANCHES attribute
LEFT JOIN (
    SELECT 
        cad.AddressID,
        cada.Value AS BranchCode
    FROM [PLUS].pls.CodeAddressDetails cad
    LEFT JOIN [PLUS].pls.CodeAddressDetailsAttribute cada ON cad.ID = cada.AddressDetailID
    LEFT JOIN [PLUS].pls.CodeAttribute ca ON cada.AttributeID = ca.ID
    WHERE ca.AttributeName = 'BRANCHES'
      AND cad.AddressType = 'ShipFrom'
) branch ON ro.AddressID = branch.AddressID

-- Status lookup
LEFT JOIN [PLUS].pls.CodeStatus cs ON rol.StatusID = cs.ID

-- Configuration lookup
LEFT JOIN [PLUS].pls.CodeConfiguration cc ON rol.ConfigurationID = cc.ID

-- User lookup
LEFT JOIN [PLUS].pls.[User] u ON rol.UserID = u.ID

WHERE (ro.CustomerReference LIKE 'EX%' OR ro.CustomerReference LIKE 'SP%')
  AND ro.ProgramID = 10068
  AND cs.Description IN ('RECEIVED', 'PARTIALLYRECEIVED');