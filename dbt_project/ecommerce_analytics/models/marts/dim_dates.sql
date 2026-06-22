{{
    config(
        materialized='table',
        schema='marts'
    )
}}

-- ============================================================
-- Mart Model: dim_dates
-- Purpose: Date dimension for time-based analysis
-- Generates: All dates from 2016-01-01 to 2026-12-31
-- ============================================================

WITH date_spine AS (

    -- Generate a sequence of dates
    SELECT 
        DATEADD('day', SEQ4(), '2016-01-01'::DATE) AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 4018))  -- ~11 years of days

),

final AS (

    SELECT
        -- Surrogate key (YYYYMMDD as integer)
        TO_NUMBER(TO_CHAR(date_day, 'YYYYMMDD')) AS date_key,
        
        -- The actual date
        date_day AS date,
        
        -- Year info
        YEAR(date_day) AS year,
        QUARTER(date_day) AS quarter,
        MONTH(date_day) AS month,
        WEEK(date_day) AS week_of_year,
        DAY(date_day) AS day_of_month,
        DAYOFWEEK(date_day) AS day_of_week,
        DAYOFYEAR(date_day) AS day_of_year,
        
        -- Names
        MONTHNAME(date_day) AS month_name,
        DAYNAME(date_day) AS day_name,
        
        -- Quarter info
        'Q' || QUARTER(date_day) AS quarter_name,
        
        -- Weekend flag
        CASE
            WHEN DAYOFWEEK(date_day) IN (0, 6) THEN TRUE
            ELSE FALSE
        END AS is_weekend,
        
        -- Weekday flag
        CASE
            WHEN DAYOFWEEK(date_day) IN (1, 2, 3, 4, 5) THEN TRUE
            ELSE FALSE
        END AS is_weekday,
        
        -- Month start/end flags
        CASE
            WHEN day_of_month = 1 THEN TRUE
            ELSE FALSE
        END AS is_month_start,
        
        CASE
            WHEN LAST_DAY(date_day) = date_day THEN TRUE
            ELSE FALSE
        END AS is_month_end,
        
        -- First/Last day of year
        CASE
            WHEN MONTH(date_day) = 1 AND DAY(date_day) = 1 THEN TRUE
            ELSE FALSE
        END AS is_year_start,
        
        CASE
            WHEN MONTH(date_day) = 12 AND DAY(date_day) = 31 THEN TRUE
            ELSE FALSE
        END AS is_year_end,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM date_spine

)

SELECT * FROM final
ORDER BY date