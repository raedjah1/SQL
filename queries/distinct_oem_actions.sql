-- GET ALL DISTINCT OEM ACTIONS
SELECT DISTINCT
    rma.[oem_action] AS OEMAction,
    COUNT(*) AS RecordCount
FROM
    ClarityWarehouse.rpt.ADTReconextRMAData rma
WHERE
    rma.[oem_action] IS NOT NULL
    AND LTRIM(RTRIM(rma.[oem_action])) != ''
GROUP BY
    rma.[oem_action]
ORDER BY
    RecordCount DESC, OEMAction;

