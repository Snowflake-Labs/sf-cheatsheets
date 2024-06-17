--!jinja
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
  -- disable auto start
  INITIALLY_SUSPENDED=TRUE
  -- auto suspend in two mins
  AUTO_SUSPEND=120;

-- grants on warehouse to cheatsheets_spcs_demo_role
GRANT USAGE ON WAREHOUSE cheatsheets_spcs_wh_s TO ROLE cheatsheets_spcs_demo_role;

-- security integration to allow accessing service via endpoint
CREATE SECURITY INTEGRATION IF NOT EXISTS snowservices_ingress_oauth
  TYPE=oauth
  OAUTH_CLIENT=snowservices_ingress
  ENABLED=true;

-- allow endpoint binding to role 
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE cheatsheets_spcs_demo_role;

-- allow role to use and monitor compute pool
GRANT USAGE, MONITOR ON COMPUTE POOL my_xs_compute_pool TO ROLE cheatsheets_spcs_demo_role;

-- grant cheatsheets_spcs_demo_role role to current user
GRANT ROLE cheatsheets_spcs_demo_role TO USER &{ctx.env.SNOWFLAKE_USER};