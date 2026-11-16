-- 16: Power BI tables
-- Purpose: small, ready-to-load tables for the Power BI model.
-- pbi_sessions adds the shipping and payment steps the dashboard
-- funnel needs, so events_flat (4.3M rows) doesn't have to be loaded.
-- pbi_products holds one row per visit per product instead of
-- items_flat's ~4M rows of repeated events.
-- Steps are stored as 1 or 0 so Power BI can count them with SUM.

-- Part A: one row per session with every funnel step
CREATE OR REPLACE TABLE `gstore-analysis-muzarurwi.gstore.pbi_sessions` AS
SELECT
  session_key,
  user_pseudo_id,
  MIN(event_date) AS session_date,
  ANY_VALUE(device_category) AS device_category,
  ANY_VALUE(country) AS country,
  ANY_VALUE(traffic_source) AS traffic_source,
  ANY_VALUE(traffic_medium) AS traffic_medium,
  IF(COUNTIF(event_name = 'view_item') > 0, 1, 0) AS viewed_item,
  IF(COUNTIF(event_name = 'add_to_cart') > 0, 1, 0) AS added_to_cart,
  IF(COUNTIF(event_name = 'begin_checkout') > 0, 1, 0) AS began_checkout,
  IF(COUNTIF(event_name = 'add_shipping_info') > 0, 1, 0) AS added_shipping,
  IF(COUNTIF(event_name = 'add_payment_info') > 0, 1, 0) AS added_payment,
  IF(COUNTIF(event_name = 'purchase') > 0, 1, 0) AS purchased
FROM `gstore-analysis-muzarurwi.gstore.events_flat`
GROUP BY session_key, user_pseudo_id;

-- Check: should match the funnel in file 11
SELECT
  COUNT(*) AS sessions,
  SUM(viewed_item) AS viewed_item,
  SUM(added_to_cart) AS added_to_cart,
  SUM(began_checkout) AS began_checkout,
  SUM(added_shipping) AS added_shipping,
  SUM(added_payment) AS added_payment,
  SUM(purchased) AS purchased
FROM `gstore-analysis-muzarurwi.gstore.pbi_sessions`;

-- Results: 360,129 sessions; 77,020 viewed; 15,188 carted;
-- 11,106 checkout; 11,105 shipping; 6,815 payment; 4,848 purchased.
-- Matches file 11 exactly.

-- Part B: one row per visit per product
-- Products matched by name (file 08); sales only from real order
-- numbers with copies removed (file 13).
CREATE OR REPLACE TABLE `gstore-analysis-muzarurwi.gstore.pbi_products` AS
WITH steps AS (
  SELECT
    session_key,
    item_name,
    ANY_VALUE(item_category) AS item_category,
    IF(COUNTIF(event_name = 'view_item') > 0, 1, 0) AS viewed,
    IF(COUNTIF(event_name = 'add_to_cart') > 0, 1, 0) AS carted,
    IF(COUNTIF(event_name = 'begin_checkout') > 0, 1, 0) AS reached_checkout
  FROM `gstore-analysis-muzarurwi.gstore.items_flat`
  WHERE item_name IS NOT NULL
    AND item_name != '(not set)'
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
  GROUP BY session_key, item_name
),
sales AS (
  SELECT
    session_key,
    item_name,
    COUNT(DISTINCT transaction_id) AS orders,
    SUM(quantity) AS units,
    SUM(item_revenue) AS revenue
  FROM (
    SELECT DISTINCT session_key, transaction_id, item_name, price, quantity, item_revenue
    FROM `gstore-analysis-muzarurwi.gstore.items_flat`
    WHERE event_name = 'purchase'
      AND transaction_id IS NOT NULL
      AND transaction_id != '(not set)'
  )
  GROUP BY session_key, item_name
)
SELECT
  s.session_key,
  s.item_name,
  s.item_category,
  s.viewed,
  s.carted,
  s.reached_checkout,
  COALESCE(p.orders, 0) AS orders,
  COALESCE(p.units, 0) AS units,
  COALESCE(p.revenue, 0) AS revenue
FROM steps s
LEFT JOIN sales p USING (session_key, item_name);

-- Check: size, and revenue against the file 13 rule
SELECT
  COUNT(*) AS table_rows,
  COUNT(DISTINCT item_name) AS products,
  SUM(viewed) AS viewed,
  SUM(carted) AS carted,
  SUM(reached_checkout) AS reached_checkout,
  SUM(orders) AS orders,
  ROUND(SUM(revenue), 0) AS revenue,
  (
    SELECT ROUND(SUM(item_revenue), 0)
    FROM (
      SELECT DISTINCT transaction_id, item_name, price, quantity, item_revenue
      FROM `gstore-analysis-muzarurwi.gstore.items_flat`
      WHERE event_name = 'purchase'
        AND transaction_id IS NOT NULL
        AND transaction_id != '(not set)'
        AND item_name IS NOT NULL
        AND item_name != '(not set)'
    )
  ) AS revenue_check
FROM `gstore-analysis-muzarurwi.gstore.pbi_products`;

-- Results: 1,111,507 rows (vs ~4M in items_flat), 429 products,
-- 274,041 cart adds (matches file 13), 17,858 reached checkout,
-- 12,887 product orders, revenue $298,189 vs check $298,177.
-- The $12 gap (0.004%) comes from a few order copies logged in a second
-- visit, which count once per visit here. Accepted as too small to matter.
-- Product revenue is below the $308,830 order total because it only
-- counts products with a real name, so revenue totals in the dashboard
-- come from the orders table and this table is used for product comparisons.