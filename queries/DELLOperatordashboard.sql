SELECT 
    u.Username as Operator,
    CAST(pt.CreateDate as DATE) as WorkDate,
    DATEPART(HOUR, pt.CreateDate) as WorkHour,
    
    -- Disposition (always TEARDOWN since we filter for it)
    'TEARDOWN' AS Disposition,
    
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    MIN(pt.CreateDate) as FirstTransaction,
    MAX(pt.CreateDate) as LastTransaction,
    DATEDIFF(MINUTE, MIN(pt.CreateDate), MAX(pt.CreateDate)) as ActiveMinutes
    
FROM Plus.pls.PartTransaction pt
INNER JOIN Plus.pls.[User] u ON u.ID = pt.UserID
-- Disposition from PartSerialAttribute (Priority 1) - only get TEARDOWN
LEFT JOIN Plus.pls.PartSerial ps ON ps.SerialNo = pt.SerialNo 
    AND ps.ProgramID = pt.ProgramID
    AND ps.PartNo = pt.PartNo
OUTER APPLY (
    SELECT TOP 1 psa.Value
    FROM Plus.pls.PartSerialAttribute psa
    WHERE psa.PartSerialID = ps.ID
        AND psa.AttributeID = 558  -- DISPOSITION AttributeID
        AND UPPER(LTRIM(RTRIM(psa.Value))) = 'TEARDOWN'
    ORDER BY psa.LastActivityDate DESC, psa.ID DESC
) psa_disposition
-- Disposition from PartNoAttribute (Priority 2 - fallback) - only get TEARDOWN
OUTER APPLY (
    SELECT TOP 1 pna.Value
    FROM Plus.pls.PartNoAttribute pna
    WHERE pna.PartNo = REPLACE(pt.PartNo, '-H', '')
        AND pna.ProgramID = pt.ProgramID
        AND pna.AttributeID = 558  -- DISPOSITION AttributeID
        AND UPPER(LTRIM(RTRIM(pna.Value))) = 'TEARDOWN'
    ORDER BY pna.LastActivityDate DESC, pna.ID DESC
) pna_disposition
WHERE u.Username IS NOT NULL
  AND pt.ProgramID = 10053
  AND pt.PartTransactionID = 1  -- RO-RECEIVE (hardcoded for performance)
  AND (psa_disposition.Value IS NOT NULL OR pna_disposition.Value IS NOT NULL)  -- Must have TEARDOWN from one source
GROUP BY u.Username, 
    CAST(pt.CreateDate as DATE), 
    DATEPART(HOUR, pt.CreateDate)
ORDER BY WorkDate DESC, WorkHour DESC, Operator;
