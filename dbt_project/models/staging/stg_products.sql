select
    product_id,
    product_name,
    category,
    unit_price as current_price
from {{ source('staging', 'products') }}
