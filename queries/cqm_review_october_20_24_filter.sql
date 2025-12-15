-- ================================================
-- QUERY RPT.CQMREVIEW WITH OCTOBER 20-24 FILTER
-- ================================================
-- Use this to query the existing view with date filtering
-- ================================================

SELECT *
FROM rpt.CQMReview
WHERE [CQM Date] >= '2024-10-20'
  AND [CQM Date] < '2024-10-25'
ORDER BY [CQM Date] DESC;

-- ================================================
-- SUMMARY QUERY
-- ================================================
-- Get summary statistics for the week

SELECT 
    COUNT(*) as TotalRecords,
    SUM(CASE WHEN [CQM Results] = 'Pass' THEN 1 ELSE 0 END) as PassCount,
    SUM(CASE WHEN [CQM Results] = 'Fail' THEN 1 ELSE 0 END) as FailCount,
    CAST(SUM(CASE WHEN [CQM Results] = 'Pass' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as PassRate,
    MIN([CQM Date]) as FirstRecord,
    MAX([CQM Date]) as LastRecord
FROM rpt.CQMReview
WHERE [CQM Date] >= '2024-10-20'
  AND [CQM Date] < '2024-10-25';

-- ================================================
-- BREAKDOWN BY AUDITOR
-- ================================================

SELECT 
    [Auditor Name],
    COUNT(*) as TotalReviews,
    SUM(CASE WHEN [CQM Results] = 'Pass' THEN 1 ELSE 0 END) as PassCount,
    SUM(CASE WHEN [CQM Results] = 'Fail' THEN 1 ELSE 0 END) as FailCount,
    CAST(SUM(CASE WHEN [CQM Results] = 'Pass' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as PassRate
FROM rpt.CQMReview
WHERE [CQM Date] >= '2024-10-20'
  AND [CQM Date] < '2024-10-25'
GROUP BY [Auditor Name]
ORDER BY TotalReviews DESC;
