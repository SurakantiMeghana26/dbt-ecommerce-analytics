{{
    config(
        materialized='table',
        schema='marts'
    )
}}

-- ============================================================
-- Fact Model: fact_orders
-- Grain: ONE ROW PER ORDER
-- Purpose: Order-level facts with foreign keys to dimensions
-- ============================================================

WITH orders AS (

    SELECT * FROM {{ ref('stg_orders') }}

),

order_items_agg AS (

    -- Aggregate items to order level
    SELECT
        order_id,
        COUNT(*) AS total_items,
        SUM(item_price) AS items_total,
        SUM(freight_cost) AS freight_total,
        SUM(total_item_cost) AS order_total
    FROM {{ ref('stg_order_items') }}
    GROUP BY order_id

),

payments_agg AS (

    -- Aggregate payments to order level
    SELECT
        order_id,
        COUNT(*) AS payment_count,
        SUM(payment_value) AS payment_total,
        MAX(payment_installments) AS max_installments
    FROM {{ ref('stg_payments') }}
    GROUP BY order_id

),

customers_dim AS (

    SELECT * FROM {{ ref('dim_customers') }}

),

dates_dim AS (

    SELECT * FROM {{ ref('dim_dates') }}

),

final AS (

    SELECT
        -- Surrogate key for fact
        ROW_NUMBER() OVER (ORDER BY o.order_id) AS order_key,
        
        -- Natural key
        o.order_id,
        
        -- Foreign keys to dimensions
        c.customer_key,
        d.date_key AS order_date_key,
        
        -- Order status
        o.order_status,
        
        -- Dates
        o.order_purchase_at,
        o.order_approved_at,
        o.order_delivered_customer_at,
        o.order_estimated_delivery_at,
        
        -- Delivery metrics
        o.delivery_days,
        o.delivered_on_time,
        
        -- Item-level totals
        COALESCE(oi.total_items, 0) AS total_items,
        COALESCE(oi.items_total, 0) AS items_total,
        COALESCE(oi.freight_total, 0) AS freight_total,
        COALESCE(oi.order_total, 0) AS order_total,
        
        -- Payment info
        COALESCE(p.payment_count, 0) AS payment_count,
        COALESCE(p.payment_total, 0) AS payment_total,
        COALESCE(p.max_installments, 1) AS max_installments,
        
        -- Order size segmentation
        CASE
            WHEN COALESCE(oi.order_total, 0) >= 500 THEN 'Large'
            WHEN COALESCE(oi.order_total, 0) >= 100 THEN 'Medium'
            WHEN COALESCE(oi.order_total, 0) >= 0 THEN 'Small'
            ELSE 'No Amount'
        END AS order_size,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM orders o
    LEFT JOIN order_items_agg oi ON o.order_id = oi.order_id
    LEFT JOIN payments_agg p ON o.order_id = p.order_id
    LEFT JOIN customers_dim c ON o.customer_id = c.customer_id
    LEFT JOIN dates_dim d ON DATE(o.order_purchase_at) = d.date

)

SELECT * FROM final