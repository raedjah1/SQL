SELECT *
FROM(
SELECT 
    sh.CustomerReference,
    sl.ID,
    sl.PartNo,
    sl.QtyToShip,
    sh.CreateDate,
    -- Operator Assignment Info
    u.FirstName + ' ' + u.LastName AS AssignedOperator,
    u.Username AS AssignedOperatorEmail,
    CASE 
        WHEN pl.AssignedToUserID IS NULL THEN 'Unassigned'
        ELSE 'Assigned'
    END AS AssignmentStatus,
    -- ✅ NEW: Order Type field for slicer (using LEFT JOIN instead of EXISTS)
    MAX(
        CASE 
            WHEN sh.CustomerReference LIKE 'GIT%' THEN 'GIT'
            WHEN sha_ordertype.Value = 'OemOrderRequest' THEN 'OemOrderRequest'
            WHEN sha_ordertype.Value = 'OemOrderRequestExg' THEN 'OemOrderRequestExg'
            ELSE 'Other'
        END
    ) AS [Order Type],
    -- New computed ShipByDate per rules
    CAST(
        CASE 
            -- Weekend -> following Monday
            WHEN DATENAME(weekday, sh.CreateDate) = 'Saturday' THEN DATEADD(DAY, 2, CAST(sh.CreateDate AS date))
            WHEN DATENAME(weekday, sh.CreateDate) = 'Sunday'   THEN DATEADD(DAY, 1, CAST(sh.CreateDate AS date))
            -- Friday after 2pm -> following Monday
            WHEN DATENAME(weekday, sh.CreateDate) = 'Friday'
                 AND CAST(sh.CreateDate AS time) >= '14:00'   THEN DATEADD(DAY, 3, CAST(sh.CreateDate AS date))
            -- Mon–Thu after 2pm -> next day
            WHEN DATENAME(weekday, sh.CreateDate) IN ('Monday','Tuesday','Wednesday','Thursday')
                 AND CAST(sh.CreateDate AS time) >= '14:00'   THEN DATEADD(DAY, 1, CAST(sh.CreateDate AS date))
            -- Mon–Fri before 2pm -> same day
            ELSE CAST(sh.CreateDate AS date)
        END AS date) AS SHIPBYDATE,
    -- Ship By Date from Attribute (if provided)
    MAX(CASE WHEN ca_shipbydate.AttributeName = 'SHIPBYDATE' THEN sha_shipbydate.Value END) AS SHIPBYDATE_Attribute,
    sh.AddressID,
    MAX(CASE WHEN cla.AttributeName = 'SERVICETAG' THEN sla.Value END) AS SERVICETAG,
    -- PartLocationNo: Use PartSerial->PartLocation for non-GIT, PartQty->PartLocation for GIT
    COALESCE(
        MAX(CASE WHEN sh.CustomerReference NOT LIKE 'GIT%' THEN loc.LocationNo END),  -- Non-GIT: via PartSerial
        MAX(CASE WHEN sh.CustomerReference LIKE 'GIT%' THEN git_warehouse.LocationNo END)  -- GIT: via PartQty (from OUTER APPLY)
    ) AS PartLocationNo,
    -- Warehouse: Use PartSerial->PartLocation for non-GIT, PartQty->PartLocation for GIT (optimized)
    COALESCE(
        MAX(CASE WHEN sh.CustomerReference NOT LIKE 'GIT%' THEN loc.Warehouse END),  -- Non-GIT: via PartSerial
        MAX(CASE WHEN sh.CustomerReference LIKE 'GIT%' THEN git_warehouse.Warehouse END)  -- GIT: via PartQty (from OUTER APPLY)
    ) AS Warehouse,
    -- ✅ All 5 ship codes, blank for unmapped codes (no ELSE clause)
    MAX(CASE WHEN cha.AttributeName = 'SHIPCODE' THEN 
        CASE sha.Value 
            WHEN '2' THEN 'Standard Overnight'
            WHEN '7' THEN 'Fedex 2 Day'
            WHEN 'E' THEN 'Fedex 2 Day'
            WHEN 'L' THEN 'Fedex Ground'
            WHEN 'O' THEN 'Consolidated Order'
        END 
    END) AS SHIPTYPES,
    -- LOB from PartSerialAttribute
    MAX(psa_lob.Value) AS LOB,
    -- Server indicator (LOB = 'POWER')
    CASE WHEN MAX(psa_lob.Value) = 'POWER' THEN 'Server' ELSE 'Not Server' END AS ServerType,
    -- Sort order for ServerType (1 = Server first, 2 = Not Server)
    CASE WHEN MAX(psa_lob.Value) = 'POWER' THEN 1 ELSE 2 END AS ServerTypeSortOrder,
    -- SLA: 72 business hours from CreateDate to NOW (applies to all orders)
    CASE 
        WHEN (
            -- Calculate business hours excluding weekends
            DATEDIFF(HOUR, sh.CreateDate, GETDATE())
            - (DATEDIFF(WEEK, sh.CreateDate, GETDATE()) * 48)  -- Subtract 48 hours per weekend
            - CASE WHEN DATEPART(WEEKDAY, sh.CreateDate) = 7 THEN DATEDIFF(HOUR, sh.CreateDate, DATEADD(DAY, 1, CAST(sh.CreateDate AS DATE))) ELSE 0 END  -- Subtract Saturday hours at start
            - CASE WHEN DATEPART(WEEKDAY, GETDATE()) = 1 THEN DATEDIFF(HOUR, CAST(GETDATE() AS DATE), GETDATE()) ELSE 0 END  -- Subtract Sunday hours at end
        ) <= 72 THEN 'Compliant'
        ELSE 'Not Compliant'
    END AS SLAStatus,
    -- Business hours from CreateDate to NOW (for reference)
    DATEDIFF(HOUR, sh.CreateDate, GETDATE())
    - (DATEDIFF(WEEK, sh.CreateDate, GETDATE()) * 48)
    - CASE WHEN DATEPART(WEEKDAY, sh.CreateDate) = 7 THEN DATEDIFF(HOUR, sh.CreateDate, DATEADD(DAY, 1, CAST(sh.CreateDate AS DATE))) ELSE 0 END
    - CASE WHEN DATEPART(WEEKDAY, GETDATE()) = 1 THEN DATEDIFF(HOUR, CAST(GETDATE() AS DATE), GETDATE()) ELSE 0 END
    AS BusinessHoursFromCreateToNow
FROM [pls].[SOHeader] sh
JOIN pls.[User] uh ON uh.ID = sh.UserID
JOIN pls.CodeStatus cs ON cs.ID = sh.StatusID
JOIN [pls].[SOHeaderAttribute] sha ON sh.ID = sha.SOHeaderID
JOIN pls.CodeAttribute cha ON cha.ID = sha.AttributeID
-- ✅ NEW: Join to get ORDERTYPE for Order Type field
LEFT JOIN [pls].[SOHeaderAttribute] sha_ordertype ON sh.ID = sha_ordertype.SOHeaderID
LEFT JOIN pls.CodeAttribute ca_ordertype ON ca_ordertype.ID = sha_ordertype.AttributeID AND ca_ordertype.AttributeName = 'ORDERTYPE'
-- ✅ NEW: Join to get SHIPBYDATE attribute
LEFT JOIN [pls].[SOHeaderAttribute] sha_shipbydate ON sh.ID = sha_shipbydate.SOHeaderID
LEFT JOIN pls.CodeAttribute ca_shipbydate ON ca_shipbydate.ID = sha_shipbydate.AttributeID AND ca_shipbydate.AttributeName = 'SHIPBYDATE'
LEFT JOIN [pls].[SOLine] sl ON sh.ID = sl.SOHeaderID
LEFT JOIN [pls].[SOLineAttribute] sla ON sl.ID = sla.SOLineID
LEFT JOIN pls.CodeAttribute cla ON cla.ID = sla.AttributeID AND cla.AttributeName = 'SERVICETAG'
LEFT JOIN [pls].[PartSerial] ps ON ps.SerialNo = sla.Value
LEFT JOIN [pls].[PartLocation] loc ON loc.ID = ps.LocationID
-- ✅ GIT Orders: Warehouse and LocationNo via PartQty->PartLocation (optimized - only for GIT orders)
OUTER APPLY (
    SELECT TOP 1 
        loc_git.Warehouse,
        loc_git.LocationNo
    FROM [pls].[PartQty] pq_git
    INNER JOIN [pls].[PartLocation] loc_git ON loc_git.ID = pq_git.LocationID
    WHERE pq_git.PartNo = sl.PartNo 
      AND pq_git.ProgramID = 10053
      AND sh.CustomerReference LIKE 'GIT%'
    ORDER BY pq_git.AvailableQty DESC, loc_git.Warehouse  -- Prefer locations with inventory
) AS git_warehouse
-- LOB from PartSerialAttribute
LEFT JOIN [pls].[PartSerialAttribute] psa_lob ON psa_lob.PartSerialID = ps.ID
    AND psa_lob.AttributeID = (SELECT ID FROM pls.CodeAttribute WHERE AttributeName = 'TrckObjAttLOB')
-- ✓ OPERATOR ASSIGNMENT JOINS
LEFT JOIN PLUS.pls.SOPickList pl ON pl.SOHeaderID = sh.ID AND pl.SOLineID = sl.ID
LEFT JOIN PLUS.pls.[User] u ON u.ID = pl.AssignedToUserID
WHERE 
    sh.ProgramID = '10053'
    AND cs.Description NOT IN ('CANCELED', 'SHIPPED')
    AND (
        -- ✅ Include GIT orders (ORDERTYPE = 'SHIP')
        sh.CustomerReference LIKE 'GIT%'
        OR
        -- ✅ Include existing OemOrderRequest orders
        EXISTS ( 
            SELECT 1
            FROM [pls].[SOHeaderAttribute] sha_filter
            JOIN pls.CodeAttribute ca ON ca.ID = sha_filter.AttributeID
            WHERE sha_filter.SOHeaderID = sh.ID 
              AND ca.AttributeName = 'ORDERTYPE' 
              AND sha_filter.[Value] IN('OemOrderRequest', 'OemOrderRequestExg') 
        )
    )
GROUP BY 
    sh.CustomerReference, 
    sh.ThirdPartyReference, 
    sh.CreateDate,
    sh.AddressID,
    cs.Description,
    sl.PartNo,
    sl.QtyToShip,
    sl.QtyReserved,
    loc.LocationNo,
    ps.PartNo,
    uh.Username,
    sl.ID,
    loc.Warehouse,
    git_warehouse.Warehouse,  -- Added for GIT warehouse lookup (from OUTER APPLY)
    u.FirstName,  -- ✓ OPERATOR FIELDS
    u.LastName,
    u.Username,
    pl.AssignedToUserID
) d
 
WHERE d.SERVICETAG IS NOT NULL OR d.CustomerReference LIKE 'GIT%'  -- ✅ Allow GIT orders without SERVICETAG