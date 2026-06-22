{{
    config(
        materialized='view',
        schema='staging'
    )
}}

-- ============================================================
-- Staging Model: stg_sellers
-- Source: raw_data.raw_sellers
-- Purpose: Clean seller information
-- ============================================================

WITH source_data AS (

    SELECT * FROM {{ source('raw_data', 'raw_sellers') }}

),

cleaned AS (

    SELECT
        -- Primary key
        seller_id,
        
        -- Location info (cleaned and uppercased)
        UPPER(TRIM(seller_city)) AS seller_city,
        UPPER(TRIM(seller_state)) AS seller_state,
        seller_zip_code_prefix AS seller_zip_code,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM source_data

)

SELECT * FROM cleaned