-- =====================================================
-- DELL COMPLETE PROCESS DISCOVERY - MEMPHIS SITE
-- =====================================================
-- Purpose: Discover ALL DELL operations, processes, and operator activities
-- Program: DELL (ProgramID: 10053) - Memphis
-- =====================================================

-- =====================================================
-- 1. DISCOVER ALL DELL TRANSACTION TYPES & PROCESSES
-- =====================================================

-- Find ALL unique transaction types in DELL program
SELECT 
    'DELL TRANSACTION TYPES' as DiscoveryType,
    pt.PartTransaction as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent,
    MIN(pt.CreateDate) as FirstOccurrence,
    MAX(pt.CreateDate) as LastOccurrence
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -6, GETDATE())  -- Last 6 months
GROUP BY pt.PartTransaction
ORDER BY TransactionCount DESC;

-- =====================================================
-- 2. DISCOVER ALL DELL WORKSTATIONS & LOCATIONS
-- =====================================================

-- Find ALL workstations used in DELL operations (from vWOHeader)
SELECT 
    'DELL WORKSTATIONS' as DiscoveryType,
    wh.WorkstationDescription as Workstation,
    COUNT(*) as OrderCount,
    COUNT(DISTINCT wh.Username) as OperatorCount,
    COUNT(DISTINCT wh.PartNo) as UniquePartsHandled,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as UtilizationPercent,
    MIN(wh.CreateDate) as FirstActivity,
    MAX(wh.CreateDate) as LastActivity
FROM pls.vWOHeader wh
WHERE wh.ProgramID = 10053  -- DELL program
  AND wh.CreateDate >= DATEADD(month, -6, GETDATE())  -- Last 6 months
  AND wh.WorkstationDescription IS NOT NULL
GROUP BY wh.WorkstationDescription
ORDER BY OrderCount DESC;

-- =====================================================
-- 3. DISCOVER ALL DELL OPERATORS BY SPECIALIZATION
-- =====================================================

-- Find ALL operators and their specializations
SELECT 
    'DELL OPERATOR SPECIALIZATIONS' as DiscoveryType,
    pt.Username as Operator,
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT pt.PartTransaction) as TransactionTypesHandled,
    -- Get workstations from vWOHeader instead
    (SELECT COUNT(DISTINCT wh.WorkstationDescription) 
     FROM pls.vWOHeader wh 
     WHERE wh.Username = pt.Username 
       AND wh.ProgramID = 10053) as WorkstationsUsed,
    COUNT(DISTINCT pt.PartNo) as UniquePartsHandled,
    COUNT(DISTINCT pt.SerialNo) as UnitsProcessed,
    -- Top transaction type for this operator
    (SELECT TOP 1 pt2.PartTransaction 
     FROM pls.vPartTransaction pt2 
     WHERE pt2.Username = pt.Username 
       AND pt2.ProgramID = 10053
     GROUP BY pt2.PartTransaction 
     ORDER BY COUNT(*) DESC) as PrimarySpecialization,
    MIN(pt.CreateDate) as FirstActivity,
    MAX(pt.CreateDate) as LastActivity
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -6, GETDATE())  -- Last 6 months
  AND pt.Username IS NOT NULL
GROUP BY pt.Username
ORDER BY TotalTransactions DESC;

-- =====================================================
-- 4. DISCOVER DELL WORK ORDER TYPES & STATUSES
-- =====================================================

