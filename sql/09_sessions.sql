-- 09: Sessions table
-- Purpose: one row per visit, with yes/no flags for how far
-- the visit got in the funnel. Used for funnel and traffic analysis.

CREATE OR REPLACE TABLE `gstore-analysis-muzarurwi.gstore.sessions` AS
SELECT
  session_key,
  user_pseudo_id,
  MIN(event_time) AS session_start,
  MIN(event_date) AS session_date,
  -- device, country and traffic source stay the same within a
  -- session (checked below), so any row gives the right value
  ANY_VALUE(device_category) AS device_category,
  ANY_VALUE(country) AS country,
  ANY_VALUE(traffic_source) AS traffic_source,
  ANY_VALUE(traffic_medium) AS traffic_medium,
  COUNT(*) AS events,
  COUNTIF(event_name = 'page_view') AS page_views,
  -- true if the step happened at least once in the visit
  COUNTIF(event_name = 'view_item') > 0 AS viewed_item,
  COUNTIF(event_name = 'add_to_cart') > 0 AS added_to_cart,
  COUNTIF(event_name = 'begin_checkout') > 0 AS began_checkout,
  COUNTIF(event_name = 'purchase') > 0 AS purchased
FROM `gstore-analysis-muzarurwi.gstore.events_flat`
GROUP BY session_key, user_pseudo_id;

-- Check: one row per session, funnel counts, and whether device,
-- country or traffic source ever change within a session
SELECT
  COUNT(*) AS rows_in_table,
  COUNT(DISTINCT session_key) AS distinct_sessions,
  COUNTIF(viewed_item) AS viewed_item,
  COUNTIF(added_to_cart) AS added_to_cart,
  COUNTIF(began_checkout) AS began_checkout,
  COUNTIF(purchased) AS purchased,
  (
    SELECT COUNT(*) FROM (
      SELECT session_key
      FROM `gstore-analysis-muzarurwi.gstore.events_flat`
      GROUP BY session_key
      HAVING COUNT(DISTINCT device_category) > 1
          OR COUNT(DISTINCT country) > 1
          OR COUNT(DISTINCT traffic_source) > 1
    )
  ) AS sessions_with_mixed_values
FROM `gstore-analysis-muzarurwi.gstore.sessions`;

-- Results: 360,129 rows and 360,129 distinct sessions (one row each),
-- 0 sessions with mixed values.
-- Sessions reaching each step: viewed a product 77,020,
-- added to cart 15,188, started checkout 11,106, purchased 4,848.
-- 4,848 purchasing sessions vs 5,692 purchase events: the gap is
-- reload duplicates and repeat purchases within one visit.