-- Investigate TEARDOWN_DEMANDLIST table structure
-- GenericTableDefinitionID = 258

-- 1. See sample data and all columns
SELECT TOP 20
    cgt.ID,
    cgt.GenericTableDefinitionID,
    cgt.ProgramID,
    cgt.C01,
    cgt.C02,
    cgt.C03,
    cgt.C04,
    cgt.C05,
    cgt.C06,
    cgt.C07,
    cgt.C08,
    cgt.C09,
    cgt.C10,
    cgt.CreateDate,
    cgt.LastActivityDate
FROM Plus.pls.CodeGenericTable cgt
WHERE cgt.GenericTableDefinitionID = 258
    AND cgt.ProgramID = 10053
ORDER BY cgt.LastActivityDate DESC;

-- 2. Check which columns have data (non-null counts)
SELECT 
    'C01' AS ColumnName,
    COUNT(*) AS TotalRows,
    COUNT(C01) AS NonNullCount,
    COUNT(DISTINCT C01) AS DistinctValues
FROM Plus.pls.CodeGenericTable
WHERE GenericTableDefinitionID = 258 AND ProgramID = 10053
UNION ALL
SELECT 'C02', COUNT(*), COUNT(C02), COUNT(DISTINCT C02)
FROM Plus.pls.CodeGenericTable
WHERE GenericTableDefinitionID = 258 AND ProgramID = 10053
UNION ALL
SELECT 'C03', COUNT(*), COUNT(C03), COUNT(DISTINCT C03)
FROM Plus.pls.CodeGenericTable
WHERE GenericTableDefinitionID = 258 AND ProgramID = 10053
UNION ALL
SELECT 'C04', COUNT(*), COUNT(C04), COUNT(DISTINCT C04)
FROM Plus.pls.CodeGenericTable
WHERE GenericTableDefinitionID = 258 AND ProgramID = 10053
UNION ALL
SELECT 'C05', COUNT(*), COUNT(C05), COUNT(DISTINCT C05)
FROM Plus.pls.CodeGenericTable
WHERE GenericTableDefinitionID = 258 AND ProgramID = 10053
ORDER BY ColumnName;
