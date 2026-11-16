-- 13: Question 3, products
-- Which products bring in the most revenue, and which get viewed and
-- carted a lot but rarely sell?
-- Rules: products matched by item_name (IDs don't line up across
-- events, see file 08); revenue only from real order numbers, with
-- reload copies removed.

-- Part A: top 10 products by revenue
WITH views AS (
  SELECT item_name, COUNT(DISTINCT session_key) AS view_sessions
  FROM `gstore-analysis-muzarurwi.gstore.items_flat`
  WHERE event_name = 'view_item'
  GROUP BY item_name
),
carts AS (
  SELECT item_name, COUNT(DISTINCT session_key) AS cart_sessions
  FROM `gstore-analysis-muzarurwi.gstore.items_flat`
  WHERE event_name = 'add_to_cart'
  GROUP BY item_name
),
sales AS (
  SELECT
    item_name,
    COUNT(DISTINCT transaction_id) AS orders,
    SUM(quantity) AS units,
    SUM(item_revenue) AS revenue
  FROM (
    -- removes reload copies: the same product in the same order counts once
    SELECT DISTINCT transaction_id, item_name, price, quantity, item_revenue
    FROM `gstore-analysis-muzarurwi.gstore.items_flat`
    WHERE event_name = 'purchase'
      AND transaction_id IS NOT NULL
      AND transaction_id != '(not set)'
  )
  GROUP BY item_name
)
SELECT
  s.item_name,
  v.view_sessions,
  c.cart_sessions,
  s.orders,
  s.units,
  ROUND(s.revenue, 0) AS revenue,
  ROUND(100 * s.revenue / SUM(s.revenue) OVER (), 1) AS pct_of_revenue,
  ROUND(100 * s.orders / v.view_sessions, 1) AS orders_per_100_views
FROM sales s
-- USING (item_name) is shorthand for ON s.item_name = v.item_name
LEFT JOIN views v USING (item_name)
LEFT JOIN carts c USING (item_name)
WHERE s.item_name IS NOT NULL
  AND s.item_name != '(not set)'
ORDER BY revenue DESC
LIMIT 10;

-- Results (visits viewing, orders, revenue, share of revenue, orders per 100 views):
-- Google Zip Hoodie F/C               17,159  187  $9,912  3.3%  1.1
-- Google Crewneck Sweatshirt N...     10,731  196  $9,416  3.2%  1.8
-- Google Badge Heavyweight Pull...    11,273  150  $8,202  2.8%  1.3
-- Super G Unisex Joggers              18,243  221  $7,519  2.5%  1.2
-- Google Men's Tech Fleece Grey        5,573   87  $7,371  2.5%  1.6
-- Google Crewneck Sweatshirt Gr...     9,565  146  $6,952  2.3%  1.5
-- Google Men's Puff Jacket Black       4,381   52  $5,037  1.7%  1.2
-- Google Canteen Bottle Black          2,634  130  $4,930  1.7%  4.9
-- Google Men's Tech Fleece Vest ...    1,924   62  $4,793  1.6%  3.2
-- Google Utility BackPack              5,527   47  $4,752  1.6%  0.9
-- (some names were cut off on screen)
-- Findings:
-- 1. Warm clothing drives winter sales: 8 of the top 10 are hoodies,
--    sweatshirts, joggers, fleeces and jackets.
-- 2. No single product carries the store: the top 10 make 23% of revenue.
-- 3. The two most viewed products (Zip Hoodie, Joggers) convert at about
--    1 order per 100 views, so their pages may be holding shoppers back.
-- 4. The Canteen Bottle converts best (4.9) and sells almost 2 per order.

