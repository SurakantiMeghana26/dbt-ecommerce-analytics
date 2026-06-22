{{
    config(
        materialized='table',
        schema='marts'
    )
}}

-- ============================================================
-- Mart Model: dim_products
-- Purpose: Product dimension with English category names
-- Joins: stg_products + stg_category_translations
-- ============================================================

WITH products AS (

    SELECT * FROM {{ ref('stg_products') }}

),

categories AS (

    SELECT * FROM {{ ref('stg_category_translations') }}

),

final AS (

    SELECT
        -- Surrogate key
        ROW_NUMBER() OVER (ORDER BY p.product_id) AS product_key,
        
        -- Natural key
        p.product_id,
        
        -- Category (Portuguese + English translation)
        p.product_category AS category_pt,
        COALESCE(c.category_name_en, 'unknown') AS category_en,
        
        -- Product metrics
        p.name_length,
        p.description_length,
        p.photo_count,
        
        -- Physical attributes
        p.weight_grams,
        p.length_cm,
        p.height_cm,
        p.width_cm,
        p.volume_cm3,
        p.size_category,
        
        -- Description quality score
        CASE
            WHEN p.description_length IS NULL THEN 'No Description'
            WHEN p.description_length < 100 THEN 'Poor'
            WHEN p.description_length < 500 THEN 'Average'
            WHEN p.description_length < 1500 THEN 'Good'
            ELSE 'Excellent'
        END AS description_quality,
        
        -- Has photos?
        CASE
            WHEN p.photo_count > 0 THEN TRUE
            ELSE FALSE
        END AS has_photos,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM products p
    LEFT JOIN categories c 
        ON p.product_category = c.category_name_pt

)

SELECT * FROM final