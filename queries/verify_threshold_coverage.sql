-- Verification Query: Check if all ProcessCategories have proper thresholds
-- This helps identify any categories that might not be matching threshold patterns correctly

-- List all unique ProcessCategories and their assigned thresholds
SELECT 
    cat.ProcessCategory,
    th.Green_Threshold,
    th.Yellow_Threshold,
    CASE 
        WHEN th.Green_Threshold IS NULL THEN 'MISSING THRESHOLD'
        -- Most specific patterns first (matching the threshold lookup logic)
        -- Check Discrepancy first (most specific - applies to all Discrepancy categories)
        WHEN cat.ProcessCategory LIKE '%Discrepancy%' AND th.Green_Threshold != 9 THEN 'WRONG THRESHOLD'
        -- Check Engineering (applies to Engineering categories, including "Blowout - Engineering Hold")
        WHEN cat.ProcessCategory LIKE '%Engineering%' AND cat.ProcessCategory LIKE '%Hold%' AND th.Green_Threshold != 7 THEN 'WRONG THRESHOLD'
        WHEN cat.ProcessCategory LIKE '%Engineering%' AND cat.ProcessCategory NOT LIKE '%Hold%' AND th.Green_Threshold != 7 THEN 'WRONG THRESHOLD'
        -- Check Reimage (applies to Reimage categories, including "Blowout - Reimage")
        WHEN cat.ProcessCategory LIKE '%Reimage%' AND th.Green_Threshold != 20 THEN 'WRONG THRESHOLD'
        -- Check Blowout (only if not already matched by Reimage or Engineering)
        WHEN cat.ProcessCategory LIKE '%Blowout%' AND cat.ProcessCategory NOT LIKE '%Reimage%' AND cat.ProcessCategory NOT LIKE '%Engineering%' AND th.Green_Threshold != 32 THEN 'WRONG THRESHOLD'
        -- Check Receiving (only if not already matched by Discrepancy)
        WHEN cat.ProcessCategory LIKE '%Receiving%' AND cat.ProcessCategory LIKE '%Staging%' AND cat.ProcessCategory NOT LIKE '%Discrepancy%' AND th.Green_Threshold != 25 THEN 'WRONG THRESHOLD'
        WHEN cat.ProcessCategory LIKE '%Receiving%' AND cat.ProcessCategory NOT LIKE '%Staging%' AND cat.ProcessCategory NOT LIKE '%Discrepancy%' AND th.Green_Threshold != 25 THEN 'WRONG THRESHOLD'
        -- Check Picking
        WHEN cat.ProcessCategory LIKE '%Picking%' AND th.Green_Threshold != 30 THEN 'WRONG THRESHOLD'
        -- Check Shipping
        WHEN cat.ProcessCategory LIKE '%Shipping%' AND th.Green_Threshold != 27 THEN 'WRONG THRESHOLD'
        -- Check SNP (only if not already matched by Receiving, Picking, or Shipping)
        WHEN cat.ProcessCategory LIKE '%SNP%' AND cat.ProcessCategory NOT LIKE '%Receiving%' AND cat.ProcessCategory NOT LIKE '%Picking%' AND cat.ProcessCategory NOT LIKE '%Shipping%' AND cat.ProcessCategory NOT LIKE '%Discrepancy%' AND th.Green_Threshold != 25 THEN 'WRONG THRESHOLD'
        -- Check Put Away (only if not already matched by SNP or Discrepancy)
        WHEN (cat.ProcessCategory LIKE '%Put Away%' OR cat.ProcessCategory LIKE '%Putaway%') AND cat.ProcessCategory NOT LIKE '%SNP%' AND cat.ProcessCategory NOT LIKE '%Discrepancy%' AND th.Green_Threshold != 35 THEN 'WRONG THRESHOLD'
        -- Check Pallet
        WHEN cat.ProcessCategory LIKE '%Pallet%' AND th.Green_Threshold != 25 THEN 'WRONG THRESHOLD'
        -- Check exact matches
        WHEN cat.ProcessCategory = 'Harvesting' AND th.Green_Threshold != 40 THEN 'WRONG THRESHOLD'
        WHEN cat.ProcessCategory = 'Boxing' AND th.Green_Threshold != 10 THEN 'WRONG THRESHOLD'
        WHEN cat.ProcessCategory LIKE '%BOM Fix%' AND th.Green_Threshold != 10 THEN 'WRONG THRESHOLD'
        WHEN (cat.ProcessCategory LIKE '%Add Part Adjustment%' OR cat.ProcessCategory LIKE '%REMOVE Part Adjustment%') AND th.Green_Threshold != 8 THEN 'WRONG THRESHOLD'
        WHEN cat.ProcessCategory LIKE '%NPI Testing%' AND th.Green_Threshold != 65 THEN 'WRONG THRESHOLD'
        WHEN cat.ProcessCategory LIKE '%QA%' AND th.Green_Threshold != 65 THEN 'WRONG THRESHOLD'
        ELSE 'OK'
    END AS ThresholdStatus
