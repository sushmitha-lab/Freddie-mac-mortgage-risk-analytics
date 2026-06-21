with originations as (
    select * from {{ ref('stg_loan_originations') }}
),

final as (
    select distinct
        loan_sequence_number,
        loan_purpose,
        case loan_purpose
            when 'P' then 'Purchase'
            when 'C' then 'Cash-Out Refinance'
            when 'N' then 'No Cash-Out Refinance'
            when 'R' then 'Refinance (Not Specified)'
            else 'Unknown'
        end as loan_purpose_description,
        amortization_type,
        property_type,
        case property_type
            when 'SF' then 'Single Family'
            when 'PU' then 'PUD'
            when 'CO' then 'Condo'
            when 'CP' then 'Co-op'
            when 'MH' then 'Manufactured Housing'
            else 'Unknown'
        end as property_type_description,
        occupancy_status,
        case occupancy_status
            when 'P' then 'Primary Residence'
            when 'S' then 'Second Home'
            when 'I' then 'Investment Property'
            else 'Unknown'
        end as occupancy_status_description,
        channel,
        case channel
            when 'R' then 'Retail'
            when 'B' then 'Broker'
            when 'C' then 'Correspondent'
            when 'T' then 'Third Party Originator (Not Specified)'
            else 'Unknown'
        end as channel_description,
        property_state,
        original_loan_term,
        interest_only_indicator
    from originations
)

select * from final
