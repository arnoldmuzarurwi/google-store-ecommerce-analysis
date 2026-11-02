-- Event types: which events exist and how often
--
-- Purpose: List every event type and confirm the funnel events exist before
--          building the funnel.
-- Method:  Count events and unique users (user_pseudo_id) per event_name,
--          sorted by number of events.
-- Tables:  bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
-- Result:  17 event types. All funnel steps are present, with visitors per
--          step: view_item 61,252, add_to_cart 12,545, begin_checkout 9,715,
--          add_shipping_info 9,714, add_payment_info 5,751, purchase 4,419.
--          These are visitors who ever did each step, not an ordered funnel.

SELECT
  event_name,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY event_name
ORDER BY events DESC