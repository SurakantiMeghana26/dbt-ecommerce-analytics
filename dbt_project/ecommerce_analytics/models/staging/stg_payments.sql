{{
    config(
        materialized='view',
        schema='staging'
    )
}}

-- ============================================================
-- Staging Model: stg_payments
-- Source: raw_data.raw_payments
-- Purpose: Clean payment information
-- ============================================================

WITH source_data AS (

    SELECT * FROM {{ source('raw_data', 'raw_payments') }}

),

cleaned AS (

    SELECT
        -- Foreign key
        order_id,
        
        -- Payment sequence (if multiple payments per order)
        payment_sequential,
        
        -- Payment type (standardize)
        UPPER(payment_type) AS payment_type,
        
        -- Number of installments
        payment_installments,
        
        -- Payment value (ensure decimal type)
        CAST(payment_value AS DECIMAL(10,2)) AS payment_value,
        
        -- Categorize payment method
        CASE
            WHEN UPPER(payment_type) = 'CREDIT_CARD' THEN 'Card'
            WHEN UPPER(payment_type) = 'DEBIT_CARD' THEN 'Card'
            WHEN UPPER(payment_type) = 'BOLETO' THEN 'Bank Slip'
            WHEN UPPER(payment_type) = 'VOUCHER' THEN 'Voucher'
            ELSE 'Other'
        END AS payment_category,
        
        -- Was this an installment payment?
        CASE
            WHEN payment_installments > 1 THEN TRUE
            ELSE FALSE
        END AS is_installment,
        
        -- Metadata
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM source_data

)

SELECT * FROM cleaned