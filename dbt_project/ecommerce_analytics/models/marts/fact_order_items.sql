{{
    config(
        materialized='table',
        schema='marts'
    )
}}

-- ============================================================
-- Fact Model: fact_order_items
-- Grain: ONE ROW PER ITEM IN AN ORDER
-- Purpose: Item-level facts connecting all dimensions
-- ============================================================

WITH order_items AS (

    SELECT * FROM {{ ref('stg_order_items') }}

),

orders AS (

    SELECT * FROM {{ ref('stg_orders') }}

),

products_dim AS (

    SELECT * FROM {{ ref('dim_products') }}

),

sellers_dim AS (

    SELECT * FROM {{ ref('dim_sellers') }}

),

customers_dim AS (

    SELECT * FROM {{ ref('dim_customers') }}

),

dates_dim AS (

    SELECT * FROM {{ ref('dim_dates') }}

),

orders_fact AS (

    SELECT * FROM {{ ref('fact_orders') }}

),

final AS (

    SELECT
        -- Surrogate key for item
        ROW_NUMBER() OVER (ORDER BY oi.order_id, oi.order_item_id) AS order_item_key,
        
        -- Natural keys
        oi.order_id,
        oi.order_item_id,
        
        -- Foreign keys to dimensions
        p.product_key,
        s.seller_key,
        c.customer_key,
        d.date_key AS order_date_key,
        f.order_key,
        
        -- Item details
        oi.shipping_limit_at,
        
        -- Financial metrics
        oi.item_price,
        oi.freight_cost,
        oi.total_item_cost,
        
        -- Calculated: freight as % of item price
        CASE
            WHEN oi.item_price > 0 THEN 
                ROUND((oi.freight_cost / oi.item_price) * 100, 2)
            ELSE 0
        END AS freight_pct_of_price,
        
        -- Price tier
        CASE
            WHEN oi.item_price >= 500 THEN 'Premium'
            WHEN oi.item_price >= 100 THEN 'High'
            WHEN oi.item_price >= 50 THEN 'Medium'
            WHEN oi.item_price > 0 THEN 'Low'
            ELSE 'Free'
        END AS price_tier,
        
        -- Has high freight?
        CASE
            WHEN oi.freight_cost > oi.item_price * 0.5 THEN TRUE
            ELSE FALSE
        END AS high_freight_flag,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM order_items oi
    LEFT JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN products_dim p ON oi.product_id = p.product_id
    LEFT JOIN sellers_dim s ON oi.seller_id = s.seller_id
    LEFT JOIN customers_dim c ON o.customer_id = c.customer_id
    LEFT JOIN dates_dim d ON DATE(o.order_purchase_at) = d.date
    LEFT JOIN orders_fact f ON oi.order_id = f.order_id

)

SELECT * FROM final