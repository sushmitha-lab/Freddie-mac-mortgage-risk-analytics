with originations as (
    select * from {{ ref('stg_loan_originations') }}
),

final as (
    select
        loan_sequence_number,
        first_payment_date,
        maturity_date,
        original_upb,
        original_interest_rate,
        original_ltv,
        original_cltv,
        original_dti,
        original_loan_term,
        mi_percent,
        number_of_units,
        super_conforming_flag,
        harp_indicator,
        program_indicator
    from originations
)

select * from final
