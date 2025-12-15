-- Verification Query: Operator Efficiency Percentages by Process Category
-- ✅ CHANGE USERNAME HERE: Replace 'username' with the username you want to investigate
DECLARE @Username VARCHAR(100) = 'celeste.virrey@reconext.com';  -- Change this to the username you want
DECLARE @DateFilter DATE = CAST(GETDATE() AS DATE);  -- ✅ Change this to filter by specific date, or use NULL for all dates

SELECT 
    Username,
    Date,
    Hour,
    Department,
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
    ISNULL(pt.Green_Threshold, 25) as Green_Threshold,
    ISNULL(pt.Yellow_Threshold, 12) as Yellow_Threshold,
    CASE 
      WHEN (CASE 
              WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
              THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
              ELSE COUNT(*) 
            END) >= ISNULL(pt.Green_Threshold, 25) THEN 'Green'
      WHEN (CASE 
              WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) > 0 
              THEN CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60 
              ELSE COUNT(*) 
            END) >= ISNULL(pt.Yellow_Threshold, 12) THEN 'Yellow'
      ELSE 'Red'
    END as PerformanceStatus,
    CASE 
      WHEN DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) = 0 THEN 0
      ELSE ROUND(((CAST(COUNT(*) AS FLOAT) / DATEDIFF(MINUTE, MIN(cm.CreateDate), MAX(cm.CreateDate)) * 60) / ISNULL(pt.Green_Threshold, 25)) * 100, 1)
    END as EfficiencyPercentage
  FROM (
    SELECT 
      u.Username,
      pt.CreateDate,
      DATEPART(HOUR, pt.CreateDate) as Hour,
      CAST(pt.CreateDate AS DATE) as Date,
      CASE 
        WHEN UPPER(pt.Location) LIKE '%ARB%' OR UPPER(pt.ToLocation) LIKE '%ARB%' THEN 'ARB'
        WHEN UPPER(pt.Location) LIKE '%SNP%' OR UPPER(pt.ToLocation) LIKE '%SNP%' OR UPPER(pt.Source) LIKE '%SNP%' OR UPPER(pt.Source) LIKE '%S&P%' THEN 'SNP'
        WHEN UPPER(pt.Location) LIKE '%GIT%' OR UPPER(pt.ToLocation) LIKE '%GIT%' OR UPPER(pt.CustomerReference) LIKE 'GIT%' THEN 'GIT'
        WHEN UPPER(pt.Location) LIKE '%CROSSDOCK%' OR UPPER(pt.ToLocation) LIKE '%CROSSDOCK%' THEN 'Crossdock'
        ELSE 'General'
      END AS Department,
      CASE
        WHEN cpt.Description IN ('RO-RECEIVE') AND UPPER(pt.Location) IS NULL AND UPPER(pt.ToLocation) LIKE '3RMRAWG.%' THEN 'ARB Receiving - Raw Goods'
        WHEN cpt.Description IN ('WH-MOVEPART') AND UPPER(pt.Location) LIKE 'RECEIVED.ARB%' AND UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS.%' THEN 'ARB Receiving - Finished Goods'
        WHEN cpt.Description IN ('WH-MOVEPART') AND UPPER(pt.Location) LIKE 'RECEIVED.ARB%' AND UPPER(pt.ToLocation) LIKE 'SAN.%' THEN 'ARB Receiving - SaN'
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
        WHEN UPPER(pt.ToLocation) LIKE 'REIMAGE.%' THEN 'Reimage - Move TO Reimage'
        WHEN UPPER(pt.Location) LIKE 'REIMAGE.%' THEN 'Reimage - Move FROM Reimage'
        WHEN cpt.Description = 'WH-MOVEPARTTOPALLET' THEN 'Pallet Consolidation - Move TO Pallet'
        WHEN cpt.Description = 'WH-MOVEPARTFROMPALLET' THEN 'Pallet Deconsolidation - Move FROM Pallet'
        ELSE cpt.Description  -- Show exact transaction type for uncategorized transactions
      END AS ProcessCategory
    FROM Plus.pls.PartTransaction pt
    JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
    JOIN Plus.pls.[User] u ON u.ID = pt.UserID
    WHERE pt.ProgramID = 10053
      AND u.Username = @Username  -- ✅ Filter by username
      AND (@DateFilter IS NULL OR CAST(pt.CreateDate AS DATE) = @DateFilter)  -- ✅ Filter by date (NULL = all dates)
  ) cm
  LEFT JOIN (
    SELECT 
      pc.ProcessCategory,
      CASE 
        WHEN pc.ProcessCategory LIKE '%Discrepancy%' THEN 9
        WHEN pc.ProcessCategory LIKE '%Engineering%' AND pc.ProcessCategory LIKE '%Hold%' THEN 7
        WHEN pc.ProcessCategory LIKE '%Engineering%' THEN 7
        WHEN pc.ProcessCategory LIKE '%Reimage%' THEN 20
        WHEN pc.ProcessCategory LIKE '%Blowout%' THEN 32
        WHEN pc.ProcessCategory LIKE '%Receiving%' AND pc.ProcessCategory LIKE '%Staging%' THEN 25
        WHEN pc.ProcessCategory LIKE '%Receiving%' THEN 25
        WHEN pc.ProcessCategory LIKE '%Picking%' THEN 30
        WHEN pc.ProcessCategory LIKE '%Shipping%' THEN 27
        WHEN pc.ProcessCategory LIKE '%SNP%' AND pc.ProcessCategory NOT LIKE '%Receiving%' AND pc.ProcessCategory NOT LIKE '%Picking%' AND pc.ProcessCategory NOT LIKE '%Shipping%' THEN 25
        WHEN pc.ProcessCategory LIKE '%Put Away%' OR pc.ProcessCategory LIKE '%Putaway%' THEN 35
        WHEN pc.ProcessCategory LIKE '%Pallet%' THEN 25
        WHEN pc.ProcessCategory = 'Harvesting' THEN 40
        WHEN pc.ProcessCategory = 'Boxing' THEN 10
        WHEN pc.ProcessCategory LIKE '%BOM Fix%' THEN 10
        WHEN pc.ProcessCategory LIKE '%Add Part Adjustment%' OR pc.ProcessCategory LIKE '%REMOVE Part Adjustment%' THEN 8
        WHEN pc.ProcessCategory LIKE '%NPI Testing%' THEN 65
        WHEN pc.ProcessCategory LIKE '%QA%' THEN 65
        ELSE 25
      END as Green_Threshold,
      CASE 
        WHEN pc.ProcessCategory LIKE '%Discrepancy%' THEN 7
        WHEN pc.ProcessCategory LIKE '%Engineering%' AND pc.ProcessCategory LIKE '%Hold%' THEN 5
        WHEN pc.ProcessCategory LIKE '%Engineering%' THEN 5
        WHEN pc.ProcessCategory LIKE '%Reimage%' THEN 10
        WHEN pc.ProcessCategory LIKE '%Blowout%' THEN 16
        WHEN pc.ProcessCategory LIKE '%Receiving%' AND pc.ProcessCategory LIKE '%Staging%' THEN 12
        WHEN pc.ProcessCategory LIKE '%Receiving%' THEN 12
        WHEN pc.ProcessCategory LIKE '%Picking%' THEN 15
        WHEN pc.ProcessCategory LIKE '%Shipping%' THEN 14
        WHEN pc.ProcessCategory LIKE '%SNP%' AND pc.ProcessCategory NOT LIKE '%Receiving%' AND pc.ProcessCategory NOT LIKE '%Picking%' AND pc.ProcessCategory NOT LIKE '%Shipping%' THEN 12
        WHEN pc.ProcessCategory LIKE '%Put Away%' OR pc.ProcessCategory LIKE '%Putaway%' THEN 17
        WHEN pc.ProcessCategory LIKE '%Pallet%' THEN 13
        WHEN pc.ProcessCategory = 'Harvesting' THEN 20
        WHEN pc.ProcessCategory = 'Boxing' THEN 8
        WHEN pc.ProcessCategory LIKE '%BOM Fix%' THEN 8
        WHEN pc.ProcessCategory LIKE '%Add Part Adjustment%' OR pc.ProcessCategory LIKE '%REMOVE Part Adjustment%' THEN 6
        WHEN pc.ProcessCategory LIKE '%NPI Testing%' THEN 32
        WHEN pc.ProcessCategory LIKE '%QA%' THEN 32
        ELSE 12
      END as Yellow_Threshold
    FROM (SELECT DISTINCT ProcessCategory FROM (
      SELECT 
        CASE
          WHEN cpt.Description IN ('RO-RECEIVE') AND UPPER(pt.Location) IS NULL AND UPPER(pt.ToLocation) LIKE '3RMRAWG.%' THEN 'ARB Receiving - Raw Goods'
          WHEN cpt.Description IN ('WH-MOVEPART') AND UPPER(pt.Location) LIKE 'RECEIVED.ARB%' AND UPPER(pt.ToLocation) LIKE 'FINISHEDGOODS.%' THEN 'ARB Receiving - Finished Goods'
          WHEN cpt.Description IN ('WH-MOVEPART') AND UPPER(pt.Location) LIKE 'RECEIVED.ARB%' AND UPPER(pt.ToLocation) LIKE 'SAN.%' THEN 'ARB Receiving - SaN'
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
          WHEN UPPER(pt.ToLocation) LIKE 'REIMAGE.%' THEN 'Reimage - Move TO Reimage'
          WHEN UPPER(pt.Location) LIKE 'REIMAGE.%' THEN 'Reimage - Move FROM Reimage'
          WHEN cpt.Description = 'WH-MOVEPARTTOPALLET' THEN 'Pallet Consolidation - Move TO Pallet'
          WHEN cpt.Description = 'WH-MOVEPARTFROMPALLET' THEN 'Pallet Deconsolidation - Move FROM Pallet'
          ELSE cpt.Description
        END AS ProcessCategory
      FROM Plus.pls.PartTransaction pt
      JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
      WHERE pt.ProgramID = 10053
    ) x
    ) pc
  ) pt ON cm.ProcessCategory = pt.ProcessCategory
  GROUP BY cm.Username, cm.Hour, cm.Date, cm.Department, cm.ProcessCategory, pt.Green_Threshold, pt.Yellow_Threshold
  HAVING COUNT(*) <= (ISNULL(pt.Green_Threshold, 25) * 10)
) OperatorEfficiency
ORDER BY Date DESC, Hour DESC, EfficiencyPercentage DESC, ProcessCategory;

