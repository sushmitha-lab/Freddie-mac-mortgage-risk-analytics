with svcg_2018 as (
    select * from {{ source('raw', 'RAW_SVCG_2018') }}
),

svcg_2019 as (
    select * from {{ source('raw', 'RAW_SVCG_2019') }}
),

svcg_2020 as (
    select * from {{ source('raw', 'RAW_SVCG_2020') }}
),

unioned as (
    select * from svcg_2018
    union all
    select * from svcg_2019
    union all
    select * from svcg_2020
),

cleaned as (
    select
        loan_sequence_number,
        try_to_date(monthly_reporting_period, 'YYYYMM')   as monthly_reporting_period,
        try_to_number(current_actual_upb)                  as current_actual_upb,
        current_loan_delinquency_status,
        try_to_number(loan_age)                             as loan_age,
        try_to_number(remaining_months_to_maturity)         as remaining_months_to_maturity,
        try_to_date(defect_settlement_date, 'YYYYMM')       as defect_settlement_date,
        modification_flag,
        try_to_number(zero_balance_code)                    as zero_balance_code,
        try_to_date(zero_balance_effective_date, 'YYYYMM')  as zero_balance_effective_date,
        try_to_number(current_interest_rate)                as current_interest_rate,
        try_to_number(current_deferred_upb)                 as current_deferred_upb,
        try_to_date(ddlpi, 'YYYYMM')                         as ddlpi,
        try_to_number(mi_recoveries)                         as mi_recoveries,
        net_sales_proceeds,
        try_to_number(non_mi_recoveries)                    as non_mi_recoveries,
        try_to_number(expenses)                              as expenses,
        try_to_number(legal_costs)                           as legal_costs,
        try_to_number(maintenance_preservation_costs)       as maintenance_preservation_costs,
        try_to_number(taxes_and_insurance)                  as taxes_and_insurance,
        try_to_number(miscellaneous_expenses)               as miscellaneous_expenses,
        try_to_number(actual_loss_calculation)              as actual_loss_calculation,
        try_to_number(modification_cost)                    as modification_cost,
        step_modification_flag,
        deferred_payment_plan,
        try_to_number(estimated_ltv)                         as estimated_ltv,
        try_to_number(zero_balance_removal_upb)             as zero_balance_removal_upb,
        try_to_number(delinquent_accrued_interest)          as delinquent_accrued_interest,
        delinquency_due_to_disaster,
        borrower_assistance_status_code,
        try_to_number(current_month_modification_cost)     as current_month_modification_cost,
        try_to_number(interest_bearing_upb)                 as interest_bearing_upb
    from unioned
)

select * from cleaned
