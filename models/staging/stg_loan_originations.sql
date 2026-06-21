with orig_2018 as (
    select * from {{ source('raw', 'RAW_ORIG_2018') }}
),

orig_2019 as (
    select * from {{ source('raw', 'RAW_ORIG_2019') }}
),

orig_2020 as (
    select * from {{ source('raw', 'RAW_ORIG_2020') }}
),

unioned as (
    select * from orig_2018
    union all
    select * from orig_2019
    union all
    select * from orig_2020
),

cleaned as (
    select
        loan_sequence_number,
        try_to_number(credit_score)                  as credit_score,
        try_to_date(first_payment_date, 'YYYYMM')     as first_payment_date,
        first_time_homebuyer_flag,
        try_to_date(maturity_date, 'YYYYMM')          as maturity_date,
        msa_or_metro_division,
        try_to_number(mi_percent)                     as mi_percent,
        try_to_number(number_of_units)                as number_of_units,
        occupancy_status,
        try_to_number(original_cltv)                  as original_cltv,
        try_to_number(original_dti)                   as original_dti,
        try_to_number(original_upb)                   as original_upb,
        try_to_number(original_ltv)                   as original_ltv,
        try_to_number(original_interest_rate)         as original_interest_rate,
        channel,
        ppm_flag,
        amortization_type,
        property_state,
        property_type,
        postal_code,
        loan_purpose,
        try_to_number(original_loan_term)             as original_loan_term,
        try_to_number(number_of_borrowers)             as number_of_borrowers,
        seller_name,
        servicer_name,
        super_conforming_flag,
        pre_harp_loan_sequence_number,
        program_indicator,
        harp_indicator,
        property_valuation_method,
        interest_only_indicator,
        mi_cancellation_indicator
    from unioned
)

select * from cleaned
