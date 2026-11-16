-- 15: Question 5, the holiday season
-- How did visits, conversion and revenue change week by week from
-- November through the holidays into January?
-- Visits and conversion come from the sessions table (counts any
-- purchase); orders and revenue come from the clean orders table
-- (real order numbers only).

WITH s AS (
  SELECT
    -- DATE_TRUNC rounds each date back to the Sunday starting its week
    DATE_TRUNC(session_date, WEEK) AS week_start,
    COUNT(*) AS sessions,
    COUNTIF(purchased) AS purchasing_sessions
  FROM `gstore-analysis-muzarurwi.gstore.sessions`
  GROUP BY week_start
),
o AS (
  SELECT
    DATE_TRUNC(order_date, WEEK) AS week_start,
    COUNT(*) AS orders,
    SUM(order_revenue) AS revenue
  FROM `gstore-analysis-muzarurwi.gstore.orders`
  GROUP BY week_start
)
SELECT
  s.week_start,
  s.sessions,
  ROUND(100 * s.purchasing_sessions / s.sessions, 2) AS conversion_rate,
  o.orders,
  ROUND(o.revenue, 0) AS revenue,
  ROUND(o.revenue / o.orders, 2) AS avg_order_value
FROM s
LEFT JOIN o USING (week_start)
ORDER BY s.week_start;

-- Results (week starting, visits, conversion, orders, revenue, average order):
-- 2020-11-01  25,453  0.91%  (none)  (none)
-- 2020-11-08  22,458  1.55%    189   $12,836  $67.92
-- 2020-11-15  25,440  1.45%    373   $26,388  $70.75
-- 2020-11-22  27,214  1.82%    513   $37,922  $73.92  (Black Friday)
-- 2020-11-29  31,014  1.93%    618   $44,165  $71.46  (Cyber Monday)
-- 2020-12-06  38,357  1.96%    798   $57,299  $71.80  (peak week)
-- 2020-12-13  33,822  1.76%    712   $49,844  $70.01
-- 2020-12-20  22,694  1.02%    245   $14,740  $60.16
-- 2020-12-27  20,336  0.70%    149   $10,743  $72.10
-- 2021-01-03  28,812  0.56%    160    $9,019  $56.37
-- 2021-01-10  27,721  0.82%    233   $13,473  $57.82
-- 2021-01-17  27,498  1.29%    339   $24,447  $72.12
-- 2021-01-24  26,469  1.24%    137    $7,954  $58.06
-- 2021-01-31   2,841  0.63%  (none)  (none)   (a single day)
--
-- Findings:
-- 1. The season is short and sharp: the four weeks from Nov 22 to
--    Dec 19 bring in $189,230, 61% of all revenue. The peak week
--    (Dec 6) alone made $57,299.
-- 2. It ends abruptly around Dec 20, most likely at the last date for
--    delivery before Christmas: conversion halves that week.
-- 3. January visitors browse but don't buy: visits stay high but
--    conversion falls to 0.56% in the week of Jan 3, a third of the
--    December peak, recovering to about 1.3% by mid January.
--
-- Data note: the week of Nov 1 has 0.91% conversion but no orders with a
-- real order number, and the week of Jan 24 has 137 orders against about
-- 330 purchasing sessions (visits x conversion). The purchases missing
-- order numbers (file 04) are bunched at the start and end of the period.
-- Conversion is reliable for every week; revenue is complete only from
-- mid November to mid January.