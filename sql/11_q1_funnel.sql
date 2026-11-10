-- 11: Question 1, the funnel
-- Where does the store lose shoppers between viewing a product
-- and buying? One row per step, with the share of all sessions
-- and the share kept from the step before.

WITH session_steps AS (
  -- one row per session: did each step happen at least once?
  SELECT
    session_key,
    COUNTIF(event_name = 'view_item') > 0 AS viewed,
    COUNTIF(event_name = 'add_to_cart') > 0 AS carted,
    COUNTIF(event_name = 'begin_checkout') > 0 AS checkout,
    COUNTIF(event_name = 'add_shipping_info') > 0 AS shipping,
    COUNTIF(event_name = 'add_payment_info') > 0 AS payment,
    COUNTIF(event_name = 'purchase') > 0 AS bought
  FROM `gstore-analysis-muzarurwi.gstore.events_flat`
  GROUP BY session_key
),
counts AS (
  SELECT
    COUNT(*) AS all_sessions,
    COUNTIF(viewed) AS viewed,
    COUNTIF(carted) AS carted,
    COUNTIF(checkout) AS checkout,
    COUNTIF(shipping) AS shipping,
    COUNTIF(payment) AS payment,
    COUNTIF(bought) AS bought
  FROM session_steps
)
SELECT
  step.step_number,
  step.step_name,
  step.sessions,
  ROUND(100 * step.sessions / all_sessions, 1) AS pct_of_all_sessions,
  -- LAG looks at the step above, so each step is divided by the one before it
  ROUND(100 * step.sessions / LAG(step.sessions) OVER (ORDER BY step.step_number), 1) AS pct_of_previous_step
FROM counts,
  -- turns the single row of counts into one row per step
  UNNEST([
    STRUCT(1 AS step_number, 'All sessions' AS step_name, all_sessions AS sessions),
    STRUCT(2, 'Viewed a product', viewed),
    STRUCT(3, 'Added to cart', carted),
    STRUCT(4, 'Started checkout', checkout),
    STRUCT(5, 'Added shipping info', shipping),
    STRUCT(6, 'Added payment info', payment),
    STRUCT(7, 'Purchased', bought)
  ]) AS step
ORDER BY step.step_number;

-- Results (sessions, % of all, % kept from previous step):
-- All sessions          360,129  100.0
-- Viewed a product       77,020   21.4   21.4
-- Added to cart          15,188    4.2   19.7
-- Started checkout       11,106    3.1   73.1
-- Added shipping info    11,105    3.1  100.0
-- Added payment info      6,815    1.9   61.4
-- Purchased               4,848    1.3   71.1
--
-- Findings:
-- 1. Biggest drop by volume: about 80% of visits that view a product
--    never add to cart (about 62,000 sessions).
-- 2. Most expensive drop: about 39% of shoppers who entered shipping
--    quit before payment (about 4,300 ready to buy sessions).
-- 3. 1.3% of all visits end in a purchase.
-- Note: shipping info is logged together with begin_checkout (100%),
-- so the checkout has two real steps: shipping, then payment.