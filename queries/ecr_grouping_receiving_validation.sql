/*
ECR Grouping / Consolidation - Receipt-time validation (Plus)

Goal:
  Block receiving unless ALL tracking numbers for the Group ID are dock-logged.

Storage (Phase 1 - by B2B on Plus ROHeaderAttribute):
  - ECR_GROUP_ID
  - ECR_TRACKING_COUNT           (string value containing an integer)
  - ECR_TRACKING_NUMBERS         (CSV, comma-separated)

This script is designed to be pasted into an ADT/SP "server side validation" section.
You provide @ProgramID and @ReceivingROHeaderID (the RO you're attempting to receive).
*/

SET NOCOUNT ON;

DECLARE @ProgramID SMALLINT = 10068;         -- TODO: wire to @v_ProgramID in ADT/SP
DECLARE @ReceivingROHeaderID INT = NULL;     -- TODO: set to the ROHeaderID being received

/* ------------------------------------------
   Resolve Attribute IDs (once)
------------------------------------------ */
DECLARE
    @Attr_GroupID INT,
    @Attr_TrackingCount INT,
    @Attr_TrackingCsv INT;

SELECT
    @Attr_GroupID       = MAX(CASE WHEN ca.AttributeName = 'ECR_GROUP_ID' THEN ca.ID END),
    @Attr_TrackingCount = MAX(CASE WHEN ca.AttributeName = 'ECR_TRACKING_COUNT' THEN ca.ID END),
    @Attr_TrackingCsv   = MAX(CASE WHEN ca.AttributeName = 'ECR_TRACKING_NUMBERS' THEN ca.ID END)
FROM Plus.pls.CodeAttribute ca
WHERE ca.AttributeName IN ('ECR_GROUP_ID', 'ECR_TRACKING_COUNT', 'ECR_TRACKING_NUMBERS');

IF (@Attr_GroupID IS NULL OR @Attr_TrackingCount IS NULL OR @Attr_TrackingCsv IS NULL)
BEGIN
    -- If the attributes don't exist in CodeAttribute yet, you can't validate.
    -- Decide whether to fail closed or fail open. Defaulting to fail open here.
    -- RAISERROR('ECR grouping attributes are not configured in CodeAttribute.', 16, 1);
    RETURN;
END

/* ------------------------------------------
   Find the Group ID for the RO being received
------------------------------------------ */
DECLARE @GroupID VARCHAR(200);

SELECT TOP 1
    @GroupID = roa.Value
FROM Plus.pls.ROHeaderAttribute roa
JOIN Plus.pls.ROHeader rh ON rh.ID = roa.ROHeaderID
WHERE rh.ProgramID = @ProgramID
  AND roa.ROHeaderID = @ReceivingROHeaderID
  AND roa.AttributeID = @Attr_GroupID
  AND NULLIF(LTRIM(RTRIM(roa.Value)), '') IS NOT NULL
ORDER BY roa.ID DESC;

-- If no Group ID, this RO is not under ECR consolidation gating.
IF (@GroupID IS NULL)
    RETURN;

/* ------------------------------------------
   Collect ALL ROs in this Group ID (group-level validation)
------------------------------------------ */
;WITH GroupROs AS (
    SELECT DISTINCT rh.ID AS ROHeaderID
    FROM Plus.pls.ROHeader rh
    JOIN Plus.pls.ROHeaderAttribute roa ON roa.ROHeaderID = rh.ID AND roa.AttributeID = @Attr_GroupID
    WHERE rh.ProgramID = @ProgramID
      AND roa.Value = @GroupID
),
GroupAttrs AS (
    SELECT
        gr.ROHeaderID,
        TrackingCount = TRY_CONVERT(INT, MAX(CASE WHEN roa.AttributeID = @Attr_TrackingCount THEN roa.Value END)),
        TrackingCsv   = MAX(CASE WHEN roa.AttributeID = @Attr_TrackingCsv THEN roa.Value END)
    FROM GroupROs gr
    LEFT JOIN Plus.pls.ROHeaderAttribute roa
        ON roa.ROHeaderID = gr.ROHeaderID
       AND roa.AttributeID IN (@Attr_TrackingCount, @Attr_TrackingCsv)
    GROUP BY gr.ROHeaderID
),
ExpectedTracking AS (
    SELECT DISTINCT
        ga.ROHeaderID,
        TrackingNo = LTRIM(RTRIM(ss.value))
    FROM GroupAttrs ga
    CROSS APPLY STRING_SPLIT(COALESCE(ga.TrackingCsv, ''), ',') ss
    WHERE NULLIF(LTRIM(RTRIM(ss.value)), '') IS NOT NULL
),
ExpectedSummary AS (
    SELECT
        -- IMPORTANT:
        -- If multiple ROs exist under the same Group ID, the attributes may be:
        --   (a) written only on one RO, or
        --   (b) replicated on all ROs.
        -- Summing across ROs would over-count in case (b), so we use MAX as the
        -- group-level "expected count" signal.
        ExpectedCountFromAttr = MAX(COALESCE(ga.TrackingCount, 0)),
        ExpectedCountFromCsv  = (SELECT COUNT(DISTINCT et.TrackingNo) FROM ExpectedTracking et)
    FROM GroupAttrs ga
),
DockLoggedTracking AS (
    SELECT DISTINCT
        dl.TrackingNo
    FROM Plus.pls.RODockLog dl
    JOIN GroupROs gr ON gr.ROHeaderID = dl.ROHeaderID
    WHERE dl.ProgramID = @ProgramID
      AND NULLIF(LTRIM(RTRIM(dl.TrackingNo)), '') IS NOT NULL
),
DockSummary AS (
    SELECT DockLoggedDistinctCount = COUNT(*) FROM DockLoggedTracking
),
MissingTracking AS (
    SELECT et.TrackingNo
    FROM (SELECT DISTINCT TrackingNo FROM ExpectedTracking) et
    EXCEPT
    SELECT dlt.TrackingNo
    FROM DockLoggedTracking dlt
),
ExtraTracking AS (
    SELECT dlt.TrackingNo
    FROM DockLoggedTracking dlt
    EXCEPT
    SELECT et.TrackingNo
    FROM (SELECT DISTINCT TrackingNo FROM ExpectedTracking) et
)
SELECT
    @GroupID AS GroupID,
    es.ExpectedCountFromAttr,
    es.ExpectedCountFromCsv,
    ds.DockLoggedDistinctCount,
    MissingCount = (SELECT COUNT(*) FROM MissingTracking),
    ExtraCount   = (SELECT COUNT(*) FROM ExtraTracking)
