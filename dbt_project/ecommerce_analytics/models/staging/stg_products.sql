{{
    config(
        materialized='view',
        schema='staging'
    )
}}

-- ============================================================
-- Staging Model: stg_products
-- Source: raw_data.raw_products
-- Purpose: Clean product catalog data
-- ============================================================

WITH source_data AS (

    SELECT * FROM {{ source('raw_data', 'raw_products') }}

),

cleaned AS (

    SELECT
        -- Primary key
        product_id,
        
        -- Category (clean nulls)
        COALESCE(LOWER(TRIM(product_category_name)), 'unknown') AS product_category,
        
        -- Product description metrics
        product_name_lenght AS name_length,
        product_description_lenght AS description_length,
        product_photos_qty AS photo_count,
        
        -- Physical dimensions
        product_weight_g AS weight_grams,
        product_length_cm AS length_cm,
        product_height_cm AS height_cm,
        product_width_cm AS width_cm,
        
        -- Calculated: volume in cubic centimeters
        product_length_cm * product_height_cm * product_width_cm AS volume_cm3,
        
        -- Categorize product size
        CASE
            WHEN product_weight_g IS NULL THEN 'Unknown'
            WHEN product_weight_g < 500 THEN 'Small'
            WHEN product_weight_g < 2000 THEN 'Medium'
            WHEN product_weight_g < 10000 THEN 'Large'
            ELSE 'Extra Large'
        END AS size_category,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM source_data

)

SELECT * FROM cleaned