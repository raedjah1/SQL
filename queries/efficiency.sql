SELECT 
  Username,
  Date,
  Hour,
  Department,
  IsToday,
  ProcessCategory,
  TransactionCount,
  MinutesWorked,
  TransactionsPerHour,
  Green_Threshold,
  Yellow_Threshold,
  PerformanceStatus,
  EfficiencyPercentage
FROM (
  SELECT 
    cm.Username,
    cm.Hour,
    cm.Date,
    cm.Department,
    cm.IsToday,
    cm.ProcessCategory,
    COUNT(*) as TransactionCount,
    MIN(cm.CreateDate) as FirstTransaction,
    MAX(cm.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) as MinutesWorked,
    CASE 
      WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
      THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
      ELSE COUNT(*) 
    END as TransactionsPerHour,
    pt.Green_Threshold,
    pt.Yellow_Threshold,
    CASE 
      WHEN (CASE 
              WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
              THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
              ELSE COUNT(*) 
            END) >= pt.Green_Threshold THEN 'Green'
      WHEN (CASE 
              WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
              THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
              ELSE COUNT(*) 
            END) >= pt.Yellow_Threshold THEN 'Yellow'
      ELSE 'Red'
    END as PerformanceStatus,
    CASE 
      WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) = 0 THEN 0
      ELSE ROUND(((CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60) / pt.Green_Threshold) * 100, 1)
    END as EfficiencyPercentage
  FROM (
    SELECT 
      Username,
      CreateDate,
      DATEPART(HOUR, CreateDate) as Hour,
      CAST(CreateDate AS DATE) as Date,
      CASE 
        WHEN UPPER(Location) LIKE '%ARB%' OR UPPER(ToLocation) LIKE '%ARB%' THEN 'ARB'
        WHEN UPPER(Location) LIKE '%SNP%' OR UPPER(ToLocation) LIKE '%SNP%' OR UPPER(Source) LIKE '%SNP%' OR UPPER(Source) LIKE '%S&P%' THEN 'SNP'
        WHEN UPPER(Location) LIKE '%GIT%' OR UPPER(ToLocation) LIKE '%GIT%' OR UPPER(CustomerReference) LIKE 'GIT%' THEN 'GIT'
        WHEN UPPER(Location) LIKE '%CROSSDOCK%' OR UPPER(ToLocation) LIKE '%CROSSDOCK%' THEN 'Crossdock'
        ELSE 'General'
      END AS Department,
      CASE 
        WHEN CAST(DATEADD(hour, -6, CreateDate) AS DATE) = CAST(DATEADD(hour, -6, GETDATE()) AS DATE) THEN 'Today'
        ELSE 'Historical'
      END AS IsToday,
      -- COMPLETE CATEGORIZATION - NO DOUBLE COUNTING
      CASE
        WHEN PartTransaction IN ('RO-RECEIVE') AND UPPER(Location) IS NULL AND UPPER(ToLocation) LIKE '3RMRAWG.%' THEN 'ARB Receiving - Raw Goods'
        WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.ARB%' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS.%' THEN 'ARB Receiving - Finished Goods'
        WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.ARB%' AND UPPER(ToLocation) LIKE 'SAN.%' THEN 'ARB Receiving - SaN'
        WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.%' AND UPPER(ToLocation) LIKE 'LIQUIDATION.%' THEN 'SNP Receiving - Liquidation'
        WHEN PartTransaction = 'WH-ADDPART' AND UPPER(Source) LIKE '%HARVESTING%' THEN 'Harvesting'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) = 'FINISHEDGOODS.ARB.0.0.0' AND UPPER(ToLocation) LIKE '%FINISHEDGOODS.ARB%' THEN 'Put Away - Finished Goods'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'FINISHEDGOODS.ARB.%' AND UPPER(ToLocation) LIKE '%SHIPPEDTOCUSTOMER%' THEN 'Put Away - Finished Goods Correction'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE '3RMRAWG.ARB.GIT.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE '3RMRAWG.ARB.0.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'ENGHOLD.ARB.0.%' AND UPPER(ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Put Away - EngHold'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.UR.%' AND UPPER(ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.0.%' AND UPPER(ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy'
        WHEN PartTransaction = 'WH-MOVEPART' AND (UPPER(Location) LIKE 'DISCREPANCY.ARB.B%' OR UPPER(Location) LIKE 'DISCREPANCY.ARB.R%') AND UPPER(ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE '3RMRAWG.ARB.A%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'FINISHEDGOODS.ARB.B%' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS.ARB.%' THEN 'Put Away - Finished Goods Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND (UPPER(Location) LIKE 'ENGHOLD.ARB.E%' OR UPPER(Location) LIKE 'ENGHOLD.ARB.A%') AND UPPER(ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Put Away - EngHold Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'REIMAGE.ARB.ENG%' AND UPPER(ToLocation) LIKE 'REIMAGE.ARB.ENG%' THEN 'Put Away - EngRev Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RAPENDING.SNP.S%' AND UPPER(ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'Put Away - RAPENDING Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'CRA.ARB.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Harvest Parts'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'SCRAP.%' AND UPPER(ToLocation) LIKE 'SCRAP.%' THEN 'Put Away - SCRAP Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'REIMAGE.%' AND UPPER(ToLocation) LIKE 'REIMAGE.%' THEN 'Put Away - REIMAGE Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RAPENDING.SNP.0.%' AND UPPER(ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'Put Away - SNP'
        WHEN PartTransaction = 'SO-RESERVE' AND UPPER(Location) LIKE 'DISCREPANCY.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Discrepancy - Reship'
        WHEN UPPER(PartTransaction) = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RECEIVED.ARB.%' AND UPPER(ToLocation) LIKE 'SAFETYCAPTURE.%' THEN 'ARB Receiving - Safety Capture'
        WHEN UPPER(Location) LIKE 'BOXING.ARB.%' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS.ARB.0.0.0%' THEN 'Put Away - In Progress'
        WHEN UPPER(ToLocation) = 'BOXING.ARB.H0.0.0' THEN 'Boxing'
        WHEN UPPER(Location) LIKE 'STAGING.ARB.%' AND UPPER(ToLocation) LIKE 'REIMAGE.%' THEN 'Blowout - Reimage'
        WHEN UPPER(Location) LIKE 'STAGING.ARB.%' AND UPPER(ToLocation) LIKE 'TEARDOWN.%' THEN 'Blowout - Teardown'
        WHEN UPPER(Location) LIKE 'STAGING.ARB.%' AND UPPER(ToLocation) LIKE 'BROKER.%' THEN 'Blowout - Broker'
        WHEN UPPER(Location) LIKE 'STAGING.%' AND UPPER(ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Blowout -  Engineering Hold'
        WHEN UPPER(Location) LIKE 'STAGING.%' AND UPPER(ToLocation) LIKE 'INTRANSITTOMEXICO.%' THEN 'Blowout -  Repair'
        WHEN UPPER(Location) LIKE 'FINISHEDGOODS.%' AND UPPER(ToLocation) = 'RESERVE.10053.0.0.0' THEN 'Picking - ARB'
        WHEN UPPER(Location) LIKE 'RAAPPROVED.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP RAAPPROVED'
        WHEN UPPER(Location) LIKE 'RAAPENDING.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP RAPENDING'
        WHEN UPPER(Location) LIKE 'LIQUIDATION.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP Liquidation'
        WHEN UPPER(PartTransaction) = 'SO-RESERVE' AND UPPER(Location) LIKE 'SERVICESREPAIR.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - Teardown'
        WHEN UPPER(PartTransaction) = 'SO-RESERVE' AND UPPER(Location) LIKE 'CROSSDOCK.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP Crossdock'
        WHEN UPPER(PartTransaction) = 'RO-RECEIVE' AND UPPER(ToLocation) LIKE 'CROSSDOCK.SNP.%' THEN 'SNP Receiving - Crossdock'
        WHEN UPPER(Location) LIKE 'RECEIVED.ARB%' AND (UPPER(ToLocation) LIKE 'DISCREPANCY.%' OR UPPER(ToLocation) LIKE 'RESEARCH.%') THEN 'ARB Receiving - Discrepancy'
        WHEN UPPER(Location) LIKE 'RECEIVED.SNP%' AND (UPPER(ToLocation) LIKE 'DISCREPANCY.%' OR UPPER(ToLocation) LIKE 'RESEARCH.%') THEN 'SNP Receiving - Discrepancy'
        WHEN UPPER(Location) LIKE 'WIP%' AND UPPER(ToLocation) LIKE '%REV.%' THEN 'To Engineering Review'
        WHEN UPPER(Location) LIKE '%REV.%' AND UPPER(ToLocation) LIKE 'WIP%' THEN 'From Engineering Review'
        WHEN UPPER(Location) LIKE 'ENGHOLD.ARB.%' AND UPPER(ToLocation) LIKE 'STAGING.ARB.%' THEN 'From Engineering Hold'
        WHEN UPPER(Location) LIKE 'RECEIVED.ARB.%' AND UPPER(ToLocation) LIKE 'STAGING.ARB.%' THEN 'ARB Receiving - Staging'
        WHEN UPPER(Location) LIKE 'RECEIVED.SNP.%' AND UPPER(ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'SNP Receiving - Rapending'
        WHEN UPPER(Location) LIKE 'REIMAGE.%' AND UPPER(ToLocation) LIKE 'BOMFIX.%' THEN 'To BOM Fix'
        WHEN UPPER(Location) LIKE 'ENGHOLD.%' AND UPPER(ToLocation) LIKE 'WIP.%' THEN 'NPI Testing'
        WHEN UPPER(Location) LIKE 'RAPENDING.%' AND UPPER(ToLocation) LIKE 'RAAPPROVED.%' THEN 'SNP - To RA Approved'
        WHEN UPPER(PartTransaction) = 'WH-ADDPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'Add Part Adjustment - Raw Goods'
        WHEN UPPER(PartTransaction) = 'ERP-ADDPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'Add Part Adjustment - Raw Goods'
        WHEN UPPER(PartTransaction) = 'ERP-ADDPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'Add Part Adjustment - Finished Goods'
        WHEN UPPER(PartTransaction) = 'WH-ADDPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'Add Part Adjustment - Finished Goods'
        WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'REMOVE Part Adjustment - Raw Goods'
        WHEN UPPER(PartTransaction) = 'ERP-REMOVEPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'REMOVE Part Adjustment - Raw Goods'
        WHEN UPPER(PartTransaction) = 'ERP-REMOVEPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'REMOVE Part Adjustment - Finished Goods'
        WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'REMOVE Part Adjustment - Finished Goods'
        WHEN UPPER(PartTransaction) = 'ERP-REMOVEPART' AND Location IS NULL THEN 'REMOVE Part Adjustment'
        WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND Location IS NULL THEN 'REMOVE Part Adjustment'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Source) LIKE '%GLPR%' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.%' AND UPPER(ToLocation) LIKE 'RECEIVED.ARB.%' THEN 'Discrepancy - Rereceived'
        WHEN PartTransaction = 'SO-RESERVE' AND UPPER(Source) LIKE '%GLPR%' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.%' AND UPPER(ToLocation) LIKE 'RECEIVED.ARB.%' THEN 'Discrepancy - Rereceived'
        WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND UPPER(Location) LIKE 'DISCREPANCY.%' AND ToLocation IS NULL THEN 'Discrepancy - Rereceived'
        WHEN UPPER(PartTransaction) = 'WH-MOVEPART' AND UPPER(ToLocation) LIKE 'RECEIVED.%' THEN 'Discrepancy - In Receiving Fix'
        WHEN UPPER(PartTransaction) = 'SO-SHIP' AND LEN(SerialNo) = 7 AND (LEN(PartNo) = 5 OR PartNo = 'PART001') THEN 'Shipping - ARB'
        WHEN UPPER(PartTransaction) = 'SO-SHIP' AND UPPER(SerialNo) LIKE 'RXT%' AND LEN(SerialNo) > 7 THEN 'Shipping - SNP'
        WHEN UPPER(PartTransaction) = 'SO-SHIP' AND SerialNo = '*' THEN 'Shipping - SNP Crossdock'
        WHEN UPPER(PartTransaction) = 'SO-SHIP' AND UPPER(CustomerReference) LIKE 'GIT%' THEN 'Shipping - GIT'
        WHEN UPPER(PartTransaction) = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RAPENDING%' AND UPPER(ToLocation) LIKE 'LIQUIDATION.%' THEN 'SNP To Liquidation'
        -- REIMAGE Operations
        WHEN UPPER(ToLocation) LIKE 'REIMAGE.%' THEN 'Reimage - Move TO Reimage'
        WHEN UPPER(Location) LIKE 'REIMAGE.%' THEN 'Reimage - Move FROM Reimage'
        WHEN PartTransaction = 'WH-MOVEPARTTOPALLET' THEN 'Pallet Consolidation - Move TO Pallet'
        WHEN PartTransaction = 'WH-MOVEPARTFROMPALLET' THEN 'Pallet Deconsolidation - Move FROM Pallet'
        ELSE 'TBD'
      END AS ProcessCategory
    FROM pls.vPartTransaction 
    WHERE ProgramID = '10053' AND Username IS NOT NULL
  ) cm
  LEFT JOIN (
    SELECT 
      cm.ProcessCategory,
      CASE 
        WHEN cm.ProcessCategory LIKE '%Receiving%' AND cm.ProcessCategory LIKE '%Staging%' THEN 25  -- Receiving to Staging
        WHEN cm.ProcessCategory LIKE '%Receiving%' THEN 25  -- All other Receiving
        WHEN cm.ProcessCategory LIKE '%Put Away%' OR cm.ProcessCategory LIKE '%Putaway%' THEN 35
        WHEN cm.ProcessCategory LIKE '%Blowout%' THEN 32  -- Blow Out
        WHEN cm.ProcessCategory LIKE '%Picking%' THEN 30  -- Pick
        WHEN cm.ProcessCategory LIKE '%Shipping%' THEN 27  -- Ship
        WHEN cm.ProcessCategory LIKE '%Discrepancy%' THEN 9
        WHEN cm.ProcessCategory LIKE '%Pallet%' THEN 25  -- Pallet
        WHEN cm.ProcessCategory LIKE '%Reimage%' THEN 20
        WHEN cm.ProcessCategory LIKE '%Engineering%' AND cm.ProcessCategory LIKE '%Hold%' THEN 7  -- Engineering into Hold
        WHEN cm.ProcessCategory LIKE '%Engineering%' THEN 7  -- Engineering out
        WHEN cm.ProcessCategory = 'Harvesting' THEN 40  -- Harvest
        WHEN cm.ProcessCategory = 'Boxing' THEN 10
        WHEN cm.ProcessCategory LIKE '%BOM Fix%' THEN 10
        WHEN cm.ProcessCategory LIKE '%Add Part Adjustment%' OR cm.ProcessCategory LIKE '%REMOVE Part Adjustment%' THEN 8  -- Add Part Adjustments
        WHEN cm.ProcessCategory LIKE '%NPI Testing%' THEN 65  -- QA (NPI Testing is QA work)
        WHEN cm.ProcessCategory LIKE '%QA%' THEN 65  -- QA
        WHEN cm.ProcessCategory LIKE '%SNP%' AND cm.ProcessCategory NOT LIKE '%Receiving%' AND cm.ProcessCategory NOT LIKE '%Picking%' AND cm.ProcessCategory NOT LIKE '%Shipping%' THEN 25
        ELSE 25
      END as Green_Threshold,
      CASE 
        WHEN cm.ProcessCategory LIKE '%Receiving%' AND cm.ProcessCategory LIKE '%Staging%' THEN 12  -- Receiving to Staging
        WHEN cm.ProcessCategory LIKE '%Receiving%' THEN 12  -- All other Receiving
        WHEN cm.ProcessCategory LIKE '%Put Away%' OR cm.ProcessCategory LIKE '%Putaway%' THEN 17
        WHEN cm.ProcessCategory LIKE '%Blowout%' THEN 16  -- Blow Out
        WHEN cm.ProcessCategory LIKE '%Picking%' THEN 15  -- Pick
        WHEN cm.ProcessCategory LIKE '%Shipping%' THEN 14  -- Ship
        WHEN cm.ProcessCategory LIKE '%Discrepancy%' THEN 7
        WHEN cm.ProcessCategory LIKE '%Pallet%' THEN 13  -- Pallet
        WHEN cm.ProcessCategory LIKE '%Reimage%' THEN 10
        WHEN cm.ProcessCategory LIKE '%Engineering%' AND cm.ProcessCategory LIKE '%Hold%' THEN 5  -- Engineering into Hold
        WHEN cm.ProcessCategory LIKE '%Engineering%' THEN 5  -- Engineering out
        WHEN cm.ProcessCategory = 'Harvesting' THEN 20  -- Harvest
        WHEN cm.ProcessCategory = 'Boxing' THEN 8
        WHEN cm.ProcessCategory LIKE '%BOM Fix%' THEN 8
        WHEN cm.ProcessCategory LIKE '%Add Part Adjustment%' OR cm.ProcessCategory LIKE '%REMOVE Part Adjustment%' THEN 6  -- Add Part Adjustments
        WHEN cm.ProcessCategory LIKE '%NPI Testing%' THEN 32  -- QA (NPI Testing is QA work)
        WHEN cm.ProcessCategory LIKE '%QA%' THEN 32  -- QA
        WHEN cm.ProcessCategory LIKE '%SNP%' AND cm.ProcessCategory NOT LIKE '%Receiving%' AND cm.ProcessCategory NOT LIKE '%Picking%' AND cm.ProcessCategory NOT LIKE '%Shipping%' THEN 12
        ELSE 12
      END as Yellow_Threshold
    FROM (SELECT DISTINCT ProcessCategory FROM (
      SELECT 
        CASE
          WHEN PartTransaction IN ('RO-RECEIVE') AND UPPER(Location) IS NULL AND UPPER(ToLocation) LIKE '3RMRAWG.%' THEN 'ARB Receiving - Raw Goods'
          WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.ARB%' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS.%' THEN 'ARB Receiving - Finished Goods'
          WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.ARB%' AND UPPER(ToLocation) LIKE 'SAN.%' THEN 'ARB Receiving - SaN'
          WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.%' AND UPPER(ToLocation) LIKE 'LIQUIDATION.%' THEN 'SNP Receiving - Liquidation'
          WHEN PartTransaction = 'WH-ADDPART' AND UPPER(Source) LIKE '%HARVESTING%' THEN 'Harvesting'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) = 'FINISHEDGOODS.ARB.0.0.0' AND UPPER(ToLocation) LIKE '%FINISHEDGOODS.ARB%' THEN 'Put Away - Finished Goods'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'FINISHEDGOODS.ARB.%' AND UPPER(ToLocation) LIKE '%SHIPPEDTOCUSTOMER%' THEN 'Put Away - Finished Goods Correction'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE '3RMRAWG.ARB.GIT.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE '3RMRAWG.ARB.0.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'ENGHOLD.ARB.0.%' AND UPPER(ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Put Away - EngHold'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.UR.%' AND UPPER(ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.0.%' AND UPPER(ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy'
          WHEN PartTransaction = 'WH-MOVEPART' AND (UPPER(Location) LIKE 'DISCREPANCY.ARB.B%' OR UPPER(Location) LIKE 'DISCREPANCY.ARB.R%') AND UPPER(ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy Consolidation'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE '3RMRAWG.ARB.A%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods Consolidation'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'FINISHEDGOODS.ARB.B%' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS.ARB.%' THEN 'Put Away - Finished Goods Consolidation'
          WHEN PartTransaction = 'WH-MOVEPART' AND (UPPER(Location) LIKE 'ENGHOLD.ARB.E%' OR UPPER(Location) LIKE 'ENGHOLD.ARB.A%') AND UPPER(ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Put Away - EngHold Consolidation'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'REIMAGE.ARB.ENG%' AND UPPER(ToLocation) LIKE 'REIMAGE.ARB.ENG%' THEN 'Put Away - EngRev Consolidation'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RAPENDING.SNP.S%' AND UPPER(ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'Put Away - RAPENDING Consolidation'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'CRA.ARB.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Harvest Parts'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'SCRAP.%' AND UPPER(ToLocation) LIKE 'SCRAP.%' THEN 'Put Away - SCRAP Consolidation'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'REIMAGE.%' AND UPPER(ToLocation) LIKE 'REIMAGE.%' THEN 'Put Away - REIMAGE Consolidation'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RAPENDING.SNP.0.%' AND UPPER(ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'Put Away - SNP'
          WHEN PartTransaction = 'SO-RESERVE' AND UPPER(Location) LIKE 'DISCREPANCY.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Discrepancy - Reship'
          WHEN UPPER(PartTransaction) = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RECEIVED.ARB.%' AND UPPER(ToLocation) LIKE 'SAFETYCAPTURE.%' THEN 'ARB Receiving - Safety Capture'
          WHEN UPPER(Location) LIKE 'BOXING.ARB.%' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS.ARB.0.0.0%' THEN 'Put Away - In Progress'
          WHEN UPPER(ToLocation) = 'BOXING.ARB.H0.0.0' THEN 'Boxing'
          WHEN UPPER(Location) LIKE 'STAGING.ARB.%' AND UPPER(ToLocation) LIKE 'REIMAGE.%' THEN 'Blowout - Reimage'
          WHEN UPPER(Location) LIKE 'STAGING.ARB.%' AND UPPER(ToLocation) LIKE 'TEARDOWN.%' THEN 'Blowout - Teardown'
          WHEN UPPER(Location) LIKE 'STAGING.ARB.%' AND UPPER(ToLocation) LIKE 'BROKER.%' THEN 'Blowout - Broker'
          WHEN UPPER(Location) LIKE 'STAGING.%' AND UPPER(ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Blowout -  Engineering Hold'
          WHEN UPPER(Location) LIKE 'STAGING.%' AND UPPER(ToLocation) LIKE 'INTRANSITTOMEXICO.%' THEN 'Blowout -  Repair'
          WHEN UPPER(Location) LIKE 'FINISHEDGOODS.%' AND UPPER(ToLocation) = 'RESERVE.10053.0.0.0' THEN 'Picking - ARB'
          WHEN UPPER(Location) LIKE 'RAAPPROVED.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP RAAPPROVED'
          WHEN UPPER(Location) LIKE 'RAAPENDING.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP RAPENDING'
          WHEN UPPER(Location) LIKE 'LIQUIDATION.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP Liquidation'
          WHEN UPPER(PartTransaction) = 'SO-RESERVE' AND UPPER(Location) LIKE 'SERVICESREPAIR.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - Teardown'
          WHEN UPPER(PartTransaction) = 'SO-RESERVE' AND UPPER(Location) LIKE 'CROSSDOCK.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP Crossdock'
          WHEN UPPER(PartTransaction) = 'RO-RECEIVE' AND UPPER(ToLocation) LIKE 'CROSSDOCK.SNP.%' THEN 'SNP Receiving - Crossdock'
          WHEN UPPER(Location) LIKE 'RECEIVED.ARB%' AND (UPPER(ToLocation) LIKE 'DISCREPANCY.%' OR UPPER(ToLocation) LIKE 'RESEARCH.%') THEN 'ARB Receiving - Discrepancy'
          WHEN UPPER(Location) LIKE 'RECEIVED.SNP%' AND (UPPER(ToLocation) LIKE 'DISCREPANCY.%' OR UPPER(ToLocation) LIKE 'RESEARCH.%') THEN 'SNP Receiving - Discrepancy'
          WHEN UPPER(Location) LIKE 'WIP%' AND UPPER(ToLocation) LIKE '%REV.%' THEN 'To Engineering Review'
          WHEN UPPER(Location) LIKE '%REV.%' AND UPPER(ToLocation) LIKE 'WIP%' THEN 'From Engineering Review'
          WHEN UPPER(Location) LIKE 'ENGHOLD.ARB.%' AND UPPER(ToLocation) LIKE 'STAGING.ARB.%' THEN 'From Engineering Hold'
          WHEN UPPER(Location) LIKE 'RECEIVED.ARB.%' AND UPPER(ToLocation) LIKE 'STAGING.ARB.%' THEN 'ARB Receiving - Staging'
          WHEN UPPER(Location) LIKE 'RECEIVED.SNP.%' AND UPPER(ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'SNP Receiving - Rapending'
          WHEN UPPER(Location) LIKE 'REIMAGE.%' AND UPPER(ToLocation) LIKE 'BOMFIX.%' THEN 'To BOM Fix'
          WHEN UPPER(Location) LIKE 'ENGHOLD.%' AND UPPER(ToLocation) LIKE 'WIP.%' THEN 'NPI Testing'
          WHEN UPPER(Location) LIKE 'RAPENDING.%' AND UPPER(ToLocation) LIKE 'RAAPPROVED.%' THEN 'SNP - To RA Approved'
          WHEN UPPER(PartTransaction) = 'WH-ADDPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'Add Part Adjustment - Raw Goods'
          WHEN UPPER(PartTransaction) = 'ERP-ADDPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'Add Part Adjustment - Raw Goods'
          WHEN UPPER(PartTransaction) = 'ERP-ADDPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'Add Part Adjustment - Finished Goods'
          WHEN UPPER(PartTransaction) = 'WH-ADDPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'Add Part Adjustment - Finished Goods'
          WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'REMOVE Part Adjustment - Raw Goods'
          WHEN UPPER(PartTransaction) = 'ERP-REMOVEPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'REMOVE Part Adjustment - Raw Goods'
          WHEN UPPER(PartTransaction) = 'ERP-REMOVEPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'REMOVE Part Adjustment - Finished Goods'
          WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'REMOVE Part Adjustment - Finished Goods'
          WHEN UPPER(PartTransaction) = 'ERP-REMOVEPART' AND Location IS NULL THEN 'REMOVE Part Adjustment'
          WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND Location IS NULL THEN 'REMOVE Part Adjustment'
          WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Source) LIKE '%GLPR%' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.%' AND UPPER(ToLocation) LIKE 'RECEIVED.ARB.%' THEN 'Discrepancy - Rereceived'
          WHEN PartTransaction = 'SO-RESERVE' AND UPPER(Source) LIKE '%GLPR%' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.%' AND UPPER(ToLocation) LIKE 'RECEIVED.ARB.%' THEN 'Discrepancy - Rereceived'
          WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND UPPER(Location) LIKE 'DISCREPANCY.%' AND ToLocation IS NULL THEN 'Discrepancy - Rereceived'
          WHEN UPPER(PartTransaction) = 'WH-MOVEPART' AND UPPER(ToLocation) LIKE 'RECEIVED.%' THEN 'Discrepancy - In Receiving Fix'
          WHEN UPPER(PartTransaction) = 'SO-SHIP' AND LEN(SerialNo) = 7 AND (LEN(PartNo) = 5 OR PartNo = 'PART001') THEN 'Shipping - ARB'
          WHEN UPPER(PartTransaction) = 'SO-SHIP' AND UPPER(SerialNo) LIKE 'RXT%' AND LEN(SerialNo) > 7 THEN 'Shipping - SNP'
          WHEN UPPER(PartTransaction) = 'SO-SHIP' AND SerialNo = '*' THEN 'Shipping - SNP Crossdock'
          WHEN UPPER(PartTransaction) = 'SO-SHIP' AND UPPER(CustomerReference) LIKE 'GIT%' THEN 'Shipping - GIT'
          WHEN UPPER(PartTransaction) = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RAPENDING%' AND UPPER(ToLocation) LIKE 'LIQUIDATION.%' THEN 'SNP To Liquidation'
          WHEN UPPER(ToLocation) LIKE 'REIMAGE.%' THEN 'Reimage - Move TO Reimage'
          WHEN UPPER(Location) LIKE 'REIMAGE.%' THEN 'Reimage - Move FROM Reimage'
          WHEN PartTransaction = 'WH-MOVEPARTTOPALLET' THEN 'Pallet Consolidation - Move TO Pallet'
          WHEN PartTransaction = 'WH-MOVEPARTFROMPALLET' THEN 'Pallet Deconsolidation - Move FROM Pallet'
          WHEN UPPER(ToLocation) LIKE 'REIMAGE.%' THEN 'Reimage - Move TO Reimage'
          WHEN UPPER(Location) LIKE 'REIMAGE.%' THEN 'Reimage - Move FROM Reimage'
          ELSE 'TBD'
        END AS ProcessCategory
      FROM pls.vPartTransaction WHERE ProgramID = '10053'
    ) x WHERE ProcessCategory != 'TBD'
    ) cm
  ) pt ON cm.ProcessCategory = pt.ProcessCategory
  WHERE cm.ProcessCategory != 'TBD'
  GROUP BY cm.Username, cm.Hour, cm.Date, cm.Department, cm.IsToday, cm.ProcessCategory, pt.Green_Threshold, pt.Yellow_Threshold
  HAVING COUNT(*) <= (pt.Green_Threshold * 10)
) OperatorEfficiency

UNION ALL

SELECT 
  Username,
  Date,
  Hour,
  Department,
  IsToday,
  ProcessCategory,
  TransactionCount,
  MinutesWorked,
  TransactionsPerHour,
  Green_Threshold,
  Yellow_Threshold,
  PerformanceStatus,
  EfficiencyPercentage
FROM (
  SELECT 
    cm.Username,
    cm.Hour,
    cm.Date,
    cm.Department,
    cm.IsToday,
    'COMBINED_ALL_PROCESSES' as ProcessCategory,
    COUNT(*) as TransactionCount,
    MIN(cm.CreateDate) as FirstTransaction,
    MAX(cm.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) as MinutesWorked,
    CASE 
      WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
      THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
      ELSE COUNT(*) 
    END as TransactionsPerHour,
    25 as Green_Threshold,
    12 as Yellow_Threshold,
    CASE 
      WHEN (CASE 
              WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
              THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
              ELSE COUNT(*) 
            END) >= 25 THEN 'Green'
      WHEN (CASE 
              WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
              THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
              ELSE COUNT(*) 
            END) >= 12 THEN 'Yellow'
      ELSE 'Red'
    END as PerformanceStatus,
    CASE 
      WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) = 0 THEN 0
      ELSE ROUND(((CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60) / 25) * 100, 1)
    END as EfficiencyPercentage
  FROM (
    SELECT 
      Username,
      CreateDate,
      DATEPART(HOUR, CreateDate) as Hour,
      CAST(CreateDate AS DATE) as Date,
      CASE 
        WHEN UPPER(Location) LIKE '%ARB%' OR UPPER(ToLocation) LIKE '%ARB%' THEN 'ARB'
        WHEN UPPER(Location) LIKE '%SNP%' OR UPPER(ToLocation) LIKE '%SNP%' OR UPPER(Source) LIKE '%SNP%' OR UPPER(Source) LIKE '%S&P%' THEN 'SNP'
        WHEN UPPER(Location) LIKE '%GIT%' OR UPPER(ToLocation) LIKE '%GIT%' OR UPPER(CustomerReference) LIKE 'GIT%' THEN 'GIT'
        WHEN UPPER(Location) LIKE '%CROSSDOCK%' OR UPPER(ToLocation) LIKE '%CROSSDOCK%' THEN 'Crossdock'
        ELSE 'General'
      END AS Department,
      CASE 
        WHEN CAST(DATEADD(hour, -6, CreateDate) AS DATE) = CAST(DATEADD(hour, -6, GETDATE()) AS DATE) THEN 'Today'
        ELSE 'Historical'
      END AS IsToday,
      -- SAME CATEGORIZATION - NO DOUBLE COUNTING
      CASE
        WHEN PartTransaction IN ('RO-RECEIVE') AND UPPER(Location) IS NULL AND UPPER(ToLocation) LIKE '3RMRAWG.%' THEN 'ARB Receiving - Raw Goods'
        WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.ARB%' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS.%' THEN 'ARB Receiving - Finished Goods'
        WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.ARB%' AND UPPER(ToLocation) LIKE 'SAN.%' THEN 'ARB Receiving - SaN'
        WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.%' AND UPPER(ToLocation) LIKE 'LIQUIDATION.%' THEN 'SNP Receiving - Liquidation'
        WHEN PartTransaction = 'WH-ADDPART' AND UPPER(Source) LIKE '%HARVESTING%' THEN 'Harvesting'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) = 'FINISHEDGOODS.ARB.0.0.0' AND UPPER(ToLocation) LIKE '%FINISHEDGOODS.ARB%' THEN 'Put Away - Finished Goods'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'FINISHEDGOODS.ARB.%' AND UPPER(ToLocation) LIKE '%SHIPPEDTOCUSTOMER%' THEN 'Put Away - Finished Goods Correction'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE '3RMRAWG.ARB.GIT.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE '3RMRAWG.ARB.0.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'ENGHOLD.ARB.0.%' AND UPPER(ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Put Away - EngHold'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.UR.%' AND UPPER(ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.0.%' AND UPPER(ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy'
        WHEN PartTransaction = 'WH-MOVEPART' AND (UPPER(Location) LIKE 'DISCREPANCY.ARB.B%' OR UPPER(Location) LIKE 'DISCREPANCY.ARB.R%') AND UPPER(ToLocation) LIKE 'DISCREPANCY.ARB.%' THEN 'Put Away - Discrepancy Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE '3RMRAWG.ARB.A%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Raw Goods Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'FINISHEDGOODS.ARB.B%' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS.ARB.%' THEN 'Put Away - Finished Goods Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND (UPPER(Location) LIKE 'ENGHOLD.ARB.E%' OR UPPER(Location) LIKE 'ENGHOLD.ARB.A%') AND UPPER(ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Put Away - EngHold Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'REIMAGE.ARB.ENG%' AND UPPER(ToLocation) LIKE 'REIMAGE.ARB.ENG%' THEN 'Put Away - EngRev Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RAPENDING.SNP.S%' AND UPPER(ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'Put Away - RAPENDING Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'CRA.ARB.%' AND UPPER(ToLocation) LIKE '3RMRAWG.ARB.%' THEN 'Put Away - Harvest Parts'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'SCRAP.%' AND UPPER(ToLocation) LIKE 'SCRAP.%' THEN 'Put Away - SCRAP Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'REIMAGE.%' AND UPPER(ToLocation) LIKE 'REIMAGE.%' THEN 'Put Away - REIMAGE Consolidation'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RAPENDING.SNP.0.%' AND UPPER(ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'Put Away - SNP'
        WHEN PartTransaction = 'SO-RESERVE' AND UPPER(Location) LIKE 'DISCREPANCY.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Discrepancy - Reship'
        WHEN UPPER(PartTransaction) = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RECEIVED.ARB.%' AND UPPER(ToLocation) LIKE 'SAFETYCAPTURE.%' THEN 'ARB Receiving - Safety Capture'
        WHEN UPPER(Location) LIKE 'BOXING.ARB.%' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS.ARB.0.0.0%' THEN 'Put Away - In Progress'
        WHEN UPPER(ToLocation) = 'BOXING.ARB.H0.0.0' THEN 'Boxing'
        WHEN UPPER(Location) LIKE 'STAGING.ARB.%' AND UPPER(ToLocation) LIKE 'REIMAGE.%' THEN 'Blowout - Reimage'
        WHEN UPPER(Location) LIKE 'STAGING.ARB.%' AND UPPER(ToLocation) LIKE 'TEARDOWN.%' THEN 'Blowout - Teardown'
        WHEN UPPER(Location) LIKE 'STAGING.ARB.%' AND UPPER(ToLocation) LIKE 'BROKER.%' THEN 'Blowout - Broker'
        WHEN UPPER(Location) LIKE 'STAGING.%' AND UPPER(ToLocation) LIKE 'ENGHOLD.ARB.%' THEN 'Blowout -  Engineering Hold'
        WHEN UPPER(Location) LIKE 'STAGING.%' AND UPPER(ToLocation) LIKE 'INTRANSITTOMEXICO.%' THEN 'Blowout -  Repair'
        WHEN UPPER(Location) LIKE 'FINISHEDGOODS.%' AND UPPER(ToLocation) = 'RESERVE.10053.0.0.0' THEN 'Picking - ARB'
        WHEN UPPER(Location) LIKE 'RAAPPROVED.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP RAAPPROVED'
        WHEN UPPER(Location) LIKE 'RAAPENDING.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP RAPENDING'
        WHEN UPPER(Location) LIKE 'LIQUIDATION.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP Liquidation'
        WHEN UPPER(PartTransaction) = 'SO-RESERVE' AND UPPER(Location) LIKE 'SERVICESREPAIR.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - Teardown'
        WHEN UPPER(PartTransaction) = 'SO-RESERVE' AND UPPER(Location) LIKE 'CROSSDOCK.%' AND UPPER(ToLocation) LIKE 'RESERVE.%' THEN 'Picking - SNP Crossdock'
        WHEN UPPER(PartTransaction) = 'RO-RECEIVE' AND UPPER(ToLocation) LIKE 'CROSSDOCK.SNP.%' THEN 'SNP Receiving - Crossdock'
        WHEN UPPER(Location) LIKE 'RECEIVED.ARB%' AND (UPPER(ToLocation) LIKE 'DISCREPANCY.%' OR UPPER(ToLocation) LIKE 'RESEARCH.%') THEN 'ARB Receiving - Discrepancy'
        WHEN UPPER(Location) LIKE 'RECEIVED.SNP%' AND (UPPER(ToLocation) LIKE 'DISCREPANCY.%' OR UPPER(ToLocation) LIKE 'RESEARCH.%') THEN 'SNP Receiving - Discrepancy'
        WHEN UPPER(Location) LIKE 'WIP%' AND UPPER(ToLocation) LIKE '%REV.%' THEN 'To Engineering Review'
        WHEN UPPER(Location) LIKE '%REV.%' AND UPPER(ToLocation) LIKE 'WIP%' THEN 'From Engineering Review'
        WHEN UPPER(Location) LIKE 'ENGHOLD.ARB.%' AND UPPER(ToLocation) LIKE 'STAGING.ARB.%' THEN 'From Engineering Hold'
        WHEN UPPER(Location) LIKE 'RECEIVED.ARB.%' AND UPPER(ToLocation) LIKE 'STAGING.ARB.%' THEN 'ARB Receiving - Staging'
        WHEN UPPER(Location) LIKE 'RECEIVED.SNP.%' AND UPPER(ToLocation) LIKE 'RAPENDING.SNP.%' THEN 'SNP Receiving - Rapending'
        WHEN UPPER(Location) LIKE 'REIMAGE.%' AND UPPER(ToLocation) LIKE 'BOMFIX.%' THEN 'To BOM Fix'
        WHEN UPPER(Location) LIKE 'ENGHOLD.%' AND UPPER(ToLocation) LIKE 'WIP.%' THEN 'NPI Testing'
        WHEN UPPER(Location) LIKE 'RAPENDING.%' AND UPPER(ToLocation) LIKE 'RAAPPROVED.%' THEN 'SNP - To RA Approved'
        WHEN UPPER(PartTransaction) = 'WH-ADDPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'Add Part Adjustment - Raw Goods'
        WHEN UPPER(PartTransaction) = 'ERP-ADDPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'Add Part Adjustment - Raw Goods'
        WHEN UPPER(PartTransaction) = 'ERP-ADDPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'Add Part Adjustment - Finished Goods'
        WHEN UPPER(PartTransaction) = 'WH-ADDPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'Add Part Adjustment - Finished Goods'
        WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'REMOVE Part Adjustment - Raw Goods'
        WHEN UPPER(PartTransaction) = 'ERP-REMOVEPART' AND (UPPER(ToLocation) LIKE '3RMRAW%' OR UPPER(ToLocation) LIKE 'FLOORSTOCK.%') THEN 'REMOVE Part Adjustment - Raw Goods'
        WHEN UPPER(PartTransaction) = 'ERP-REMOVEPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'REMOVE Part Adjustment - Finished Goods'
        WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS%' THEN 'REMOVE Part Adjustment - Finished Goods'
        WHEN UPPER(PartTransaction) = 'ERP-REMOVEPART' AND Location IS NULL THEN 'REMOVE Part Adjustment'
        WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND Location IS NULL THEN 'REMOVE Part Adjustment'
        WHEN PartTransaction = 'WH-MOVEPART' AND UPPER(Source) LIKE '%GLPR%' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.%' AND UPPER(ToLocation) LIKE 'RECEIVED.ARB.%' THEN 'Discrepancy - Rereceived'
        WHEN PartTransaction = 'SO-RESERVE' AND UPPER(Source) LIKE '%GLPR%' AND UPPER(Location) LIKE 'DISCREPANCY.ARB.%' AND UPPER(ToLocation) LIKE 'RECEIVED.ARB.%' THEN 'Discrepancy - Rereceived'
        WHEN UPPER(PartTransaction) = 'WH-REMOVEPART' AND UPPER(Location) LIKE 'DISCREPANCY.%' AND ToLocation IS NULL THEN 'Discrepancy - Rereceived'
        WHEN UPPER(PartTransaction) = 'WH-MOVEPART' AND UPPER(ToLocation) LIKE 'RECEIVED.%' THEN 'Discrepancy - In Receiving Fix'
        WHEN UPPER(PartTransaction) = 'SO-SHIP' AND LEN(SerialNo) = 7 AND (LEN(PartNo) = 5 OR PartNo = 'PART001') THEN 'Shipping - ARB'
        WHEN UPPER(PartTransaction) = 'SO-SHIP' AND UPPER(SerialNo) LIKE 'RXT%' AND LEN(SerialNo) > 7 THEN 'Shipping - SNP'
        WHEN UPPER(PartTransaction) = 'SO-SHIP' AND SerialNo = '*' THEN 'Shipping - SNP Crossdock'
        WHEN UPPER(PartTransaction) = 'SO-SHIP' AND UPPER(CustomerReference) LIKE 'GIT%' THEN 'Shipping - GIT'
        WHEN UPPER(PartTransaction) = 'WH-MOVEPART' AND UPPER(Location) LIKE 'RAPENDING%' AND UPPER(ToLocation) LIKE 'LIQUIDATION.%' THEN 'SNP To Liquidation'
        -- REIMAGE Operations
        WHEN UPPER(ToLocation) LIKE 'REIMAGE.%' THEN 'Reimage - Move TO Reimage'
        WHEN UPPER(Location) LIKE 'REIMAGE.%' THEN 'Reimage - Move FROM Reimage'
        WHEN PartTransaction = 'WH-MOVEPARTTOPALLET' THEN 'Pallet Consolidation - Move TO Pallet'
        WHEN PartTransaction = 'WH-MOVEPARTFROMPALLET' THEN 'Pallet Deconsolidation - Move FROM Pallet'
        ELSE 'TBD'
      END AS ProcessCategory
    FROM pls.vPartTransaction 
    WHERE ProgramID = '10053' AND Username IS NOT NULL
  ) cm
  WHERE cm.ProcessCategory != 'TBD'
  GROUP BY cm.Username, cm.Hour, cm.Date, cm.Department, cm.IsToday
  HAVING COUNT(*) <= 250
) CombinedEfficiency


