-- Snowflake Git Integration Bootstrap
--
-- Execute in order. Replace <YOUR_GITHUB_CLASSIC_PAT> before running.
-- For private GitHub repos, PAT typically needs classic `repo` scope.
-- This script can run before or after sql/bootstrap_prod.sql.

-- ------------------------------------------------------------------
-- 1) Create API integration and required containers (ACCOUNTADMIN)
-- ------------------------------------------------------------------
-- Purpose:
-- Establish a Snowflake API integration that allows outbound HTTPS
-- calls to the specific GitHub repository prefix only.
-- Also ensure database/schemas required by this script exist.
-- Result:
-- Integration object GITHUB_INT is created/enabled and scoped to repo URL.
-- Secret and git objects can be created in dedicated schemas.
USE ROLE ACCOUNTADMIN;

-- Make script order-independent (can run before bootstrap_prod.sql)
CREATE DATABASE IF NOT EXISTS ANALYTICS_PROD;
CREATE SCHEMA IF NOT EXISTS ANALYTICS_PROD.SECURITY;
CREATE SCHEMA IF NOT EXISTS ANALYTICS_PROD.INTEGRATION;

CREATE OR REPLACE API INTEGRATION GITHUB_INT
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = (
    'https://github.com/mareksyldatk/snowflake-dbt.git',
    'https://github.com/mareksyldatk/snowflake-dbt'
  )
  ALLOWED_AUTHENTICATION_SECRETS = ALL
  ENABLED = TRUE;

-- Allow SECURITYADMIN to manage secrets in dedicated SECURITY schema.
GRANT USAGE ON INTEGRATION GITHUB_INT TO ROLE SECURITYADMIN;
GRANT USAGE ON DATABASE ANALYTICS_PROD TO ROLE SECURITYADMIN;
GRANT USAGE ON SCHEMA ANALYTICS_PROD.SECURITY TO ROLE SECURITYADMIN;
GRANT CREATE SECRET ON SCHEMA ANALYTICS_PROD.SECURITY TO ROLE SECURITYADMIN;

-- ------------------------------------------------------------------
-- 2) Create secret with GitHub credentials (SECURITYADMIN)
-- ------------------------------------------------------------------
-- Purpose:
-- Store GitHub username + PAT in a Snowflake SECRET object so credentials
-- are not embedded in GIT REPOSITORY definitions.
-- Result:
-- Secret GITHUB_PAT_SECRET is available in ANALYTICS_PROD.SECURITY.
-- Required action:
-- Replace <YOUR_GITHUB_CLASSIC_PAT> with a valid token before execution.
USE ROLE SECURITYADMIN;
USE DATABASE ANALYTICS_PROD;
USE SCHEMA SECURITY;

CREATE ROLE IF NOT EXISTS ROLE_PROD_DBT;

CREATE OR REPLACE SECRET GITHUB_PAT_SECRET
  TYPE = PASSWORD
  USERNAME = 'mareksyldatk'
  PASSWORD = '<YOUR_GITHUB_CLASSIC_PAT>';

-- ------------------------------------------------------------------
-- 3) Grant access for dbt role (SECURITYADMIN)
-- ------------------------------------------------------------------
-- Purpose:
-- Authorize ROLE_PROD_DBT to use the API integration and secret.
-- Result:
-- ROLE_PROD_DBT can use integration credentials in Snowflake-managed dbt.
GRANT USAGE ON INTEGRATION GITHUB_INT TO ROLE ROLE_PROD_DBT;
GRANT USAGE ON DATABASE ANALYTICS_PROD TO ROLE ROLE_PROD_DBT;
GRANT USAGE ON SCHEMA ANALYTICS_PROD.SECURITY TO ROLE ROLE_PROD_DBT;
GRANT READ ON SECRET ANALYTICS_PROD.SECURITY.GITHUB_PAT_SECRET TO ROLE ROLE_PROD_DBT;
GRANT USAGE ON SECRET ANALYTICS_PROD.SECURITY.GITHUB_PAT_SECRET TO ROLE ROLE_PROD_DBT;

GRANT USAGE ON SCHEMA ANALYTICS_PROD.INTEGRATION TO ROLE ROLE_PROD_DBT;
