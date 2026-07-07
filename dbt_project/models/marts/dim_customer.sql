select
    row_number() over (order by customer_id) as customer_sk,  -- surrogate key
    customer_id,                                                -- natural/business key
    full_name,
    email,
    city,
    country,
    signup_date,
    signup_date as valid_from,
    cast(null as date) as valid_to,
    true as is_current
from {{ ref('stg_customers') }}
