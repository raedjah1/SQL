-- ================================================
-- ADT RMA Dashboard - Comprehensive View
-- Includes: Supplier/Cost fallbacks, all SLA metrics, business day calculations
-- ================================================

WITH RMAData AS (
    SELECT 
        rma.[Ticket Number] AS TicketNumber,
        rma.[part_code] AS PartCode,
        rma.[manufacturer] AS RMAManufacturer,
        rma.[oem_action] AS OEMAction,
        rma.[EXT Cost] AS ExtendedCostFromRMA,
        rma.[Entry Date] AS EntryDate,
        rma.[request_timestamp] AS RequestTimestamp,
        rma.[rma_num_timestamp] AS RMANumTimestamp,
        rma.[reply_timestamp] AS ReplyTimestamp,
        rma.[Shipped_date] AS ShippedDate,
        rma.[Status] AS Status,
        rma.[Credit/Replacement] AS CreditReplacement,
        -- Quantity: Use Quantity approved for shipment if available, otherwise get from PartTransaction
        COALESCE(
            CAST(rma.[Quantity approved for shipment] AS INT),
            (SELECT SUM(CAST(pt.Qty AS BIGINT))
             FROM Plus.pls.PartTransaction pt
             INNER JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
             WHERE pt.PartNo = rma.[part_code]
               AND pt.ProgramID IN (10068, 10072)
               AND cpt.Description = 'RO-RECEIVE')
        ) AS Quantity,
        -- Get warranty status to determine "IW and waiting to submit to vendor" category
        -- Try PartNoAttribute first, then PartSerialAttribute through PartSerial
        COALESCE(
            (SELECT TOP 1 pna.Value
             FROM Plus.pls.PartNoAttribute pna
             INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
             WHERE pna.PartNo = rma.[part_code]
               AND ca.AttributeName = 'WARRANTY_STATUS'
             ORDER BY pna.LastActivityDate DESC),
            (SELECT TOP 1 psa.Value
             FROM Plus.pls.PartSerialAttribute psa
             INNER JOIN Plus.pls.PartSerial ps ON ps.ID = psa.PartSerialID
             INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = psa.AttributeID
             WHERE ps.PartNo = rma.[part_code]
               AND ps.ProgramID IN (10068, 10072)
               AND ca.AttributeName = 'WARRANTY_STATUS'
             ORDER BY psa.LastActivityDate DESC)
        ) AS WarrantyStatus,
        
        -- Supplier: SUPPLIER_NO or Manufacturer fallback
        COALESCE(
            (SELECT TOP 1 pna.Value
             FROM Plus.pls.PartNoAttribute pna
             INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
             WHERE pna.PartNo = rma.[part_code]
               AND ca.AttributeName = 'SUPPLIER_NO'
             ORDER BY pna.LastActivityDate DESC),
            rma.[manufacturer]
        ) AS Supplier,
        
        -- Supplier Source
        CASE 
            WHEN (SELECT TOP 1 pna.Value
                  FROM Plus.pls.PartNoAttribute pna
                  INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
                  WHERE pna.PartNo = rma.[part_code]
                    AND ca.AttributeName = 'SUPPLIER_NO'
                  ORDER BY pna.LastActivityDate DESC) IS NOT NULL
            THEN 'SUPPLIER_NO'
            ELSE 'Manufacturer'
        END AS SupplierSource,
        
        -- Cost: PartNoAttribute Cost or RMA Extended Cost fallback
        COALESCE(
            (SELECT TOP 1 
                CASE 
                    WHEN ISNUMERIC(pna.Value) = 1 THEN CAST(pna.Value AS DECIMAL(18,2))
                    ELSE NULL
                END
             FROM Plus.pls.PartNoAttribute pna
             INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
             WHERE pna.PartNo = rma.[part_code]
               AND ca.AttributeName = 'Cost'
             ORDER BY pna.LastActivityDate DESC),
            rma.[EXT Cost]
        ) AS Cost,
        
        -- Cost Source
        CASE 
            WHEN (SELECT TOP 1 pna.Value
                  FROM Plus.pls.PartNoAttribute pna
                  INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
                  WHERE pna.PartNo = rma.[part_code]
                    AND ca.AttributeName = 'Cost'
                  ORDER BY pna.LastActivityDate DESC) IS NOT NULL
                 AND ISNUMERIC((SELECT TOP 1 pna.Value
                               FROM Plus.pls.PartNoAttribute pna
                               INNER JOIN Plus.pls.CodeAttribute ca ON ca.ID = pna.AttributeID
                               WHERE pna.PartNo = rma.[part_code]
                                 AND ca.AttributeName = 'Cost'
                               ORDER BY pna.LastActivityDate DESC)) = 1
            THEN 'PartNoAttribute'
            ELSE 'RMA Extended Cost'
        END AS CostSource
        
    FROM [ClarityWarehouse].[rpt].[ADTReconextRMAData] rma
    WHERE rma.[part_code] IS NOT NULL
)
SELECT 
    -- Basic RMA Information
    rma.TicketNumber,
    rma.PartCode,
    rma.RMAManufacturer,
    rma.OEMAction,
    rma.Status,
    rma.CreditReplacement,
    rma.Quantity,
    rma.WarrantyStatus,
    
    -- Supplier Information
    rma.Supplier,
    rma.SupplierSource,
    
    -- Cost Information
    rma.Cost,
    rma.CostSource,
    rma.ExtendedCostFromRMA,
    
    -- Date Fields
    rma.EntryDate,
    rma.RequestTimestamp,
    rma.RMANumTimestamp,
    rma.ReplyTimestamp,
    rma.ShippedDate,
    
    -- ============================================
    -- SLA CALCULATIONS
    -- ============================================
    
    -- 1. Request SLA: Days from Entry Date to Request (5 business day target)
    CASE 
        WHEN rma.RequestTimestamp IS NOT NULL AND rma.EntryDate IS NOT NULL THEN
            DATEDIFF(DAY, CAST(rma.EntryDate AS DATE), CAST(rma.RequestTimestamp AS DATE)) - 
            ((DATEDIFF(WEEK, CAST(rma.EntryDate AS DATE), CAST(rma.RequestTimestamp AS DATE)) * 2) +
             CASE WHEN DATEPART(WEEKDAY, CAST(rma.EntryDate AS DATE)) = 1 THEN 1 ELSE 0 END -
             CASE WHEN DATEPART(WEEKDAY, CAST(rma.RequestTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END)
        ELSE NULL
    END AS RequestBusinessDays,
    
    CASE 
        WHEN rma.RequestTimestamp IS NOT NULL AND rma.EntryDate IS NOT NULL THEN
            CASE 
                WHEN (DATEDIFF(DAY, CAST(rma.EntryDate AS DATE), CAST(rma.RequestTimestamp AS DATE)) - 
                      ((DATEDIFF(WEEK, CAST(rma.EntryDate AS DATE), CAST(rma.RequestTimestamp AS DATE)) * 2) +
                       CASE WHEN DATEPART(WEEKDAY, CAST(rma.EntryDate AS DATE)) = 1 THEN 1 ELSE 0 END -
                       CASE WHEN DATEPART(WEEKDAY, CAST(rma.RequestTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END)) <= 5
                THEN 1  -- Pass
                ELSE 0  -- Fail
            END
        ELSE NULL
    END AS RequestSLAPass,
    
    -- 2. Approval-to-Ship SLA: Days from Approval to Shipping (5 business day target, only for APPROVED)
    CASE 
        WHEN rma.OEMAction = 'APPROVED' 
             AND rma.RMANumTimestamp IS NOT NULL 
             AND rma.ShippedDate IS NOT NULL THEN
            DATEDIFF(DAY, CAST(rma.RMANumTimestamp AS DATE), CAST(rma.ShippedDate AS DATE)) - 
            ((DATEDIFF(WEEK, CAST(rma.RMANumTimestamp AS DATE), CAST(rma.ShippedDate AS DATE)) * 2) +
             CASE WHEN DATEPART(WEEKDAY, CAST(rma.RMANumTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END -
             CASE WHEN DATEPART(WEEKDAY, CAST(rma.ShippedDate AS DATE)) = 1 THEN 1 ELSE 0 END)
        ELSE NULL
    END AS ApprovalToShipBusinessDays,
    
    CASE 
        WHEN rma.OEMAction = 'APPROVED' 
             AND rma.RMANumTimestamp IS NOT NULL 
             AND rma.ShippedDate IS NOT NULL THEN
            CASE 
                WHEN (DATEDIFF(DAY, CAST(rma.RMANumTimestamp AS DATE), CAST(rma.ShippedDate AS DATE)) - 
                      ((DATEDIFF(WEEK, CAST(rma.RMANumTimestamp AS DATE), CAST(rma.ShippedDate AS DATE)) * 2) +
                       CASE WHEN DATEPART(WEEKDAY, CAST(rma.RMANumTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END -
                       CASE WHEN DATEPART(WEEKDAY, CAST(rma.ShippedDate AS DATE)) = 1 THEN 1 ELSE 0 END)) <= 5
                THEN 1  -- Pass
                ELSE 0  -- Fail
            END
        ELSE NULL
    END AS ApprovalToShipSLAPass,
    
    -- 3. Reply SLA: Days from Request to Reply (5 business day target)
    CASE 
        WHEN rma.RequestTimestamp IS NOT NULL AND rma.ReplyTimestamp IS NOT NULL THEN
            DATEDIFF(DAY, CAST(rma.RequestTimestamp AS DATE), CAST(rma.ReplyTimestamp AS DATE)) - 
            ((DATEDIFF(WEEK, CAST(rma.RequestTimestamp AS DATE), CAST(rma.ReplyTimestamp AS DATE)) * 2) +
             CASE WHEN DATEPART(WEEKDAY, CAST(rma.RequestTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END -
             CASE WHEN DATEPART(WEEKDAY, CAST(rma.ReplyTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END)
        ELSE NULL
    END AS ReplyBusinessDays,
    
    CASE 
        WHEN rma.RequestTimestamp IS NOT NULL AND rma.ReplyTimestamp IS NOT NULL THEN
            CASE 
                WHEN (DATEDIFF(DAY, CAST(rma.RequestTimestamp AS DATE), CAST(rma.ReplyTimestamp AS DATE)) - 
                      ((DATEDIFF(WEEK, CAST(rma.RequestTimestamp AS DATE), CAST(rma.ReplyTimestamp AS DATE)) * 2) +
                       CASE WHEN DATEPART(WEEKDAY, CAST(rma.RequestTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END -
                       CASE WHEN DATEPART(WEEKDAY, CAST(rma.ReplyTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END)) <= 5
                THEN 1  -- Pass
                ELSE 0  -- Fail
            END
        ELSE NULL
    END AS ReplySLAPass,
    
    -- 4. Credit Aging: Days since shipment (30 day target for credit tracking)
    CASE 
        WHEN rma.ShippedDate IS NOT NULL THEN
            DATEDIFF(DAY, CAST(rma.ShippedDate AS DATE), CAST(GETDATE() AS DATE))
        ELSE NULL
    END AS DaysSinceShipment,
    
    CASE 
        WHEN rma.ShippedDate IS NOT NULL THEN
            CASE 
                WHEN DATEDIFF(DAY, CAST(rma.ShippedDate AS DATE), CAST(GETDATE() AS DATE)) <= 30
                THEN 1  -- Within 30 days
                ELSE 0  -- Over 30 days (aged)
            END
        ELSE NULL
    END AS CreditWithin30Days,
    
    -- Credit Aging Details
    CASE 
        WHEN rma.ShippedDate IS NOT NULL 
             AND DATEDIFF(DAY, CAST(rma.ShippedDate AS DATE), CAST(GETDATE() AS DATE)) > 30 THEN
            DATEDIFF(DAY, CAST(rma.ShippedDate AS DATE), CAST(GETDATE() AS DATE)) - 30
        ELSE 0
    END AS DaysAgedOver30,
    
    CASE 
        WHEN rma.ShippedDate IS NOT NULL 
             AND DATEDIFF(DAY, CAST(rma.ShippedDate AS DATE), CAST(GETDATE() AS DATE)) > 30 THEN
            rma.Cost
        ELSE 0
    END AS AgedCostAmount,
    
    -- ============================================
    -- SUMMARY FLAGS FOR FILTERING
    -- ============================================
    
    -- Request made within 5 business days flag
    CASE 
        WHEN rma.RequestTimestamp IS NOT NULL AND rma.EntryDate IS NOT NULL 
             AND (DATEDIFF(DAY, CAST(rma.EntryDate AS DATE), CAST(rma.RequestTimestamp AS DATE)) - 
                  ((DATEDIFF(WEEK, CAST(rma.EntryDate AS DATE), CAST(rma.RequestTimestamp AS DATE)) * 2) +
                   CASE WHEN DATEPART(WEEKDAY, CAST(rma.EntryDate AS DATE)) = 1 THEN 1 ELSE 0 END -
                   CASE WHEN DATEPART(WEEKDAY, CAST(rma.RequestTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END)) <= 5
        THEN 1
        ELSE 0
    END AS RequestWithin5Days,
    
    -- EMAIL oem_action flag
    CASE WHEN rma.OEMAction = 'EMAIL' THEN 1 ELSE 0 END AS IsEmailAction,
    
    -- APPROVED flag
    CASE WHEN rma.OEMAction = 'APPROVED' THEN 1 ELSE 0 END AS IsApproved,
    
    -- DECLINED flag
    CASE WHEN rma.OEMAction = 'DECLINED' THEN 1 ELSE 0 END AS IsDeclined,
    
    -- NOT APPROVED flag
    CASE WHEN rma.OEMAction = 'NOT APPROVED' THEN 1 ELSE 0 END AS IsNotApproved,
    
    -- CANCELLED flag
    CASE WHEN rma.OEMAction = 'CANCELLED' THEN 1 ELSE 0 END AS IsCancelled,
    
    -- ============================================
    -- ENHANCED OEM ACTION CATEGORIZATION
    -- ============================================
    
    -- Enhanced OEM Action Category (includes "IW and waiting to submit to vendor")
    CASE 
        -- IW and waiting to submit to vendor: In warranty but no request yet
        WHEN (rma.WarrantyStatus IN ('IN WARRANTY', 'IW', 'IN_WARRANTY') 
              OR UPPER(LTRIM(RTRIM(COALESCE(rma.WarrantyStatus, '')))) IN ('IN WARRANTY', 'IW', 'IN_WARRANTY'))
             AND rma.RequestTimestamp IS NULL
        THEN 'IW and waiting to submit to vendor'
        -- Use actual OEM Action if it exists
        WHEN rma.OEMAction IS NOT NULL AND LTRIM(RTRIM(rma.OEMAction)) != ''
        THEN rma.OEMAction
        -- Default for records without OEM Action
        ELSE 'UNKNOWN'
    END AS OEMActionCategory,
    
    -- ============================================
    -- ADDITIONAL METRICS FOR DASHBOARD
    -- ============================================
    
    -- Total Cost (Quantity * Cost per unit)
    rma.Quantity * rma.Cost AS TotalCost,
    
    -- Pending Shipment Flag (APPROVED but not shipped)
    CASE 
        WHEN rma.OEMAction = 'APPROVED' AND rma.ShippedDate IS NULL THEN 1
        ELSE 0
    END AS IsPendingShipment,
    
    -- Pending Shipment Aging (business days since approval)
    CASE 
        WHEN rma.OEMAction = 'APPROVED' 
             AND rma.RMANumTimestamp IS NOT NULL 
             AND rma.ShippedDate IS NULL THEN
            DATEDIFF(DAY, CAST(rma.RMANumTimestamp AS DATE), CAST(GETDATE() AS DATE)) - 
            ((DATEDIFF(WEEK, CAST(rma.RMANumTimestamp AS DATE), CAST(GETDATE() AS DATE)) * 2) +
             CASE WHEN DATEPART(WEEKDAY, CAST(rma.RMANumTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END -
             CASE WHEN DATEPART(WEEKDAY, CAST(GETDATE() AS DATE)) = 1 THEN 1 ELSE 0 END)
        ELSE NULL
    END AS PendingShipmentBusinessDays,
    
    -- Pending Shipment Aged Over 5 Days
    CASE 
        WHEN rma.OEMAction = 'APPROVED' 
             AND rma.RMANumTimestamp IS NOT NULL 
             AND rma.ShippedDate IS NULL 
             AND (DATEDIFF(DAY, CAST(rma.RMANumTimestamp AS DATE), CAST(GETDATE() AS DATE)) - 
                  ((DATEDIFF(WEEK, CAST(rma.RMANumTimestamp AS DATE), CAST(GETDATE() AS DATE)) * 2) +
                   CASE WHEN DATEPART(WEEKDAY, CAST(rma.RMANumTimestamp AS DATE)) = 1 THEN 1 ELSE 0 END -
                   CASE WHEN DATEPART(WEEKDAY, CAST(GETDATE() AS DATE)) = 1 THEN 1 ELSE 0 END)) > 5
        THEN 1
        ELSE 0
    END AS IsPendingShipmentAgedOver5Days,
    
    -- Has Response Flag
    CASE WHEN rma.ReplyTimestamp IS NOT NULL THEN 1 ELSE 0 END AS HasResponse,
    
    -- Has Credit Flag (for credit tracking)
    CASE 
        WHEN rma.CreditReplacement IS NOT NULL 
             AND UPPER(LTRIM(RTRIM(rma.CreditReplacement))) LIKE '%CREDIT%'
        THEN 1
        ELSE 0
    END AS HasCredit

FROM RMAData rma
ORDER BY rma.EntryDate DESC;

