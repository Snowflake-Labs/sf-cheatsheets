-- Run with: snow sql --stdin --env SNOWFLAKE_USER=$SNOWFLAKE_USER < samples/spcs_setup.sql
-- Uses <% ctx.env.SNOWFLAKE_USER %> (STANDARD templating, enabled by default in snow sql)
USE ROLE ACCOUNTADMIN;
-- Role that will be used to create services
CREATE ROLE IF NOT EXISTS cheatsheets_spcs_demo_role;

CREATE DATABASE IF NOT EXISTS CHEATSHEETS_DB;

-- Grant ownership on the DB to cheatsheets_spcs_demo_role
GRANT OWNERSHIP ON DATABASE CHEATSHEETS_DB TO ROLE cheatsheets_spcs_demo_role COPY CURRENT GRANTS;

-- use cheatsheets_spcs_demo_role to create the data schema
USE ROLE cheatsheets_spcs_demo_role;
-- data_schema will house the image repositories
CREATE SCHEMA IF NOT EXISTS CHEATSHEETS_DB.DATA_SCHEMA;
-- Switch back to accountadmin for rest of the tasks
USE ROLE ACCOUNTADMIN;

-- Create warehouse to be used for queries from the service
CREATE WAREHOUSE IF NOT EXISTS cheatsheets_spcs_wh_s WITH
  WAREHOUSE_SIZE='X-SMALL'
  INITIALLY_SUSPENDED=TRUE
  AUTO_SUSPEND=120;

-- grants on warehouse to cheatsheets_spcs_demo_role
GRANT USAGE ON WAREHOUSE cheatsheets_spcs_wh_s TO ROLE cheatsheets_spcs_demo_role;

-- allow endpoint binding to role
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE cheatsheets_spcs_demo_role;

-- NOTE: GRANT on compute pool must be run AFTER the pool is created:
--   GRANT USAGE, MONITOR ON COMPUTE POOL <pool_name> TO ROLE cheatsheets_spcs_demo_role;

-- grant cheatsheets_spcs_demo_role role to current user
GRANT ROLE cheatsheets_spcs_demo_role TO USER <% ctx.env.SNOWFLAKE_USER %>;
