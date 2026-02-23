-- Bootstrap (or recreate) Snowflake Git repository object for dbt project
-- Target: ANALYTICS_PROD.INTEGRATION.DBT_REPO
-- Repo:   https://github.com/mareksyldatk/snowflake-dbt.git
--
-- Prerequisite:
-- - Run sql/bootstrap_prod.sql
-- - Run sql/bootstrap_git_integration.sql (secret + API integration)

-- ------------------------------------------------------------------
-- 1) Ensure required grants exist (ACCOUNTADMIN)
-- ------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS ANALYTICS_PROD;
CREATE SCHEMA IF NOT EXISTS ANALYTICS_PROD.INTEGRATION;
CREATE ROLE IF NOT EXISTS ROLE_PROD_DBT;

GRANT USAGE ON DATABASE ANALYTICS_PROD TO ROLE ROLE_PROD_DBT;
GRANT USAGE ON SCHEMA ANALYTICS_PROD.INTEGRATION TO ROLE ROLE_PROD_DBT;
GRANT CREATE GIT REPOSITORY ON SCHEMA ANALYTICS_PROD.INTEGRATION TO ROLE ROLE_PROD_DBT;
GRANT USAGE ON INTEGRATION GITHUB_INT TO ROLE ROLE_PROD_DBT;

-- ------------------------------------------------------------------
-- 2) Ensure secret access for ROLE_PROD_DBT (SECURITYADMIN)
-- ------------------------------------------------------------------
USE ROLE SECURITYADMIN;

GRANT USAGE ON SCHEMA ANALYTICS_PROD.SECURITY TO ROLE ROLE_PROD_DBT;
GRANT READ ON SECRET ANALYTICS_PROD.SECURITY.GITHUB_PAT_SECRET TO ROLE ROLE_PROD_DBT;
GRANT USAGE ON SECRET ANALYTICS_PROD.SECURITY.GITHUB_PAT_SECRET TO ROLE ROLE_PROD_DBT;

-- ------------------------------------------------------------------
-- 3) Create or replace DBT_REPO as ROLE_PROD_DBT
-- ------------------------------------------------------------------
-- If this fails with "Requested role 'ROLE_PROD_DBT' is not assigned",
-- run (as SECURITYADMIN):
--   GRANT ROLE ROLE_PROD_DBT TO USER <YOUR_USER>;
USE ROLE ROLE_PROD_DBT;
USE DATABASE ANALYTICS_PROD;
USE SCHEMA INTEGRATION;

CREATE OR REPLACE GIT REPOSITORY DBT_REPO
  API_INTEGRATION = GITHUB_INT
  ORIGIN = 'https://github.com/mareksyldatk/snowflake-dbt.git'
  GIT_CREDENTIALS = ANALYTICS_PROD.SECURITY.GITHUB_PAT_SECRET;

ALTER GIT REPOSITORY DBT_REPO FETCH;

-- ------------------------------------------------------------------
-- 4) Verify visibility and refs
-- ------------------------------------------------------------------
SHOW GIT REPOSITORIES IN SCHEMA ANALYTICS_PROD.INTEGRATION;
SHOW GIT BRANCHES IN GIT REPOSITORY ANALYTICS_PROD.INTEGRATION.DBT_REPO;
SHOW GIT TAGS IN GIT REPOSITORY ANALYTICS_PROD.INTEGRATION.DBT_REPO;
