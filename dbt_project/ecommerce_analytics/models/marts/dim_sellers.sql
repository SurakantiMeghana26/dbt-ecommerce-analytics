{{
    config(
        materialized='table',
        schema='marts'
    )
}}

-- ============================================================
-- Mart Model: dim_sellers
-- Purpose: Seller dimension with sales metrics
-- Joins: stg_sellers + stg_order_items for metrics
-- ============================================================

WITH sellers AS (

    SELECT * FROM {{ ref('stg_sellers') }}

),

seller_metrics AS (

    -- Calculate sales metrics per seller
    SELECT
        seller_id,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(*) AS total_items_sold,
        SUM(item_price) AS total_revenue,
        AVG(item_price) AS avg_item_price
    FROM {{ ref('stg_order_items') }}
    GROUP BY seller_id

),

final AS (

    SELECT
        -- Surrogate key
        ROW_NUMBER() OVER (ORDER BY s.seller_id) AS seller_key,
        
        -- Natural key
        s.seller_id,
        
        -- Location info
        s.seller_city,
        s.seller_state,
        s.seller_zip_code,
        
        -- Sales metrics (from JOIN)
        COALESCE(sm.total_orders, 0) AS total_orders,
        COALESCE(sm.total_items_sold, 0) AS total_items_sold,
        COALESCE(sm.total_revenue, 0) AS total_revenue,
        COALESCE(sm.avg_item_price, 0) AS avg_item_price,
        
        -- Seller segmentation
        CASE
            WHEN sm.total_revenue >= 100000 THEN 'Top Seller'
            WHEN sm.total_revenue >= 10000 THEN 'High Seller'
            WHEN sm.total_revenue >= 1000 THEN 'Medium Seller'
            WHEN sm.total_revenue > 0 THEN 'Low Seller'
            ELSE 'No Sales'
        END AS seller_tier,
        
        -- Is active?
        CASE
            WHEN sm.total_orders > 0 THEN TRUE
            ELSE FALSE
        END AS is_active,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM sellers s
    LEFT JOIN seller_metrics sm 
        ON s.seller_id = sm.seller_id

)

SELECT * FROM final