{{
    config(
        materialized='view',
        schema='staging'
    )
}}

-- ============================================================
-- Staging Model: stg_reviews
-- Source: raw_data.raw_reviews
-- Purpose: Clean customer review data
-- ============================================================

WITH source_data AS (

    SELECT * FROM {{ source('raw_data', 'raw_reviews') }}

),

cleaned AS (

    SELECT
        -- Primary key
        review_id,
        
        -- Foreign key
        order_id,
        
        -- Review score (1-5)
        review_score,
        
        -- Review text fields (clean nulls)
        COALESCE(review_comment_title, 'No Title') AS review_title,
        COALESCE(review_comment_message, 'No Comment') AS review_comment,
        
        -- Dates
        TO_TIMESTAMP(review_creation_date) AS review_created_at,
        TO_TIMESTAMP(review_answer_timestamp) AS review_answered_at,
        
        -- Days to answer review
        DATEDIFF('day',
            review_creation_date,
            review_answer_timestamp
        ) AS days_to_answer,
        
        -- Categorize review sentiment
        CASE
            WHEN review_score >= 4 THEN 'Positive'
            WHEN review_score = 3 THEN 'Neutral'
            WHEN review_score <= 2 THEN 'Negative'
        END AS sentiment,
        
        -- Was review answered?
        CASE
            WHEN review_answer_timestamp IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS is_answered,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM source_data

)

SELECT * FROM cleaned