-- Get all items received under ASNs created by @reconext.com users
WITH ASNList AS (
    SELECT
        rh.ID AS ROHeaderID,
        rh.CustomerReference AS ASN,
        (SELECT TOP 1 rha.Value 
         FROM Plus.pls.ROHeaderAttribute rha
         JOIN Plus.pls.CodeAttribute att ON att.ID = rha.AttributeID 
         WHERE rha.ROHeaderID = rh.ID AND att.AttributeName = 'SHIPFROMORG'
         ORDER BY rha.ID DESC) AS BranchID,
        u.ID AS UserID,
        u.Username AS CreatedBy,
        crst.ID AS CarrierResultID,
        crst.TrackingNo,
        crst.CreateDate AS TrackingCreatedDate,
        rh.CreateDate AS ASNCreateDate,
        rh.ProgramID,
        p.Name AS ProgramName
    FROM
        Plus.pls.ROHeader rh
    CROSS APPLY (
        SELECT TOP 1 crst1.ProgramID, crst1.TrackingNo, crst1.UserID, crst1.ID, crst1.CreateDate
        FROM Plus.pls.CarrierResult crst1 
        WHERE crst1.OrderHeaderID = rh.ID 
          AND crst1.ProgramID = rh.ProgramID 
          AND crst1.OrderType = 'RO' 
        ORDER BY crst1.ID DESC
    ) crst
    LEFT JOIN
        Plus.pls.[User] u ON u.ID = crst.UserID
    LEFT JOIN
        Plus.pls.Program p ON p.ID = rh.ProgramID
    WHERE
        rh.ProgramID = 10068
        AND u.Username LIKE '%@reconext.com'
)
SELECT
    a.ASN,
    a.BranchID,
    a.CreatedBy AS ASNCreatedBy,
    a.TrackingNo AS ASNTrackingNo,
    a.ASNCreateDate,
    rec.CreateDate AS ReceiptDate,
    rec.PartNo,
    rec.SerialNo,
    rec.Qty,
    dl.TrackingNo AS ReceiptTrackingNo,
    u_rec.Username AS ReceivedBy,
    cpt.Description AS TransactionType
FROM
    ASNList a
INNER JOIN
    Plus.pls.PartTransaction rec ON rec.CustomerReference = a.ASN
INNER JOIN
    Plus.pls.CodePartTransaction cpt ON cpt.ID = rec.PartTransactionID
LEFT JOIN
    Plus.pls.RODockLog dl ON dl.ID = rec.RODockLogID
LEFT JOIN
    Plus.pls.[User] u_rec ON u_rec.ID = rec.UserID
WHERE
    rec.ProgramID = 10068
    AND cpt.Description = 'RO-RECEIVE'
ORDER BY
    a.ASN, rec.CreateDate, rec.PartNo, rec.SerialNo;