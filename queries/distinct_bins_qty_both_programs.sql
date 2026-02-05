-- Distinct bins with occupancy flag for both programs.
-- Returns:
-- - 'Occupied' if total AvailableQty in the bin > 0
-- - 'Empty' otherwise
-- Shows results for both ProgramID 10068 (ADT) and 10053 (DELL)
-- Excludes DELL locations that contain 'ADT' in the location name

SELECT
    pl.ProgramID,
    CASE 
        WHEN pl.ProgramID = 10068 THEN 'ADT'
        WHEN pl.ProgramID = 10053 THEN 'DELL'
        ELSE CAST(pl.ProgramID AS VARCHAR)
    END AS ProgramName,
    pl.Warehouse,
    LTRIM(RTRIM(pl.Bin)) AS Bin,
    LTRIM(RTRIM(pl.Bay)) AS Bay,
    CASE WHEN ISNULL(SUM(pq.AvailableQty), 0) > 0 THEN 'Occupied' ELSE 'Empty' END AS BinStatus,
    ISNULL(SUM(pq.AvailableQty), 0) AS TotalQty,
    CAST(ISNULL(SUM(pq.AvailableQty), 0) AS DECIMAL(10, 2)) / 12.0 AS PalletEquivalent,
    -- Pallet/Bin column (based on Bay for DELL only, plus MRO and 3RM% warehouses)
    CASE 
        WHEN pl.ProgramID = 10053 THEN
            CASE 
                -- MRO and 3RM% warehouses are always Pallet
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'MRO' OR UPPER(LTRIM(RTRIM(pl.Warehouse))) LIKE '3RM%' THEN 'Pallet'
                -- Bay-based Pallet classifications
                WHEN UPPER(LTRIM(RTRIM(pl.Bay))) IN ('AD', 'AE', 'AF', 'AG', 'AH', 'AJ', 'AK', 'AL', 'AM', 'AN', 'AO', 'AP', 'AQ', 'AR', 'DA', 'DB', 'DC', 'DD', 'DF', 'ZA', 'ZB', 'ZC', 'ZD', 'ZE', 'ZF') THEN 'Pallet'
                -- Bay-based Bin classifications
                WHEN UPPER(LTRIM(RTRIM(pl.Bay))) IN ('BA', 'BB', 'BC', 'BD', 'BE', 'BF', 'BG', 'BH', 'BJ', 'BK', 'BL', 'BM', 'BN', 'BP', 'BR', 'EHA', 'ENG', 'ERV', 'W1A', 'W1B', 'W1C') THEN 'Bin'
                ELSE ''
            END
        ELSE ''
    END AS PalletBin,
    -- Classification column
    CASE 
        -- ADT classifications
        WHEN pl.ProgramID = 10068 THEN
            CASE 
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) IN ('FGI', 'FINISHEDGOODS') THEN 'FinishedGoods Inventory'
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'HOLD' THEN 'Customer Hold'
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'SCRAP' THEN 'Scrap Outbound'
                ELSE NULL
            END
        -- DELL classifications (Warehouse-based with Bay fallback)
        WHEN pl.ProgramID = 10053 THEN
            CASE 
                -- Warehouse-based classifications (take precedence)
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'WHSE DEF' THEN 'WHSE Def'
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'MRO' THEN 'Consumables'
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) LIKE '3RM%' THEN 'Consumables'
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) IN ('BOMFIX', 'BOXING', 'BROKER', 'DISCREPANCY', 'FGI', 'GENCOEMR', 'GENCOFGI', 'INTRANSITTOMEMPHIS', 'INTRANSITTOMEXICO', 'L2STAGING', 'RAAPPROVED', 'RAPENDING', 'RECEIVED', 'REIMAGE', 'RESEARCH', 'SAFETYCAPTURE', 'STAGING', 'TEARDOWN', 'WIP') THEN 'Production Staging'
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) = 'ENGHOLD' THEN 'Production Hold'
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) IN ('FINISHEDGOODS', 'INDEMANDBADPARTS', 'INDEMANDGOODPARTS', 'NODEMANDBADPARTS', 'NODEMANDGOODPARTS', 'SERVICESFINGOODS', 'SERVICESREPAIR') THEN 'FinishedGoods Inventory'
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) IN ('LIQUIDATION', 'SCRAP', 'TAGTORNDOWN') THEN 'Scrap Outbound'
                WHEN UPPER(LTRIM(RTRIM(pl.Warehouse))) IN ('MEXBOMFIX', 'MEXREIMAGE', 'MEXREPAIR') THEN 'NA'
                -- Bay-based fallback classifications (when warehouse doesn't match above)
                WHEN UPPER(LTRIM(RTRIM(pl.Bay))) IN ('AD', 'AE', 'AF', 'AG', 'AH', 'AJ', 'AK', 'AL', 'AM', 'AN', 'AO', 'AP', 'AQ', 'AR', 'DA', 'DB', 'DC', 'DD', 'DF', 'ZA', 'ZB', 'ZC', 'ZD', 'ZE', 'ZF') THEN 'Pallet'
                WHEN UPPER(LTRIM(RTRIM(pl.Bay))) IN ('BA', 'BB', 'BC', 'BD', 'BE', 'BF', 'BG', 'BH', 'BJ', 'BK', 'BL', 'BM', 'BN', 'BP', 'BR', 'EHA', 'ENG', 'ERV', 'W1A', 'W1B', 'W1C') THEN 'Bin'
                -- All other Bays default to Production Staging (majority of the list)
                WHEN LTRIM(RTRIM(pl.Bay)) IS NOT NULL AND LTRIM(RTRIM(pl.Bay)) <> '' THEN 'Production Staging'
                ELSE NULL
            END
        ELSE NULL
    END AS Classification
FROM Plus.pls.PartLocation pl
LEFT JOIN Plus.pls.PartQty pq
    ON pq.LocationID = pl.ID
   AND pq.ProgramID = pl.ProgramID
WHERE pl.ProgramID IN (10068, 10053)
  AND pl.Bin IS NOT NULL
  AND LTRIM(RTRIM(pl.Bin)) <> ''
  AND (pl.ProgramID != 10053 OR pl.LocationNo NOT LIKE '%ADT%')
  -- Filter out warehouses starting with Mex% and 3RJ%
  AND UPPER(LTRIM(RTRIM(pl.Warehouse))) NOT LIKE 'MEX%'
  AND UPPER(LTRIM(RTRIM(pl.Warehouse))) NOT LIKE '3RJ%'
GROUP BY pl.ProgramID, LTRIM(RTRIM(pl.Bin)), pl.Warehouse, pl.LocationNo, pl.Bay, LTRIM(RTRIM(pl.Bay))
ORDER BY pl.ProgramID, Bin;
