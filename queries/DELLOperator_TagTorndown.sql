SELECT 
    u.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATEPART(HOUR, pt.CreateDate) as WorkHour,
    
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActiveMinutes
    
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.[User] u ON u.ID = pt.UserID
INNER JOIN Plus.pls.PartLocation pl_to ON pl_to.LocationNo = pt.ToLocation
    AND pl_to.ProgramID = pt.ProgramID
    AND UPPER(LTRIM(RTRIM(pl_to.Warehouse))) = 'TAGTORNDOWN'
WHERE u.Username IS NOT NULL
  AND pt.ProgramID = 10053
  AND pt.ToLocation IS NOT NULL
GROUP BY u.Username, 
    CAST(pt.CreateDate as DATE), 
    DATEPART(HOUR, pt.CreateDate)
ORDER BY WorkDate DESC, WorkHour DESC, Operator;
