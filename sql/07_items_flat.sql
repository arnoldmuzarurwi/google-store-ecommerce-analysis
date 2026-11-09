-- 07: Flat items table
-- Purpose: unpack the product list inside each event into
-- one row per product per event, for product analysis.

CREATE OR REPLACE TABLE `gstore-analysis-muzarurwi.gstore.items_flat` AS
SELECT
  PARSE_DATE('%Y%m%d', e.event_date) AS event_date,
  TIMESTAMP_MICROS(e.event_timestamp) AS event_time,
  e.event_name,
  e.user_pseudo_id,
  CONCAT(
    e.user_pseudo_id, '_',
    CAST((SELECT value.int_value FROM UNNEST(e.event_params) WHERE key = 'ga_session_id') AS STRING)
  ) AS session_key,
  e.ecommerce.transaction_id AS transaction_id,
  i.item_id,
  i.item_name,
  i.item_category,
  i.price_in_usd AS price,
  i.quantity,
  i.item_revenue_in_usd AS item_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e,
  -- turns each event's product list into separate rows
  UNNEST(e.items) AS i;

-- Check: product rows by event type
SELECT
  event_name,
  COUNT(*) AS item_rows,
  COUNT(DISTINCT item_id) AS distinct_items,
  COUNTIF(item_name IS NULL OR item_name = '(not set)') AS missing_name,
  COUNTIF(item_category IS NULL OR item_category = '(not set)') AS missing_category,
  ROUND(SUM(item_revenue), 2) AS item_revenue_usd
FROM `gstore-analysis-muzarurwi.gstore.items_flat`
GROUP BY event_name
ORDER BY item_rows DESC;

-- Results:
-- view_item: 2,748,246 rows, 427 products, 9 missing names
-- add_to_cart: 667,426 rows, 806 products, 144 missing names
-- select_item: 329,364 rows, 641 products, 2,720 missing names
-- view_promotion: 134,602 rows, nearly all missing (banner ads, not products)
-- begin_checkout: 77,980 rows, 797 products, 1,933 missing names
-- purchase: 16,003 rows, 810 products, 448 missing names, $362,110 revenue
--   (order level total in file 04 is $362,165, a 0.02% difference)
-- select_promotion: 8,595 rows, all missing (banner ads)
-- view_item_list: 516 rows, 64 products, 8 missing names
-- Open question: 810 products were bought but only 427 were viewed,
-- so product IDs may not line up across events. Checked next.