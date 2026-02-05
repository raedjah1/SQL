-- ============================================
-- INDEX RECOMMENDATIONS FOR tdgoodgit.sql
-- Purpose: Speed up GIT lookup and overall query performance
-- ============================================
-- 
-- IMPORTANT: 
-- - Run these in a test environment first
-- - Review with your DBA (indexes have write overhead)
-- - Monitor index usage and adjust as needed
-- ============================================

-- 1. SOUnit: Critical for GIT lookup (SerialNo lookup)
-- This is the most important index for the new GIT functionality
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SOUnit_SerialNo_SOShipmentInfoID')
BEGIN
    CREATE INDEX IX_SOUnit_SerialNo_SOShipmentInfoID
    ON Plus.pls.SOUnit (SerialNo, SOShipmentInfoID)
    INCLUDE (ID);
    PRINT 'Created: IX_SOUnit_SerialNo_SOShipmentInfoID';
END
GO

-- 2. SOShipmentInfo: For joining to SOHeader
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SOShipmentInfo_SOHeaderID_ShipmentDate')
BEGIN
    CREATE INDEX IX_SOShipmentInfo_SOHeaderID_ShipmentDate
    ON Plus.pls.SOShipmentInfo (SOHeaderID, ShipmentDate DESC, ID DESC)
    INCLUDE (TrackingNo);
    PRINT 'Created: IX_SOShipmentInfo_SOHeaderID_ShipmentDate';
END
GO

-- 3. SOHeader: For GIT filter (ProgramID + CustomerReference LIKE 'GIT%')
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SOHeader_ProgramID_CustomerReference')
BEGIN
    CREATE INDEX IX_SOHeader_ProgramID_CustomerReference
    ON Plus.pls.SOHeader (ProgramID, CustomerReference)
    INCLUDE (ID);
    PRINT 'Created: IX_SOHeader_ProgramID_CustomerReference';
END
GO

-- 4. PartTransaction: For main query filter (ProgramID + ToLocation)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PartTransaction_ProgramID_ToLocation_CreateDate')
BEGIN
    CREATE INDEX IX_PartTransaction_ProgramID_ToLocation_CreateDate
    ON Plus.pls.PartTransaction (ProgramID, ToLocation, CreateDate DESC)
    INCLUDE (SerialNo, PartNo, Location, ParentSerialNo);
    PRINT 'Created: IX_PartTransaction_ProgramID_ToLocation_CreateDate';
END
GO

-- 5. PartLocation: For warehouse filter (LocationNo + ProgramID + Warehouse)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PartLocation_LocationNo_ProgramID_Warehouse')
BEGIN
    CREATE INDEX IX_PartLocation_LocationNo_ProgramID_Warehouse
    ON Plus.pls.PartLocation (LocationNo, ProgramID, Warehouse)
    INCLUDE (ID);
    PRINT 'Created: IX_PartLocation_LocationNo_ProgramID_Warehouse';
END
GO

-- 6. PartSerialAttribute: For Family/LOB lookups (already optimized with AttributeID hardcoded)
-- This should already exist, but verify:
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PartSerialAttribute_PartSerialID_AttributeID_CreateDate')
BEGIN
    CREATE INDEX IX_PartSerialAttribute_PartSerialID_AttributeID_CreateDate
    ON Plus.pls.PartSerialAttribute (PartSerialID, AttributeID, CreateDate DESC, ID DESC)
    INCLUDE (Value);
    PRINT 'Created: IX_PartSerialAttribute_PartSerialID_AttributeID_CreateDate';
END
GO

-- 7. CodeGenericTable: For TEARDOWN_DEMANDLIST lookup (GenericTableDefinitionID + C01)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CodeGenericTable_GenericTableDefinitionID_C01_LastActivityDate')
BEGIN
    CREATE INDEX IX_CodeGenericTable_GenericTableDefinitionID_C01_LastActivityDate
    ON Plus.pls.CodeGenericTable (GenericTableDefinitionID, C01, LastActivityDate DESC, ID DESC)
    INCLUDE (C07, C08);
    PRINT 'Created: IX_CodeGenericTable_GenericTableDefinitionID_C01_LastActivityDate';
END
GO

-- 8. PartSerial: For SerialNo lookups (ProgramID + SerialNo + PartNo)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PartSerial_ProgramID_SerialNo_PartNo')
BEGIN
    CREATE INDEX IX_PartSerial_ProgramID_SerialNo_PartNo
    ON Plus.pls.PartSerial (ProgramID, SerialNo, PartNo)
    INCLUDE (ID, ParentSerialNo);
    PRINT 'Created: IX_PartSerial_ProgramID_SerialNo_PartNo';
END
GO

PRINT '============================================';
PRINT 'Index creation complete.';
PRINT 'Review index usage with:';
PRINT '  SELECT * FROM sys.dm_db_index_usage_stats WHERE database_id = DB_ID()';
PRINT '============================================';
