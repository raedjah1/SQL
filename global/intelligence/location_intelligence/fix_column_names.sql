-- ============================================
-- FIX COLUMN NAMES - FIND CORRECT DATE COLUMNS
-- ============================================
-- 
-- The CREATE_DATE column doesn't exist, let's find the right column names

-- STEP 1: Find all columns in the shop_ord_tab table
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ifsapp'
  AND TABLE_NAME = 'shop_ord_tab'
ORDER BY ORDINAL_POSITION;

-- STEP 2: Look for date-related columns specifically
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ifsapp'
  AND TABLE_NAME = 'shop_ord_tab'
  AND (COLUMN_NAME LIKE '%date%' 
       OR COLUMN_NAME LIKE '%time%'
       OR DATA_TYPE LIKE '%date%')
ORDER BY COLUMN_NAME;

-- STEP 3: Get sample data to see what columns actually contain
SELECT TOP 5 *
FROM ifsapp.shop_ord_tab
WHERE region IS NOT NULL
ORDER BY region;
