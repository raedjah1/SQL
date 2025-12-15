-- Show all available ROHeader attribute names for Program 10068
SELECT DISTINCT
    ca.AttributeName,
    COUNT(*) AS UsageCount,
    COUNT(DISTINCT roa.ROHeaderID) AS UniqueROHeaders,
    MIN(roa.Value) AS SampleValue
FROM Plus.pls.ROHeaderAttribute roa
JOIN Plus.pls.CodeAttribute ca ON ca.ID = roa.AttributeID
JOIN Plus.pls.ROHeader rh ON rh.ID = roa.ROHeaderID
WHERE rh.ProgramID = 10068
GROUP BY ca.AttributeName
ORDER BY UsageCount DESC, ca.AttributeName;



