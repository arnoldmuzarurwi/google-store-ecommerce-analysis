# Data Quality Notes

Dataset: Google Analytics 4 sample data from the Google Merchandise Store
(bigquery-public-data.ga4_obfuscated_sample_ecommerce), covering
November 1, 2020 to January 31, 2021.

Google obfuscated (scrambled or hid) parts of this dataset before making it
public, so some values are placeholders. The checks below find those issues
and set rules for handling them. Each check has its own file in the sql folder.

## Checks

| File | What it checks | Main finding |
|---|---|---|
| 01_dataset_overview.sql | Size of the dataset | 4.3M events, 270K users, 360K sessions over 92 days |
| 02_event_types.sql | Which events exist | All funnel steps are present, plus two extra checkout steps |
| 03_missing_and_placeholder_values.sql | Missing or hidden values | Device, session and country fields are clean; traffic source fields are 21 to 34% hidden |
| 04_purchase_revenue_check.sql | Purchase money problems | Duplicate order copies, 906 purchases with no real order number, 450 purchases at $0 |
| 05_conflicting_order_amounts.sql | Orders with two different amounts | 15 order numbers shared by two separate sales |

## Purchase findings

* 5,692 purchase events in total, worth $362,165.
* 4,786 have a real order number and carry 91% of revenue.
* 335 of those are repeat copies of the same order with the same amount,
  most likely from the confirmation page being reloaded.
* 15 order numbers appear with two very different amounts logged days or
  weeks apart. These are treated as separate sales that share a number.
* 883 purchases have the placeholder (not set) as their order number,
  including all 450 of the $0 purchases.
* 23 purchases have no order number at all.

## Rules used in this project

1. **Revenue and order analysis** (sales totals, average order value,
   product performance) uses only purchases with a real order number,
   counting each order number and amount combination once. This gives
   4,466 orders.
2. **Funnel and retention analysis** (did a visitor buy or not) uses every
   purchase event, since a hidden order number does not change the fact that
   a purchase happened.
3. Purchases with a (not set) or empty order number ($31,817, about 9% of raw
   revenue) are left out of revenue totals because repeats cannot be told
   apart from new orders, and half of them show $0.
4. Traffic source results are reported with a note that 21 to 34% of values
   are hidden by Google.