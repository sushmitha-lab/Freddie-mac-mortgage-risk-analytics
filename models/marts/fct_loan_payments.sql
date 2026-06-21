with performance as (
    select * from {{ ref('stg_loan_performance') }}
),

flagged as (
    select
        loan_sequence_number,
        monthly_reporting_period,
        current_actual_upb,
        current_loan_delinquency_status,
        loan_age,
        remaining_months_to_maturity,
        current_interest_rate,
        modification_flag,
        zero_balance_code,
        zero_balance_effective_date,

        -- Delinquency status as a clean number where possible (R = REO, stays as flag)
        case
            when current_loan_delinquency_status = 'R' then null
            else try_to_number(current_loan_delinquency_status)
        end as delinquency_months,

        -- Is this loan severely delinquent this month? (90+ days / 3+ months past due)
        case
            when current_loan_delinquency_status = 'R' then true
            when try_to_number(current_loan_delinquency_status) >= 3 then true
            else false
        end as is_severely_delinquent,

        -- Zero balance code meanings (per Freddie Mac documentation)
        case zero_balance_code
            when 1 then 'Prepaid or Matured'
            when 2 then 'Third Party Sale'
            when 3 then 'Short Sale/Charge-off'
            when 6 then 'Repurchased'
            when 9 then 'REO Disposition'
            when 15 then 'Non-Performing/Reperforming'
            when 16 then 'Reperforming Loan Removal'
            else null
        end as zero_balance_description,

        -- Did this loan exit due to a loss event? (codes 3 and 9 indicate loss)
        case
            when zero_balance_code in (3, 9) then true
            else false
        end as is_loss_event

    from performance
),

final as (
    select
        *,
        -- Default = earliest of: first severe delinquency OR a loss event
        -- (standard credit risk industry definition)
        case
            when is_severely_delinquent or is_loss_event then true
            else false
        end as is_default_event
    from flagged
)

select * from final
