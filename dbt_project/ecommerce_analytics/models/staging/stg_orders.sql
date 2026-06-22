{{
    config(
        materialized='view',
        schema='staging'
    )
}}

-- ============================================================
-- Staging Model: stg_orders
-- Source: raw_data.raw_orders
-- Purpose: Clean order data with proper data types
-- ============================================================

WITH source_data AS (

    SELECT * FROM {{ source('raw_data', 'raw_orders') }}

),

cleaned AS (

    SELECT
        -- Primary key
        order_id,
        
        -- Foreign key
        customer_id,
        
        -- Order status (standardize to uppercase)
        UPPER(order_status) AS order_status,
        
        -- Convert string timestamps to proper timestamp type
        TO_TIMESTAMP(order_purchase_timestamp) AS order_purchase_at,
        TO_TIMESTAMP(order_approved_at) AS order_approved_at,
        TO_TIMESTAMP(order_delivered_carrier_date) AS order_delivered_carrier_at,
        TO_TIMESTAMP(order_delivered_customer_date) AS order_delivered_customer_at,
        TO_TIMESTAMP(order_estimated_delivery_date) AS order_estimated_delivery_at,
        
        -- Calculate delivery time in days
        DATEDIFF('day', 
            order_purchase_timestamp, 
            order_delivered_customer_date
        ) AS delivery_days,
        
        -- Was delivery on time? (delivered before estimated date)
        CASE
            WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN TRUE
            WHEN order_delivered_customer_date IS NULL THEN NULL
            ELSE FALSE
        END AS delivered_on_time,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM source_data

)

SELECT * FROM cleaned