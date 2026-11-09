-- 10: Orders table
-- Purpose: one row per real order, with the revenue cleaning rule
-- applied once. Used for all revenue and order analysis.
-- Rule: only real order numbers, each order number plus amount
-- counted once (see docs/data_quality.md).

CREATE OR REPLACE TABLE `gstore-analysis-muzarurwi.gstore.orders` AS
SELECT
  transaction_id,
  purchase_revenue AS order_revenue,
  MIN(event_time) AS order_time,
  MIN(event_date) AS order_date,
  ANY_VALUE(user_pseudo_id) AS user_pseudo_id,
  ANY_VALUE(session_key) AS session_key,
  ANY_VALUE(device_category) AS device_category,
  ANY_VALUE(country) AS country,
  ANY_VALUE(traffic_source) AS traffic_source,
  ANY_VALUE(traffic_medium) AS traffic_medium,
  -- how many times this order was logged (above 1 = reload copies)
  COUNT(*) AS copies_logged
FROM `gstore-analysis-muzarurwi.gstore.events_flat`
WHERE event_name = 'purchase'
  AND transaction_id IS NOT NULL
  AND transaction_id != '(not set)'
-- copies with the same number and amount collapse into one order;
-- the same number with a different amount stays a separate order
GROUP BY transaction_id, purchase_revenue;

-- Check: the rule worked as planned
SELECT
  COUNT(*) AS orders,
  COUNT(DISTINCT transaction_id) AS distinct_order_numbers,
  SUM(copies_logged) AS purchase_events_covered,
  COUNTIF(order_revenue = 0) AS zero_revenue_orders,
  ROUND(SUM(order_revenue), 2) AS total_revenue,
  ROUND(AVG(order_revenue), 2) AS average_order_value
FROM `gstore-analysis-muzarurwi.gstore.orders`;

-- Results: 4,466 orders from 4,451 order numbers (15 shared numbers
-- kept as separate sales), covering all 4,786 real purchase events,
-- 0 orders at $0.
-- Clean revenue $308,830 (vs $330,348 before removing reload copies),
-- average order value $69.15.