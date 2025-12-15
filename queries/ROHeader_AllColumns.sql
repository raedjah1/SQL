-- Show all ROHeader base columns for Program 10068 (recent records)
SELECT TOP 100
    rh.*,
    cs.Description AS StatusDescription,
    u.Username AS CreatedByUser,
    p.Name AS ProgramName
FROM Plus.pls.ROHeader rh
LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = rh.StatusID
LEFT JOIN Plus.pls.[User] u ON u.ID = rh.UserID
LEFT JOIN Plus.pls.Program p ON p.ID = rh.ProgramID
WHERE rh.ProgramID = 10068
ORDER BY rh.CreateDate DESC;



