-- ============================================
-- ENHANCED CATEGORIZATION WITH PALLET TRACKING
-- ============================================
-- This query adds the missing pallet consolidation categories
-- that Albert Vincent identified as gaps in the current dashboard

SELECT *,
    CASE
        -- EXISTING CATEGORIES (from your current query)
        WHEN PartTransaction IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE') AND UPPER(Source) LIKE '%ARB%' THEN 'ARB Receiving'
        WHEN PartTransaction IN ('RO-RECEIVE') AND UPPER(Location) IS NULL AND UPPER(ToLocation) LIKE '3RMRAWG.%' THEN 'ARB Receiving - Raw Goods'
        WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.ARB%' AND UPPER(ToLocation) LIKE 'FINISHEDGOODS.%' THEN 'ARB Receiving - Finished Goods'
        WHEN PartTransaction IN ('WH-MOVEPART') AND UPPER(Location) LIKE 'RECEIVED.ARB%' AND UPPER(ToLocation) LIKE 'SAN.%' THEN 'ARB Receiving - SaN'
        WHEN PartTransaction IN ('RO-RECEIVE', 'WH-DISCREPANCYRECEIVE') AND (UPPER(Source) LIKE '%SNP%' OR UPPER(Source) LIKE '%S&P%') THEN 'SNP Receiving'
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
        
        -- NEW PALLET CONSOLIDATION CATEGORIES (Albert Vincent's requirements)
        -- Move TO Pallet Box (Consolidation)
        WHEN PartTransaction = 'WH-MOVEPARTTOPALLET' THEN 'Pallet Consolidation - Move TO Pallet'
             
        -- Move FROM Pallet Box (Deconsolidation)  
        WHEN PartTransaction = 'WH-MOVEPARTFROMPALLET' THEN 'Pallet Deconsolidation - Move FROM Pallet'
        
        ELSE 'TBD'
    END AS Category
FROM pls.vPartTransaction
WHERE ProgramID = '10053'  -- Memphis DELL program
  AND CreateDate >= DATEADD(day, -30, GETDATE())  -- Last 30 days
ORDER BY CreateDate DESC;
