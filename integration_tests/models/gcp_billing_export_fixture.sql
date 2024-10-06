{{
   config(
    materialized='table',
    tags=['fixtures'],
    )
}}
SELECT
  "123456-789012-345678" AS billing_account_id,  -- String
  STRUCT("202409" AS month) AS invoice,  -- Struct for invoice with a month field (String)
  "regular" AS cost_type,  -- String
  STRUCT("6F81-5844-5657" AS id, "Compute Engine" AS description) AS service,  -- Struct for service with id and description
  STRUCT("D29-4578" AS id, "N1-Standard-1" AS description) AS sku,  -- Struct for sku with id and description
  TIMESTAMP("2024-09-01 00:00:00 UTC") AS usage_start_time,  -- Timestamp
  TIMESTAMP("2024-09-30 23:59:59 UTC") AS usage_end_time,  -- Timestamp
  STRUCT("my_project" AS id, "876543210" AS number, "My Project" AS name, "/123456789/987654321/" AS ancestry_numbers) AS project,  -- Struct for project
  [STRUCT("env" AS key, "production" AS value)] AS labels,  -- Array of Struct for labels
  [STRUCT("machine_type" AS key, "n1-standard-1" AS value)] AS system_labels,  -- Array of Struct for system_labels
  STRUCT("us-central1" AS location, "US" AS country, "us-central1" AS region, "us-central1-a" AS zone) AS location,  -- Struct for location details
  100.50 AS cost,  -- Float
  "USD" AS currency,  -- String
  1.0 AS currency_conversion_rate,  -- Float
  STRUCT(150.75 AS amount, "byte-seconds" AS unit, 150.75 AS amount_in_pricing_units, "byte-seconds" AS pricing_unit) AS usage,  -- Struct for usage with units and amount
  [STRUCT("123456" AS id, "Sustained Use Discount" AS full_name, "COMMITTED_USAGE_DISCOUNT" AS type, -10.25 AS amount)] AS credits,  -- Array of Struct for credits
  STRUCT("98765" AS id, "Correction due to incorrect usage" AS description, "USAGE_CORRECTION" AS type, "COMPLETE_NEGATION" AS mode) AS adjustment_info,  -- Struct for adjustment_info
  TIMESTAMP("2024-10-01 12:00:00 UTC") AS export_time,  -- Timestamp
  [STRUCT("owner" AS key, "john.doe" AS value, FALSE AS inherited, "organization/tag1" AS namespace)] AS tags,  -- Array of Struct for tags
  120.00 AS cost_at_list,  -- Float
  "GOOGLE" AS transaction_type,  -- String for transaction type
  "Google LLC" AS seller_name  -- String for seller name

UNION ALL

SELECT
  "234567-890123-456789" AS billing_account_id,
  STRUCT("202409" AS month) AS invoice,
  "promo" AS cost_type,
  STRUCT("7H93-8472-7854" AS id, "BigQuery" AS description) AS service,
  STRUCT("E78-6543" AS id, "Analysis" AS description) AS sku,
  TIMESTAMP("2024-09-15 00:00:00 UTC") AS usage_start_time,
  TIMESTAMP("2024-09-15 23:59:59 UTC") AS usage_end_time,
  STRUCT("another_project" AS id, "123456789" AS number, "Another Project" AS name, "/234567890/123456789/" AS ancestry_numbers) AS project,
  [STRUCT("env" AS key, "development" AS value)] AS labels,
  [STRUCT("priority" AS key, "high" AS value)] AS system_labels,
  STRUCT("europe-west1" AS location, "EU" AS country, "europe-west1" AS region, NULL AS zone) AS location,
  50.75 AS cost,
  "USD" AS currency,
  1.2 AS currency_conversion_rate,
  STRUCT(100.25 AS amount, "byte-seconds" AS unit, 100.25 AS amount_in_pricing_units, "byte-seconds" AS pricing_unit) AS usage,
  [STRUCT("654321" AS id, "Promotional Credit" AS full_name, "PROMOTION" AS type, -5.75 AS amount)] AS credits,
  STRUCT("54321" AS id, "Correction for incorrect pricing" AS description, "PRICE_CORRECTION" AS type, "PARTIAL_CORRECTION" AS mode) AS adjustment_info,
  TIMESTAMP("2024-10-02 08:30:00 UTC") AS export_time,
  [STRUCT("owner" AS key, "jane.smith" AS value, TRUE AS inherited, "organization/tag2" AS namespace)] AS tags,
  60.00 AS cost_at_list,
  "GOOGLE" AS transaction_type,
  "Google LLC" AS seller_name

UNION ALL

SELECT
  "234567-890123-456789" AS billing_account_id,
  STRUCT("202409" AS month) AS invoice,
  "promo" AS cost_type,
  STRUCT("7H93-8472-7854" AS id, "BigQuery" AS description) AS service,
  STRUCT("E78-6543" AS id, "Physical Storage" AS description) AS sku,
  TIMESTAMP("2024-09-15 00:00:00 UTC") AS usage_start_time,
  TIMESTAMP("2024-09-15 23:59:59 UTC") AS usage_end_time,
  STRUCT("another_project" AS id, "123456789" AS number, "Another Project" AS name, "/234567890/123456789/" AS ancestry_numbers) AS project,
  [STRUCT("env" AS key, "development" AS value)] AS labels,
  [STRUCT("priority" AS key, "high" AS value)] AS system_labels,
  STRUCT("europe-west1" AS location, "EU" AS country, "europe-west1" AS region, NULL AS zone) AS location,
  50.75 AS cost,
  "USD" AS currency,
  1.2 AS currency_conversion_rate,
  STRUCT(100.25 AS amount, "byte-seconds" AS unit, 100.25 AS amount_in_pricing_units, "byte-seconds" AS pricing_unit) AS usage,
  [STRUCT("654321" AS id, "Promotional Credit" AS full_name, "PROMOTION" AS type, -5.75 AS amount)] AS credits,
  STRUCT("54321" AS id, "Correction for incorrect pricing" AS description, "PRICE_CORRECTION" AS type, "PARTIAL_CORRECTION" AS mode) AS adjustment_info,
  TIMESTAMP("2024-10-02 08:30:00 UTC") AS export_time,
  [STRUCT("owner" AS key, "jane.smith" AS value, TRUE AS inherited, "organization/tag2" AS namespace)] AS tags,
  60.00 AS cost_at_list,
  "GOOGLE" AS transaction_type,
  "Google LLC" AS seller_name