FROM (
    SELECT DISTINCT ProcessCategory
    FROM (
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
) cat
LEFT JOIN (
    SELECT 
      pc.ProcessCategory,
      CASE 
        -- Most specific patterns first (matching category_dell.sql logic)
        WHEN pc.ProcessCategory LIKE '%Discrepancy%' THEN 9  -- Discrepancy categories (including "Receiving - Discrepancy", "Put Away - Discrepancy", etc.)
        WHEN pc.ProcessCategory LIKE '%Engineering%' AND pc.ProcessCategory LIKE '%Hold%' THEN 7  -- Engineering into Hold
        WHEN pc.ProcessCategory LIKE '%Engineering%' THEN 7  -- Engineering out
        WHEN pc.ProcessCategory LIKE '%Reimage%' THEN 20  -- Reimage categories (including "Blowout - Reimage")
        WHEN pc.ProcessCategory LIKE '%Blowout%' THEN 32  -- Blow Out (must come after Reimage check)
        WHEN pc.ProcessCategory LIKE '%Receiving%' AND pc.ProcessCategory LIKE '%Staging%' THEN 25  -- Receiving to Staging
        WHEN pc.ProcessCategory LIKE '%Receiving%' THEN 25  -- All other Receiving
        WHEN pc.ProcessCategory LIKE '%Picking%' THEN 30  -- Pick
        WHEN pc.ProcessCategory LIKE '%Shipping%' THEN 27  -- Ship
        WHEN pc.ProcessCategory LIKE '%SNP%' AND pc.ProcessCategory NOT LIKE '%Receiving%' AND pc.ProcessCategory NOT LIKE '%Picking%' AND pc.ProcessCategory NOT LIKE '%Shipping%' THEN 25  -- SNP categories (including "Put Away - SNP")
        WHEN pc.ProcessCategory LIKE '%Put Away%' OR pc.ProcessCategory LIKE '%Putaway%' THEN 35  -- Put Away (must come after SNP check)
        WHEN pc.ProcessCategory LIKE '%Pallet%' THEN 25  -- Pallet
        WHEN pc.ProcessCategory = 'Harvesting' THEN 40  -- Harvest
        WHEN pc.ProcessCategory = 'Boxing' THEN 10
        WHEN pc.ProcessCategory LIKE '%BOM Fix%' THEN 10
        WHEN pc.ProcessCategory LIKE '%Add Part Adjustment%' OR pc.ProcessCategory LIKE '%REMOVE Part Adjustment%' THEN 8  -- Add Part Adjustments
        WHEN pc.ProcessCategory LIKE '%NPI Testing%' THEN 65  -- QA (NPI Testing is QA work)
        WHEN pc.ProcessCategory LIKE '%QA%' THEN 65  -- QA
        ELSE 25
      END as Green_Threshold,
      CASE 
        -- Most specific patterns first (matching category_dell.sql logic)
        WHEN pc.ProcessCategory LIKE '%Discrepancy%' THEN 7  -- Discrepancy categories (including "Receiving - Discrepancy", "Put Away - Discrepancy", etc.)
        WHEN pc.ProcessCategory LIKE '%Engineering%' AND pc.ProcessCategory LIKE '%Hold%' THEN 5  -- Engineering into Hold
        WHEN pc.ProcessCategory LIKE '%Engineering%' THEN 5  -- Engineering out
        WHEN pc.ProcessCategory LIKE '%Reimage%' THEN 10  -- Reimage categories (including "Blowout - Reimage")
        WHEN pc.ProcessCategory LIKE '%Blowout%' THEN 16  -- Blow Out (must come after Reimage check)
        WHEN pc.ProcessCategory LIKE '%Receiving%' AND pc.ProcessCategory LIKE '%Staging%' THEN 12  -- Receiving to Staging
        WHEN pc.ProcessCategory LIKE '%Receiving%' THEN 12  -- All other Receiving
        WHEN pc.ProcessCategory LIKE '%Picking%' THEN 15  -- Pick
        WHEN pc.ProcessCategory LIKE '%Shipping%' THEN 14  -- Ship
        WHEN pc.ProcessCategory LIKE '%SNP%' AND pc.ProcessCategory NOT LIKE '%Receiving%' AND pc.ProcessCategory NOT LIKE '%Picking%' AND pc.ProcessCategory NOT LIKE '%Shipping%' THEN 12  -- SNP categories (including "Put Away - SNP")
        WHEN pc.ProcessCategory LIKE '%Put Away%' OR pc.ProcessCategory LIKE '%Putaway%' THEN 17  -- Put Away (must come after SNP check)
        WHEN pc.ProcessCategory LIKE '%Pallet%' THEN 13  -- Pallet
        WHEN pc.ProcessCategory = 'Harvesting' THEN 20  -- Harvest
        WHEN pc.ProcessCategory = 'Boxing' THEN 8
        WHEN pc.ProcessCategory LIKE '%BOM Fix%' THEN 8
        WHEN pc.ProcessCategory LIKE '%Add Part Adjustment%' OR pc.ProcessCategory LIKE '%REMOVE Part Adjustment%' THEN 6  -- Add Part Adjustments
        WHEN pc.ProcessCategory LIKE '%NPI Testing%' THEN 32  -- QA (NPI Testing is QA work)
        WHEN pc.ProcessCategory LIKE '%QA%' THEN 32  -- QA
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
          WHEN UPPER(cpt.Description) = 'SO-SHIP' AND LEN(pt.SerialNo) = '7' AND (LEN(pt.PartNo) = 5 OR pt.PartNo = 'PART001') THEN 'Shipping - ARB'
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
) th ON cat.ProcessCategory = th.ProcessCategory
ORDER BY ThresholdStatus, cat.ProcessCategory;

