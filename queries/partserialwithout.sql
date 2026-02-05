SELECT 
    ps.*,
    'DELL - MEMPHIS' AS Location,
    -- Warehouse = Level1 prefix from PartLocationNo (this replaces using StatusDescription as "warehouse")
    w.WarehousePrefix AS Warehouse,
    -- Classification columns
    CASE
        -- Step 8: TEARDOWN parts (PartNo ends with -H or RESERVED status)
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND UPPER(PartNo) LIKE '%-H'
        THEN 'Teardown Part'
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND StatusDescription = 'RESERVED'
        THEN 'Teardown Part'

        -- CSV edge-case: TEARDOWN awaiting states
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND StatusDescription IN ('NEW', 'HOLD', 'REPAIR', 'SCRAP')
        THEN 'Awaiting Teardown'

        -- Step 7: BROKER (RECEIVED) location-based split
        -- Broker.ARB.0.0.0 should be classified as 'Broker' (W_Level)
        WHEN StatusDescription = 'RECEIVED'
             AND UPPER(PartLocationNo) = 'BROKER.ARB.0.0.0'
        THEN 'Broker'
        -- CSV edge-case: BROKER HOLD/RECEIVED (general, after location-specific rules)
        WHEN w.WarehousePrefix = 'BROKER'
             AND StatusDescription IN ('HOLD', 'RECEIVED')
        THEN 'Broker'
        WHEN StatusDescription = 'RECEIVED'
             AND UPPER(PartLocationNo) LIKE '%BROKER%'
             AND UPPER(PartLocationNo) != 'BROKER.ARB.0.0.0'
        THEN 'Broker FGI'

        -- Step 6: REIMAGE / MEXREPAIR location-based overrides
        WHEN w.WarehousePrefix = 'REIMAGE'
             AND StatusDescription <> 'HOLD'
             AND UPPER(PartLocationNo) LIKE 'REIMAGE.ARB.ENG.REV.NPI%'
        THEN 'Engineering Review'
        WHEN w.WarehousePrefix = 'REIMAGE'
             AND StatusDescription <> 'HOLD'
        THEN 'Engineering Review'
        WHEN w.WarehousePrefix = 'MEXREPAIR'
             AND (
                 UPPER(PartLocationNo) LIKE '%AWP%'
                 OR UPPER(PartLocationNo) = 'INTRANSITTOMEXICO.ARB.0.0.0.1'
             )
        THEN 'MexRepair AWP'

        -- Step 5: DISCREPANCY (NEW/RECEIVED/REPAIR) - location-based rules (ARB vs SnP; UR vs Loc/Research)
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.ARB.%'
             AND UPPER(PartLocationNo) LIKE '%.UR.%'
        THEN 'ARB UR'
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.SNP.%'
             AND UPPER(PartLocationNo) LIKE '%.UR.%'
        THEN 'SnP UR'
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.ARB.%'
             AND UPPER(PartLocationNo) NOT LIKE '%.UR.%'
        THEN 'ARB Research'
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.SNP.%'
             AND UPPER(PartLocationNo) NOT LIKE '%.UR.%'
        THEN 'SnP Research'

        -- Step 4: additional warehouse-based mappings (Warehouse = Level1 prefix)
        WHEN w.WarehousePrefix = 'L2STAGING'
             AND StatusDescription = 'RECEIVED'
        THEN 'Saftey Capture'
        WHEN w.WarehousePrefix = 'RAAPPROVED'
             AND StatusDescription = 'RECEIVED'
        THEN 'RAAPPROVED'
        WHEN w.WarehousePrefix = 'INDEMANDBADPARTS'
             AND StatusDescription = 'RECEIVED'
        THEN 'Teardown Part'
        WHEN w.WarehousePrefix = 'SERVICESFINGOODS'
             AND StatusDescription IN ('NEW', 'RECEIVED')
        THEN 'Teardown Part'
        -- Note: user-provided warehouse name has a typo (INTRANSIITTOMEXICO). Support both spellings.
        WHEN w.WarehousePrefix IN ('INTRANSIITTOMEXICO', 'INTRANSITTOMEXICO')
             AND StatusDescription = 'HOLD'
        THEN 'IntransittoMexico'
        -- CSV edge-case: INTRANSITTOMEXICO received/scrap states
        WHEN w.WarehousePrefix IN ('INTRANSIITTOMEXICO', 'INTRANSITTOMEXICO')
             AND StatusDescription IN ('RECEIVED', 'SCRAP')
        THEN 'IntransittoMexico'
        WHEN w.WarehousePrefix = 'INDEMANDGOODPARTS'
             AND StatusDescription = 'RECEIVED'
        THEN 'Teardown Part'
        WHEN w.WarehousePrefix = 'NODEMANDGOODPARTS'
             AND StatusDescription = 'RECEIVED'
        THEN 'Teardown Part'
        WHEN w.WarehousePrefix = 'NODEMANDBADPARTS'
             AND StatusDescription = 'RECEIVED'
        THEN 'Teardown Part'

        -- Step 3: additional non-WIP warehouse-based mappings (Warehouse = Level1 prefix)
        -- CSV edge-case: STAGING "Blowout" states
        WHEN w.WarehousePrefix = 'STAGING'
             AND StatusDescription IN ('HOLD', 'NEW', 'REPAIR', 'SCRAP')
        THEN 'Blowout'
        WHEN w.WarehousePrefix = 'MEXREIMAGE'
             AND StatusDescription = 'HOLD'
        THEN 'MexReimage'
        WHEN w.WarehousePrefix = 'MEXBOMFIX'
             AND StatusDescription = 'HOLD'
        THEN 'MexBomFix'
        WHEN w.WarehousePrefix = 'RESEARCH'
             AND StatusDescription = 'RECEIVED'
        THEN 'Research'
        WHEN w.WarehousePrefix = 'LIQUIDATION'
             AND StatusDescription = 'RECEIVED'
        THEN 'Liquidation'
        WHEN w.WarehousePrefix = 'BOMFIX'
             AND StatusDescription = 'HOLD'
        THEN 'BomFIX'
        WHEN w.WarehousePrefix = 'TAGTORNDOWN'
             AND StatusDescription = 'RECEIVED'
        THEN 'TagTorn Down'
        -- CSV edge-case: TAGTORNDOWN completion states
        WHEN w.WarehousePrefix = 'TAGTORNDOWN'
             AND StatusDescription IN ('HOLD', 'NEW', 'REPAIR')
        THEN 'Teardown Complete'
        WHEN w.WarehousePrefix = 'SCRAP'
        THEN 'Scrap'
        WHEN w.WarehousePrefix = 'SAFETYCAPTURE'
             AND StatusDescription = 'RECEIVED'
        THEN 'Saftey Capture'
        WHEN w.WarehousePrefix = 'FGI'
             AND StatusDescription = 'REPAIR'
        THEN 'FGI'
        WHEN w.WarehousePrefix = 'GENCOFGI'
             AND StatusDescription = 'RECEIVED'
        THEN 'FGI'
        WHEN w.WarehousePrefix = 'GENCOEMR'
             AND StatusDescription = 'RECEIVED'
        THEN 'MexRepair'
        WHEN w.WarehousePrefix = 'SERVICESREPAIR'
        THEN 'Teardown Part'

        -- Step 2: non-WIP warehouse-based mappings (Warehouse = Level1 prefix)
        WHEN w.WarehousePrefix = 'RAPENDING'
             AND StatusDescription = 'RECEIVED'
        THEN 'RAPENDING'
        WHEN w.WarehousePrefix = 'REIMAGE'
             AND StatusDescription = 'HOLD'
        THEN 'Reimage'
        WHEN w.WarehousePrefix = 'INTRANSITTOMEXICO'
             AND StatusDescription = 'HOLD'
        THEN 'IntransittoMexico'
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND StatusDescription = 'RECEIVED'
        THEN 'Teardown'
        -- CSV edge-case: ENGHOLD non-received states
        WHEN w.WarehousePrefix = 'ENGHOLD'
             AND StatusDescription IN ('NEW', 'HOLD')
        THEN 'NPI'
        WHEN w.WarehousePrefix = 'ENGHOLD'
             AND StatusDescription = 'RECEIVED'
        THEN 'ENG Hold'
        -- CSV edge-case: FINISHEDGOODS awaiting putaway location
        WHEN w.WarehousePrefix = 'FINISHEDGOODS'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) = 'FINISHEDGOODS.ARB.0.0.0'
        THEN 'Awaiting Putaway'
        -- CSV edge-case: FINISHEDGOODS non-root locations should be treated as FGI
        WHEN w.WarehousePrefix = 'FINISHEDGOODS'
             AND StatusDescription IN ('NEW', 'RECEIVED')
             AND UPPER(PartLocationNo) <> 'FINISHEDGOODS.ARB.0.0.0'
        THEN 'FGI'
        WHEN w.WarehousePrefix = 'FINISHEDGOODS'
             AND StatusDescription = 'REPAIR'
        THEN 'FGI'
        WHEN w.WarehousePrefix = 'STAGING'
             AND StatusDescription = 'RECEIVED'
        THEN 'Staging'
        WHEN w.WarehousePrefix = 'MEXREPAIR'
             AND StatusDescription = 'HOLD'
        THEN 'MexRepair'
        WHEN w.WarehousePrefix = 'INTRANSITTOMEMPHIS'
             AND StatusDescription = 'HOLD'
        THEN 'INTRANSITTOMEMPHIS'
        -- CSV edge-case: INTRANSITTOMEMPHIS received naming
        WHEN w.WarehousePrefix = 'INTRANSITTOMEMPHIS'
             AND StatusDescription = 'RECEIVED'
        THEN 'IntransittoMem'
        -- CSV edge-case: BOXING workstation states
        WHEN w.WarehousePrefix = 'BOXING'
             AND StatusDescription IN ('HOLD', 'RECEIVED')
        THEN 'Boxing'
        WHEN w.WarehousePrefix = 'RECEIVED'
             AND StatusDescription = 'RECEIVED'
             AND PartLocationNo LIKE '%.SNP.%'
        THEN 'SnP Recv'
        -- CSV edge-case: generic RECEIVED warehouse rows
        WHEN w.WarehousePrefix = 'RECEIVED'
             AND StatusDescription IN ('NEW', 'RECEIVED')
        THEN 'Received'

        -- CSV edge-case: LIQUIDATION awaiting state
        WHEN w.WarehousePrefix = 'LIQUIDATION'
             AND StatusDescription = 'NEW'
             AND UPPER(PartLocationNo) = 'LIQUIDATION.SNP.MAN.0.0'
        THEN 'Awaiting Liq'

        -- CSV edge-case: RESEARCH NEW should be ARB Research at the root location
        WHEN w.WarehousePrefix = 'RESEARCH'
             AND StatusDescription = 'NEW'
             AND UPPER(PartLocationNo) = 'RESEARCH.ARB.0.0.0'
        THEN 'ARB Research'

        -- Step 1: WIP workstation-based mapping (Warehouse = WIP)
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription = 'gTask2' THEN 'MexRepair'
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription IN ('gTask5', 'gTest0', 'Datawipe') THEN 'Reimage'
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription IN ('Cosmetic', 'gTask3') THEN 'Clean & Grade'
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription = 'gTask1' THEN 'Grading'
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription = 'Triage' THEN 'Broker'
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription = 'Close' THEN 'Putaway'
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription = 'Scrap' THEN 'Scrap'
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription = 'gTask0' THEN 'Optiline'
        ELSE NULL
    END AS W_Level,
    CASE
        -- Step 8: TEARDOWN parts (PartNo ends with -H or RESERVED status)
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND UPPER(PartNo) LIKE '%-H'
        THEN 'Teardown Part'
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND StatusDescription = 'RESERVED'
        THEN 'Teardown Part'

        -- CSV edge-case: TEARDOWN awaiting states
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND StatusDescription IN ('NEW', 'HOLD', 'REPAIR', 'SCRAP')
        THEN 'Teardown'

        -- Step 7: BROKER (RECEIVED) location-based split
        -- Broker.ARB.0.0.0 should be classified as 'WIP' (Mid_Level)
        WHEN StatusDescription = 'RECEIVED'
             AND UPPER(PartLocationNo) = 'BROKER.ARB.0.0.0'
        THEN 'WIP'
        -- CSV edge-case: BROKER HOLD/RECEIVED (general, after location-specific rules)
        WHEN w.WarehousePrefix = 'BROKER'
             AND StatusDescription IN ('HOLD', 'RECEIVED')
        THEN 'WIP'
        WHEN StatusDescription = 'RECEIVED'
             AND UPPER(PartLocationNo) LIKE '%BROKER%'
             AND UPPER(PartLocationNo) != 'BROKER.ARB.0.0.0'
        THEN 'Broker FGI'

        -- Step 6: REIMAGE / MEXREPAIR location-based overrides
        WHEN w.WarehousePrefix = 'REIMAGE'
             AND StatusDescription <> 'HOLD'
             AND UPPER(PartLocationNo) LIKE 'REIMAGE.ARB.ENG.REV.NPI%'
        THEN 'Reimage'
        WHEN w.WarehousePrefix = 'REIMAGE'
             AND StatusDescription <> 'HOLD'
        THEN 'Reimage'
        WHEN w.WarehousePrefix = 'MEXREPAIR'
             AND (
                 UPPER(PartLocationNo) LIKE '%AWP%'
                 OR UPPER(PartLocationNo) = 'INTRANSITTOMEXICO.ARB.0.0.0.1'
             )
        THEN 'AWP'

        -- Step 5: DISCREPANCY (NEW/RECEIVED/REPAIR) - location-based rules (ARB vs SnP; UR vs Loc/Research)
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.ARB.%'
             AND UPPER(PartLocationNo) LIKE '%.UR.%'
        THEN 'ARB UR'
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.SNP.%'
             AND UPPER(PartLocationNo) LIKE '%.UR.%'
        THEN 'SnP UR'
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.ARB.%'
             AND UPPER(PartLocationNo) NOT LIKE '%.UR.%'
        THEN 'ARB Research'
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.SNP.%'
             AND UPPER(PartLocationNo) NOT LIKE '%.UR.%'
        THEN 'SnP Research'

        -- Step 4: additional warehouse-based mappings (Warehouse = Level1 prefix)
        WHEN w.WarehousePrefix = 'L2STAGING'
             AND StatusDescription = 'RECEIVED'
        THEN 'WIP'
        WHEN w.WarehousePrefix = 'RAAPPROVED'
             AND StatusDescription = 'RECEIVED'
        THEN 'SNP PenRTV'
        WHEN w.WarehousePrefix IN ('INDEMANDBADPARTS', 'INDEMANDGOODPARTS', 'NODEMANDGOODPARTS', 'NODEMANDBADPARTS', 'SERVICESFINGOODS')
             AND StatusDescription IN ('NEW', 'RECEIVED')
        THEN 'Teardown Part'
        WHEN w.WarehousePrefix IN ('INTRANSIITTOMEXICO', 'INTRANSITTOMEXICO')
             AND StatusDescription = 'HOLD'
        THEN 'REPAIR'
        -- CSV edge-case: INTRANSITTOMEXICO received/scrap states
        WHEN w.WarehousePrefix IN ('INTRANSIITTOMEXICO', 'INTRANSITTOMEXICO')
             AND StatusDescription IN ('RECEIVED', 'SCRAP')
        THEN 'Repair'

        -- Step 3: additional non-WIP warehouse-based mappings (Warehouse = Level1 prefix)
        -- CSV edge-case: RESEARCH NEW should be ARB Research at the root location
        WHEN w.WarehousePrefix = 'RESEARCH'
             AND StatusDescription = 'NEW'
             AND UPPER(PartLocationNo) = 'RESEARCH.ARB.0.0.0'
        THEN 'ARB Research'
        WHEN w.WarehousePrefix IN ('MEXREIMAGE', 'MEXBOMFIX')
             AND StatusDescription = 'HOLD'
        THEN 'REPAIR'
        WHEN w.WarehousePrefix = 'RESEARCH'
             AND StatusDescription = 'RECEIVED'
        THEN 'Research'
        -- CSV edge-case: LIQUIDATION awaiting state
        WHEN w.WarehousePrefix = 'LIQUIDATION'
             AND StatusDescription = 'NEW'
             AND UPPER(PartLocationNo) = 'LIQUIDATION.SNP.MAN.0.0'
        THEN 'SnP Liq'
        WHEN w.WarehousePrefix = 'LIQUIDATION'
             AND StatusDescription = 'RECEIVED'
        THEN 'SNP PenLiq'
        WHEN w.WarehousePrefix = 'BOMFIX'
             AND StatusDescription = 'HOLD'
        THEN 'WIP'
        WHEN w.WarehousePrefix = 'TAGTORNDOWN'
             AND StatusDescription = 'RECEIVED'
        THEN 'TagTornDown'
        -- CSV edge-case: TAGTORNDOWN completion states
        WHEN w.WarehousePrefix = 'TAGTORNDOWN'
             AND StatusDescription IN ('HOLD', 'NEW', 'REPAIR')
        THEN 'TagTornDown'
        WHEN w.WarehousePrefix = 'SCRAP'
        THEN 'Scrap'
        WHEN w.WarehousePrefix = 'SAFETYCAPTURE'
             AND StatusDescription = 'RECEIVED'
        THEN 'WIP'
        WHEN w.WarehousePrefix IN ('FGI', 'GENCOFGI')
             AND StatusDescription IN ('REPAIR', 'RECEIVED')
        THEN 'FGI'
        WHEN w.WarehousePrefix = 'GENCOEMR'
             AND StatusDescription = 'RECEIVED'
        THEN 'REPAIR'
        WHEN w.WarehousePrefix = 'SERVICESREPAIR'
        THEN 'Teardown Part'

        -- Step 2: non-WIP warehouse-based mappings (Warehouse = Level1 prefix)
        WHEN w.WarehousePrefix = 'RAPENDING'
             AND StatusDescription = 'RECEIVED'
        THEN 'SNP RAPEN'
        WHEN w.WarehousePrefix = 'REIMAGE'
             AND StatusDescription = 'HOLD'
        THEN 'Reimage'
        WHEN w.WarehousePrefix IN ('INTRANSITTOMEXICO', 'INTRANSITTOMEMPHIS', 'MEXREPAIR')
             AND StatusDescription = 'HOLD'
        THEN 'REPAIR'
        -- CSV edge-case: INTRANSITTOMEMPHIS received
        WHEN w.WarehousePrefix = 'INTRANSITTOMEMPHIS'
             AND StatusDescription = 'RECEIVED'
        THEN 'Repair'
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND StatusDescription = 'RECEIVED'
        THEN 'TEARDOWN'
        -- CSV edge-case: ENGHOLD non-received states
        WHEN w.WarehousePrefix = 'ENGHOLD'
             AND StatusDescription IN ('NEW', 'HOLD')
        THEN 'ENGR Hold'
        WHEN w.WarehousePrefix = 'ENGHOLD'
             AND StatusDescription = 'RECEIVED'
        THEN 'HOLD'
        -- CSV edge-case: FINISHEDGOODS awaiting putaway location
        WHEN w.WarehousePrefix = 'FINISHEDGOODS'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) = 'FINISHEDGOODS.ARB.0.0.0'
        THEN 'WIP'
        -- CSV edge-case: FINISHEDGOODS non-root locations should be treated as FGI
        WHEN w.WarehousePrefix = 'FINISHEDGOODS'
             AND StatusDescription IN ('NEW', 'RECEIVED')
             AND UPPER(PartLocationNo) <> 'FINISHEDGOODS.ARB.0.0.0'
        THEN 'FGI'
        WHEN w.WarehousePrefix = 'FINISHEDGOODS'
             AND StatusDescription = 'REPAIR'
        THEN 'FGI'
        -- CSV edge-case: STAGING "Blowout" states
        WHEN w.WarehousePrefix = 'STAGING'
             AND StatusDescription IN ('HOLD', 'NEW', 'REPAIR', 'SCRAP')
        THEN 'WIP'
        WHEN w.WarehousePrefix = 'STAGING'
             AND StatusDescription = 'RECEIVED'
        THEN 'WIP'
        -- CSV edge-case: BOXING workstation states
        WHEN w.WarehousePrefix = 'BOXING'
             AND StatusDescription IN ('HOLD', 'RECEIVED')
        THEN 'WIP'
        WHEN w.WarehousePrefix = 'RECEIVED'
             AND StatusDescription = 'RECEIVED'
             AND PartLocationNo LIKE '%.SNP.%'
        THEN 'SNP Recv'
        -- CSV edge-case: generic RECEIVED warehouse rows
        WHEN w.WarehousePrefix = 'RECEIVED'
             AND StatusDescription IN ('NEW', 'RECEIVED')
        THEN 'WIP'

        -- Step 1: WIP workstation-based mapping (Warehouse = WIP)
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription = 'gTask2' THEN 'REPAIR'
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription IN ('gTask5', 'gTest0', 'Datawipe') THEN 'Reimage'
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription IN ('Cosmetic', 'gTask3', 'gTask1', 'Triage', 'Close', 'gTask0') THEN 'WIP'
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription = 'Scrap' THEN 'Scrap'
        ELSE NULL
    END AS Mid_Level,
    CASE
        -- Step 8: TEARDOWN parts (PartNo ends with -H or RESERVED status)
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND UPPER(PartNo) LIKE '%-H'
        THEN 'Teardown Part'
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND StatusDescription = 'RESERVED'
        THEN 'Teardown Part'

        -- CSV edge-case: TEARDOWN awaiting states
        WHEN w.WarehousePrefix = 'TEARDOWN'
             AND StatusDescription IN ('NEW', 'HOLD', 'REPAIR', 'SCRAP')
        THEN 'ARB WIP'

        -- Step 7: BROKER (RECEIVED) location-based split
        -- Broker.ARB.0.0.0 should be classified as 'ARB WIP' (High_Level)
        WHEN StatusDescription = 'RECEIVED'
             AND UPPER(PartLocationNo) = 'BROKER.ARB.0.0.0'
        THEN 'ARB WIP'
        -- CSV edge-case: BROKER HOLD/RECEIVED (general, after location-specific rules)
        WHEN w.WarehousePrefix = 'BROKER'
             AND StatusDescription IN ('HOLD', 'RECEIVED')
        THEN 'ARB WIP'
        WHEN StatusDescription = 'RECEIVED'
             AND UPPER(PartLocationNo) LIKE '%BROKER%'
             AND UPPER(PartLocationNo) != 'BROKER.ARB.0.0.0'
        THEN 'ARB Complete'

        -- Step 6: REIMAGE / MEXREPAIR location-based overrides
        WHEN w.WarehousePrefix = 'REIMAGE'
             AND StatusDescription <> 'HOLD'
             AND UPPER(PartLocationNo) LIKE 'REIMAGE.ARB.ENG.REV.NPI%'
        THEN 'ARB WIP'
        WHEN w.WarehousePrefix = 'REIMAGE'
             AND StatusDescription <> 'HOLD'
        THEN 'ARB WIP'
        WHEN w.WarehousePrefix = 'MEXREPAIR'
             AND (
                 UPPER(PartLocationNo) LIKE '%AWP%'
                 OR UPPER(PartLocationNo) = 'INTRANSITTOMEXICO.ARB.0.0.0.1'
             )
        THEN 'ARB Hold'

        -- Step 5: DISCREPANCY (NEW/RECEIVED/REPAIR) - location-based rules (ARB vs SnP; UR vs Loc/Research)
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.ARB.%'
             AND UPPER(PartLocationNo) LIKE '%.UR.%'
        THEN 'ARB Hold'
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.SNP.%'
             AND UPPER(PartLocationNo) LIKE '%.UR.%'
        THEN 'SNP Hold'
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.ARB.%'
             AND UPPER(PartLocationNo) NOT LIKE '%.UR.%'
        THEN 'ARB Hold'
        WHEN w.WarehousePrefix = 'DISCREPANCY'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) LIKE '%.SNP.%'
             AND UPPER(PartLocationNo) NOT LIKE '%.UR.%'
        THEN 'SNP Hold'

        -- Step 4: additional warehouse-based mappings (Warehouse = Level1 prefix)
        WHEN w.WarehousePrefix = 'L2STAGING'
             AND StatusDescription = 'RECEIVED'
        THEN 'ARB WIP'
        WHEN w.WarehousePrefix = 'RAAPPROVED'
             AND StatusDescription = 'RECEIVED'
        THEN 'SnP WIP'
        WHEN w.WarehousePrefix IN ('INDEMANDBADPARTS', 'INDEMANDGOODPARTS', 'NODEMANDGOODPARTS', 'NODEMANDBADPARTS', 'SERVICESFINGOODS')
             AND StatusDescription IN ('NEW', 'RECEIVED')
        THEN 'Teardown Part'
        WHEN w.WarehousePrefix IN ('INTRANSIITTOMEXICO', 'INTRANSITTOMEXICO')
             AND StatusDescription = 'HOLD'
        THEN 'ARB WIP'
        -- CSV edge-case: INTRANSITTOMEXICO received/scrap states
        WHEN w.WarehousePrefix IN ('INTRANSIITTOMEXICO', 'INTRANSITTOMEXICO')
             AND StatusDescription IN ('RECEIVED', 'SCRAP')
        THEN 'ARB WIP'

        -- Step 3: additional non-WIP warehouse-based mappings (Warehouse = Level1 prefix)
        WHEN w.WarehousePrefix IN ('MEXREIMAGE', 'MEXBOMFIX')
             AND StatusDescription = 'HOLD'
        THEN 'ARB WIP'
        -- CSV edge-case: RESEARCH NEW should be ARB Hold at the root location
        WHEN w.WarehousePrefix = 'RESEARCH'
             AND StatusDescription = 'NEW'
             AND UPPER(PartLocationNo) = 'RESEARCH.ARB.0.0.0'
        THEN 'ARB Hold'
        WHEN w.WarehousePrefix = 'RESEARCH'
             AND StatusDescription = 'RECEIVED'
        THEN 'ARB Hold'
        WHEN w.WarehousePrefix = 'LIQUIDATION'
             AND StatusDescription = 'RECEIVED'
        THEN 'SnP Complete'
        WHEN w.WarehousePrefix = 'BOMFIX'
             AND StatusDescription = 'HOLD'
        THEN 'ARB WIP'
        WHEN w.WarehousePrefix = 'TAGTORNDOWN'
             AND StatusDescription = 'RECEIVED'
        THEN 'ARB Complete'
        -- CSV edge-case: TAGTORNDOWN completion states
        WHEN w.WarehousePrefix = 'TAGTORNDOWN'
             AND StatusDescription IN ('HOLD', 'NEW', 'REPAIR')
        THEN 'ARB Complete'
        WHEN w.WarehousePrefix = 'SCRAP'
        THEN 'ARB Complete'
        WHEN w.WarehousePrefix = 'SAFETYCAPTURE'
             AND StatusDescription = 'RECEIVED'
        THEN 'ARB WIP'
        WHEN w.WarehousePrefix IN ('FGI', 'GENCOFGI')
             AND StatusDescription IN ('REPAIR', 'RECEIVED')
        THEN 'ARB FGI'
        WHEN w.WarehousePrefix = 'GENCOEMR'
             AND StatusDescription = 'RECEIVED'
        THEN 'ARB WIP'
        WHEN w.WarehousePrefix = 'SERVICESREPAIR'
        THEN 'Teardown Part'

        -- Step 2: non-WIP warehouse-based mappings (Warehouse = Level1 prefix)
        WHEN w.WarehousePrefix = 'RAPENDING'
             AND StatusDescription = 'RECEIVED'
        THEN 'SnP WIP'
        WHEN w.WarehousePrefix = 'RECEIVED'
             AND StatusDescription = 'RECEIVED'
             AND PartLocationNo LIKE '%.SNP.%'
        THEN 'SnP WIP'
        -- CSV edge-case: generic RECEIVED warehouse rows
        WHEN w.WarehousePrefix = 'RECEIVED'
             AND StatusDescription IN ('NEW', 'RECEIVED')
        THEN 'ARB WIP'
        WHEN w.WarehousePrefix IN ('TEARDOWN', 'STAGING')
             AND StatusDescription = 'RECEIVED'
        THEN 'ARB WIP'
        -- CSV edge-case: STAGING "Blowout" states
        WHEN w.WarehousePrefix = 'STAGING'
             AND StatusDescription IN ('HOLD', 'NEW', 'REPAIR', 'SCRAP')
        THEN 'ARB WIP'
        WHEN w.WarehousePrefix IN ('REIMAGE', 'INTRANSITTOMEXICO', 'MEXREPAIR', 'INTRANSITTOMEMPHIS', 'BOXING')
             AND StatusDescription = 'HOLD'
        THEN 'ARB WIP'
        -- CSV edge-case: BOXING received state
        WHEN w.WarehousePrefix = 'BOXING'
             AND StatusDescription = 'RECEIVED'
        THEN 'ARB WIP'
        -- CSV edge-case: INTRANSITTOMEMPHIS received
        WHEN w.WarehousePrefix = 'INTRANSITTOMEMPHIS'
             AND StatusDescription = 'RECEIVED'
        THEN 'ARB WIP'
        -- CSV edge-case: ENGHOLD non-received states
        WHEN w.WarehousePrefix = 'ENGHOLD'
             AND StatusDescription IN ('NEW', 'HOLD')
        THEN 'ARB Hold'
        WHEN w.WarehousePrefix = 'ENGHOLD'
             AND StatusDescription = 'RECEIVED'
        THEN 'ARB Hold'
        -- CSV edge-case: FINISHEDGOODS awaiting putaway location
        WHEN w.WarehousePrefix = 'FINISHEDGOODS'
             AND StatusDescription IN ('NEW', 'RECEIVED', 'REPAIR')
             AND UPPER(PartLocationNo) = 'FINISHEDGOODS.ARB.0.0.0'
        THEN 'ARB WIP'
        -- CSV edge-case: FINISHEDGOODS non-root locations should be treated as FGI
        WHEN w.WarehousePrefix = 'FINISHEDGOODS'
             AND StatusDescription IN ('NEW', 'RECEIVED')
             AND UPPER(PartLocationNo) <> 'FINISHEDGOODS.ARB.0.0.0'
        THEN 'ARB FGI'
        WHEN w.WarehousePrefix = 'FINISHEDGOODS'
             AND StatusDescription = 'REPAIR'
        THEN 'ARB FGI'
        -- CSV edge-case: LIQUIDATION awaiting state
        WHEN w.WarehousePrefix = 'LIQUIDATION'
             AND StatusDescription = 'NEW'
             AND UPPER(PartLocationNo) = 'LIQUIDATION.SNP.MAN.0.0'
        THEN 'SnP Complete'

        -- Step 1: WIP workstation-based mapping (Warehouse = WIP)
        WHEN w.WarehousePrefix = 'WIP'
             AND WorkstationDescription IN ('gTask2', 'gTask5', 'gTest0', 'Cosmetic', 'gTask3', 'gTask1', 'Triage', 'Close', 'Scrap', 'gTask0', 'Datawipe')
        THEN 'ARB WIP'
        ELSE NULL
    END AS High_Level,
    CASE
        WHEN age.MinutesSinceLastActivity > 720 THEN 'Outside SLA'
        ELSE 'Within SLA'
    END AS SLA_Status,
    
    age.Age_Hours_LastActivityDate AS SLA_Aging_Hours,

    CASE 
        WHEN age.Age_Hours_LastActivityDate < 24 THEN 0
        ELSE FLOOR(age.Age_Hours_LastActivityDate / 24.0)
    END AS SLA_Aging_Days,

    -- Age in hours from CreateDate
    age.Age_Hours_CreateDate AS Age_Hours_CreateDate,

    -- Age in hours from LastActivityDate
    age.Age_Hours_LastActivityDate AS Age_Hours_LastActivityDate,

    -- Aging days from CreateDate (same logic as SLA_Aging_Days)
    CASE 
        WHEN age.Age_Hours_CreateDate < 24 THEN 0
        ELSE FLOOR(age.Age_Hours_CreateDate / 24.0)
    END AS Aging_Days_CreateDate,

    -- Aging days from LastActivityDate (same logic as SLA_Aging_Days)
    CASE 
        WHEN age.Age_Hours_LastActivityDate < 24 THEN 0
        ELSE FLOOR(age.Age_Hours_LastActivityDate / 24.0)
    END AS Aging_Days_LastActivityDate,

    -- Bucket for Age_Hours_CreateDate (10-hour ranges, 100+ for >= 100)
    CASE 
        WHEN age.Age_Hours_CreateDate >= 100 THEN '100+'
        ELSE CAST(FLOOR(age.Age_Hours_CreateDate / 10.0) * 10 AS VARCHAR)
             + '-'
             + CAST(FLOOR(age.Age_Hours_CreateDate / 10.0) * 10 + 9 AS VARCHAR)
    END AS Age_Bucket_CreateDate,

    -- Bucket for Age_Hours_LastActivityDate (10-hour ranges, 100+ for >= 100)
    CASE 
        WHEN age.Age_Hours_LastActivityDate >= 100 THEN '100+'
        ELSE CAST(FLOOR(age.Age_Hours_LastActivityDate / 10.0) * 10 AS VARCHAR)
             + '-'
             + CAST(FLOOR(age.Age_Hours_LastActivityDate / 10.0) * 10 + 9 AS VARCHAR)
    END AS Age_Bucket_LastActivityDate,

    CASE 
        WHEN PartLocationNo LIKE '%ARB.0.0.0%' THEN 'ARB Location'
        ELSE 'Put Away location'
    END AS Location_Type

