with originations as (
    select * from {{ ref('stg_loan_originations') }}
),

final as (
    select distinct
        loan_sequence_number,
        credit_score,
        case
            when credit_score >= 740 then 'Excellent (740+)'
            when credit_score >= 670 then 'Good (670-739)'
            when credit_score >= 580 then 'Fair (580-669)'
            when credit_score is not null then 'Poor (<580)'
            else 'Unknown'
        end as credit_score_band,
        first_time_homebuyer_flag,
        number_of_borrowers,
        original_dti,
        case
            when original_dti <= 36 then 'Low DTI (<=36%)'
            when original_dti <= 43 then 'Moderate DTI (37-43%)'
            when original_dti is not null then 'High DTI (>43%)'
            else 'Unknown'
        end as dti_band
    from originations
)

select * from final
