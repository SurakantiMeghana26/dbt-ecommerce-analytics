{{
    config(
        materialized='view',
        schema='staging'
    )
}}

-- ============================================================
-- Staging Model: stg_category_translations
-- Source: raw_data.raw_category_translations
-- Purpose: Map Portuguese category names to English
-- ============================================================

WITH source_data AS (

    SELECT * FROM {{ source('raw_data', 'raw_category_translations') }}

),

cleaned AS (

    SELECT
        -- Portuguese name (key)
        LOWER(TRIM(product_category_name)) AS category_name_pt,
        
        -- English translation
        LOWER(TRIM(product_category_name_english)) AS category_name_en,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM source_data

)

SELECT * FROM cleaned