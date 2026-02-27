# snowflake-dbt

Minimal Snowflake + dbt setup with medallion layers split across three databases.

## Layer Layout

- Bronze: `BRONZE_DEV.BRONZE` (`users`, `products`, `transactions` from seeds)
- Silver: `SILVER_DEV.DIMENSIONS` (`users`, `products`) and `SILVER_DEV.FACTS` (`transactions`)
- Gold: `GOLDEN_DEV.DATASET` (`transaction`, `user_transactions`)

dbt moves data across databases using `ref()` and per-layer `+database` config in `dbt_project.yml`.

## Project Files

- `dbt_project.yml`: layer-to-database/schema mapping
- `profiles.yml.example`: minimal dbt target profile
- `sql/bootstrap_dev.sql`: core warehouses, roles, users, and RBAC
- `sql/bootstrap_git_integration.sql`: GitHub API integration + PAT secret grants
- `sql/bootstrap_current_user_permissions.sql`: grants `ROLE_DEV_DBT` to your current user and sets defaults
- `models/`, `seeds/`, `macros/`: dbt models, source seeds, and schema macro override

## Bootstrap (Snowflake)

1. Run `sql/bootstrap_dev.sql`.
2. Run `sql/bootstrap_git_integration.sql` (replace `<YOUR_GITHUB_CLASSIC_PAT>` first).
3. Run `sql/bootstrap_current_user_permissions.sql` to grant `ROLE_DEV_DBT` to your current user and set default role/warehouse/namespace for dbt.

Git integration objects are created in:
- `PLATFORM_DEV.SECURITY.GITHUB_PAT_SECRET`
- `GITHUB_INT_SNOWFLAKE_DBT` API integration

## dbt Profile

Copy `profiles.yml.example` to `~/.dbt/profiles.yml` and fill credentials as needed.

Current default target in example:
- role: `ROLE_DEV_DBT`
- warehouse: `WH_DEV_DBT`
- database/schema fallback: `PLATFORM_DEV.DBT_RUNTIME`

## Run dbt

From repo root:

```bash
dbt deps
dbt debug --target dev
dbt seed --target dev
dbt build --target dev
```

## RBAC Summary

- `ROLE_DEV_INGEST`: read/write on `BRONZE_DEV.BRONZE`
- `ROLE_DEV_DBT`: read Bronze, write Silver/Gold, use Git integration secret
- `ROLE_DEV_BI`: read-only on `SILVER_DEV.DIMENSIONS`, `SILVER_DEV.FACTS`, and `GOLDEN_DEV.DATASET`

Bootstrapped users:
- `SVC_DEV_INGEST`
- `EXT_DEV_DBT`
- `EXT_DEV_BI`

## Snowsight dbt Project Deployment

Project name: `SNOWFLAKE_DBT`

Reference tutorial:
https://docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-getting-started-tutorial#run-the-sql-commands-in-tasty-bytes-setup-sql-to-set-up-source-data

Suggested deploy location:
- `PLATFORM_DEV / INTEGRATION`

## Expected Outputs

- `BRONZE_DEV.BRONZE.users`
- `BRONZE_DEV.BRONZE.products`
- `BRONZE_DEV.BRONZE.transactions`
- `SILVER_DEV.DIMENSIONS.users`
- `SILVER_DEV.DIMENSIONS.products`
- `SILVER_DEV.FACTS.transactions`
- `GOLDEN_DEV.DATASET.transaction`
- `GOLDEN_DEV.DATASET.user_transactions`
