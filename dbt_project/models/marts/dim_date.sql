with distinct_dates as (
    select distinct order_date::date as full_date
    from {{ ref('stg_orders') }}
)

select
    to_char(full_date, 'YYYYMMDD')::int as date_key,
    full_date,
    extract(day from full_date)::int as day,
    extract(month from full_date)::int as month,
    to_char(full_date, 'FMMonth') as month_name,
    extract(quarter from full_date)::int as quarter,
    extract(year from full_date)::int as year,
    to_char(full_date, 'FMDay') as day_of_week,
    extract(isodow from full_date) in (5, 6) as is_weekend  -- Fri/Sat weekend (Egypt)
from distinct_dates
