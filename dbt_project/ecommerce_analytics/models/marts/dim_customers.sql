{{
    config(
        materialized='table',
        schema='marts'
    )
}}

-- ============================================================
-- Mart Model: dim_customers
-- Purpose: Customer dimension table with calculated metrics
-- Joins: stg_customers + stg_orders for customer behavior
-- ============================================================

WITH customers AS (

    SELECT * FROM {{ ref('stg_customers') }}

),

customer_orders AS (

    -- Calculate metrics per customer
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders,
        MIN(order_purchase_at) AS first_order_at,
        MAX(order_purchase_at) AS last_order_at
    FROM {{ ref('stg_orders') }}
    GROUP BY customer_id

),

final AS (

    SELECT
        -- Surrogate key (auto-generated)
        ROW_NUMBER() OVER (ORDER BY c.customer_id) AS customer_key,
        
        -- Natural keys
        c.customer_id,
        c.customer_unique_id,
        
        -- Customer attributes
        c.customer_city,
        c.customer_state,
        c.customer_zip_code,
        
        -- Customer metrics (from joined orders)
        COALESCE(co.total_orders, 0) AS total_orders,
        co.first_order_at,
        co.last_order_at,
        
        -- Customer segmentation (business logic!)
        CASE
            WHEN co.total_orders >= 5 THEN 'VIP'
            WHEN co.total_orders >= 2 THEN 'Repeat'
            WHEN co.total_orders = 1 THEN 'One-time'
            ELSE 'No Orders'
        END AS customer_segment,
        
        -- Days since last order (recency!)
        DATEDIFF('day', co.last_order_at, CURRENT_TIMESTAMP()) AS days_since_last_order,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM customers c
    LEFT JOIN customer_orders co ON c.customer_id = co.customer_id

)

SELECT * FROM final