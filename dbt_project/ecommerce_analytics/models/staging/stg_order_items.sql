{{
    config(
        materialized='view',
        schema='staging'
    )
}}

-- ============================================================
-- Staging Model: stg_order_items
-- Source: raw_data.raw_order_items
-- Purpose: Clean order item details with prices
-- ============================================================

WITH source_data AS (

    SELECT * FROM {{ source('raw_data', 'raw_order_items') }}

),

cleaned AS (

    SELECT
        -- Composite key (order + item)
        order_id,
        order_item_id,
        
        -- Foreign keys
        product_id,
        seller_id,
        
        -- Dates
        TO_TIMESTAMP(shipping_limit_date) AS shipping_limit_at,
        
        -- Prices (ensure numeric type)
        CAST(price AS DECIMAL(10,2)) AS item_price,
        CAST(freight_value AS DECIMAL(10,2)) AS freight_cost,
        
        -- Calculated field: total cost per item
        CAST(price AS DECIMAL(10,2)) + CAST(freight_value AS DECIMAL(10,2)) AS total_item_cost,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM source_data

)

SELECT * FROM cleaned