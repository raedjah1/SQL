-- ============================================
-- TEST: Generate ZPL Label with Test Data
-- ============================================
-- Test Record:
-- Serial No: 2503CYD002490
-- Part No: OC845
-- Reception Date: 2025-12-15
-- Warranty Status: In_Warranty (IW)
-- Vendor: SERCOMM CORP
-- ============================================

DECLARE @SerialNo VARCHAR(50) = '2503CYD002490'
DECLARE @PartNo VARCHAR(100) = 'OC845'
DECLARE @DateCode VARCHAR(10) = ''  -- Date code not provided, using empty
DECLARE @ReceiveDate VARCHAR(100) = '12/15/2025'
DECLARE @IsInWarranty BIT = 1
DECLARE @Vendor VARCHAR(100) = 'SERCOMM CORP'
DECLARE @labelCode VARCHAR(MAX) = ''

-- Build ZPL code
SET @labelCode = ''
DECLARE @LabelLength VARCHAR(10) = '0380'  -- Using 380 since vendor will be shown

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

-- Add Vendor line since In Warranty
IF (@IsInWarranty = 1 AND @Vendor IS NOT NULL AND LEN(@Vendor) > 0)
BEGIN
    SET @labelCode = CONCAT(
        @labelCode,
        '^FO450,220^A0,30^FDVendor:^FS',
        '^FO680,220^A0,30^FD', @Vendor, '^FS'
    )
END

-- Close ZPL
SET @labelCode = CONCAT(@labelCode, '^XZ')

-- Output the ZPL code
SELECT @labelCode AS ZPL_Code

