select
    lineitems.order_item_key,
    lineitems.part_key,
    lineitems.line_number,
    lineitems.extended_price,
    orders.order_key,
    orders.customer_key,
    orders.order_date,
    {{ discounted_amount('lineitems.extended_price', 'lineitems.discount_percentage') }} as discount_amount
from
    {{ ref('stg_tpch_orders')}} as orders
join
    {{ ref('stg_tpch_lineitems') }} as lineitems 
        on orders.order_key = lineitems.order_key
order by 
    orders.order_date