-- Find ALL work order types and statuses in DELL
SELECT 
    'DELL WORK ORDER TYPES' as DiscoveryType,
    wh.OrderType as WorkOrderType,
    wh.Status as WorkOrderStatus,
    COUNT(*) as OrderCount,
    COUNT(DISTINCT wh.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent,
    MIN(wh.CreateDate) as FirstOrder,
    MAX(wh.CreateDate) as LastOrder
FROM pls.vWOHeader wh
WHERE wh.ProgramID = 10053  -- DELL program
  AND wh.CreateDate >= DATEADD(month, -6, GETDATE())  -- Last 6 months
GROUP BY wh.OrderType, wh.Status
ORDER BY OrderCount DESC;

-- =====================================================
-- 5. DISCOVER DELL SALES ORDER PROCESSES
-- =====================================================

-- Find ALL sales order types and statuses in DELL
SELECT 
    'DELL SALES ORDER TYPES' as DiscoveryType,
    so.OrderType as SalesOrderType,
    so.Status as SalesOrderStatus,
    COUNT(*) as OrderCount,
    COUNT(DISTINCT so.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent,
    MIN(so.CreateDate) as FirstOrder,
    MAX(so.CreateDate) as LastOrder
FROM pls.vSOHeader so
WHERE so.ProgramID = 10053  -- DELL program
  AND so.CreateDate >= DATEADD(month, -6, GETDATE())  -- Last 6 months
GROUP BY so.OrderType, so.Status
ORDER BY OrderCount DESC;

-- =====================================================
-- 6. DISCOVER DELL REPAIR ORDER PROCESSES
-- =====================================================

-- Find ALL repair order types and statuses in DELL
SELECT 
    'DELL REPAIR ORDER TYPES' as DiscoveryType,
    ro.OrderType as RepairOrderType,
    ro.Status as RepairOrderStatus,
    COUNT(*) as OrderCount,
    COUNT(DISTINCT ro.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent,
    MIN(ro.CreateDate) as FirstOrder,
    MAX(ro.CreateDate) as LastOrder
FROM pls.vROHeader ro
WHERE ro.ProgramID = 10053  -- DELL program
  AND ro.CreateDate >= DATEADD(month, -6, GETDATE())  -- Last 6 months
GROUP BY ro.OrderType, ro.Status
ORDER BY OrderCount DESC;

-- =====================================================
-- 7. DISCOVER DELL PART CONDITIONS & QUALITY PROCESSES
-- =====================================================

-- Find ALL part conditions and quality processes in DELL
SELECT 
    'DELL PART CONDITIONS' as DiscoveryType,
    pt.Condition as PartCondition,
    pt.PartTransaction as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent,
    MIN(pt.CreateDate) as FirstOccurrence,
    MAX(pt.CreateDate) as LastOccurrence
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -6, GETDATE())  -- Last 6 months
  AND pt.Condition IS NOT NULL
GROUP BY pt.Condition, pt.PartTransaction
ORDER BY TransactionCount DESC;

-- =====================================================
-- 8. DISCOVER DELL LOCATION HIERARCHY & WAREHOUSE PROCESSES
-- =====================================================

-- Find ALL location patterns and warehouse processes in DELL
SELECT 
    'DELL LOCATION PATTERNS' as DiscoveryType,
    pt.Location as Location,
    pt.PartTransaction as TransactionType,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent,
    MIN(pt.CreateDate) as FirstActivity,
    MAX(pt.CreateDate) as LastActivity
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -6, GETDATE())  -- Last 6 months
  AND pt.Location IS NOT NULL
GROUP BY pt.Location, pt.PartTransaction
ORDER BY TransactionCount DESC;

-- =====================================================
-- 9. DISCOVER DELL SHIFT PATTERNS & TIME-BASED PROCESSES
-- =====================================================

-- Find shift patterns and time-based processes in DELL
SELECT 
    'DELL SHIFT PATTERNS' as DiscoveryType,
    DATEPART(HOUR, pt.CreateDate) as HourOfDay,
    DATENAME(WEEKDAY, pt.CreateDate) as DayOfWeek,
    COUNT(*) as TransactionCount,
    COUNT(DISTINCT pt.Username) as ActiveOperators,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as ActivityPercent,
    MIN(pt.CreateDate) as FirstActivity,
    MAX(pt.CreateDate) as LastActivity
FROM pls.vPartTransaction pt
WHERE pt.ProgramID = 10053  -- DELL program
  AND pt.CreateDate >= DATEADD(month, -6, GETDATE())  -- Last 6 months
  AND pt.Username IS NOT NULL
GROUP BY DATEPART(HOUR, pt.CreateDate), DATENAME(WEEKDAY, pt.CreateDate)
ORDER BY TransactionCount DESC;

-- =====================================================
-- 10. DISCOVER DELL CUSTOMER REFERENCE PATTERNS
-- =====================================================

-- Find customer reference patterns and external integrations
SELECT 
    'DELL CUSTOMER REFERENCES' as DiscoveryType,
    CASE 
        WHEN wh.CustomerReference LIKE 'TEMPRO%' THEN 'TEMPRO Series'
        WHEN wh.CustomerReference LIKE 'FSR%' THEN 'FSR Series'
        WHEN wh.CustomerReference LIKE 'EX%' THEN 'EX Series'
        WHEN wh.CustomerReference LIKE 'SO%' THEN 'SO Series'
        WHEN ISNUMERIC(wh.CustomerReference) = 1 THEN 'Numeric Reference'
        ELSE 'Other Pattern'
    END as ReferencePattern,
    COUNT(*) as OrderCount,
    COUNT(DISTINCT wh.Username) as OperatorCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as DistributionPercent,
    MIN(wh.CreateDate) as FirstOrder,
    MAX(wh.CreateDate) as LastOrder
FROM pls.vWOHeader wh
WHERE wh.ProgramID = 10053  -- DELL program
  AND wh.CreateDate >= DATEADD(month, -6, GETDATE())  -- Last 6 months
  AND wh.CustomerReference IS NOT NULL
GROUP BY CASE 
    WHEN wh.CustomerReference LIKE 'TEMPRO%' THEN 'TEMPRO Series'
    WHEN wh.CustomerReference LIKE 'FSR%' THEN 'FSR Series'
    WHEN wh.CustomerReference LIKE 'EX%' THEN 'EX Series'
    WHEN wh.CustomerReference LIKE 'SO%' THEN 'SO Series'
    WHEN ISNUMERIC(wh.CustomerReference) = 1 THEN 'Numeric Reference'
    ELSE 'Other Pattern'
END
ORDER BY OrderCount DESC;
