USE ROLE cheatsheets_spcs_demo_role;

DROP DATABASE IF EXISTS CHEATSHEETS_DB;

USE ROLE ACCOUNTADMIN;

-- gracefully stop and delete all services running on this compute pool
ALTER COMPUTE POOL my_xs_compute_pool STOP ALL;

DROP COMPUTE POOL IF EXISTS my_xs_compute_pool;

-- drop role 
DROP ROLE IF EXISTS cheatsheets_spcs_demo_role;

-- drop warehouse
DROP WAREHOUSE IF EXISTS cheatsheets_spcs_wh_s;
-- suspend warehouse 
-- ALTER WAREHOUSE cheatsheets_spcs_wh_s SUSPEND;