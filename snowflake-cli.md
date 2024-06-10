---
authors: Kamesh Sampath
date: 2024-06-10
version: v1
tags: [cli, cheatsheets]
---

# Snowflake CLI

[Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/index) is next gen command line utility to interact with Snowflake.

## Install

```shell
pip install -U snowflake-cli-labs
```

or

```shell
pipx install snowflake-cli-labs
```

## Get Help

```shell
snow --help
```

## Information

General information about version of CLI and Python, default configuration path etc.,

```shell
snow  --info
```

> [!TIP]
> The connection configuration `config.toml` by default is stored under`$HOME/.snowflake`.
> If you wish to change it set the environment variable `$SNOWFLAKE_HOME`[^1] to director where
> you want to store the `config.toml`

## Connection

### Add

```shell
snow connection add
```

Adding connection `cheatsheets` following the prompts,

```shell
snow connection add
```

Adding connection named `cheatsheets` using command options,

```shell
snow connection add --connection-name cheatsheets \
  --account <your-account-identifier> \
  --user <your-user> \
  --password <your-password>
```

> [!NOTE]
> Currently need to follow the prompts for the defaults or add other parameters

## List

```shell
snow connection list
```

## Set Default

```shell
snow connection set-default cheatsheets
```

## Test a Connection

```shell
snow connection test -c cheatsheets
```

> [!TIP]
> If you don't specify `-c`, then it test with default connection that was set in
> the config

## Manipulating Snowflake Objects

### Creating Objects

Simple one line query,

```shell
snow sql -q 'CREATE DATABASE FOO'
```

Loading DDL/DML commands from a file,

```shell
snow sql --filename my_objects.sql
```

Using Standard Input(`stdin`)

```shell
cat <<EOF | snow sql --stdin
CREATE OR REPLACE DATABASE FOO;
USE DATABASE FOO;
CREATE OR REPLACE SCHEMA CLI;
USE SCHEMA CLI;
CREATE OR ALTER TABLE employees(
  id int,
  first_name string,
  last_name string,
  dept int
);
EOF
```

### Listing Objects

#### Warehouses

```shell
snow object list warehouse
```

#### Databases

```shell
snow object list database
```

List all databases in `JSON` format,

```shell
snow object list database --format json
```

> [!TIP]
> With `JSON` you can extract values using tools like [jq](https://jqlang.github.io/jq/)
> e.g.
>
> ```shell
>  snow object list database --format json | jq '.[].name'
> ```

List databases that starts with `snow`,

```shell
snow object list database --like '%snow%'
```

#### Schemas

```shell
snow object list schema
```

Filtering schemas by database,

```shell
snow object list schema --in database foo
```

#### Tables

```shell
snow object list table
```

List tables in a specific schema of a database,

```shell
snow object list table --database foo --in schema cli
```

### Describe an Object

Let us describe the table `employees` in the `foo` database' schema `cli`,

```shell
snow object describe table employees --database foo --schema cli
```

### Drop an object

```shell
snow object drop table employees --database foo --schema cli
```

## Streamlit Applications

Create a [Streamlit](https://streamlit.io) application and deploy to Snowflake,

```shell
snow streamlit init streamlit_app
```

Create a Warehouse that the Streamlit application will use,

```shell
snow sql -q 'CREATE WAREHOUSE my_streamlit_warehouse'
```

Create a database that the Streamlit application will use,

```shell
snow sql -q 'CREATE DATABASE my_streamlit_app'
```

### Deploy Application

> [!IMPORTANT]
> Ensure you are in the Streamlit application folder before running the command.

```shell
snow streamlit deploy --database=my_streamlit_app
```

### List Applications

```shell
snow streamlit list
```

### Describe Application

```shell
snow streamlit describe streamlit_app --schema=public --database=my_streamlit_app
```

> [!NOTE]
> When describing Streamlit application either provide the schema as parameter or
> use fully qualified name

### Get Application URL

```shell
snow streamlit get-url streamlit_app --database=my_streamlit_app
```

### Drop Application

```shell
snow streamlit drop streamlit_app --schema=public --database=my_streamlit_app
```

## Internal Stages

### Create

```shell
snow stage create cli_stage  --schema=cli --database=foo
```

### Describe

```shell
snow stage describe cli_stage  --schema=cli --database=foo
```

### List Stages

List all available stages,

```shell
snow stage list
```

List stages in specific database,

```shell
snow stage list --in database foo
```

List stages by name that starts with `cli`,

```shell
snow stage list --like '%cli%' --in database foo
```

### Copy Files

Create a file to copy, there are few [samples](./samples) in the repo, download `employees.csv`.

```shell
curl -sSL -o employees.csv https://raw.githubusercontent.com/Snowflake-Labs/sf-cheatsheets/main/samples/employees.csv
```

```shell
snow stage copy employees.csv '@cli_stage/data'  --schema=cli --database=foo
```

### List Files in Stage

```shell
snow stage list-files cli_stage  --schema=cli --database=foo
```

List files by pattern,

```shell
snow stage list-files cli_stage --pattern='.*[.]csv' --schema=cli --database=foo
```

### Execute Files From Stage

Download the `load_employees.sql` to copy on to the stage,

```shell
curl -sSL -o load_employees.sql https://raw.githubusercontent.com/Snowflake-Labs/sf-cheatsheets/main/samples/load_employees.sql
```

```shell
snow stage copy load_employees.sql '@cli_stage/sql'  --schema=cli --database=foo
```

Execute the SQL from stage,

```shell
snow stage execute '@cli_stage/sql/*'  --schema=cli --database=foo
```

> [!NOTE]
> Execute takes the glob pattern, allowing to specify the file pattern to execute. `
@stage/*` or `@stage/*.sql` both executes only sql files

Query all employees to make sure the load worked,

```shell
snow sql --schema=cli --database=foo -q 'SELECT * FROM EMPLOYEES'
```

### Remove File(s) from Stage

```shell
snow stage remove cli_stage 'data/'  --schema=cli --database=foo
```

## References

- [Snowflake Developers::Getting Started With Snowflake CLI](https://youtu.be/ooyZh56NePA?si=3yV3s2z9YwPWVJc-)
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/index)
- [Accelerate Development and Productivity with DevOps in Snowflake](https://www.snowflake.com/blog/devops-snowflake-accelerating-development-productivity/)

[^1]: https://docs.snowflake.com/developer-guide/snowflake-cli-v2/connecting/specify-credentials#how-to-use-environment-variables-for-snowflake-credentials
