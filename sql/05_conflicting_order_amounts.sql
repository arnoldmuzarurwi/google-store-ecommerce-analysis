-- 05: Orders recorded with different amounts
-- Purpose: look at the 15 real order numbers that appear
-- with more than one amount, to decide how to count them.

WITH purchases AS (
  SELECT
    ecommerce.transaction_id AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS revenue,
    event_timestamp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase'
    AND ecommerce.transaction_id IS NOT NULL
    AND ecommerce.transaction_id != '(not set)'
),
conflicts AS (
  SELECT transaction_id
  FROM purchases
  GROUP BY transaction_id
  HAVING COUNT(DISTINCT revenue) > 1
)
SELECT
  p.transaction_id,
  p.revenue,
  COUNT(*) AS copies,
  MIN(TIMESTAMP_MICROS(p.event_timestamp)) AS first_logged
FROM purchases p
JOIN conflicts c
  ON p.transaction_id = c.transaction_id
GROUP BY p.transaction_id, p.revenue
ORDER BY p.transaction_id, first_logged;

-- Results: 30 rows, 15 order numbers with exactly 2 amounts each.
-- The two amounts are always very different and logged days or
-- weeks apart (example: 140428 at $13 on Nov 23, then $27 on Dec 18).
-- These are not reload duplicates or price corrections. They are
-- separate orders that share a number, likely from the dataset's
-- obfuscation.
-- Decision: count each order number plus amount as one order,
-- giving 4,466 orders for revenue analysis.