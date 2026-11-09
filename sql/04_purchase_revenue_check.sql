-- 04: Purchase revenue check
-- Purpose: check purchase events for missing order numbers,
-- zero or negative revenue, and duplicate orders.

-- Part A: overall revenue check
SELECT
  COUNT(*) AS purchase_events,
  COUNT(DISTINCT ecommerce.transaction_id) AS distinct_transactions,
  COUNTIF(ecommerce.transaction_id IS NULL OR ecommerce.transaction_id = '(not set)') AS missing_transaction_id,
  COUNTIF(ecommerce.purchase_revenue_in_usd IS NULL) AS missing_revenue,
  COUNTIF(ecommerce.purchase_revenue_in_usd = 0) AS zero_revenue,
  COUNTIF(ecommerce.purchase_revenue_in_usd < 0) AS negative_revenue,
  ROUND(SUM(ecommerce.purchase_revenue_in_usd), 2) AS total_revenue_usd,
  ROUND(MIN(ecommerce.purchase_revenue_in_usd), 2) AS min_revenue_usd,
  ROUND(MAX(ecommerce.purchase_revenue_in_usd), 2) AS max_revenue_usd
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = 'purchase';

-- Results: 5,692 purchase events, 4,452 distinct order numbers,
-- 906 with no real order number, 450 with $0 revenue,
-- 0 negative, 0 missing amounts, total $362,165,
-- smallest order $0, largest order $1,530.

-- Part B: breakdown by order number type
WITH purchases AS (
  SELECT
    ecommerce.transaction_id AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase'
)
SELECT
  CASE
    WHEN transaction_id IS NULL THEN 'empty'
    WHEN transaction_id = '(not set)' THEN '(not set)'
    ELSE 'real order number'
  END AS id_type,
  COUNT(*) AS purchase_events,
  COUNT(DISTINCT transaction_id) AS distinct_ids,
  COUNT(*) - COUNT(DISTINCT transaction_id) AS repeated_events,
  COUNT(DISTINCT CONCAT(transaction_id, '|', CAST(revenue AS STRING))) AS distinct_id_and_amount,
  COUNTIF(revenue = 0) AS zero_revenue,
  ROUND(SUM(revenue), 2) AS revenue_usd
FROM purchases
GROUP BY id_type
ORDER BY purchase_events DESC;

-- Results:
-- real order number: 4,786 events, 4,451 orders, 335 duplicate copies,
--   15 orders recorded with different amounts (4,466 minus 4,451),
--   0 with $0 revenue, $330,348 (91% of revenue)
-- (not set): 883 events, all 450 of the $0 purchases, $30,489 (8%)
-- empty: 23 events, $1,328 (under 1%)
-- Note: repeated_events for (not set) and empty are not real duplicates;
-- they share one placeholder or have no order number, so copies
-- cannot be told apart from separate orders.