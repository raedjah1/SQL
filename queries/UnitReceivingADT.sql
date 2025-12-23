ID	Name	InputFields	PersistantFields	PopulateDropDown	ClientSideValidation	ServerSideValidation	AttributesQuery	ExecuteQuery	Info	SummaryInfo	Reports	ImportantMessage	DropdownUpdate	EditValidation	ListReport	ListReportLinkAction	RowLimit	LabelID	UserID	CreateDate	LastActivityDate
749	Unit Receiving ADT	C01^_TRACKING_NO^^C02^_R_M_A^^C03^_FLAGGED_BOXES^^C04^_TECH_ID^^C05^_PART_NO^^C06^_QTY/SERIAL^^C07^_MAC^^C08^_I_M_E_I^^C09^_BATTERY_REMOVAL^^C10^_DATE_CODE^^C11^_DOCK_LOG_ID^^C12^_DISPOSITION^^C13^_SERIAL_NUMBER_NOT_AVAILABLE	--!PF:C01^^C02^^C03^^C11
	--!TXTVALUE:C02^_--@BEGIN DECLARE @TrackingNo VARCHAR(100) = @v_C01 IF EXISTS(SELECT 1 FROM [pls].[CarrierResult] cr WHERE cr.ProgramID = @v_ProgramID AND (cr.TrackingNo = @TrackingNo OR cr.ChildTrackingNumber = @TrackingNo)) BEGIN SELECT cr.CustomerReference FROM [pls].[CarrierResult] cr WHERE cr.ProgramID = @v_ProgramID AND (cr.TrackingNo = @TrackingNo OR cr.ChildTrackingNumber = @TrackingNo) END ELSE BEGIN IF (LEN(@TrackingNo) = 34) BEGIN SET @TrackingNo = RIGHT(@TrackingNo,12) IF EXISTS(SELECT cr.CustomerReference FROM [pls].[CarrierResult] cr WHERE cr.ProgramID = @v_ProgramID AND cr.Carrier = 'FEDEX' AND (cr.TrackingNo = @TrackingNo OR cr.ChildTrackingNumber = @TrackingNo)) BEGIN SELECT cr.CustomerReference FROM [pls].[CarrierResult] cr WHERE cr.ProgramID = @v_ProgramID AND cr.Carrier = 'FEDEX' AND (cr.TrackingNo = @TrackingNo OR cr.ChildTrackingNumber = @TrackingNo) END ELSE SELECT 'Invalid TrackingNo' END ELSE SELECT 'Invalid TrackingNo' END END^^C01
