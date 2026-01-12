-- ============================================
-- UNIT RECEIVING ADT ZPL LABEL CONFIGURATION
-- ============================================
-- Source: pls.DataDocumentConfiguration
-- ID: 1806
-- ProgramID: 10068
-- PageName: DataEntry
-- Type: ZPLLabel
-- ============================================

-- Configuration Details:
-- ID: 1806
-- ProgramID: 10068
-- PageName: DataEntry
-- Type: ZPLLabel
-- InputFields: C05^_PART_NO^^C06^_QTY/SERIAL^^C10^_DATE_CODE
-- AutoPrint: 0
-- StatusID: 4
-- FileName: (empty)
-- FilePath: (empty)

-- ============================================
-- ZPL LABEL SCRIPT (ReportQuery)
-- ============================================
-- Create ReceiptLabel
-- -------------------------------------
-- Developer   : Sandra Chacon
-- Create Date : 06/17/2025
-- Name        : Receive Order
-- Description : Receive Order
-- Contract    : Any Contract
-- Purpose     : Create Unit Receiving Label
-- ---------------------------------------

SET NOCOUNT ON;

BEGIN
    --Declare the variables here
    
    /*------For Test----------------------
    DECLARE @v_ProgramID SMALLINT = 10068,
            @v_Result VARCHAR(MAX),
            @v_C05 VARCHAR(100) = '5816WMWH',
            @v_C06 VARCHAR(100) = '1903BV5000615',
            @v_C10 VARCHAR(10) = '1231',
            @v_UserID SMALLINT = (SELECT ID FROM pls.[User] WHERE UserName = 'sandra.chacon')
    ------------------------------------*/
    
    DECLARE @v_error            VARCHAR(MAX)
    DECLARE @labelCode          VARCHAR(MAX) = ''
    DECLARE @PartNo             VARCHAR(100)
    DECLARE @SerialNo           VARCHAR(50)
    DECLARE @PartSerialID       INT
    DECLARE @PartLocation       VARCHAR(100)
    DECLARE @ReceiveDate        VARCHAR(100)
    DECLARE @DateTime           DATETIME = utl.fnGetProgramDateTime(@v_programid)
    DECLARE @DateCode           VARCHAR(10)
    DECLARE @WarrantyStatus     VARCHAR(100)
    DECLARE @Vendor             VARCHAR(100)
    DECLARE @IsInWarranty       BIT = 0
    DECLARE @Disposition        VARCHAR(100)
    DECLARE @DispositionDisplay VARCHAR(100)
    
    SET @PartNo = @v_C05
    SET @SerialNo = @v_C06
    SET @DateCode = @v_C10
    
    SET @ReceiveDate = FORMAT(@DateTime,'MM/dd/yyyy')
    
    -- Get PartSerialID and Location
    IF (@SerialNo IS NULL OR LEN(@SerialNo) = 0)
    BEGIN
        SELECT TOP (1)
            @PartSerialID = pt.ID, 
            @PartLocation = pt.ToLocation, 
            @SerialNo = pt.SerialNo
        FROM [Plus].[pls].[PartTransaction] pt 
        INNER JOIN pls.CodePartTransaction cpt ON cpt.[Description] = 'RO-RECEIVE'
        WHERE pt.ProgramID = @v_ProgramID 
            AND pt.PartTransactionID = cpt.ID 
            AND pt.PartNo = @PartNo 
            AND pt.UserID = @v_UserID 
            AND pt.Source = 'DataEntry - Unit Receiving ADT' 
            AND pt.CreateDate > @ReceiveDate
        ORDER BY pt.ID DESC
    END
    ELSE
    BEGIN
        SELECT TOP 1
            @PartSerialID = ps.ID, 
            @PartLocation = pl.LocationNo
        FROM pls.PartSerial ps 
        INNER JOIN pls.PartLocation pl ON pl.ID = ps.LocationID
        WHERE ps.ProgramID = @v_ProgramID 
            AND ps.PartNo = @PartNo 
            AND ps.SerialNo = @SerialNo
        ORDER BY ps.ID DESC
    END
    
    -- Validate PartSerialID exists
    IF (@PartSerialID IS NULL OR LEN(@PartSerialID) = 0)
    BEGIN
        SET @v_error = 'SerialNo not found'
        GOTO error
    END
    
    -- ============================================
    -- ADDED: Warranty Status and Vendor Logic
    -- Date: 2025-12-26
    -- Purpose: Display Vendor on label when part is In Warranty (IW)
    -- IMPORTANT: This runs AFTER ExecuteQuery processes the receipt and saves
    --            WARRANTY_STATUS to PartSerialAttribute or ROUnitAttribute
    -- ============================================
    
    -- Get Warranty Status from PartSerialAttribute (PRIMARY SOURCE)
    -- This is where ExecuteQuery saves it after warranty calculation
    SELECT TOP 1
        @WarrantyStatus = psa.Value
    FROM pls.PartSerialAttribute psa
    INNER JOIN pls.CodeAttribute ca ON ca.ID = psa.AttributeID
    WHERE psa.PartSerialID = @PartSerialID
        AND ca.AttributeName = 'WARRANTY_STATUS'
    ORDER BY psa.LastActivityDate DESC
    
    -- FALLBACK: If not found in PartSerialAttribute, try ROUnitAttribute
    -- This is where ExecuteQuery may save it for non-serialized parts
    IF (@WarrantyStatus IS NULL)
    BEGIN
        SELECT TOP 1
            @WarrantyStatus = rua.Value
        FROM pls.PartSerial ps
        INNER JOIN pls.ROLine rl ON rl.ROHeaderID = ps.ROHeaderID AND rl.PartNo = ps.PartNo
        INNER JOIN pls.ROUnit ru ON ru.ROLineID = rl.ID AND ru.SerialNo = ps.SerialNo
        INNER JOIN pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID
        INNER JOIN pls.CodeAttribute ca ON ca.ID = rua.AttributeID
        WHERE ps.ID = @PartSerialID
            AND ca.AttributeName = 'WARRANTY_STATUS'
        ORDER BY rua.LastActivityDate DESC
    END
    
    -- ADDED: Check if In Warranty (IW) and get Vendor
    -- Logic: If Warranty Status = IW/IN WARRANTY/IN_WARRANTY, display Vendor on label
    -- Condition: Warranty Status must be "IW", "IN WARRANTY", or "IN_WARRANTY"
    IF (@WarrantyStatus IS NOT NULL)
    BEGIN
        SET @WarrantyStatus = UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@WarrantyStatus, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' '))))
        IF (@WarrantyStatus IN ('IN WARRANTY', 'IW', 'IN_WARRANTY'))
        BEGIN
            SET @IsInWarranty = 1
            
            -- ADDED: Get Vendor/Supplier from PartNoAttribute for IW parts
            -- Source: PartNoAttribute where AttributeName = 'SUPPLIER_NO'
            SELECT TOP 1
                @Vendor = pna.Value
            FROM pls.PartNoAttribute pna
            INNER JOIN pls.CodeAttribute ca ON ca.ID = pna.AttributeID
            WHERE pna.ProgramID = @v_ProgramID
                AND pna.PartNo = @PartNo
                AND ca.AttributeName = 'SUPPLIER_NO'
            ORDER BY pna.LastActivityDate DESC
        END
    END
    
    -- ============================================
    -- ADDED: Disposition Display Logic
    -- Date: 2025-12-26
    -- Purpose: Display Disposition (CR PROGRAM or HLD) on label
    -- IMPORTANT: This runs AFTER ExecuteQuery processes the receipt and saves
    --            DISPOSITION to PartSerialAttribute or ROUnitAttribute
    -- Note: Disposition takes precedence over Vendor - only one will show
    -- ============================================
    
    -- Get Disposition from PartSerialAttribute (PRIMARY SOURCE - Priority 1)
    -- This is where ExecuteQuery saves it after processing
    SELECT TOP 1
        @Disposition = psa.Value
    FROM pls.PartSerialAttribute psa
    INNER JOIN pls.CodeAttribute ca ON ca.ID = psa.AttributeID
    WHERE psa.PartSerialID = @PartSerialID
        AND ca.AttributeName = 'DISPOSITION'
    ORDER BY psa.LastActivityDate DESC
    
    -- FALLBACK 1: If not found in PartSerialAttribute, try ROUnitAttribute (Priority 2)
    -- This is where ExecuteQuery may save it for non-serialized parts
    IF (@Disposition IS NULL)
    BEGIN
        SELECT TOP 1
            @Disposition = rua.Value
        FROM pls.PartSerial ps
        INNER JOIN pls.ROLine rl ON rl.ROHeaderID = ps.ROHeaderID AND rl.PartNo = ps.PartNo
        INNER JOIN pls.ROUnit ru ON ru.ROLineID = rl.ID AND ru.SerialNo = ps.SerialNo
        INNER JOIN pls.ROUnitAttribute rua ON rua.ROUnitID = ru.ID
        INNER JOIN pls.CodeAttribute ca ON ca.ID = rua.AttributeID
        WHERE ps.ID = @PartSerialID
            AND ca.AttributeName = 'DISPOSITION'
        ORDER BY rua.LastActivityDate DESC
    END
    
    -- FALLBACK 2: If still not found, try PartNoAttribute (Priority 3)
    -- This is the default disposition from part master data
    IF (@Disposition IS NULL)
    BEGIN
        SELECT TOP 1
            @Disposition = pna.Value
        FROM pls.PartNoAttribute pna
        INNER JOIN pls.CodeAttribute ca ON ca.ID = pna.AttributeID
        WHERE pna.ProgramID = @v_ProgramID
            AND pna.PartNo = @PartNo
            AND ca.AttributeName = 'DISPOSITION'
        ORDER BY pna.LastActivityDate DESC
    END
    
    -- ADDED: Clean and set Disposition display value
    -- Condition: Disposition must be one of:
    --   "CR PROGRAM" → Display: "CR PROGRAM"
    --   "HOLD" or "WIPE AND HOLD" → Display: "HLD"
    IF (@Disposition IS NOT NULL)
    BEGIN
        SET @Disposition = UPPER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@Disposition, CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' '))))
        
        IF (@Disposition = 'CR PROGRAM')
        BEGIN
            SET @DispositionDisplay = 'CR PROGRAM'
        END
        ELSE IF (@Disposition IN ('HOLD', 'WIPE AND HOLD'))
        BEGIN
            SET @DispositionDisplay = 'HLD'
        END
    END
    
    -- Generate ZPL Label Code (only if not SCRAP location)
    IF (@PartLocation NOT LIKE 'SCRAP%')
    BEGIN
        SET @labelCode = ''
        
        -- ADDED: Calculate label length based on what needs to be shown
        -- Logic: Disposition takes precedence over vendor - only one will show
        -- Base length: 315, With disposition/vendor: 380
        DECLARE @LabelLength VARCHAR(10) = '0315'
        
        -- Increase length if disposition OR vendor (but not both) is shown
        IF (@DispositionDisplay IS NOT NULL AND LEN(@DispositionDisplay) > 0)
        BEGIN
            SET @LabelLength = '0380'  -- Disposition at Y=220
        END
        ELSE IF (@IsInWarranty = 1 AND @Vendor IS NOT NULL AND LEN(@Vendor) > 0)
        BEGIN
            SET @LabelLength = '0380'  -- Vendor at Y=220
        END
        
        -- Build ZPL code
        SET @labelCode = CONCAT(
            '^XA',
            '^LL', @LabelLength,
            '^PW1280',
            '^LH0,0',
            '^FO450,30^BQN,2,3^FDQA,', @SerialNo, '^FS',
            '^FO450,120^A0,25^FD', @SerialNo, '^FS',
            '^FO530,70^A0,30^FDDatecode: ', @DateCode, '^FS',
            '^FO450,170^A0,30^FDReception Date:^FS',
            '^FO680,170^A0,30^FD', @ReceiveDate, '^FS'
        )
        
        -- ============================================
        -- ADDED: Conditional Display Logic
        -- Priority: 1) Disposition (CR PROGRAM/HLD), 2) Vendor (if IW)
        -- Only one will display at Y=220 position
        -- Both check AFTER ExecuteQuery has processed and saved attributes
        -- ============================================
        
        -- ADDED: Add Disposition line (takes precedence over vendor)
        -- Condition: Disposition exists and is "CR PROGRAM" or "HOLD"/"WIPE AND HOLD"
        -- Display: "CR PROGRAM" or "HLD" at Y=220
        IF (@DispositionDisplay IS NOT NULL AND LEN(@DispositionDisplay) > 0)
        BEGIN
            SET @labelCode = CONCAT(
                @labelCode,
                '^FO450,220^A0,30^FD', @DispositionDisplay, '^FS'
            )
        END
        -- ADDED: Add Vendor line only if In Warranty AND no disposition to show
        -- Condition: Warranty Status = IW/IN WARRANTY/IN_WARRANTY AND Vendor exists
        -- Display: "Vendor: [VendorName]" at Y=220
        -- Truncation: Vendor names longer than 35 characters are truncated to 32 chars + "..."
        ELSE IF (@IsInWarranty = 1 AND @Vendor IS NOT NULL AND LEN(@Vendor) > 0)
        BEGIN
            -- ADDED: Truncate vendor name if too long (max 35 characters)
            DECLARE @VendorDisplay VARCHAR(100) = @Vendor
            IF (LEN(@VendorDisplay) > 35)
            BEGIN
                SET @VendorDisplay = LEFT(@VendorDisplay, 32) + '...'
            END
            
            SET @labelCode = CONCAT(
                @labelCode,
                '^FO450,220^A0,30^FDVendor:^FS',
                '^FO580,220^A0,30^FD', @VendorDisplay, '^FS'
            )
        END
        
        -- Close ZPL
        SET @labelCode = CONCAT(@labelCode, '^XZ')
    END
    
    SET @v_Result = @labelCode
    
    error:
    IF (@v_error IS NOT NULL)
        SET @v_Result = @v_error
END
