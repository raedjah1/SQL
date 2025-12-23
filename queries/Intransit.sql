SELECT
    ID,
    ProgramID,
    PartTransaction,
    PartNo,
    ParentSerialNo,
    SerialNo,
    Qty,
    [Source],
    [Condition],
    [Configuration],
    [Location],
    ToLocation,
    PalletBoxNo,
    ToPalletBoxNo,
    LotNo,
    Reason,
    CustomerReference,
    OrderType,
    OrderHeaderID,
    OrderLineID,
    RODockLogID,
    InventorySource,
    ERPProgramID,
    CurrencyCode,
    CostPerUnit,
    Username,
    CreateDate,
    ForDate,
    ForYear,
    ForMonth,
    ForWeek,
    ForQuarter,
    SourcePartNo,
    SourceSerialNo,
    ConversionFactor,
    ERPQty,
    CurrentLocation,
    CurrentWarehouse
FROM (
    SELECT
        pt.ID,
        pt.ProgramID,
        cpt.[Description]                 AS PartTransaction,
        pt.PartNo,
        pt.ParentSerialNo,
        pt.SerialNo,
        pt.Qty,
        pt.[Source],
        pt.[Condition],
        pt.[Configuration],
        pt.[Location],
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
        pl_current.LocationNo AS CurrentLocation,
        pl_current.Warehouse AS CurrentWarehouse,
        ROW_NUMBER() OVER (PARTITION BY pt.SerialNo ORDER BY pt.CreateDate DESC) AS rn
    FROM [Plus].[pls].[PartTransaction]       AS pt
    JOIN [Plus].[pls].[CodePartTransaction]   AS cpt ON cpt.ID = pt.PartTransactionID
    JOIN [Plus].[pls].[User]                  AS u   ON u.ID   = pt.UserID
    LEFT JOIN [Plus].[pls].[PartSerial]       AS ps_current 
        ON ps_current.SerialNo = pt.SerialNo 
        AND ps_current.ProgramID = 10053
    LEFT JOIN [Plus].[pls].[PartLocation]     AS pl_current 
        ON pl_current.ID = ps_current.LocationID
    WHERE pt.Location LIKE '%IntransittoMemphis%'
        AND cpt.[Description] = 'WH-MOVEPARTTOPALLET'
        AND pl_current.Warehouse IS NOT NULL
        AND UPPER(pl_current.Warehouse) LIKE 'FINISHEDGOODS%'
) AS BaseData
WHERE rn = 1
