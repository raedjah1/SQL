-- Search for ADT Customer Reference in SOHeader and ROHeader
-- Reference: 8888OH 8564547   11238170
-- This searches for all parts of the reference in both tables

-- ================================================
-- SEARCH IN SOHEADER (Sales Orders)
-- ================================================
SELECT 
    'SOHeader' AS SourceTable,
    soh.ID AS OrderID,
    soh.CustomerReference,
    soh.ProgramID,
    p.Name AS ProgramName,
    soh.StatusID,
    cs.Description AS Status,
    soh.CreateDate,
    soh.LastActivityDate,
    soh.AddressID,
    cad.Name AS OrgName,
    cad.Address1,
    cad.City,
    cad.State,
    cad.Zip
FROM 
    Plus.pls.SOHeader soh
    LEFT JOIN Plus.pls.Program p ON p.ID = soh.ProgramID
    LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = soh.StatusID
    LEFT JOIN Plus.pls.CodeAddressDetails cad ON cad.AddressID = soh.AddressID AND cad.AddressType = 'ShipTo'
WHERE 
    soh.ProgramID IN (10068, 10072)  -- ADT Program IDs
    AND (
        soh.CustomerReference LIKE '%8888OH%'
        OR soh.CustomerReference LIKE '%8564547%'
        OR soh.CustomerReference LIKE '%11238170%'
        OR soh.CustomerReference LIKE '%8888OH 8564547%'
        OR soh.CustomerReference LIKE '%8564547%11238170%'
        OR soh.CustomerReference = '8888OH 8564547   11238170'
    )

UNION ALL

-- ================================================
-- SEARCH IN ROHEADER (Return Orders)
-- ================================================
SELECT 
    'ROHeader' AS SourceTable,
    rh.ID AS OrderID,
    rh.CustomerReference,
    rh.ProgramID,
    p.Name AS ProgramName,
    rh.StatusID,
    cs.Description AS Status,
    rh.CreateDate,
    rh.LastActivityDate,
    rh.AddressID,
    cad.Name AS OrgName,
    cad.Address1,
    cad.City,
    cad.State,
    cad.Zip
FROM 
    Plus.pls.ROHeader rh
    LEFT JOIN Plus.pls.Program p ON p.ID = rh.ProgramID
    LEFT JOIN Plus.pls.CodeStatus cs ON cs.ID = rh.StatusID
    LEFT JOIN Plus.pls.CodeAddressDetails cad ON cad.AddressID = rh.AddressID AND cad.AddressType = 'ShipTo'
WHERE 
    rh.ProgramID IN (10068, 10072)  -- ADT Program IDs
    AND (
        rh.CustomerReference LIKE '%8888OH%'
        OR rh.CustomerReference LIKE '%8564547%'
        OR rh.CustomerReference LIKE '%11238170%'
        OR rh.CustomerReference LIKE '%8888OH 8564547%'
        OR rh.CustomerReference LIKE '%8564547%11238170%'
        OR rh.CustomerReference = '8888OH 8564547   11238170'
    )

ORDER BY 
    SourceTable,
    CreateDate DESC;

-- ================================================
-- ALTERNATIVE: More flexible search
-- ================================================
-- If the above doesn't find anything, try this broader search:
/*
SELECT 
    'SOHeader' AS SourceTable,
    soh.ID AS OrderID,
    soh.CustomerReference,
    soh.ProgramID,
    p.Name AS ProgramName,
    soh.CreateDate
FROM 
    Plus.pls.SOHeader soh
    LEFT JOIN Plus.pls.Program p ON p.ID = soh.ProgramID
WHERE 
    soh.ProgramID IN (10068, 10072)
    AND soh.CustomerReference LIKE '%8564547%'

UNION ALL

SELECT 
    'ROHeader' AS SourceTable,
    rh.ID AS OrderID,
    rh.CustomerReference,
    rh.ProgramID,
    p.Name AS ProgramName,
    rh.CreateDate
FROM 
    Plus.pls.ROHeader rh
    LEFT JOIN Plus.pls.Program p ON p.ID = rh.ProgramID
WHERE 
    rh.ProgramID IN (10068, 10072)
    AND rh.CustomerReference LIKE '%8564547%'

ORDER BY CreateDate DESC;
*/

