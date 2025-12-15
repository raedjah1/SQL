-- Work Order Header Query with ProgramID 10053 Filter
-- Combines Plus and ClarityLakehouse data

SELECT WOH.ProgramID,
       P.Name                                                                   AS Program,
       P.Site,
       WOH.ID,
       WOH.StatusID,
       WOH.CustomerReference,
       WOH.PartNo,
       WOH.SerialNo,
       pcc.[Description]                                                        AS [PrimaryCommodity],
       scc.[Description]                                                        AS [SecondaryCommodity],
       CRT.Description                                                          As RepairType,
       CASE WHEN wsd.Code IS NULL THEN CWS.ID ELSE wsd.ID END                   AS WorkstationID,
       CASE WHEN wsd.Code IS NULL THEN CWS.Description ELSE wsd.Description END AS Workstation,
       CS.Description                                                           AS Status,
       DATEDIFF(SECOND, WOH.[CreateDate], WOH.[LastActivityDate])              AS DurationInSeconds,
       CASE
           WHEN PS.RODate IS NOT NULL AND PS.SODate IS NOT NULL THEN DATEDIFF(SECOND, PS.RODate, PS.SODate)
           WHEN PS.RODate IS NOT NULL THEN DATEDIFF(SECOND, PS.RODate, GETDATE())
           ELSE NULL END                                                        AS TATInSeconds,
       CASE
           WHEN PS.RODate IS NOT NULL AND PS.WOStartDate IS NOT NULL THEN DATEDIFF(SECOND, PS.RODate, PS.WOStartDate)
           WHEN PS.RODate IS NOT NULL THEN DATEDIFF(SECOND, PS.RODate, GETDATE())
           ELSE NULL END                                                        AS TATIntakeInSeconds,
       CASE
           WHEN PS.WOEndDate IS NOT NULL AND PS.SODate IS NOT NULL THEN DATEDIFF(SECOND, PS.WOEndDate, PS.SODate)
           WHEN PS.WOEndDate IS NOT NULL THEN DATEDIFF(SECOND, PS.WOEndDate, GETDATE())
           ELSE NULL END                                                        AS TATShipInSeconds,
       DATEDIFF(DAY, WOH.CreateDate, GETDATE())                                 AS Aging,
       U.Username,
       WOH.CreateDate,
       WOH.LastActivityDate,
       PS.RODate as ReceiveDate,
       PS.SODate as ShipDate,
       PS.WOEndDate
FROM [Plus].[pls].WOHeader WOH
         INNER JOIN [Plus].[pls].[User] U ON U.ID = WOH.UserID
         INNER JOIN [Plus].[pls].Program P ON P.ID = WOH.ProgramID
         INNER JOIN [Plus].[pls].[PartNo] pn ON pn.[PartNo] = WOH.PartNo
         LEFT JOIN [Plus].[pls].[CodeCommodity] pcc ON pcc.[ID] = pn.[PrimaryCommodityID]
         LEFT JOIN [Plus].[pls].[CodeCommodity] scc ON scc.[ID] = pn.[SecondaryCommodityID]
         LEFT JOIN [Plus].[pls].CodeRepairType CRT ON CRT.ID = WOH.RepairTypeID
         LEFT JOIN [Plus].[pls].CodeWorkStation CWS ON CWS.ID = WOH.WorkStationID
         LEFT JOIN [Plus].[pls].CodeWorkStationCustomDescription wsd
                   ON wsd.ProgramID = WOH.ProgramID AND wsd.RepairTypeID = WOH.RepairTypeID AND
                      wsd.CodeWorkStationID = WOH.WorkStationID and wsd.ProgramID = P.ID
         LEFT JOIN [Plus].[pls].CodeStatus CS ON CS.ID = WOH.StatusID
         LEFT JOIN [Plus].[pls].PartSerial PS ON WOH.ID = PS.WOHeaderID
WHERE WOH.ProgramID = 10053

UNION ALL

