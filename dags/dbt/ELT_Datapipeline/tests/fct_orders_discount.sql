select 
    *
from
    {{ ref('fct_orders') }}
where
    discount_amount > 0