--!DDLOV:C03^_NO,YES
--!DDLVALUE:C03^_--@BEGIN DECLARE @FlaggedBoxes VARCHAR(100) SELECT @FlaggedBoxes = roha.[Value] FROM pls.ROHeader roh INNER JOIN pls.CodeAttribute ca ON ca.AttributeName = 'FLAGGED_BOXES' INNER JOIN pls.ROHeaderAttribute roha ON roha.ROHeaderID = roh.ID AND roha.AttributeID = ca.ID WHERE roh.ProgramID = @v_programid AND roh.CustomerReference = @v_C02 IF (@FlaggedBoxes IS NOT NULL AND LEN(@FlaggedBoxes) > 0) SELECT @FlaggedBoxes END^^C02
--!DDLOV:C09^_--@Select cgt.C01, cgt.C01 FROM pls.CodeGenericTable cgt INNER JOIN pls.CodeStatus cs ON cs.[Description] = 'ACTIVE' INNER JOIN pls.CodeGenericTableDefinition cgtd ON cgtd.ID = cgt.GenericTableDefinitionID AND cgtd.ProgramID = @v_programID AND cgtd.[Name] = 'BATTERY REMOVAL' AND cgtd.StatusID = cs.ID WHERE cgt.StatusID = cs.ID ORDER BY cgt.C01
--!TXTVALUE:C11^_--@BEGIN DECLARE @ProgramID SMALLINT = @v_programID, @TrackingNo VARCHAR(100) = @v_C01, @CustomerReference VARCHAR(100) = @v_C02 IF (@TrackingNo <> 'Invalid TrackingNo') BEGIN SELECT TOP 1 rodl.ID FROM pls.RODockLog rodl INNER JOIN pls.ROHeader roh ON roh.ProgramID = @ProgramID AND roh.CustomerReference = @CustomerReference WHERE rodl.ProgramID = @ProgramID AND rodl.TrackingNo = @TrackingNo AND rodl.ROHeaderID = roh.ID END END^^C02
--!TXTVALUE:C12^_--@BEGIN DECLARE @ProgramID SMALLINT = @v_programID, @PartNo VARCHAR(100) = @v_C05 SELECT TOP 1 pna.[Value] FROM pls.PartNoAttribute pna INNER JOIN pls.CodeAttribute ca ON ca.AttributeName = 'DISPOSITION' WHERE pna.ProgramID = @ProgramID AND pna.PartNo = @PartNo AND pna.AttributeID = ca.ID END^^C05	--!CV:C01^_^(?!\s*$).+^_TRACKING_NO cannot be empty.
--!CV:C03^_^(?!\s*$).+^_FLAGGED_BOXES cannot be empty.
--!CV:C04^_^([0-9]{3}[A-Z-a-z]{2}[0-9]{3})$^_TECH_ID is not in correct format.
--!CV:C05^_^(?!\s*$).+^_PART_NO cannot be empty.
--!CV:C09^_^(?!\s*$).+^_BATTERY_REMOVAL cannot be empty.
--!CV:C11^_^(?!\s*$).+^_DOCK_LOG_ID cannot be empty.
--!CV:C12^_^(?!\s*$).+^_DISPOSITION cannot be empty. Part number not in program or missing disposition attribute.	SET NOCOUNT ON;
BEGIN
    /*-------Test data--------------------
    --C01^_TRACKING_NO^^C02^_R_M_A^^C03^_FLAGGED_BOXES^^C04^_TECH_ID^^C05^_PART_NO^^C06^_QTY/SERIAL^^C07^_MAC^^C08^_I_M_E_I^^C09^_BATTERY_REMOVAL^^C10^_DATE_CODE^^C11^_DOCK_LOG_ID^^C12^_DISPOSITION
    DECLARE
    @v_Result   	VARCHAR(2000),
    @pstr       	VARCHAR(2000),
    @v_ProgramID  	SMALLINT = 10068,
    @v_C01      	VARCHAR(100) = '1001891724060003811800795797903483',
    @v_C02      	VARCHAR(20),
    @v_C03      	VARCHAR(20) = 'NO',
    @v_C04      	VARCHAR(20) = '7878',
    @v_C05      	VARCHAR(20) = 'SKF5R0-29-CW',    
    @v_C06      	VARCHAR(20),
    @v_C07      	VARCHAR(20),
	@v_C08      	VARCHAR(20),
    @v_C09      	VARCHAR(20),
    @v_C10      	VARCHAR(20),
    @v_C11          VARCHAR(100)
    -------------------------------------*/

    DECLARE @v_error        VARCHAR(200),
            @UserID         INT,
            @n              INT,
            @scriptid       INT,
            @Attributes     utl.KeyValueType,
			@ProgramID		SMALLINT = @v_ProgramID
    DECLARE @TechID			VARCHAR(100),
			@TrackingNo		VARCHAR(100),
			@PartNo			VARCHAR(100),
			@QtySerial		VARCHAR(100),
			@MAC			VARCHAR(100),
			@IMEI			VARCHAR(100),
			@BatteryRemoval	VARCHAR(5),
			@FlaggedBoxes	VARCHAR(5),
			@DateCode		VARCHAR(100),
            @CustomerReference VARCHAR(100),
            @WarrantyIdentifier VARCHAR(100),
			@Disposition		VARCHAR(100),
			@Wipe               VARCHAR(10)

    SET @TrackingNo     =  @v_C01
    SET @CustomerReference  =  @v_C02
    SET @FlaggedBoxes	=  @v_C03
    SET @TechID      	=  @v_C04
    SET @PartNo       	=  @v_C05
    SET @QtySerial      =  @v_C06
    SET @MAC          	=  @v_C07
    SET @IMEI        	=  @v_C08
    SET @BatteryRemoval =  @v_C09
    SET @DateCode       =  @v_C10
	SET @Disposition	=  @v_C12

    --Validate TrackingNo
    BEGIN
        IF NOT EXISTS(SELECT 1
        FROM [pls].[CarrierResult] cr
        WHERE cr.ProgramID = @ProgramID AND (cr.TrackingNo = @TrackingNo OR cr.ChildTrackingNumber = @TrackingNo)
		)
		BEGIN
            SET @TrackingNo = RIGHT(@TrackingNo, 12)
            IF NOT EXISTS(SELECT 1
            FROM [pls].[CarrierResult] cr
            WHERE cr.ProgramID = @ProgramID AND cr.Carrier = 'FEDEX' AND (cr.TrackingNo = @TrackingNo OR cr.ChildTrackingNumber = @TrackingNo)
            )
            BEGIN
                SET @v_error = 'Invalid TrackingNo'
                GOTO error
            END
        END
    END

    --Validate PartNo
    BEGIN
        IF NOT EXISTS(SELECT 1
        FROM pls.PartNo pn
        WHERE pn.PartNo = @PartNo)
		BEGIN
            SET @v_error = 'Invalid PartNo'
            GOTO error
        END
    END

    --Validate WIPE Attribute
    IF (@v_C12 IN ('Wipe and Hold','Wipe and Scrap')) 
    BEGIN
        IF (@v_Attributes IS NOT NULL AND LEN(@v_Attributes) > 0)
        BEGIN
            IF (ISNULL((SELECT COUNT(*)
            FROM OPENJSON(@v_attributes,'$')),0) > 0)
            BEGIN
                SET @Wipe = JSON_VALUE(@v_attributes,'$[0].Value')
                IF (@wipe IS NULL OR LEN(@Wipe) = 0)
                BEGIN
                    SET @v_error = 'Wipe Complete attribute cannot be empty'
                    GOTO error
                END
            END
            ELSE
            BEGIN
                SET @v_error = 'Wipe Complete attribute cannot be empty'
                GOTO error
            END
        END
        ELSE
        BEGIN
            SET @v_error = 'Wipe Complete attribute cannot be empty'
            GOTO error
        END
    END
	
    --Validate SerialNo
    IF ((SELECT pn.SerialFlag
    FROM pls.PartNo pn
    WHERE PartNo = @PartNo) = 1)
	BEGIN
        IF (@QtySerial IS NOT NULL AND LEN(@QtySerial) > 0)
        BEGIN
            --Validate the Serial length
            IF ( LEN(@QtySerial) <= 5 )
		    BEGIN
                SET @v_error = 'Invalid Serial number length, it must be 5 character length as minimum.'
                GOTO error
            END

            --Validate if the Serial number entered is non alphanumeric
            IF ( ( SELECT PATINDEX('%[^0-9A-Z]%', @QtySerial) ) > 0 )
		    BEGIN
                SET @v_error = 'Invalid Serial Number entered ( special characters and or spaces found ), only alphanumeric values are allowed.'
                GOTO error
            END

            --Validate if Serial NO entered exist in Invenotry
            IF EXISTS(SELECT 1
            FROM pls.PartSerial ps
                LEFT JOIN pls.PartTransaction pt
                ON pt.ProgramID = ps.ProgramID AND pt.PartNo = ps.PartNo AND pt.SerialNo = ps.SerialNo
                    AND ps.StatusID = 14 /*CONSUMED*/ AND pt.PartTransactionID = 35
            /*WO-CONSUMECOMPONENTS*/
            WHERE ps.ProgramID = @ProgramId
                --AND ps.PartNo = @PART_NUMBER 
                AND ps.SerialNo = @QtySerial
                AND ps.StatusID NOT IN (8, 18, 32) /*UNRECEIVED, SHIPPED, REID*/
                AND pt.ID IS NULL)
		    BEGIN
                SET @v_error = CONCAT('The Serial Number ', @QtySerial, ' is already in Inventory')
                GOTO error
            END
        END
    END
	ELSE
	BEGIN
        IF (@QtySerial IS NULL AND LEN(@QtySerial) = 0)
        BEGIN
            SET @v_error = 'Quantity cannot be null'
            GOTO error
        END

        IF (ISNUMERIC(@QtySerial) = 0)
		BEGIN
            SET @v_error = 'Invalid Quantity'
            GOTO error
        END
		
		IF (@QtySerial > 1)
        BEGIN
            SET @v_error = 'Invalid Quantity, is different from 1'
            GOTO error
        END
    END

    --Validating Warranty fields
    BEGIN
	  IF (@Disposition NOT LIKE '%WIPE%')
	  BEGIN
		  IF NOT EXISTS(SELECT 1
		  FROM pls.PartNoAttribute pna INNER JOIN pls.CodeAttribute ca ON ca.AttributeName = 'WARRANTY_IDENTIFIER'
		  WHERE pna.ProgramID = @ProgramID AND pna.PartNo = @PartNo AND pna.AttributeID = ca.ID)
		  BEGIN
			  SET @v_error = CONCAT('Attribute WARRANTY_IDENTIFIER was not found for partNo: ', @PartNo)
			  GOTO error
		  END
		  
		    SET @WarrantyIdentifier = (SELECT pna.[Value]
            FROM pls.PartNoAttribute pna INNER JOIN pls.CodeAttribute ca ON ca.AttributeName = 'WARRANTY_IDENTIFIER'
            WHERE pna.ProgramID = @ProgramID AND pna.PartNo = @PartNo AND pna.AttributeID = ca.ID)

            IF (@WarrantyIdentifier <> 'None')
			BEGIN
                IF (@WarrantyIdentifier LIKE 'Date Code%')
				BEGIN
                    IF (@DateCode IS NULL OR LEN(@DateCode) = 0)
                    BEGIN
                        SET @v_error = 'WARRANTY_IDENTIFIER Date Code cannot be null'
                        GOTO error
                    END
                END
				ELSE
				IF (@WarrantyIdentifier LIKE 'MAC%')
				BEGIN
                    IF (@MAC IS NULL OR LEN(@MAC) = 0)
                    BEGIN
                        SET @v_error = 'WARRANTY_IDENTIFIER MAC cannot be null'
                        GOTO error
                    END
                END
			    ELSE IF (@WarrantyIdentifier LIKE 'IMEI%')
				BEGIN
                    IF (@IMEI IS NULL OR LEN(@IMEI) = 0)
                    BEGIN
                        SET @v_error = 'WARRANTY_IDENTIFIER IMEI cannot be null'
                        GOTO error
                    END
                END
            END

		  IF NOT EXISTS(SELECT 1
		  FROM pls.PartNoAttribute pna INNER JOIN pls.CodeAttribute ca ON ca.AttributeName = 'SUPPLIER_NO'
		  WHERE pna.ProgramID = @ProgramID AND pna.PartNo = @PartNo AND pna.AttributeID = ca.ID)
		  BEGIN
			  SET @v_error = CONCAT('Attribute SUPPLIER_NO was not found for partNo: ', @PartNo)
			  GOTO error
		  END

		  IF NOT EXISTS(SELECT 1
		  FROM pls.PartNoAttribute pna INNER JO	--C12
BEGIN
    DECLARE @CustomerType INT

    SET @CustomerType = (SELECT COUNT(1)
    FROM pls.ROHeader roh
        INNER JOIN pls.CodeAttribute ca ON ca.AttributeName IN ('CustomerType', 'ReturnType')
        INNER JOIN pls.ROHeaderAttribute roha ON roha.ROHeaderID = roh.ID AND roha.AttributeID = ca.ID
    WHERE roh.ProgramID = @v_programID AND roh.CustomerReference = @v_C02 AND roha.[Value] IN ('DIY', 'DIFM'))

    BEGIN
            SELECT 'Wipe Complete' as AttributeName, '' DefaultValue, ISNULL((SELECT b.value
                FROM ( SELECT value
                    FROM string_split('YES,NO',',')) b
                FOR JSON PATH), '[]') as DataSource
            WHERE @v_C12 IN ('Wipe and Hold','Wipe and Scrap')
        UNION ALL
            SELECT 'New' as AttributeName, '' DefaultValue, ISNULL((SELECT b.value
                FROM ( SELECT value
                    FROM string_split('YES,NO',',')) b
                FOR JSON PATH), '[]') as DataSource
            WHERE @CustomerType > 0
    END
END	-- Unit Receiving ADT
---------------------------------------
-- Developer   : Sandra Chacon
-- Create Date : 06/03/2025
-- Name        : Unit Receiving ADT
-- Description : Unit Receiving ADT
-- Contract    : ADT
-- Purpose     : #254429 Unit Receiving ADT
-- Modification History
-- Description : Sandra Chacon. Shorten Tracking number - FEDEX TrackingNo is 34 digits plus only recognize the last 12.
-- Description : Feature #255939 - Sandra Chacon - SerialNo format for serialno null
-- Description : Feature #256039 - Sandra Chacon - Getting DockLogID from screen (populateDropdown logic)
-- Description : Feature #256061 - Sandra Chacon - Adding logic for warranty status
-- Description : Feature #256460 - 7/15/2025 - Sandra Chacon - Warranty logic update
-- Description : Feature #256441 - 7/15/2025 - Sandra Chacon - Adding Google Wipe Logic, save WIPE attribute
-- Description : Feature #257171 - 9/10/2025 - Snadra Chacon - Creating WorkOrder based on partno attribute ETest
-- Description : Feature #257591 - 9/17/2025 by Sandra Chacon - Warranty Logic - for Non SN parts
-- Description : Feature #257580 - 9/17/2025 by Sandra Chacon - Save all the attributes in RO Unit table
-- Description : Feature CR-294 - 10/30/2025 by Sandra Chacon - Adding new locations based on ROHeaderAttributes and new field.
-- Description : Feature PADT-60 - 11/21/2025 by Sandra Chacon - Change from CustomerType to ReturnType
-- Description : ExecuteQuery region - 12/15/2025 by Raymundo Mariscal - Handle Transaction for StoredProcedures execution
---------------------------------------
SET NOCOUNT ON;

BEGIN
    --Declare the variables here

    DECLARE   @v_count         	INT
    DECLARE   @v_programid      VARCHAR(10)
    DECLARE   @v_error         	VARCHAR(2000)
    DECLARE   @v_userid         VARCHAR(50)
    DECLARE   @v_scriptid     	VARCHAR(50)
    DECLARE   @n               	INT
    DECLARE   @i               	INT
    DECLARE   @v_id           	INT
    DECLARE   @vAttr	   		VARCHAR(MAX)
    DECLARE   @Attributes		utl.KeyValueType

    /*-----For testing-------------------------
    DECLARE @v_Result VARCHAR(MAX)
    DECLARE @pstr VARCHAR(MAX) = ''
    SET @pstr = utl.fnPackString('programid','10068', @pstr)
    SET @pstr = utl.fnPackString('NUMBER_OF_ROWS_TO_PROCESS','1', @pstr)
    SET @pstr = utl.fnPackString('userid', (select id
    from pls.[User]
    where username = 'sandra.chacon@reconext.com'), @pstr)
    SET @pstr = utl.fnPackString('scriptid',(select id
    from pls.DataEntryScript
    where name = 'Unit Receiving ADT'), @pstr)
    --SET @pstr = utl.fnPackString('PRINTER','', @pstr)
    -----------------------------------------*/

    ---Get parameters values

    SET @v_programid		= utl.fnUnpackString('programid', @pstr);
    SET @n					= utl.fnUnpackString('NUMBER_OF_ROWS_TO_PROCESS', @pstr);
    SET @v_userid		    = utl.fnUnpackString('userid', @pstr);
    SET @v_scriptid			= utl.fnUnpackString('scriptid', @pstr);
    --SET @printer			= utl.fnUnpackString('PRINTER', @pstr);

    DECLARE ris_cursor CURSOR FOR   
		SELECT c.*
    FROM (  
        ----For test--------------------------------------------------------------------------------
        --SELECT '795799879992' AS TrackingNo, 'FSR2505364' AS CustomerReference, 'YES' AS FlaggedBoxes, '111NA111' AS TechID, 'SIXCTA' AS PartNo, 'C1BDVM4006080' AS 'Qty/SerialNo', NULL AS Mac, NULL AS IMEI, 'NO' AS BatteryRemoval, '2523' as DateCode, '103458' AS DockLogID, 'SCRAP' AS Disposition, 123123 AS ID, '' AS Attributes, 1 AS r /*
        --------------------------------------------------------------------------------------------
        SELECT t.c01, t.c02, t.c03, t.c04, t.c05, t.c06, t.c07, t.c08, t.c09, t.c10, t.c11, t.c12, t.ID, t.Attributes, ROW_NUMBER() over(ORDER BY ID) r
        FROM pls.DataEntry t
        WHERE t.StatusID = 0
            AND UPPER(t.DataEntryScriptID) = @v_scriptid
            AND UPPER(t.programid) = @v_programid
            AND UPPER(t.userid) = @v_userid --*/
             ) as c
    WHERE c.r <= @n;

    DECLARE @TechID		    	VARCHAR(100)
    DECLARE @TrackingNo         VARCHAR(100)
    DECLARE @FlaggedBoxes       VARCHAR(5)
    DECLARE @WHS				VARCHAR(100)
    DECLARE @BIN				VARCHAR(100)
    DECLARE @PartNo				VARCHAR(100)
    DECLARE	@QtySerial			VARCHAR(50)
    DECLARE	@Qty				INT
    DECLARE	@SerialNo			VARCHAR(50)
    DECLARE	@ConditionId		INT
    DECLARE	@ConfigurationId	INT
    DECLARE @Serialized			BIT
    DECLARE @UserName		  	VARCHAR(255)
    DECLARE	@LocationId			INT
    DECLARE @Location			VARCHAR(100)
    DECLARE @MAC                VARCHAR(100)
    DECLARE @IMEI               VARCHAR(100)
    DECLARE @BatteryRemoval	    VARCHAR(5)
    DECLARE @DateCode           VARCHAR(100)
    DECLARE @Disposition        VARCHAR(100)

    DECLARE @ROHeaderID         INT
    DECLARE @CustomerReference  VARCHAR(100)
    DECLARE @ROLineID           INT
    DECLARE @RODockLogId        INT
    DECLARE @QtyToReceive       INT
    DECLARE @Configuration      VARCHAR(10)
    DECLARE @Condition          VARCHAR(10)
    DECLARE @QtyReceived        INT
    DECLARE @StatusDescription  VARCHAR(100)
    DECLARE @ROUnitID           INT
    DECLARE @QtyUnits           INT
    DECLARE @PreAlert           BIT
    DECLARE @ParentSerialNo     VARCHAR(100)
    DECLARE @CarrierName        VARCHAR(100)
    DECLARE @WarrantyIdentifier VARCHAR(100)
    DECLARE @SupplierNo         VARCHAR(100),
            @WarrantyTerm       VARCHAR(100),
            @WarrantyStatus     VARCHAR(100),
            @WarrantyIdValue    VARCHAR(100),
            @WarrantyRule       VARCHAR(100),
            @StartIndex         INT,
            @EndIndex           INT,
			@Year               VARCHAR(1),
            @YY                 INT,
            @WW                 INT,
            @WarrantyDate       DATE = utl.fnGetProgramDateTime(@v_programid),
            @Wipe               VARCHAR(10)

    DECLARE @PartSerialID       INT
    DECLARE @pstr2              VARCHAR(MAX)
    DECLARE @AttributeID        SMALLINT
    DECLARE @AttributeName      VARCHAR(100)
    DECLARE @AttributeValue     VARCHAR(100)

    DECLARE @Source             VARCHAR(100) = 'DataEntry - Unit Receiving ADT',
            @RepairType         VARCHAR(100),
            @WOHeaderID         INT

    DECLARE @CustomerType       VARCHAR(100)
    DECLARE @ProductStatus      VARCHAR(100)
    DECLARE @ReturnType         VARCHAR(100)
    DECLARE @Branch             VARCHAR(100)
    DECLARE @PSNew              VARCHAR(100)
    DECLARE @AttCount           INT
	DECLARE @QtyROUnit          INT

    DECLARE @rohapstr VARCHAR(4000) 
    DECLARE @spResult VARCHAR(2000) 

    SET @UserName = (SELECT username
    from pls.[User]
    where id = @v_userid )

    OPEN ris_cursor
    FETCH NEXT FROM ris_cursor INTO @TrackingNo, @CustomerReference, @FlaggedBoxes, @TechID, @PartNo, @QtySerial, @MAC, @IMEI, @BatteryRemoval, @DateCode, @RODockLogId, @Disposition, @v_id, @vAttr, @i ;

    WHILE @@FETCH_STATUS = 0 
	BEGIN
        BEGIN TRY

            IF (LEN(@TrackingNo) = 34)
                SET @TrackingNo = RIGHT(@TrackingNo,12)

				SET @v_error = NULL;
				DELETE FROM @Attributes

        --Get Serialized Flag
			SET @Serialized = ( SELECT SerialFlag
        FROM pls.PartNo
        WHERE PartNo = @PartNo)

        --Warranty Validation
        BEGIN
            --Get WarrantyStatus
            SET @WarrantyStatus = NULL

            BEGIN TRY
    	BEGIN
                IF (@Disposition NOT LIKE '%WIPE%')
		  BEGIN
                    IF EXISTS(SELECT 1
                    FROM pls.PartNoAttribute pna INNER JOIN pls.CodeAttribute ca ON ca.AttributeName = 'WARRANTY_IDENTIFIER'
                    WHERE pna.ProgramID = @v_programid AND pna.PartNo = @PartNo AND pna.AttributeID = ca.ID)
			  BEGIN
           					C09				1	NULL	370	2025-06-04 13:49:00.000000	2025-12-18 17:19:00.000000