-- staging model: قراءة مباشرة من staging.customers، بدون أي منطق بيزنس
select
    customer_id,
    full_name,
    email,
    city,
    country,
    signup_date
from {{ source('staging', 'customers') }}
