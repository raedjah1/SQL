-- Index recommendations for queries/partserialwithout.sql
-- Purpose: speed up the TOP 1 OUTER APPLY lookups (Family / LOB / StandardCost) and the main filter path.
-- Notes:
-- - Run these in the target database with appropriate permissions.
-- - Always validate in a lower environment first and review with your DBA (write overhead, storage, fragmentation).

/* 1) PartSerialAttribute: supports TOP 1 by (PartSerialID, AttributeID) ordered by (CreateDate DESC, ID DESC) */
CREATE INDEX IX_PartSerialAttribute_PartSerialID_AttributeID_CreateDate_ID
ON Plus.pls.PartSerialAttribute (PartSerialID, AttributeID, CreateDate DESC, ID DESC)
INCLUDE (Value);

/* 2) PartNoAttribute: supports TOP 1 by (ProgramID, PartNo, AttributeID) ordered by (LastActivityDate DESC, ID DESC) */
CREATE INDEX IX_PartNoAttribute_ProgramID_PartNo_AttributeID_LastActivityDate_ID
ON Plus.pls.PartNoAttribute (ProgramID, PartNo, AttributeID, LastActivityDate DESC, ID DESC)
INCLUDE (Value);

/* 3) PartSerial: supports ProgramID filter + joins (UserID/LocationID/StatusID/WorkStationID/ConfigurationID) */
-- Only create if you see scans on PartSerial in the actual plan.
-- CREATE INDEX IX_PartSerial_ProgramID_LocationID
-- ON Plus.pls.PartSerial (ProgramID, LocationID)
-- INCLUDE (UserID, StatusID, WorkStationID, ConfigurationID, PartNo, SerialNo, ParentSerialNo, PalletBoxNo, LotNo, ROHeaderID, RODate, WOHeaderID, WOStartDate, WOEndDate, WOPass, Shippable, SOHeaderID, SODate, CreateDate, LastActivityDate);


