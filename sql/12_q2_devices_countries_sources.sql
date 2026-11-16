-- 12: Question 2, devices, countries and traffic sources
-- Which audiences convert best, and which bring visitors who rarely buy?
-- Visits and purchases come from the sessions table; revenue comes from
-- the clean orders table. Store wide: 1.35% of visits buy, $0.86 per visit.

-- Part A: devices
WITH s AS (
  SELECT
    device_category,
    COUNT(*) AS sessions,
    COUNTIF(added_to_cart) AS cart_sessions,
    COUNTIF(purchased) AS purchasing_sessions
  FROM `gstore-analysis-muzarurwi.gstore.sessions`
  GROUP BY device_category
),
o AS (
  SELECT
    device_category,
    COUNT(*) AS orders,
    SUM(order_revenue) AS revenue
  FROM `gstore-analysis-muzarurwi.gstore.orders`
  GROUP BY device_category
)
SELECT
  s.device_category,
  s.sessions,
  -- SUM(...) OVER () adds up every row, giving each device's share of the total
  ROUND(100 * s.sessions / SUM(s.sessions) OVER (), 1) AS pct_of_sessions,
  ROUND(100 * s.cart_sessions / s.sessions, 2) AS cart_rate,
  ROUND(100 * s.purchasing_sessions / s.sessions, 2) AS conversion_rate,
  o.orders,
  ROUND(o.revenue, 0) AS revenue,
  ROUND(o.revenue / s.sessions, 2) AS revenue_per_session
FROM s
LEFT JOIN o
  ON s.device_category = o.device_category
ORDER BY s.sessions DESC;

-- Results (share of visits, conversion, revenue per visit):
-- desktop 58.0%, 1.32%, $0.86
-- mobile  39.8%, 1.39%, $0.87
-- tablet   2.2%, 1.30%, $0.66
-- Finding: device makes almost no difference. Mobile converts as well as
-- desktop, so the mobile experience is not where shoppers are lost.

-- Part B: top 10 countries by visits
WITH s AS (
  SELECT
    country,
    COUNT(*) AS sessions,
    COUNTIF(purchased) AS purchasing_sessions
  FROM `gstore-analysis-muzarurwi.gstore.sessions`
  GROUP BY country
),
o AS (
  SELECT
    country,
    COUNT(*) AS orders,
    SUM(order_revenue) AS revenue
  FROM `gstore-analysis-muzarurwi.gstore.orders`
  GROUP BY country
)
SELECT
  s.country,
  s.sessions,
  ROUND(100 * s.sessions / SUM(s.sessions) OVER (), 1) AS pct_of_sessions,
  ROUND(100 * s.purchasing_sessions / s.sessions, 2) AS conversion_rate,
  o.orders,
  ROUND(o.revenue, 0) AS revenue,
  ROUND(100 * o.revenue / SUM(o.revenue) OVER (), 1) AS pct_of_revenue,
  ROUND(o.revenue / s.sessions, 2) AS revenue_per_session
FROM s
LEFT JOIN o
  ON s.country = o.country
ORDER BY s.sessions DESC
LIMIT 10;

-- Results (share of visits, conversion, share of revenue, revenue per visit):
-- United States  43.9%, 1.34%, 44.1%, $0.86
-- India           9.4%, 1.33%,  9.5%, $0.87
-- Canada          7.4%, 1.45%,  8.8%, $1.02
-- United Kingdom  3.1%, 1.33%,  3.2%, $0.87
-- France          2.0%, 1.42%,  1.9%, $0.82
-- Spain           1.9%, 1.48%,  2.2%, $1.03
-- Germany         1.8%, 1.27%,  1.6%, $0.76
-- China           1.7%, 1.28%,  1.7%, $0.82
-- Taiwan          1.7%, 1.32%,  1.2%, $0.59
-- Italy           1.4%, 1.10%,  1.4%, $0.88
-- Finding: country also makes little difference; each country's share of
-- revenue tracks its share of visits. Canada is the strongest big market
-- (higher conversion, $75 average order vs $70 for the US), a modest edge.
-- Smaller countries have 50 to 106 orders each, too few to read much into.

-- Part C: top 10 traffic sources by visits
-- Caveat: traffic source records how a visitor first found the store,
-- and about a third of visits are hidden as <Other> or (data deleted).
WITH s AS (
  SELECT
    traffic_source,
    traffic_medium,
    COUNT(*) AS sessions,
    COUNTIF(purchased) AS purchasing_sessions
  FROM `gstore-analysis-muzarurwi.gstore.sessions`
  GROUP BY traffic_source, traffic_medium
),
o AS (
  SELECT
    traffic_source,
    traffic_medium,
    COUNT(*) AS orders,
    SUM(order_revenue) AS revenue
  FROM `gstore-analysis-muzarurwi.gstore.orders`
  GROUP BY traffic_source, traffic_medium
)
SELECT
  s.traffic_source,
  s.traffic_medium,
  s.sessions,
  ROUND(100 * s.sessions / SUM(s.sessions) OVER (), 1) AS pct_of_sessions,
  ROUND(100 * s.purchasing_sessions / s.sessions, 2) AS conversion_rate,
  o.orders,
  ROUND(o.revenue, 0) AS revenue,
  ROUND(100 * o.revenue / SUM(o.revenue) OVER (), 1) AS pct_of_revenue,
  ROUND(o.revenue / s.sessions, 2) AS revenue_per_session
FROM s
LEFT JOIN o
  -- match on both columns: "google" means free search or paid ads
  -- depending on the medium
  ON s.traffic_source = o.traffic_source
  AND s.traffic_medium = o.traffic_medium
ORDER BY s.sessions DESC
LIMIT 10;

-- Results (share of visits, conversion, share of revenue, revenue per visit):
-- google / organic           31.3%, 1.11%, 27.1%, $0.74
-- (direct) / (none)          23.2%, 1.29%, 22.1%, $0.82
-- <Other> / <Other>          14.5%, 0.97%,  9.9%, $0.59
-- <Other> / referral          9.6%, 1.36%, 10.1%, $0.90
-- store's own site / referral 8.0%, 2.03%, 13.0%, $1.39
-- (data deleted)              6.2%, 3.14%, 13.0%, $1.80
-- google / cpc (paid ads)     4.3%, 0.98%,  2.5%, $0.50
-- <Other> / organic           2.8%, 0.95%,  2.3%, $0.70
-- (two more rows with under 400 visits each)
-- Findings:
-- 1. Paid search ads are the weakest named source: 4.3% of visits but
--    2.5% of revenue, $0.50 per visit, about 40% below average.
-- 2. Free Google search is the biggest source but converts below average.
-- 3. Visitors arriving from the store's own site convert best of the
--    named sources, most likely returning shoppers.
-- Caveat: the hidden (data deleted) group converts at 3.14%, the highest
-- of any row, so Google did not hide data at random. Source rankings are
-- a partial picture.