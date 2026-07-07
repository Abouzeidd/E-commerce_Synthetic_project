select
    order_id,
    customer_id,
    order_date,
    status as order_status
from {{ source('staging', 'orders') }}