FROM (
    -- Base tables behind pls.vPartSerial (mirrors queries/PartSeriallive.sql)
    SELECT
          t0.ID
        , t0.ProgramID
        , t0.PartNo
        , codeConfiguration.[Description] AS ConfigurationDescription
        , t0.ParentSerialNo
        , t0.SerialNo
        , partLocation.LocationNo         AS PartLocationNo
        , t0.PalletBoxNo
        , t0.LotNo
        , codeStatus.[Description]        AS StatusDescription
        , t0.ROHeaderID
        , t0.RODate
        , t0.WOHeaderID
        , codeWorkstation.[Description]   AS WorkstationDescription
        , t0.WOStartDate
        , t0.WOEndDate
        , t0.WOPass
        , t0.Shippable
        , t0.SOHeaderID
        , t0.SODate
        , u.Username
        , t0.CreateDate
        , t0.LastActivityDate
        , partLocation.Warehouse          AS PartLocationWarehouse
        , ISNULL(psa_family.Value, 'Unknown') AS Family
        , ISNULL(psa_lob.Value, 'Unknown') AS LOB
        , ISNULL(lob_grouping.C02, 'CSG') AS LOB_Category
        , CASE
              WHEN ISNUMERIC(pna_cost.Value) = 1 THEN CAST(pna_cost.Value AS DECIMAL(10,2))
              ELSE 0
          END AS Standard_Cost
    FROM Plus.pls.PartSerial AS t0
    CROSS JOIN (
        SELECT
              MAX(CASE WHEN AttributeName = 'TrckObjAttFamily' THEN ID END) AS FamilyAttributeID
            , MAX(CASE WHEN AttributeName = 'TrckObjAttLOB' THEN ID END) AS LOBAttributeID
            , MAX(CASE WHEN AttributeName = 'STANDARDCOST' THEN ID END) AS StandardCostAttributeID
        FROM Plus.pls.CodeAttribute
        WHERE AttributeName IN ('TrckObjAttFamily', 'TrckObjAttLOB', 'STANDARDCOST')
    ) AS attr
    INNER JOIN Plus.pls.[User] AS u
        ON u.ID = t0.UserID
    LEFT JOIN Plus.pls.CodeConfiguration AS codeConfiguration
        ON t0.ConfigurationID = codeConfiguration.ID
    INNER JOIN Plus.pls.CodeStatus AS codeStatus
        ON t0.StatusID = codeStatus.ID
    LEFT JOIN Plus.pls.CodeWorkStation AS codeWorkstation
        ON t0.WorkStationID = codeWorkstation.ID
    INNER JOIN Plus.pls.PartLocation AS partLocation
        ON t0.LocationID = partLocation.ID
    -- Family from PartSerialAttribute
    OUTER APPLY (
        SELECT TOP 1 psa.Value
        FROM Plus.pls.PartSerialAttribute psa
        WHERE psa.PartSerialID = t0.ID
          AND psa.AttributeID = attr.FamilyAttributeID
        ORDER BY psa.CreateDate DESC, psa.ID DESC
    ) AS psa_family
    -- LOB from PartSerialAttribute
    OUTER APPLY (
        SELECT TOP 1 psa.Value
        FROM Plus.pls.PartSerialAttribute psa
        WHERE psa.PartSerialID = t0.ID
          AND psa.AttributeID = attr.LOBAttributeID
        ORDER BY psa.CreateDate DESC, psa.ID DESC
    ) AS psa_lob
    -- LOB category mapping (CSG/ISG/etc) from LOB_GROUPING table
    LEFT JOIN Plus.pls.CodeGenericTable AS lob_grouping
        ON lob_grouping.GenericTableDefinitionID = 228  -- LOB_GROUPING
        AND lob_grouping.C01 = ISNULL(psa_lob.Value, 'Unknown')
    -- Standard Cost from PartNoAttribute (use cleaned PartNo without '-H' suffix)
    OUTER APPLY (
        SELECT TOP 1 pna.Value
        FROM Plus.pls.PartNoAttribute pna
        WHERE pna.PartNo = REPLACE(t0.PartNo, '-H', '')
          AND pna.AttributeID = attr.StandardCostAttributeID
          AND pna.ProgramID = t0.ProgramID
        ORDER BY pna.LastActivityDate DESC, pna.ID DESC
    ) AS pna_cost
    WHERE t0.ProgramID = 10053
      AND partLocation.LocationNo NOT LIKE '%RAW%' 
      AND partLocation.LocationNo NOT LIKE '%RESERVE%'
) ps
CROSS APPLY (
    SELECT
        UPPER(LEFT(ps.PartLocationNo, CHARINDEX('.', ps.PartLocationNo + '.') - 1)) AS WarehousePrefix
) AS w
CROSS APPLY (
    SELECT GETUTCDATE() AS NowUtc
) AS nowUtc
CROSS APPLY (
    SELECT
          CAST(ps.CreateDate AT TIME ZONE 'Central Standard Time' AT TIME ZONE 'UTC' AS DATETIME) AS CreateDateUtc
        , CAST(ps.LastActivityDate AT TIME ZONE 'Central Standard Time' AT TIME ZONE 'UTC' AS DATETIME) AS LastActivityDateUtc
) AS tz
CROSS APPLY (
    SELECT
          DATEDIFF(MINUTE, tz.LastActivityDateUtc, nowUtc.NowUtc) AS MinutesSinceLastActivity
        , CEILING(DATEDIFF(MINUTE, tz.CreateDateUtc, nowUtc.NowUtc) / 60.0) AS Age_Hours_CreateDate
        , CEILING(DATEDIFF(MINUTE, tz.LastActivityDateUtc, nowUtc.NowUtc) / 60.0) AS Age_Hours_LastActivityDate
) AS age