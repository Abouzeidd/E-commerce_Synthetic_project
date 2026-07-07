select
    row_number() over (order by product_id) as product_sk,  -- surrogate key
    product_id,                                               -- natural/business key
    product_name,
    category,
    current_price
from {{ ref('stg_products') }}
