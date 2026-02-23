-- Snowflake Git Integration Bootstrap
-- Target repo: https://github.com/mareksyldatk/snowflake-dbt.git
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
-- Authorize ROLE_PROD_DBT to use the API integration and secret,
-- then allow creation of a GIT REPOSITORY object in INTEGRATION schema.
-- Result:
-- ROLE_PROD_DBT can create/use DBT_REPO with secure credentials.
GRANT USAGE ON INTEGRATION GITHUB_INT TO ROLE ROLE_PROD_DBT;
GRANT USAGE ON DATABASE ANALYTICS_PROD TO ROLE ROLE_PROD_DBT;
GRANT USAGE ON SCHEMA ANALYTICS_PROD.SECURITY TO ROLE ROLE_PROD_DBT;
GRANT READ ON SECRET ANALYTICS_PROD.SECURITY.GITHUB_PAT_SECRET TO ROLE ROLE_PROD_DBT;
GRANT USAGE ON SECRET ANALYTICS_PROD.SECURITY.GITHUB_PAT_SECRET TO ROLE ROLE_PROD_DBT;

GRANT USAGE ON SCHEMA ANALYTICS_PROD.INTEGRATION TO ROLE ROLE_PROD_DBT;
GRANT CREATE GIT REPOSITORY ON SCHEMA ANALYTICS_PROD.INTEGRATION TO ROLE ROLE_PROD_DBT;

-- ------------------------------------------------------------------
-- 4) Ensure executing user can use ROLE_PROD_DBT and create repository
-- ------------------------------------------------------------------
-- Purpose:
-- Grant ROLE_PROD_DBT to the current executing user, then register
-- the GitHub repo in Snowflake as DBT_REPO using integration + secret.
-- Result:
-- Repository is created under ROLE_PROD_DBT so follow-up operations
-- (FETCH/SHOW) work with the same role without ownership handoff.
USE ROLE SECURITYADMIN;

BEGIN
  LET EXECUTING_USER STRING := CURRENT_USER();
  EXECUTE IMMEDIATE 'GRANT ROLE ROLE_PROD_DBT TO USER "' || EXECUTING_USER || '"';
END;

USE ROLE ROLE_PROD_DBT;
USE DATABASE ANALYTICS_PROD;
USE SCHEMA INTEGRATION;

CREATE OR REPLACE GIT REPOSITORY DBT_REPO
  API_INTEGRATION = GITHUB_INT
  ORIGIN = 'https://github.com/mareksyldatk/snowflake-dbt.git'
  GIT_CREDENTIALS = ANALYTICS_PROD.SECURITY.GITHUB_PAT_SECRET;

-- ------------------------------------------------------------------
-- 5) Fetch and verify
-- ------------------------------------------------------------------
-- Purpose:
-- Pull repository metadata/content and confirm connectivity/access.
-- Result:
-- FETCH updates the repository object; SHOW commands confirm visible refs.
ALTER GIT REPOSITORY DBT_REPO FETCH;

SHOW GIT BRANCHES IN GIT REPOSITORY DBT_REPO;
SHOW GIT TAGS IN GIT REPOSITORY DBT_REPO;

-- Optional inspection:
-- SHOW GIT REPOSITORIES IN SCHEMA ANALYTICS_PROD.INTEGRATION;
