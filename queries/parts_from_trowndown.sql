-- Simple query to see all parts going to TORNDOWN location
-- Shows all part transactions (unique SerialNos, using latest CreateDate)

SELECT 
    ID,
    PartNo,
    SerialNo,
    Qty,
    FromLocation,
    ToLocation,
    TransactionType,
    CustomerReference,
    Username,
    CreateDate,
    MachineName,
    LOB,
    CSG_ISG,
    Standard_Cost
FROM (
    SELECT 
        pt.ID,
        pt.PartNo,
        pt.SerialNo,
        pt.Qty,
        pt.Location AS FromLocation,
        pt.ToLocation,
        cpt.Description AS TransactionType,
        pt.CustomerReference,
        u.Username,
        pt.CreateDate,
        dwr.MachineName,
        psa_lob.Value AS LOB,
        CASE 
            WHEN psa_lob.Value IN ('POWER', 'PVAULT') THEN 'ISG'
            ELSE 'CSG'
        END AS CSG_ISG,
        CASE 
            WHEN ISNUMERIC(psa_cost.Value) = 1 THEN CAST(psa_cost.Value AS DECIMAL(10,2))
            ELSE 0
        END AS Standard_Cost,
        ROW_NUMBER() OVER (PARTITION BY pt.SerialNo ORDER BY pt.CreateDate DESC) AS rn
    FROM Plus.pls.PartTransaction pt
        LEFT JOIN Plus.pls.CodePartTransaction cpt ON cpt.ID = pt.PartTransactionID
        LEFT JOIN Plus.pls.[User] u ON u.ID = pt.UserID
        LEFT JOIN Plus.pls.PartSerial ps ON ps.SerialNo = pt.SerialNo AND ps.ProgramID = pt.ProgramID
        LEFT JOIN Plus.pls.PartSerialAttribute psa_lob ON psa_lob.PartSerialID = ps.ID
            AND psa_lob.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB')
        LEFT JOIN Plus.pls.PartSerialAttribute psa_cost ON psa_cost.PartSerialID = ps.ID
            AND psa_cost.AttributeID = (SELECT ID FROM Plus.pls.CodeAttribute WHERE AttributeName = 'TrckObjAttTotalInventoryCost')
        LEFT JOIN (
            SELECT 
                dwr.SerialNumber,
                dwr.MachineName,
                dwr.ID
            FROM [redw].[tia].[DataWipeResult] dwr
            WHERE dwr.TestArea = 'MEMPHIS'
                AND dwr.ID = (
                    SELECT MAX(ID)
                    FROM [redw].[tia].[DataWipeResult]
                    WHERE TestArea = 'MEMPHIS'
                        AND SerialNumber = dwr.SerialNumber
                )
        ) dwr ON dwr.SerialNumber = pt.SerialNo
    WHERE UPPER(pt.ToLocation) LIKE '%TORNDOWN%'
) AS RankedTransactions
WHERE rn = 1
ORDER BY CreateDate DESC;