-- Part B: products viewed in at least 2,000 visits, worst converters first
-- Starts from views, so products that never sold still appear.
WITH views AS (
  SELECT item_name, COUNT(DISTINCT session_key) AS view_sessions
  FROM `gstore-analysis-muzarurwi.gstore.items_flat`
  WHERE event_name = 'view_item'
  GROUP BY item_name
),
carts AS (
  SELECT item_name, COUNT(DISTINCT session_key) AS cart_sessions
  FROM `gstore-analysis-muzarurwi.gstore.items_flat`
  WHERE event_name = 'add_to_cart'
  GROUP BY item_name
),
sales AS (
  SELECT
    item_name,
    COUNT(DISTINCT transaction_id) AS orders,
    SUM(item_revenue) AS revenue
  FROM (
    SELECT DISTINCT transaction_id, item_name, price, quantity, item_revenue
    FROM `gstore-analysis-muzarurwi.gstore.items_flat`
    WHERE event_name = 'purchase'
      AND transaction_id IS NOT NULL
      AND transaction_id != '(not set)'
  )
  GROUP BY item_name
)
SELECT
  v.item_name,
  v.view_sessions,
  -- COALESCE turns a blank into 0 for products with no carts or sales
  COALESCE(c.cart_sessions, 0) AS cart_sessions,
  COALESCE(s.orders, 0) AS orders,
  ROUND(COALESCE(s.revenue, 0), 0) AS revenue,
  ROUND(100 * COALESCE(c.cart_sessions, 0) / v.view_sessions, 1) AS carts_per_100_views,
  ROUND(100 * COALESCE(s.orders, 0) / v.view_sessions, 1) AS orders_per_100_views
FROM views v
LEFT JOIN carts c USING (item_name)
LEFT JOIN sales s USING (item_name)
WHERE v.view_sessions >= 2000
  AND v.item_name IS NOT NULL
  AND v.item_name != '(not set)'
ORDER BY orders_per_100_views ASC
LIMIT 10;

-- Results (visits viewing, visits carting, orders):
-- Google Black Tee                     3,513    742  0
-- Google Women's Striped L/S          11,837  3,493  0
-- Candy Cane Android Cardboard ...     2,475    301  0
-- Google Pocket Tee Grey               3,451    883  0
-- Google F/C Long Sleeve Tee Ash       9,746  2,809  0
-- Google Eco Tee Black                 8,796  2,005  0
-- Google F/C Long Sleeve Tee Ch...    11,681  2,931  0
-- Google Women's Eco Tee Black         2,527    634  1 ($35)
-- Google Cloud Unisex Zip Hoodie       3,454    931  0
-- Google Land & Sea Unisex Tee         6,464  1,270  0
-- Thousands of cart adds but no sales, which needed checking (Part C).

-- Part C: follow five of these products through every funnel step,
-- counting all purchase rows, even without a real order number
SELECT
  item_name,
  event_name,
  COUNT(*) AS item_rows,
  MIN(event_date) AS first_day,
  MAX(event_date) AS last_day
FROM `gstore-analysis-muzarurwi.gstore.items_flat`
WHERE item_name IN (
    'Google Black Tee',
    "Google Women's Striped L/S",
    'Google F/C Long Sleeve Tee Ash',
    'Google Eco Tee Black',
    'Google Land & Sea Unisex Tee'
  )
  AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
GROUP BY item_name, event_name
ORDER BY item_name, item_rows DESC;

-- Results: all five are viewed and added to carts throughout Nov to Jan,
-- but never reach checkout and never appear in any purchase row. The only
-- exception is the Land & Sea Tee, with 9 checkout rows on Jan 19 and 20.
-- Bestsellers reach checkout normally, so these sales were not lost in
-- the data scrambling: these products genuinely stop at the cart.
-- Likely cause (not provable from the data): out of stock or unavailable
-- at checkout, or broken checkout tracking for these items.

-- Part D: how big is the problem?
WITH p AS (
  SELECT
    item_name,
    -- IF(...) inside COUNT only counts rows where the condition is true
    COUNT(DISTINCT IF(event_name = 'add_to_cart', session_key, NULL)) AS cart_sessions,
    COUNTIF(event_name = 'begin_checkout') AS checkout_rows,
    COUNTIF(event_name = 'purchase') AS purchase_rows
  FROM `gstore-analysis-muzarurwi.gstore.items_flat`
  WHERE item_name IS NOT NULL
    AND item_name != '(not set)'
  GROUP BY item_name
)
SELECT
  COUNT(*) AS products_added_to_carts,
  COUNTIF(checkout_rows = 0 AND purchase_rows = 0) AS products_never_reaching_checkout,
  SUM(cart_sessions) AS all_product_cart_adds,
  SUM(IF(checkout_rows = 0 AND purchase_rows = 0, cart_sessions, 0)) AS cart_adds_never_reaching_checkout
FROM p
WHERE cart_sessions > 0;

-- Results: 24 of 413 carted products (about 6%) never reach checkout,
-- accounting for 16,111 of 274,041 product cart adds (about 6%).
-- Recommendation: the store team should check stock and checkout for
-- these products, starting with the most viewed ones.