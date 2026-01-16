-- Comprehensive query: All distinct parts ever for ProgramID 10068 (ADT)
-- Purpose: List of all unique PartNo values from ALL sources
-- Checks: PartSerial, PartNoAttribute, PartTransaction, PartLocation, WOHeader, ROLine

SELECT DISTINCT
    PartNo
FROM (
    -- Parts from PartSerial (serialized parts)
    SELECT DISTINCT PartNo
    FROM Plus.pls.PartSerial
    WHERE ProgramID = 10068
      AND PartNo IS NOT NULL
      AND PartNo != ''
    
    UNION
    
    -- Parts from PartNoAttribute (parts with attributes)
    SELECT DISTINCT PartNo
    FROM Plus.pls.PartNoAttribute
    WHERE ProgramID = 10068
      AND PartNo IS NOT NULL
      AND PartNo != ''
    
    UNION
    
    -- Parts from PartTransaction (parts in transactions)
    SELECT DISTINCT PartNo
    FROM Plus.pls.PartTransaction
    WHERE ProgramID = 10068
      AND PartNo IS NOT NULL
      AND PartNo != ''
    
    UNION
    
    -- Parts from PartLocation (parts in inventory locations)
    SELECT DISTINCT PartNo
    FROM Plus.pls.PartLocation
    WHERE ProgramID = 10068
      AND PartNo IS NOT NULL
      AND PartNo != ''
    
    UNION
    
    -- Parts from WOHeader (parts in work orders)
    SELECT DISTINCT PartNo
    FROM Plus.pls.WOHeader
    WHERE ProgramID = 10068
      AND PartNo IS NOT NULL
      AND PartNo != ''
    
    UNION
    
    -- Parts from ROLine (parts in return orders)
    SELECT DISTINCT PartNo
    FROM Plus.pls.ROLine
    WHERE ProgramID = 10068
      AND PartNo IS NOT NULL
      AND PartNo != ''
) AS AllParts
ORDER BY PartNo;

