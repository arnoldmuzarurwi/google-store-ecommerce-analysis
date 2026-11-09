-- 08: Do product IDs line up across events?
-- Purpose: check whether a product has the same ID when viewed and
-- when bought, so views and purchases can be compared per product.

WITH viewed AS (
  SELECT DISTINCT item_id, item_name
  FROM `gstore-analysis-muzarurwi.gstore.items_flat`
  WHERE event_name = 'view_item'
),
bought AS (
  SELECT DISTINCT item_id, item_name
  FROM `gstore-analysis-muzarurwi.gstore.items_flat`
  WHERE event_name = 'purchase'
)
SELECT
  (SELECT COUNT(DISTINCT item_id) FROM viewed) AS viewed_ids,
  (SELECT COUNT(DISTINCT item_id) FROM bought) AS bought_ids,
  (SELECT COUNT(DISTINCT item_id) FROM bought
     WHERE item_id IN (SELECT item_id FROM viewed)) AS bought_ids_also_viewed,
  (SELECT COUNT(DISTINCT item_name) FROM viewed) AS viewed_names,
  (SELECT COUNT(DISTINCT item_name) FROM bought) AS bought_names,
  (SELECT COUNT(DISTINCT item_name) FROM bought
     WHERE item_name IN (SELECT item_name FROM viewed)) AS bought_names_also_viewed;

-- Results: 427 viewed IDs, 810 bought IDs, only 5 bought IDs also viewed.
-- 422 viewed names, 396 bought names, 388 bought names also viewed (98%).
-- Purchases carry about two IDs per product name, so IDs were scrambled
-- differently across events while names were left intact.
-- Decision: identify products by item_name, not item_id, whenever
-- products are compared across funnel steps.