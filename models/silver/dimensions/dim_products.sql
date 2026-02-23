{{ config(alias='products') }}

select
  product_id,
  product_name,
  category,
  unit_price,
  is_active
from {{ ref('products') }}
