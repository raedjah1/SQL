-- ===============================================
-- MEMPHIS SITE INTELLIGENCE - MASTER EXECUTION PLAN
-- Complete Business Intelligence Data Collection
-- ===============================================

/*
EXECUTION ORDER FOR COMPREHENSIVE MEMPHIS SITE ANALYSIS:

PHASE 1: INFRASTRUCTURE (memphis_phase1_infrastructure.sql)
- Query 1: Program & Customer Details
- Query 2: Address & Geographic Information  
- Query 3: Location & Facility Mapping

PHASE 2: OPERATIONS (memphis_phase2_operations.sql)
- Query 4: Work Order Volume & Performance
- Query 5: Status Distribution Analysis
- Query 6: Daily Trends & Patterns

PHASE 3: PARTS & INVENTORY (memphis_phase3_parts_inventory.sql)
- Query 7: Parts Processing Analysis
- Query 8: Serial Number Tracking
- Query 9: Inventory Status & Locations

PHASE 4: QUALITY & TESTING (memphis_phase4_quality_testing.sql)
- Query 10: Test Results & Pass/Fail Rates
- Query 11: Workstation Performance
- Query 12: Defect & Failure Analysis

PHASE 5: WORKFORCE (memphis_phase5_workforce.sql)
- Query 13: User Activity & Performance
- Query 14: Shift Patterns & Timing
- Query 15: Team Performance Analysis

PHASE 6: FINANCIALS (memphis_phase6_financials.sql)
- Query 16: Revenue & Cost Analysis
- Query 17: Monthly Trend Analysis
- Query 18: Customer Profitability

PHASE 7: INTEGRATIONS (memphis_phase7_integrations.sql)
- Query 19: External System References
- Query 20: Configuration Management
- Query 21: API & Integration Logs

EXPECTED DELIVERABLES:
✅ Complete Memphis Site Profile
✅ Operational Performance Metrics
✅ Quality & Defect Analysis
✅ Financial Performance Dashboard
✅ Workforce Utilization Report
✅ Customer & Program Intelligence
✅ System Integration Status
✅ Strategic Recommendations

DASHBOARD COMPONENTS TO BUILD:
📊 Executive Summary KPIs
📈 Operational Performance Trends  
🔍 Quality Control Analytics
💰 Financial Performance Metrics
👥 Workforce & Resource Utilization
🏭 Facility & Equipment Status
🔗 System Integration Health
📋 Customer Program Analysis
*/

-- Quick Memphis Overview Query (Run First)
SELECT 
    'MEMPHIS SITE OVERVIEW' as ReportSection,
    COUNT(DISTINCT p.ID) as TotalPrograms,
    COUNT(DISTINCT p.CustomerID) as UniqueCustomers,
    COUNT(DISTINCT wo.ID) as TotalWorkOrders,
    COUNT(DISTINCT wo.PartID) as UniquePartsProcessed,
    COUNT(DISTINCT wo.UserID) as ActiveUsers,
    MIN(wo.CreateDate) as EarliestActivity,
    MAX(wo.LastActivityDate) as LatestActivity,
    DATEDIFF(day, MIN(wo.CreateDate), MAX(wo.LastActivityDate)) as OperationalDays
FROM PLUS.pls.Program p
LEFT JOIN PLUS.pls.WorkOrder wo ON p.ID = wo.ProgramID
WHERE p.Site = 'MEMPHIS';
