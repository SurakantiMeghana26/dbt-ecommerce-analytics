{{
    config(
        materialized='view',
        schema='staging'
    )
}}

-- ============================================================
-- Staging Model: stg_customers
-- Source: raw_data.raw_customers
-- Purpose: Clean and standardize customer data
-- ============================================================

WITH source_data AS (

    SELECT * FROM {{ source('raw_data', 'raw_customers') }}

),

cleaned AS (

    SELECT
        -- Primary key
        customer_id,
        
        -- Unique key (from Olist - their internal customer ID)
        customer_unique_id,
        
        -- Location info
        UPPER(TRIM(customer_city)) AS customer_city,
        UPPER(TRIM(customer_state)) AS customer_state,
        customer_zip_code_prefix AS customer_zip_code,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM source_data

)

SELECT * FROM cleaned