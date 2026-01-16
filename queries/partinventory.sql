CREATE OR ALTER         VIEW rpt.PartInventory AS
SELECT P.ID                                              as ProgramID,
       PQ.PartNo,
       PN.Description,
       pcc.[Description]                                 AS [PrimaryCommodity],
       scc.[Description]                                 AS [SecondaryCommodity],
       CLG.Description                                   AS LocationGroup,
       PQ.LocationID,
       PL.LocationNo,
       PL.Bin,
       UPPER(PL.Warehouse) as Warehouse,
       CC.ID                                             AS ConfigId,
       CC.Description                                    AS Configuration,
       PQ.PalletBoxNo,
       PQ.LotNo,
       CASE WHEN PN.SerialFlag = 0 THEN 'N' ELSE 'Y' END AS SerialFlag,
       PQ.AvailableQty AS SerializedQty,
       PQ.AvailableQty,
       P.Name                                            AS Program,
       P.Site,
       U.Username,
       PQ.CreateDate,
       PQ.LastActivityDate,
       DATEDIFF(DAY, PQ.LastActivityDate, GETDATE()) AS Aging,
       PL.Building,
       PL.Bay,
       PL.[Row],
       PL.Tier,
       CPT.Description AS PartType,
       NULL AS SerialNo,
       NULL AS StatusID
FROM [Plus].[pls].PartQty PQ
       INNER JOIN [Plus].[pls].PartNo PN ON PQ.PartNo = PN.PartNo
       INNER JOIN Plus.pls.CodePartType CPT ON CPT.ID = PN.PartTypeID
       LEFT JOIN [Plus].[pls].[CodeCommodity] pcc ON pcc.[ID] = PN.[PrimaryCommodityID]
       LEFT JOIN [Plus].[pls].[CodeCommodity] scc ON scc.[ID] = PN.[SecondaryCommodityID]
       INNER JOIN [Plus].[pls].PartLocation PL ON PL.ID = PQ.LocationID
       INNER JOIN [Plus].[pls].Program P ON P.ID = PQ.ProgramID
       INNER JOIN [Plus].[pls].[CodeConfiguration] CC ON CC.ID = PQ.ConfigurationID
       INNER JOIN [Plus].[pls].[User] U ON U.ID = PQ.UserID
       LEFT OUTER JOIN [Plus].[pls].CodeLocationGroup CLG ON CLG.ID = PL.LocationGroupID
WHERE PQ.AvailableQty > 0;