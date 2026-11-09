-- 06: Flat events table
-- Purpose: pull the fields we need out of the nested raw data into
-- plain columns, one row per event. All later tables read from this.

CREATE OR REPLACE TABLE `gstore-analysis-muzarurwi.gstore.events_flat` AS
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS event_date,
  TIMESTAMP_MICROS(event_timestamp) AS event_time,
  event_name,
  user_pseudo_id,
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
  -- session numbers repeat across visitors, so join them with the
  -- visitor ID to make each session unique
  CONCAT(
    user_pseudo_id, '_',
    CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING)
  ) AS session_key,
  device.category AS device_category,
  geo.country AS country,
  traffic_source.source AS traffic_source,
  traffic_source.medium AS traffic_medium,
  ecommerce.transaction_id AS transaction_id,
  ecommerce.purchase_revenue_in_usd AS purchase_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;

-- Check: the new table matches the raw data
SELECT
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT session_key) AS sessions,
  COUNTIF(ga_session_id IS NULL) AS events_missing_session,
  MIN(event_date) AS first_day,
  MAX(event_date) AS last_day
FROM `gstore-analysis-muzarurwi.gstore.events_flat`;

-- Results: 4,295,584 events, 270,154 users, 360,129 sessions,
-- 0 events missing a session ID, 2020-11-01 to 2021-01-31.
-- All match sql/01_dataset_overview.sql.