SELECT (SELECT TOP 1 ID
        FROM ClarityLakehouse.rpt.program
        WHERE ERPID = s.contract
          AND ERP = CONCAT('IFS-', s.region))                                    AS ProgramID,
       s.contract_ref                                                            AS Program,
       s.delivery_address                                                        AS Site,
       TRY_CAST(so.order_no AS INT)                                             AS ID,
       CASE
           WHEN so.on_hold_flag = 'TRUE' THEN 28
           WHEN so.quotation_result IN ('1', '2') THEN 17
           WHEN so.quotation_result = '3' THEN 15
           ELSE 19
           END                                                                   AS StatusID,
       sr.reference_no                                                           AS CustomerReference,
       so.part_no                                                                AS PartNo,
       so.serial_begin                                                           AS SerialNo,
       COALESCE(pcg.description, 'Unknown')                                      AS PrimaryCommodity,
       COALESCE(scg.description, 'Unknown')                                      AS SecondaryCommodity,
       sr.work_type_id                                                           AS RepairType,
       TRY_CAST(soo.work_center_no AS INT)                                      AS WorkstationID,
       soo.operation_description                                                 AS Workstation,
       CASE
           WHEN so.on_hold_flag = 'TRUE' THEN 'HOLD'
           WHEN so.quotation_result IN ('1', '2') THEN 'SCRAP'
           WHEN so.quotation_result = '3' THEN 'REPAIR'
           ELSE 'WIP'
           END                                                                   AS Status,
       COALESCE(DATEDIFF(SECOND, so.date_entered, so.rowversion), 0)             AS DurationInSeconds,
       CASE
           WHEN ith2.rowversion IS NOT NULL AND ith.dated IS NOT NULL THEN DATEDIFF(SECOND, ith2.rowversion, ith.dated)
           WHEN ith2.rowversion IS NOT NULL THEN DATEDIFF(SECOND, ith2.rowversion, GETDATE())
           ELSE NULL END                                                         AS TATInSeconds,
       CASE
           WHEN ith2.rowversion IS NOT NULL AND so.date_entered IS NOT NULL THEN DATEDIFF(SECOND, ith2.rowversion, so.date_entered)
           WHEN ith2.rowversion IS NOT NULL THEN DATEDIFF(SECOND, ith2.rowversion, GETDATE())
           ELSE NULL END                                                         AS TATIntakeInSeconds,
       CASE
           WHEN so.close_date IS NOT NULL AND ith.dated IS NOT NULL THEN DATEDIFF(SECOND, so.close_date, ith.dated)
           WHEN so.close_date IS NOT NULL THEN DATEDIFF(SECOND, so.close_date, GETDATE())
           ELSE NULL END                                                         AS TATShipInSeconds,
       COALESCE(DATEDIFF(DAY, so.date_entered, GETDATE()), 0)                   AS Aging,
       so.user_id                                                                AS Username,
       so.date_entered                                                           AS CreateDate,
       so.rowversion                                                             AS LastActivityDate,
       ith2.rowversion as ReceiveDate,
       ith.dated as ShipDate,
       so.close_date                                                             AS WOEndDate
FROM ClarityLakehouse.ifsapp.shop_ord_tab so
         INNER JOIN ClarityLakehouse.ifsapp.site_tab s ON so.contract = s.contract and s.region = so.region
         INNER JOIN ClarityLakehouse.ifsapp.work_order_shop_ord_tab wo
                  ON so.order_no = wo.order_no and so.region = wo.region
         INNER JOIN ClarityLakehouse.ifsapp.service_request_tab sr
                  on wo.wo_no = sr.service_request_no and wo.region = sr.region
         LEFT JOIN ClarityLakehouse.ifsapp.inventory_part_tab ip
                   ON so.part_no = ip.part_no and so.contract = ip.contract and so.region = ip.region
         LEFT JOIN ClarityLakehouse.ifsapp.inventory_transaction_hist_tab ith
                   ON ith.contract = so.contract and ith.part_no = so.part_no and ith.serial_no = so.serial_begin and so.region = ith.region and ith.[transaction] = 'REP-OESHIP' and ith.dated > so.close_date
         LEFT JOIN ClarityLakehouse.ifsapp.inventory_transaction_hist_tab ith2
                   ON ith2.contract = so.contract and ith2.part_no = so.part_no and ith2.serial_no = so.serial_begin and so.region = ith2.region and ith2.[transaction] = 'REP-REC' and ith2.rowversion < so.date_entered
         LEFT JOIN ClarityLakehouse.ifsapp.commodity_group_tab pcg
                   on ip.prime_commodity = pcg.commodity_code and ip.region = pcg.region
         LEFT JOIN ClarityLakehouse.ifsapp.commodity_group_tab scg
                   on ip.second_commodity = scg.commodity_code and ip.region = scg.region
         INNER JOIN ClarityLakehouse.ifsapp.shop_order_operation_tab soo
                  on CONCAT(soo.order_no, soo.operation_no) = (select top 1 CONCAT(soot.order_no, soot.operation_no)
                                                               from ClarityLakehouse.ifsapp.shop_order_operation_tab soot
                                                               where soot.order_no = so.order_no
                                                                 and soot.order_no = so.order_no
                                                               ORDER BY soot.operation_no DESC)
WHERE (SELECT TOP 1 ID
       FROM ClarityLakehouse.rpt.program
       WHERE ERPID = s.contract
         AND ERP = CONCAT('IFS-', s.region)) = 10053;

