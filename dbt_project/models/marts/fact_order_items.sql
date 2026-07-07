with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

dim_customer as (
    select * from {{ ref('dim_customer') }}
),

dim_product as (
    select * from {{ ref('dim_product') }}
),

joined as (
    select
        oi.order_id,
        o.order_date,
        o.order_status,
        o.customer_id,
        oi.product_id,
        oi.quantity,
        oi.unit_price,
        oi.quantity * oi.unit_price as line_total
    from order_items oi
    left join orders o on oi.order_id = o.order_id
)

select
    to_char(j.order_date::date, 'YYYYMMDD')::int as date_key,
    c.customer_sk,
    p.product_sk,
    j.order_id,
    j.order_status,
    j.quantity,
    j.unit_price,
    j.line_total
from joined j
left join dim_customer c on j.customer_id = c.customer_id
left join dim_product p on j.product_id = p.product_id