FROM ExpectedSummary es
CROSS JOIN DockSummary ds;

/* ------------------------------------------
   Enforcement logic (ADT/SP should raise + block)
------------------------------------------ */
DECLARE
    @ExpectedCountFromAttr INT,
    @ExpectedCountFromCsv INT,
    @DockLoggedDistinctCount INT,
    @MissingCount INT,
    @ExtraCount INT;

;WITH ExpectedSummary AS (
    SELECT
        -- See note above: MAX avoids double-counting when attributes are replicated.
        ExpectedCountFromAttr = MAX(COALESCE(ga.TrackingCount, 0)),
        ExpectedCountFromCsv  = (SELECT COUNT(DISTINCT et.TrackingNo) FROM (
            SELECT DISTINCT
                TrackingNo = LTRIM(RTRIM(ss.value))
            FROM Plus.pls.ROHeaderAttribute roaCsv
            JOIN Plus.pls.ROHeaderAttribute roaGroup ON roaGroup.ROHeaderID = roaCsv.ROHeaderID AND roaGroup.AttributeID = @Attr_GroupID AND roaGroup.Value = @GroupID
            JOIN Plus.pls.ROHeader rh ON rh.ID = roaCsv.ROHeaderID AND rh.ProgramID = @ProgramID
            CROSS APPLY STRING_SPLIT(COALESCE(roaCsv.Value, ''), ',') ss
            WHERE roaCsv.AttributeID = @Attr_TrackingCsv
              AND NULLIF(LTRIM(RTRIM(ss.value)), '') IS NOT NULL
        ) et)
    FROM (
        SELECT DISTINCT rh.ID AS ROHeaderID
        FROM Plus.pls.ROHeader rh
        JOIN Plus.pls.ROHeaderAttribute roa ON roa.ROHeaderID = rh.ID AND roa.AttributeID = @Attr_GroupID
        WHERE rh.ProgramID = @ProgramID
          AND roa.Value = @GroupID
    ) gr
    LEFT JOIN (
        SELECT
            roa.ROHeaderID,
            TrackingCount = TRY_CONVERT(INT, roa.Value)
        FROM Plus.pls.ROHeaderAttribute roa
        WHERE roa.AttributeID = @Attr_TrackingCount
    ) ga ON ga.ROHeaderID = gr.ROHeaderID
),
DockSummary AS (
    SELECT DockLoggedDistinctCount = COUNT(DISTINCT LTRIM(RTRIM(dl.TrackingNo)))
    FROM Plus.pls.RODockLog dl
    JOIN Plus.pls.ROHeaderAttribute roaGroup ON roaGroup.ROHeaderID = dl.ROHeaderID AND roaGroup.AttributeID = @Attr_GroupID AND roaGroup.Value = @GroupID
    JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID AND rh.ProgramID = @ProgramID
    WHERE dl.ProgramID = @ProgramID
      AND NULLIF(LTRIM(RTRIM(dl.TrackingNo)), '') IS NOT NULL
),
MissingTracking AS (
    SELECT et.TrackingNo
    FROM (
        SELECT DISTINCT LTRIM(RTRIM(ss.value)) AS TrackingNo
        FROM Plus.pls.ROHeaderAttribute roaCsv
        JOIN Plus.pls.ROHeaderAttribute roaGroup ON roaGroup.ROHeaderID = roaCsv.ROHeaderID AND roaGroup.AttributeID = @Attr_GroupID AND roaGroup.Value = @GroupID
        JOIN Plus.pls.ROHeader rh ON rh.ID = roaCsv.ROHeaderID AND rh.ProgramID = @ProgramID
        CROSS APPLY STRING_SPLIT(COALESCE(roaCsv.Value, ''), ',') ss
        WHERE roaCsv.AttributeID = @Attr_TrackingCsv
          AND NULLIF(LTRIM(RTRIM(ss.value)), '') IS NOT NULL
    ) et
    EXCEPT
    SELECT DISTINCT LTRIM(RTRIM(dl.TrackingNo)) AS TrackingNo
    FROM Plus.pls.RODockLog dl
    JOIN Plus.pls.ROHeaderAttribute roaGroup ON roaGroup.ROHeaderID = dl.ROHeaderID AND roaGroup.AttributeID = @Attr_GroupID AND roaGroup.Value = @GroupID
    JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID AND rh.ProgramID = @ProgramID
    WHERE dl.ProgramID = @ProgramID
      AND NULLIF(LTRIM(RTRIM(dl.TrackingNo)), '') IS NOT NULL
),
ExtraTracking AS (
    SELECT DISTINCT LTRIM(RTRIM(dl.TrackingNo)) AS TrackingNo
    FROM Plus.pls.RODockLog dl
    JOIN Plus.pls.ROHeaderAttribute roaGroup ON roaGroup.ROHeaderID = dl.ROHeaderID AND roaGroup.AttributeID = @Attr_GroupID AND roaGroup.Value = @GroupID
    JOIN Plus.pls.ROHeader rh ON rh.ID = dl.ROHeaderID AND rh.ProgramID = @ProgramID
    WHERE dl.ProgramID = @ProgramID
      AND NULLIF(LTRIM(RTRIM(dl.TrackingNo)), '') IS NOT NULL
    EXCEPT
    SELECT et.TrackingNo
    FROM (
        SELECT DISTINCT LTRIM(RTRIM(ss.value)) AS TrackingNo
        FROM Plus.pls.ROHeaderAttribute roaCsv
        JOIN Plus.pls.ROHeaderAttribute roaGroup ON roaGroup.ROHeaderID = roaCsv.ROHeaderID AND roaGroup.AttributeID = @Attr_GroupID AND roaGroup.Value = @GroupID
        JOIN Plus.pls.ROHeader rh ON rh.ID = roaCsv.ROHeaderID AND rh.ProgramID = @ProgramID
        CROSS APPLY STRING_SPLIT(COALESCE(roaCsv.Value, ''), ',') ss
        WHERE roaCsv.AttributeID = @Attr_TrackingCsv
          AND NULLIF(LTRIM(RTRIM(ss.value)), '') IS NOT NULL
    ) et
),
Counts AS (
    SELECT
        es.ExpectedCountFromAttr,
        es.ExpectedCountFromCsv,
        ds.DockLoggedDistinctCount,
        MissingCount = (SELECT COUNT(*) FROM MissingTracking),
        ExtraCount   = (SELECT COUNT(*) FROM ExtraTracking)
    FROM ExpectedSummary es
    CROSS JOIN DockSummary ds
)
SELECT
    @ExpectedCountFromAttr = ExpectedCountFromAttr,
    @ExpectedCountFromCsv = ExpectedCountFromCsv,
    @DockLoggedDistinctCount = DockLoggedDistinctCount,
    @MissingCount = MissingCount,
    @ExtraCount = ExtraCount
