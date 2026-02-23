select
  u.user_id,
  u.email,
  u.country,
  count(t.transaction_id) as transaction_count,
  sum(case when t.status = 'completed' then t.gross_amount else 0 end) as completed_sales_amount,
  sum(case when t.status = 'refunded' then t.gross_amount else 0 end) as refunded_sales_amount,
  min(t.transaction_ts) as first_transaction_ts,
  max(t.transaction_ts) as last_transaction_ts
from {{ ref('dim_users') }} u
left join {{ ref('fct_transactions') }} t
  on u.user_id = t.user_id
group by 1, 2, 3
