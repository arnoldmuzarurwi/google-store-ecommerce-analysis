-- Missing and placeholder values in the fields used for analysis
--
-- Purpose: Measure how much of each field is missing or hidden by Google's
--          obfuscation before using it in the analysis.
-- Method:  For each field, the percent of events with no value, the percent
--          with a placeholder ('<Other>', '(data deleted)', '(not set)'),
--          and the number of distinct values.
-- Tables:  bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
-- Result:  device.category and ga_session_id are complete (0% missing or
--          placeholder). geo.country has 0.7% placeholders across 109 values.
--          Traffic source fields are heavily obfuscated: source 33.5%,
--          campaign name 25.3%, medium 21.2% placeholders, with only 5 to 6
--          distinct values each. traffic_source is the channel that first
--          brought the visitor, not the source of each visit.

WITH events AS (
  SELECT *
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),
fields AS (
  SELECT 'traffic_source.source' AS field, traffic_source.source AS value FROM events
  UNION ALL SELECT 'traffic_source.medium', traffic_source.medium FROM events
  UNION ALL SELECT 'traffic_source.name', traffic_source.name FROM events
  UNION ALL SELECT 'device.category', device.category FROM events
  UNION ALL SELECT 'geo.country', geo.country FROM events
  UNION ALL SELECT 'ga_session_id',
    CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING)
    FROM events
)
SELECT
  field,
  COUNT(*) AS events,
  ROUND(100 * COUNTIF(value IS NULL) / COUNT(*), 1) AS pct_missing,
  ROUND(100 * COUNTIF(value IN ('<Other>', '(data deleted)', '(not set)')) / COUNT(*), 1) AS pct_placeholder,
  COUNT(DISTINCT value) AS distinct_values
FROM fields
GROUP BY field
ORDER BY field