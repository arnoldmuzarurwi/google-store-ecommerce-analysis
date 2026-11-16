-- 14: Question 4, repeat buyers
-- How many buyers came back to buy again within the three months, and
-- what share of revenue came from repeat customers?
-- Reads from the clean orders table, so reload copies can't make a
-- one-time buyer look like a repeat buyer.
-- Caveats: a "buyer" is a browser or device (user_pseudo_id), not a
-- person, so cross-device repeat buyers are undercounted; and three
-- months is a short window for customers to return.

WITH buyers AS (
  SELECT
    user_pseudo_id,
    COUNT(*) AS orders,
    COUNT(DISTINCT order_date) AS buying_days,
    SUM(order_revenue) AS revenue
  FROM `gstore-analysis-muzarurwi.gstore.orders`
  GROUP BY user_pseudo_id
)
SELECT
  -- CASE WHEN sorts each buyer into a group
  CASE
    WHEN orders = 1 THEN '1 order'
    WHEN orders = 2 THEN '2 orders'
    ELSE '3+ orders'
  END AS buyer_group,
  COUNT(*) AS buyers,
  -- COUNT(*) counts buyers per group; the window SUM adds up all groups
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_buyers,
  -- separates real return visits from several orders on the same day
  COUNTIF(buying_days > 1) AS bought_on_2plus_days,
  SUM(orders) AS orders,
  ROUND(SUM(revenue), 0) AS revenue,
  ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS pct_of_revenue,
  ROUND(SUM(revenue) / SUM(orders), 2) AS avg_order_value
FROM buyers
GROUP BY buyer_group
ORDER BY buyer_group;

-- Results (buyers, share of buyers, bought on 2+ days, orders, revenue,
-- share of revenue, average order):
-- 1 order    3,273  88.1%    0  3,273  $232,220  75.2%  $70.95
-- 2 orders     302   8.1%  178    604   $43,100  14.0%  $71.36
-- 3+ orders    138   3.7%   78    589   $33,510  10.9%  $56.89
-- Totals match the orders table: 3,713 buyers, 4,466 orders, $308,830.
--
-- Findings:
-- 1. 88% of buyers bought once. 12% ordered more than once, and 256
--    buyers (about 7%) came back on a different day.
-- 2. The 12% of repeat buyers bring in 25% of revenue. Each is worth
--    about $143 (2 orders) or $243 (3+ orders), against $71 for a
--    one-time buyer.
-- 3. The 3+ group places smaller orders ($57): frequent top-up buyers.
-- Recommendation: post-purchase follow-up to turn one-time buyers into
-- repeat buyers, since each one is worth two to three times as much.