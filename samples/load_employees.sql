CREATE OR REPLACE FILE FORMAT csv_no_header
  SKIP_HEADER=1;
COPY INTO EMPLOYEES
FROM '@cli_stage/data/employees'
FILE_FORMAT = 'csv_no_header';