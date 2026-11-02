-- Dataset overview: size and date range
--
-- Purpose: Check how big the Google Merchandise Store sample is and which
--          dates it covers before any analysis.
-- Method:  Count all events, unique users (user_pseudo_id) and sessions
--          (user_pseudo_id plus ga_session_id), and the distinct days.
-- Tables:  bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
-- Result:  4,295,584 events, 270,154 users, 360,129 sessions over 92 days,
--          Nov 1, 2020 to Jan 31, 2021 (about 1.3 sessions per user).

SELECT
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-',
    CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING))) AS sessions,
  COUNT(DISTINCT event_date) AS days,
  MIN(event_date) AS first_day,
  MAX(event_date) AS last_day
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`