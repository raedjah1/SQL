SELECT 
    pt.ID,
    pt.ProgramID,
    pt.PartTransactionID,
    pt.PartNo,
    pt.ParentSerialNo,
    pt.SerialNo,
    pt.Qty,
    pt.Source,
    pt.Condition,
    pt.Configuration,
    pt.Location,
    pt.ToLocation,
    pt.PalletBoxNo,
    pt.ToPalletBoxNo,
    pt.LotNo,
    pt.Reason,
    pt.CustomerReference,
    pt.OrderType,
    pt.OrderHeaderID,
    pt.OrderLineID,
    pt.RODockLogID,
    pt.InventorySource,
    pt.ERPProgramID,
    pt.CurrencyCode,
    pt.CostPerUnit,
    pt.UserID,
    u.Username,
    pt.CreateDate,
    pt.ForDate,
    pt.ForYear,
    pt.ForMonth,
    pt.ForWeek,
    pt.ForQuarter,
    pt.SourcePartNo,
    pt.SourceSerialNo,
    pt.ConversionFactor,
    pt.ERPQty,
    pt.CreateDate AS TransactionTimestamp,
    CAST(pt.CreateDate AS DATE) AS TransactionDate,
    CASE 
        WHEN CAST(DATEADD(hour, -6, pt.CreateDate) AS DATE) = CAST(DATEADD(hour, -6, GETDATE()) AS DATE) THEN 'Today'
        ELSE 'Historical'
    END AS IsToday,
    CASE
      WHEN cpt.Description IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE') AND UPPER(pt.Source) LIKE '%ARB%' THEN 'ARB Receiving'
      WHEN cpt.Description IN ('RO-RECEIVE') AND UPPER(pt.Location) IS NULL AND UPPER(pt.ToLocation) LIKE '3RMRAWG.%' THEN 'ARB Receiving - Raw Goods'
      WHEN cpt.Description IN ('WH-MOVEPART') AND UPPER(pt.Location) LIKE 'RECEIVED.ARB%' AND UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS.%' THEN 'ARB Receiving - Finished Goods'
      WHEN cpt.Description IN ('WH-MOVEPART') AND UPPER(pt.Location) LIKE 'RECEIVED.ARB%' AND UPPER(pt.ToLocation) LIKE 'SAN.%' THEN 'ARB Receiving - SaN'
      WHEN cpt.Description IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE') AND (UPPER(pt.Source) LIKE '%SNP%' OR UPPER(pt.Source) LIKE '%S&P%') THEN 'SNP Receiving'
      WHEN cpt.Description IN ('WH-MOVEPART') AND UPPER(pt.Location) LIKE 'RECEIVED.%' AND UPPER(pt.ToLocation) LIKE 'LIQUIDATION.%' THEN 'SNP Receiving - Liquidation'
      WHEN cpt.Description = 'WH-ADDPART' AND UPPER(pt.Source) LIKE '%HARVESTING%' THEN 'Harvesting'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) = 'FINISHEDGOODS.ARB.0.0.0' AND UPPER(pt.ToLocation) LIKE '%FINISHEDGOODS.ARB%' THEN 'Put Away - Finished Goods'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'FINISHEDGOODS.ARB.%' AND UPPER(pt.ToLocation) LIKE '%SHIPPEDTOCUSTOMER%' THEN 'Put Away - Finished Goods Correction'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE '3RMRAWG.ARB.GIT.%' AND UPPER(pt.ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE '3RMRAWG.ARB.0.%' AND UPPER(pt.ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'ENGHOLD.ARB.0.%' AND UPPER(pt.ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Put Away - EngHold'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'DISCREPANCY.ARB.UR.%' AND UPPER(pt.ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'DISCREPANCY.ARB.0.%' AND UPPER(pt.ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy'
      WHEN cpt.Description = 'WH-MOVEPART' AND (UPPER(pt.Location) LIKE 'DISCREPANCY.ARB.B%' OR UPPER(pt.Location) LIKE 'DISCREPANCY.ARB.R%') AND UPPER(pt.ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy Consolidation'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE '3RMRAWG.ARB.A%' AND UPPER(pt.ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods Consolidation'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'FINISHEDGOODS.ARB.B%' AND UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS.ARB.%' THEN 'Put Away - Finished Goods Consolidation'
      WHEN cpt.Description = 'WH-MOVEPART' AND (UPPER(pt.Location) LIKE 'ENGHOLD.ARB.E%' OR UPPER(pt.Location) LIKE 'ENGHOLD.ARB.A%') AND UPPER(pt.ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Put Away - EngHold Consolidation'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'REIMAGE.ARB.ENG%' AND UPPER(pt.ToLocation) LIKE 'REIMAGE.ARB.ENG%' THEN 'Put Away - EngRev Consolidation'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'RAPENDING.SNP.S%' AND UPPER(pt.ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'Put Away - RAPENDING Consolidation'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'CRA.ARB.%' AND UPPER(pt.ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Harvest Parts'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'SCRAP.%' AND UPPER(pt.ToLocation) LIKE 'SCRAP.%' THEN 'Put Away - SCRAP Consolidation'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'REIMAGE.%' AND UPPER(pt.ToLocation) LIKE 'REIMAGE.%' THEN 'Put Away - REIMAGE Consolidation'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'RAPENDING.SNP.0.%' AND UPPER(pt.ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'Put Away - SNP'
      WHEN cpt.Description = 'SO-RESERVE' AND UPPER(pt.Location) LIKE 'DISCREPANCY.%' AND UPPER(pt.ToLocation) LIKE 'RESERVE.%' THEN 'Discrepancy - Reship'
      WHEN UPPER(cpt.Description) = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'RECEIVED.ARB.%' AND UPPER(pt.ToLocation) LIKE 'SAFETYCAPTURE.%' THEN 'ARB Receiving - Safety Capture'
      WHEN UPPER(pt.Location) LIKE 'BOXING.ARB.%' AND UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS.ARB.0.0.0%' THEN 'Put Away - In Progress'
      WHEN UPPER(pt.ToLocation) = 'BOXING.ARB.H0.0.0' THEN 'Boxing'
      WHEN UPPER(pt.Location) LIKE 'STAGING.ARB.%' AND UPPER(pt.ToLocation) LIKE 'REIMAGE.%' THEN 'Blowout - Reimage'
      WHEN UPPER(pt.Location) LIKE 'STAGING.ARB.%' AND UPPER(pt.ToLocation) LIKE 'TEARDOWN.%' THEN 'Blowout - Teardown'
      WHEN UPPER(pt.Location) LIKE 'STAGING.ARB.%' AND UPPER(pt.ToLocation) LIKE 'BROKER.%' THEN 'Blowout - Broker'
      WHEN UPPER(pt.Location) LIKE 'STAGING.%' AND UPPER(pt.ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Blowout -  Engineering Hold'
      WHEN UPPER(pt.Location) LIKE 'STAGING.%' AND UPPER(pt.ToLocation) LIKE 'INTRANSITTOMEXICO.%' THEN 'Blowout -  Repair'
      WHEN UPPER(pt.Location) LIKE 'FINISHEDGOODS.%' AND UPPER(pt.ToLocation) = 'RESERVE.10053.0.0.0' THEN 'Picking - ARB'
      WHEN UPPER(pt.Location) LIKE 'RAAPPROVED.%' AND UPPER(pt.ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP RAAPPROVED'
      WHEN UPPER(pt.Location) LIKE 'RAAPENDING.%' AND UPPER(pt.ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP RAPENDING'
      WHEN UPPER(pt.Location) LIKE 'LIQUIDATION.%' AND UPPER(pt.ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP Liquidation'
      WHEN UPPER(cpt.Description) = 'SO-RESERVE' AND UPPER(pt.Location) LIKE 'SERVICESREPAIR.%' AND UPPER(pt.ToLocation) LIKE 'RESERVE.%' THEN 'Picking - Teardown'
      WHEN UPPER(cpt.Description) = 'SO-RESERVE' AND UPPER(pt.Location) LIKE 'CROSSDOCK.%' AND UPPER(pt.ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP Crossdock'
      WHEN UPPER(cpt.Description) = 'RO-RECEIVE' AND UPPER(pt.ToLocation) LIKE 'CROSSDOCK.SNP.%' THEN 'SNP Receiving - Crossdock'
      WHEN UPPER(pt.Location) LIKE 'RECEIVED.ARB%' AND (UPPER(pt.ToLocation) LIKE 'DISCREPANCY.%' OR UPPER(pt.ToLocation) LIKE 'RESEARCH.%') THEN 'ARB Receiving - Discrepancy'
      WHEN UPPER(pt.Location) LIKE 'RECEIVED.SNP%' AND (UPPER(pt.ToLocation) LIKE 'DISCREPANCY.%' OR UPPER(pt.ToLocation) LIKE 'RESEARCH.%') THEN 'SNP Receiving - Discrepancy'
      WHEN UPPER(pt.Location) LIKE 'WIP%' AND UPPER(pt.ToLocation) LIKE '%REV.%' THEN 'To Engineering Review'
      WHEN UPPER(pt.Location) LIKE '%REV.%' AND UPPER(pt.ToLocation) LIKE 'WIP%' THEN 'From Engineering Review'
      WHEN UPPER(pt.Location) LIKE 'ENGHOLD.ARB.%' AND UPPER(pt.ToLocation) LIKE 'STAGING.ARB.%' THEN 'From Engineering Hold'
      WHEN UPPER(pt.Location) LIKE 'RECEIVED.ARB.%' AND UPPER(pt.ToLocation) LIKE 'STAGING.ARB.%' THEN 'ARB Receiving - Staging'
      WHEN UPPER(pt.Location) LIKE 'RECEIVED.SNP.%' AND UPPER(pt.ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'SNP Receiving - Rapending'
      WHEN UPPER(pt.Location) LIKE 'REIMAGE.%' AND UPPER(pt.ToLocation) LIKE 'BOMFIX.%' THEN 'To BOM Fix'
      WHEN UPPER(pt.Location) LIKE 'ENGHOLD.%' AND UPPER(pt.ToLocation) LIKE 'WIP.%' THEN 'NPI Testing'
      WHEN UPPER(pt.Location) LIKE 'RAPENDING.%' AND UPPER(pt.ToLocation) LIKE 'RAAPPROVED.%' THEN 'SNP - To RA Approved'
      WHEN UPPER(cpt.Description) = 'WH-ADDPART' AND (UPPER(pt.ToLocation) LIKE '3RMRAW%' OR UPPER(pt.ToLocation) LIKE 'FLOORSTOCK.%') THEN 'Add Part Adjustment - Raw Goods'
      WHEN UPPER(cpt.Description) = 'ERP-ADDPART' AND (UPPER(pt.ToLocation) LIKE '3RMRAW%' OR UPPER(pt.ToLocation) LIKE 'FLOORSTOCK.%') THEN 'Add Part Adjustment - Raw Goods'
      WHEN UPPER(cpt.Description) = 'ERP-ADDPART' AND UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS%' THEN 'Add Part Adjustment - Finished Goods'
      WHEN UPPER(cpt.Description) = 'WH-ADDPART' AND UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS%' THEN 'Add Part Adjustment - Finished Goods'
      WHEN UPPER(cpt.Description) = 'WH-REMOVEPART' AND (UPPER(pt.ToLocation) LIKE '3RMRAW%' OR UPPER(pt.ToLocation) LIKE 'FLOORSTOCK.%') THEN 'REMOVE Part Adjustment - Raw Goods'
      WHEN UPPER(cpt.Description) = 'ERP-REMOVEPART' AND (UPPER(pt.ToLocation) LIKE '3RMRAW%' OR UPPER(pt.ToLocation) LIKE 'FLOORSTOCK.%') THEN 'REMOVE Part Adjustment - Raw Goods'
      WHEN UPPER(cpt.Description) = 'ERP-REMOVEPART' AND UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS%' THEN 'REMOVE Part Adjustment - Finished Goods'
      WHEN UPPER(cpt.Description) = 'WH-REMOVEPART' AND UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS%' THEN 'REMOVE Part Adjustment - Finished Goods'
      WHEN UPPER(cpt.Description) = 'ERP-REMOVEPART' AND pt.Location IS NULL THEN 'REMOVE Part Adjustment'
      WHEN UPPER(cpt.Description) = 'WH-REMOVEPART' AND pt.Location IS NULL THEN 'REMOVE Part Adjustment'
      WHEN cpt.Description = 'WH-MOVEPART' AND UPPER(pt.Source) LIKE '%GLPR%' AND UPPER(pt.Location) LIKE 'DISCREPANCY.ARB.%' AND UPPER(pt.ToLocation) LIKE 'RECEIVED.ARB.%' THEN 'Discrepancy - Rereceived'
      WHEN cpt.Description = 'SO-RESERVE' AND UPPER(pt.Source) LIKE '%GLPR%' AND UPPER(pt.Location) LIKE 'DISCREPANCY.ARB.%' AND UPPER(pt.ToLocation) LIKE 'RECEIVED.ARB.%' THEN 'Discrepancy - Rereceived'
      WHEN UPPER(cpt.Description) = 'WH-REMOVEPART' AND UPPER(pt.Location) LIKE 'DISCREPANCY.%' AND pt.ToLocation IS NULL THEN 'Discrepancy - Rereceived'
      WHEN UPPER(cpt.Description) = 'WH-MOVEPART' AND UPPER(pt.ToLocation) LIKE 'RECEIVED.%' THEN 'Discrepancy - In Receiving Fix'
      WHEN UPPER(cpt.Description) = 'SO-SHIP' AND LEN(pt.SerialNo) = 7 AND (LEN(pt.PartNo) = 5 OR pt.PartNo = 'PART001') THEN 'Shipping - ARB'
      WHEN UPPER(cpt.Description) = 'SO-SHIP' AND UPPER(pt.SerialNo) LIKE 'RXT%' AND LEN(pt.SerialNo) > 7 THEN 'Shipping - SNP'
      WHEN UPPER(cpt.Description) = 'SO-SHIP' AND pt.SerialNo = '*' THEN 'Shipping - SNP Crossdock'
      WHEN UPPER(cpt.Description) = 'SO-SHIP' AND UPPER(pt.CustomerReference) LIKE 'GIT%' THEN 'Shipping - GIT'
      WHEN UPPER(cpt.Description) = 'WH-MOVEPART' AND UPPER(pt.Location) LIKE 'RAPENDING%' AND UPPER(pt.ToLocation) LIKE 'LIQUIDATION.%' THEN 'SNP To Liquidation'
      -- Pallet Consolidation (prioritized before REIMAGE)
      WHEN cpt.Description = 'WH-MOVEPARTTOPALLET' THEN 'Pallet Consolidation - Move TO Pallet'
      WHEN cpt.Description = 'WH-MOVEPARTFROMPALLET' THEN 'Pallet Deconsolidation - Move FROM Pallet'
      -- REIMAGE Operations
      WHEN UPPER(pt.ToLocation) LIKE 'REIMAGE.%' THEN 'Reimage - Move TO Reimage'
      WHEN UPPER(pt.Location) LIKE 'REIMAGE.%' THEN 'Reimage - Move FROM Reimage'
      ELSE 'TBD'
    END AS Category,
    
    -- Hour and minute tracking
    DATEPART(HOUR, pt.CreateDate) AS WorkHour,
    
    -- Minutes worked in this hour (distinct minutes with activity)
    (
        SELECT COUNT(DISTINCT DATEPART(MINUTE, pt2.CreateDate))
        FROM Plus.pls.PartTransaction pt2
        WHERE pt2.ProgramID = 10053
          AND CAST(pt2.CreateDate AS DATE) = CAST(pt.CreateDate AS DATE)
          AND DATEPART(HOUR, pt2.CreateDate) = DATEPART(HOUR, pt.CreateDate)
    ) AS Minutes_Worked,

    -- Minutes not worked in this hour (60 - minutes worked)
    60 - (
        SELECT COUNT(DISTINCT DATEPART(MINUTE, pt2.CreateDate))
        FROM Plus.pls.PartTransaction pt2
        WHERE pt2.ProgramID = 10053
          AND CAST(pt2.CreateDate AS DATE) = CAST(pt.CreateDate AS DATE)
          AND DATEPART(HOUR, pt2.CreateDate) = DATEPART(HOUR, pt.CreateDate)
    ) AS Minutes_Not_Worked

FROM Plus.pls.PartTransaction pt
JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
JOIN Plus.pls.[User] u ON u.ID = pt.UserID
WHERE pt.ProgramID = 10053