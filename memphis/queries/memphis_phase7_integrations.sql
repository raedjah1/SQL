-- ===============================================
-- MEMPHIS SITE INTELLIGENCE - PHASE 7
-- SYSTEM INTEGRATION & REFERENCES
-- ===============================================

-- Query 19: External System Integrations
SELECT 
    wo.ExternalReference,
    wo.CustomerOrderNumber,
    wo.ExternalSystemID,
    COUNT(*) as ReferenceCount,
    COUNT(DISTINCT wo.PartID) as UniqueParts,
    COUNT(DISTINCT wo.UserID) as UniqueUsers,
    p.Name as ProgramName,
    c.Name as CustomerName,
    MIN(wo.CreateDate) as FirstReference,
    MAX(wo.LastActivityDate) as LastReference,
    AVG(DATEDIFF(day, wo.CreateDate, COALESCE(wo.CompleteDate, GETDATE()))) as AvgProcessingDays
FROM PLUS.pls.WorkOrder wo
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
LEFT JOIN PLUS.pls.Customer c ON p.CustomerID = c.ID
WHERE p.Site = 'MEMPHIS'
AND (wo.ExternalReference IS NOT NULL 
     OR wo.CustomerOrderNumber IS NOT NULL 
     OR wo.ExternalSystemID IS NOT NULL)
GROUP BY wo.ExternalReference, wo.CustomerOrderNumber, wo.ExternalSystemID, p.Name, c.Name
ORDER BY ReferenceCount DESC;

-- Query 20: Configuration and Setup Details
SELECT 
    cfg.ID as ConfigurationID,
    cfg.ConfigurationName,
    cfg.ConfigurationType,
    cfg.Description,
    cfg.Version,
    cfg.IsActive,
    cfg.CreateDate as ConfigCreateDate,
    cfg.LastModified as ConfigLastModified,
    p.Name as ProgramName,
    p.CustomerID,
    c.Name as CustomerName,
    COUNT(wo.ID) as WorkOrdersUsingConfig
FROM PLUS.pls.Configuration cfg
INNER JOIN PLUS.pls.Program p ON cfg.ProgramID = p.ID
LEFT JOIN PLUS.pls.Customer c ON p.CustomerID = c.ID
LEFT JOIN PLUS.pls.WorkOrder wo ON wo.ConfigurationID = cfg.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY cfg.ID, cfg.ConfigurationName, cfg.ConfigurationType, cfg.Description, cfg.Version, 
         cfg.IsActive, cfg.CreateDate, cfg.LastModified, p.Name, p.CustomerID, c.Name
ORDER BY WorkOrdersUsingConfig DESC;

-- Query 21: API and System Integration Logs
SELECT 
    log.ID as LogID,
    log.SystemName,
    log.IntegrationType,
    log.MessageType,
    log.Status,
    COUNT(*) as MessageCount,
    MIN(log.CreateDate) as FirstMessage,
    MAX(log.CreateDate) as LastMessage,
    p.Name as ProgramName,
    AVG(log.ResponseTime) as AvgResponseTime,
    COUNT(CASE WHEN log.Status = 'SUCCESS' THEN 1 END) as SuccessCount,
    COUNT(CASE WHEN log.Status = 'ERROR' THEN 1 END) as ErrorCount
FROM PLUS.pls.IntegrationLog log
INNER JOIN PLUS.pls.WorkOrder wo ON log.WorkOrderID = wo.ID
INNER JOIN PLUS.pls.Program p ON wo.ProgramID = p.ID
WHERE p.Site = 'MEMPHIS'
GROUP BY log.ID, log.SystemName, log.IntegrationType, log.MessageType, log.Status, p.Name
ORDER BY MessageCount DESC;
