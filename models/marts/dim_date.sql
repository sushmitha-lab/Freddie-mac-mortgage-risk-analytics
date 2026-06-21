with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="to_date('1999-01-01')",
        end_date="to_date('2026-12-31')"
    ) }}
),

final as (
    select
        date_day,
        year(date_day)                          as year_number,
        month(date_day)                          as month_number,
        day(date_day)                            as day_number,
        quarter(date_day)                        as quarter_number,
        date_trunc('month', date_day)            as month_start_date,
        date_trunc('quarter', date_day)          as quarter_start_date,
        dayname(date_day)                        as day_name,
        monthname(date_day)                      as month_name
    from date_spine
)

select * from final
