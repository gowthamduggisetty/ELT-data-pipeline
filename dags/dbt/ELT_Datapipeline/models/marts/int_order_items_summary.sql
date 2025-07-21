select 
    order_key,
    sum(extended_price) as gross_item_sales_amount,
    sum(discount_amount) as discount_amount
from
    {{ ref('int_order_items') }}
group by
    order_key
