select
  f.transaction_id,
  f.transaction_ts,
  f.status,
  f.user_id,
  u.email,
  u.country,
  f.product_id,
  p.product_name,
  p.category,
  f.quantity,
  f.unit_price,
  f.gross_amount
from {{ ref('fct_transactions') }} f
left join {{ ref('dim_users') }} u
  on f.user_id = u.user_id
left join {{ ref('dim_products') }} p
  on f.product_id = p.product_id