FROM Counts;

/* Fast gate: count mismatch blocks receiving */
-- Prefer the explicit count attribute for the fast gate.
-- If it's missing/0 but CSV is present, fall back to CSV count.
DECLARE @ExpectedFastGateCount INT = NULLIF(@ExpectedCountFromAttr, 0);
IF (@ExpectedFastGateCount IS NULL)
    SET @ExpectedFastGateCount = @ExpectedCountFromCsv;

IF (@DockLoggedDistinctCount <> @ExpectedFastGateCount)
BEGIN
    -- ADT/SP should block here
    -- RAISERROR('Receiving is not allowed. This Group ID has not been fully consolidated.', 16, 1);
    RETURN;
END

/* Backstop: exact match blocks if any expected tracking number is missing */
IF (@MissingCount > 0)
BEGIN
    -- ADT/SP should block here
    -- RAISERROR('Receiving is not allowed. This Group ID has not been fully consolidated.', 16, 1);
    RETURN;
END

/* Optional strictness: also block if there are extra dock-logged tracking numbers not in expected list */
-- IF (@ExtraCount > 0)
-- BEGIN
--     RAISERROR('Receiving is blocked due to unexpected dock-logged tracking numbers not present in ECR tracking list.', 16, 1);
--     RETURN;
-- END

/*
Optional: expose which tracking numbers are missing (for troubleshooting / supervisor override decision)
*/
-- SELECT TrackingNo FROM MissingTracking ORDER BY TrackingNo;


