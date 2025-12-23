SELECT 
    dwr.*,
    stl.*
FROM [redw].[tia].[DataWipeResult] AS dwr
JOIN [redw].[tia].[SubTestLogs] AS stl 
    ON stl.MainTestID = dwr.ID
WHERE dwr.MachineName = 'IDIAGS'
    AND dwr.TestArea = 'MEMPHIS'
    AND dwr.SerialNumber = 'DJX0V94'
    AND dwr.ID = (
        SELECT MAX(ID)
        FROM [redw].[tia].[DataWipeResult]
        WHERE MachineName = 'IDIAGS'
            AND TestArea = 'MEMPHIS'
            AND SerialNumber = 'DJX0V94'
    )
ORDER BY dwr.ID DESC;
