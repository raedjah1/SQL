-- ============================================
-- PARTS AUTOMATION TOOL - FIND PART MAPPINGS
-- ============================================
-- Queries to find where part number mappings exist in Clarity database
-- for building an automation tool

-- ============================================
-- 1. SEARCH FOR PART NUMBERS IN MAIN PARTS TABLE
-- ============================================
-- Check if any of your sample part numbers exist in the parts master
SELECT TOP 10
    PartNo,
    Description,
    PartType,
    Status,
    CreateDate
FROM pls.vPartNo
WHERE PartNo IN (
    'SA5816', '5853', '2GIG-CP21-345E', '2GIG-DW10-345', '2GIG-GB1-345',
    '2GIG-GC2E-345', '2GIG-PAD1-345', '2GIG-PIR1-345', '2GIG-SMKT3-345',
    '300-10260', '3G4000RF-ADTUSA', '5800PIR-RES', '60-362N-10-319.5',
    '60-670-95R', '6150ADT', '6150RF', '6160PL2', '6160RFPL2', '6160VADT'
);

-- ============================================
-- 2. SEARCH FOR ALTERNATE PART NUMBERS
-- ============================================
-- Many systems store part number aliases/alternates
SELECT 
    pa.PartNo as MainPartNo,
    pa.AlternatePartNo,
    pa.Description,
    pa.CreateDate
FROM pls.vPartAlternate pa
WHERE pa.PartNo IN (
    'SA5816', '5853', '2GIG-CP21-345E', '2GIG-DW10-345', '2GIG-GB1-345'
) OR pa.AlternatePartNo IN (
    '5816', '5853', 'PROTECTION 1', '013-3285', '2GIG-GB1'
);

-- ============================================
-- 3. LOOK FOR PART CONFIGURATIONS/VARIANTS
-- ============================================
-- Check if there are part configurations that handle variants
SELECT 
    pac.PartNo,
    pac.Configuration,
    pac.ConfigurationDescription,
    pac.CreateDate
FROM pls.vPartAlternateConfiguration pac
WHERE pac.PartNo LIKE '%5816%' 
   OR pac.PartNo LIKE '%2GIG%'
   OR pac.PartNo LIKE '%SA%'
   OR pac.Configuration LIKE '%5816%'
   OR pac.Configuration LIKE '%2GIG%';

-- ============================================
-- 4. SEARCH PART ATTRIBUTES FOR MAPPINGS
-- ============================================
-- Part attributes might contain original vs processed part numbers
SELECT 
    pna.PartNo,
    pna.AttributeName,
    pna.Value,
    pna.CreateDate
FROM pls.vPartNoAttribute pna
WHERE pna.AttributeName LIKE '%Original%'
   OR pna.AttributeName LIKE '%Alternate%'
   OR pna.AttributeName LIKE '%Mapping%'
   OR pna.AttributeName LIKE '%Process%'
   OR pna.Value IN ('SA5816', '5816', '2GIG-CP21-345E', 'PROTECTION 1');

-- ============================================
-- 5. CHECK SERIAL NUMBER MAPPINGS
-- ============================================
-- Serial numbers might show the relationship
SELECT TOP 20
    ps.SerialNo,
    ps.PartNo,
    ps.CreateDate
FROM pls.vPartSerial ps
WHERE ps.PartNo IN (
    'SA5816', '5816', '2GIG-CP21-345E', '2GIG-DW10-345', '2GIG-GB1-345'
);

-- ============================================
-- 6. LOOK IN GENERIC CONFIGURATION TABLES
-- ============================================
-- Generic tables might store the mapping logic
SELECT 
    gt.TableName,
    gt.KeyValue,
    gt.Description,
    gt.Value1,
    gt.Value2,
    gt.CreateDate
FROM pls.vCodeGenericTable gt
WHERE gt.TableName LIKE '%Part%'
   OR gt.TableName LIKE '%Mapping%'
   OR gt.KeyValue LIKE '%SA5816%'
   OR gt.KeyValue LIKE '%2GIG%'
   OR gt.Value1 LIKE '%5816%';

-- ============================================
-- 7. SEARCH ALL PART-RELATED VIEWS FOR PATTERNS
-- ============================================
-- Get a sample from each major part table to understand structure
SELECT 'vPartNo' as TableName, COUNT(*) as RowCount FROM pls.vPartNo
UNION ALL
SELECT 'vPartAlternate' as TableName, COUNT(*) as RowCount FROM pls.vPartAlternate  
UNION ALL
SELECT 'vPartNoAttribute' as TableName, COUNT(*) as RowCount FROM pls.vPartNoAttribute
UNION ALL
SELECT 'vPartAlternateConfiguration' as TableName, COUNT(*) as RowCount FROM pls.vPartAlternateConfiguration
UNION ALL
SELECT 'vPartSerial' as TableName, COUNT(*) as RowCount FROM pls.vPartSerial
ORDER BY RowCount DESC;

-- ============================================
-- 8. FIND PART DESCRIPTION PATTERNS
-- ============================================
-- Descriptions might contain the original part names
SELECT TOP 50
    PartNo,
    Description,
    PartType
FROM pls.vPartNo
WHERE Description LIKE '%Google%'
   OR Description LIKE '%Amazon%'
   OR Description LIKE '%2GIG%'
   OR Description LIKE '%ADT%'
   OR Description LIKE '%PROTECTION%'
   OR PartNo LIKE '%GA%'
   OR PartNo LIKE '%SA%';

-- ============================================
-- AUTOMATION TOOL STRATEGY
-- ============================================
/*
Based on results, you can build automation by:

1. CREATE MAPPING TABLE from findings above
2. BUILD LOOKUP FUNCTION that:
   - Takes input part number/name
   - Searches through alternates, attributes, descriptions
   - Returns standardized "Process as" part number

3. AUTOMATE PART PROCESSING by:
   - Reading incoming part data
   - Looking up correct part number
   - Updating records with standardized part numbers

4. MAINTAIN MAPPINGS by:
   - Adding new mappings as discovered
   - Validating against Clarity parts master
   - Tracking mapping usage and accuracy
*/
