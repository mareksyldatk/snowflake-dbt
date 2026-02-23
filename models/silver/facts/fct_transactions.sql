{{ config(alias='transactions') }}

select
  t.transaction_id,
  t.user_id,
  t.product_id,
  t.quantity,
  p.unit_price,
  (t.quantity * p.unit_price) as gross_amount,
  t.transaction_ts::timestamp_ntz as transaction_ts,
  t.status
from {{ ref('transactions') }} t
left join {{ ref('dim_products') }} p
  on t.product_id = p.product_id
