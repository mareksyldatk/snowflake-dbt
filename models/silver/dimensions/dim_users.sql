{{ config(alias='users') }}

select
  user_id,
  first_name,
  last_name,
  email,
  created_at::timestamp_ntz as created_at,
  country
from {{ ref('users') }}
