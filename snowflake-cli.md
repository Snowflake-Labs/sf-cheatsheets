---
authors: Kamesh Sampath
date: 2024-06-10
version: v1
snow_cli_version: 2.4.1
tags:
  [
    cli,
    cheatsheets,
    app,
    streamlit,
    cortex,
    connection,
    spcs,
    object,
    sql,
    stage,
  ]
---

# Snowflake CLI

[Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/index) is next gen command line utility to interact with Snowflake.

> [!NOTE]
>
> - All commands has `--help` option
> - All command allows output format to be `table`(**default**) or `json`.

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

Adding connection using command options,

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

Use the following command to see the list of supported objects,

```shell
snow object list --help
```

#### Warehouses

List all available warehouses for the current role,

```shell
snow object list warehouse
```

#### Databases

List all available databases for the current role,

```shell
snow object list database
```

List all databases in `JSON` format,

```shell
snow object list database --format json
```

> [!TIP]
> With `JSON` you can extract values using tools like [jq](https://jqlang.github.io/jq/)
> e.g. to get only names of the databases
>
> ```shell
>  snow object list database --format json | jq '.[].name'
> ```

List databases that starts with `snow`,

```shell
snow object list database --like '%snow%'
```

#### Schemas

List all schemas,

```shell
snow object list schema
```

Filtering schemas by database named `foo`,

```shell
snow object list schema --in database foo
```

#### Tables

List all tables

```shell
snow object list table
```

List tables in a specific schema `cli` of a database `foo`,

```shell
snow object list table --database foo --in schema cli
```

### Describe an Object

Let us describe the table `employees` in the `foo` database' schema `cli`,

```shell
snow object describe table employees --database foo --schema cli
```

### Drop an object

Drop an table named `employees` in schema `cli` of database `foo`,

```shell
snow object drop table employees --database foo --schema cli
```

## Streamlit Applications

Create a [Streamlit](https://streamlit.io) application and deploy to Snowflake,

```shell
snow streamlit init streamlit_app
```

Create a warehouse that the Streamlit application will use,

```shell
snow sql -q 'CREATE WAREHOUSE my_streamlit_warehouse'
```

Create a database that the Streamlit application will use,

```shell
snow sql -q 'CREATE DATABASE my_streamlit_app'
```

### Deploy an Application

> [!IMPORTANT]
> Ensure you are in the Streamlit application folder before running the command.

```shell
snow streamlit deploy --database=my_streamlit_app
```

### List Applications

List all available streamlit applications,

```shell
snow streamlit list
```

### Describe Application

Get details about a streamlit application `streamlit_app` in schema of `public` of database`my_streamlit_app`,

```shell
snow streamlit describe streamlit_app --schema=public --database=my_streamlit_app
```

> [!NOTE]
> When describing Streamlit application either provide the schema as parameter or
> use fully qualified name

### Get Application URL

Get the streamlit application URL i.e. the URL used to access the hosted application,

```shell
snow streamlit get-url streamlit_app --database=my_streamlit_app
```

### Drop Application

Drop a streamlit application named `streamlit_app` in schema of `public` of database`my_streamlit_app`,

```shell
snow streamlit drop streamlit_app --schema=public --database=my_streamlit_app
```

## Internal Stages

### Create

Create a stage named `cli_stage` in schema `cli` of database `foo`,

```shell
snow stage create cli_stage  --schema=cli --database=foo
```

### Describe

Get details of stage,

```shell
snow stage describe cli_stage  --schema=cli --database=foo
```

### List Stages

List all available stages,

```shell
snow stage list
```

List stages in specific to a database named `foo`,

```shell
snow stage list --in database foo
```

List stages by name that starts with `cli` in database `foo`,

```shell
snow stage list --like 'cli%' --in database foo
```

### Copy Files

Download [employees.csv](https://github.com/Snowflake-Labs/sf-cheatsheets/blob/main/samples/employees.csv),

```shell
curl -sSL -o employees.csv https://raw.githubusercontent.com/Snowflake-Labs/sf-cheatsheets/main/samples/employees.csv
```

Copy `employees.csv` to stage `cli_stage` to a path `/data`,

```shell
snow stage copy employees.csv '@cli_stage/data'  --schema=cli --database=foo
```

### List Files in Stage

List all files in stage `cli_stage` in schema `cli` of database `foo`,

```shell
snow stage list-files cli_stage  --schema=cli --database=foo
```

List files by pattern,

```shell
snow stage list-files cli_stage --pattern='.*[.]csv' --schema=cli --database=foo
```

### Execute Files From Stage

Download the [load_employees.sql](https://github.com/Snowflake-Labs/sf-cheatsheets/blob/main/samples/load_employees.sql),

```shell
curl -sSL -o load_employees.sql https://raw.githubusercontent.com/Snowflake-Labs/sf-cheatsheets/main/samples/load_employees.sql
```

Copy `load_employees.sql` to stage `cli_stage` at path `/sql`,

```shell
snow stage copy load_employees.sql '@cli_stage/sql'  --schema=cli --database=foo
```

Execute the SQL[^2] from stage,

```shell
snow stage execute '@cli_stage/sql/load_employees.sql'  --schema=cli --database=foo
```

> [!NOTE]
> Execute takes the glob pattern, allowing to specify the file pattern to execute. `
@stage/*` or `@stage/*.sql` both executes only sql files

Query all employees to make sure the load worked,

```shell
snow sql --schema=cli --database=foo -q 'SELECT * FROM EMPLOYEES'
```

Download [variables.sql](https://github.com/Snowflake-Labs/sf-cheatsheets/blob/main/samples/variables.sql),

```shell
curl -sSL -o variables.sql https://raw.githubusercontent.com/Snowflake-Labs/sf-cheatsheets/main/samples/variables.sql
```

Copy the `variables.sql` to stage,

```shell
snow stage copy  variables.sql '@cli_stage/sql' --schema=cli --database=foo
```

Execute files from stage with values for template variables(`{{.dept}}` in variables.sql),

```shell
snow stage execute '@cli_stage/sql/variables.sql' --variable="dept=1"  --schema=cli --database=foo
```

Executing `variables.sql` would have created a view named `EMPLOYEE_DEPT_VIEW`, list the view it to see the variables replaced,

```shell
snow object list view --like 'emp%' --database=foo --schema=cli
```

### Remove File(s) from Stage

Remove all files from stage `cli_stage` on path `/data`

```shell
snow stage remove cli_stage 'data/'  --schema=cli --database=foo
```

## Native Apps

### Create App

Create a Snowflake Native App `my_first_app` in current working directory,

```shell
snow app init my_first_app
```

Create a Snowflake Native App in directory `my_first_app`

```shell
snow app init --name 'my-first-app' my_first_app
```

> [!NOTE]
> Since the name becomes a part of the application URL its recommended to have URL
> safe names

Create a Snowflake Native App with Streamlit Python template[^3]

```shell
snow app init my_first_app --template streamlit-python
```

> [!NOTE]
> You can also create your Snowflake Native App template and use `--template-repo`
> instead, to scaffold your Native App using your template.

### Run App

From the application directory e.g. `my_first_app`

```shell
snow app run
```

### Version App

> ![IMPORTANT]
> The version name should be valid SQL identifier e.g. no dots and start with a character
> usually version labels use `v`.

#### Create Version

Create a development version named `dev`,

```shell
snow app version create
```

Create a development version named `v1_0`,

```shell
snow app version create v1_0
```

List available versions

```shell
snow app version list
```

#### Drop a Version

```shell
snow app version list v1_0
```

#### Deploy a Version

Deploy a particular version of an application,

```shell
snow app run --version=v1_0
```

Deploy a particular version and patch,

```shell
snow app run --version=v1_0 --patch=1
```

> [!NOTE]
> Version `patches` are automatically incremented when creating version with same name

## Open App

Open the application on a browser, from the application directory e.g. `my_first_app`

```shell
snow app open
```

## Deploy

Synchronize the local application file changes with stage and don't create/update the running application

```shell
snow app deploy
```

## Delete App

```shell
snow app teardown
```

If the application has version associated then drop the version,

```shell
snow app version drop
```

And then drop the application

```shell
snow app teardown
```

Drop application and its associated database objects,

```shell
snow app teardown --cascade
```

## Snowpark Container Services(SPCS)

> [!IMPORTANT]
>
> - SPCS is available only on certain AWS regions and
>   not available for trial accounts
> - All Snowpark Containers are run using a defined compute pool.

### Compute Pool

List of available instance families[^4]

- CPU_X64_XS
- CPU_X64_S
- CPU_X64_M
- CPU_X64_L
- HIGHMEM_X64_S
- HIGHMEM_X64_M
- HIGHMEM_X64_L
- GPU_NV_S
- GPU_NV_M
- GPU_NV_L

#### Create

Create a compute pool named `my_xs_compute_pool` with family `CPU_X64_XS`,

```shell
snow spcs compute-pool create my_xs_compute_pool \
  --family CPU_X64_XS
```

Create with `if not exists`,

```shell
snow spcs compute-pool create my_xs_compute_pool \
  --family CPU_X64_XS --if-not-exists
```

Create with initially suspended (**default**: not suspended initially),

```shell
snow spcs compute-pool create my_xs_compute_pool \
  --family CPU_X64_XS --init-suspend
```

Create with auto suspend(**default**: `3600 secs`) set to `2 mins(120 secs)` ,

```shell
snow spcs compute-pool create my_xs_compute_pool \
  --family CPU_X64_XS --auto-suspend-secs=120
```

Create with minimum nodes(scale down) as `1`(**default**) and maximum nodes(scale up) as `3`

```shell
snow spcs compute-pool create my_xs_compute_pool \
  --family CPU_X64_XS --min-nodes=1 --max-nodes=3
```

Create with auto resume on service/job request,

```shell
snow spcs compute-pool create my_xs_compute_pool \
  --family CPU_X64_XS --auto-resume
```

Create with auto-resume disabled,

> [!NOTE]
> Auto Resume disabled requires the compute pool to be started manually.

```shell
snow spcs compute-pool create my_xs_compute_pool \
  --family CPU_X64_XS --no-auto-resume
```

#### List Compute Pool

List all available compute pools for current role,

```shell
snow spcs compute-pool list
```

List compute pools like `my_xs%`

```shell
snow spcs compute-pool list --like 'my_xs%'
```

#### Describe Compute Pool

Get details about a compute pool,

```shell
snow spcs compute-pool describe my_xs_compute_pool
```

#### Status of Compute Pool

To know the current status of a compute pool,

```shell
snow spcs compute-pool status my_xs_compute_pool
```

#### Suspend a Compute Pool

Suspend a compute pool,

```shell
snow spcs compute-pool suspend my_xs_compute_pool
```

#### Resume a Compute Pool

Resume a compute pool,

```shell
snow spcs compute-pool resume my_xs_compute_pool
```

#### Properties on Compute Pool

You can `set/unset` the following properties on a compute pool after it's created,

| Option                | Description             |
| :-------------------- | :---------------------- |
| `--min-nodes`         | Minimum Node(s)         |
| `--max-nodes`         | Maximum Nodes(s)        |
| `--auto-resume`       | Enable Auto Resume      |
| `--no-auto-resume`    | Disable Auto Resume     |
| `--auto-suspend-secs` | Auto Suspend in seconds |
| `--comment`           | Comment                 |

##### Set

Add a `comment` to the compute pool,

```shell
snow spcs compute-pool set --comment 'my small compute pool' my_xs_compute_pool
```

##### Unset

Remove the `comment` from compute pool,

```shell
snow spcs compute-pool unset --comment my_xs_compute_pool
```

#### Delete all services on Compute Pool

Delete all services running on a compute pool

```shell
snow spcs compute-pool stop-all my_xs_compute_pool
```

#### Drop Compute Pool

Drop the compute pool,

```shell
snow spcs compute-pool drop my_xs_compute_pool
```

### Image Registry

#### Login

> [!IMPORTANT]
> This requires Docker on local system

```shell
snow spcs image-registry login
```

#### Token

Get `current user` token to access image registry,

```shell
snow spcs image-registry token
```

#### Registry URL

Get image registry URL,

```shell
snow spcs image-registry url
```

### Image Repository

> [!IMPORTANT]
>
> - A Database and Schema is required to create the Image Repository
> - Services can't be created using `ACCOUNTADMIN`, a custom role is required

The [SQL script](https://raw.githubusercontent.com/Snowflake-Labs/sf-cheatsheets/main/samples/spcs_setup.sql) defines role, grants and warehouse.

As `ACCOUNTADMIN` run the script to setup required Snowflake resources,

- A Role named `cheatsheets_spcs_demo_role` to create Snowpark Container Services
- A Database named `CHEATSHEETS_DB` where the services will be attached to
- A Schema named `DATA_SCHEMA` on DB `CHEATSHEETS_DB` to hold the image repository.
- A Warehouse `cheatsheets_spcs_wh_s` which will be used to run query from services.

Set your Snowflake account user name,

```shell
export SNOWFLAKE_USER=<your snowflake user>
```

Run the `spcs_setup.sql` create the aforementioned Snowflake objects,

```shell
curl https://raw.githubusercontent.com/Snowflake-Labs/sf-cheatsheets/main/samples/spcs_setup.sql |
snow sql --stdin
```

#### Create

Create a image repository named `my_image_repository`,

```shell
snow spcs image-repository create my_image_repository \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

Create with if not exists,

```shell
snow spcs image-repository create my_image_repository \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role' \
  --if-not-exists
```

Replace image repository `my_image_repository`,

```shell
snow spcs image-repository create my_image_repository \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role' \
  --replace
```

#### List Image Repositories

List all image repositories in the database and schema,

```shell
snow spcs image-repository list \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### URL

Get URL of the image repository `my_image_repository`,

```shell
snow spcs image-repository url my_image_repository \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### List Images

Let us push a sample image to repository,

```shell
IMAGE_REPOSITORY=$(snow spcs image-repository url my_image_repository \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA'  \
  --role='cheatsheets_spcs_demo_role')
docker pull --platform=linux/amd64 nginx
docker tag nginx "$IMAGE_REPOSITORY/nginx"
docker push "$IMAGE_REPOSITORY/nginx"
```

List all images in repository `my_image_repository`,

```shell
snow spcs image-repository list-images my_image_repository \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### List Image Tags

List all tags for image `nginx` in repository `my_image_repository`,

> [!IMPORTANT]
> The `--image-name` should be fully qualified name. Use `list-images` to get
> the fully qualified image name

```shell
snow spcs image-repository list-tags my_image_repository \
  --image-name=/CHEATSHEETS_DB/DATA_SCHEMA/my_image_repository/nginx \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### Drop

```shell
snow spcs image-repository drop my_image_repository \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

### Services

Create a SPCS service specification[^5] file,

> [!TIP]
> Tools like [jq](https://jqlang.github.io/jq/) can help extract data from the command output
> e.g. to get the image name
>
> ```shell
> export IMAGE=$(snow spcs image-repository list-images my_image_repository \
>   --database='CHEATSHEETS_DB' \
>   --schema='DATA_SCHEMA' --format json | jq -r '.[0].image')
> ```

```shell
cat <<EOF | tee work/service-spec.yaml
spec:
  containers:
    - name: nginx
      image: $IMAGE
      readinessProbe:
        port: 80
        path: /
  endpoints:
    - name: nginx
      port: 80
      public: true
EOF
```

Create a Service named `nginx` using compute pool `my_xs_compute_pool` and
specification `work/service-spec.yaml`,

```shell
snow spcs service create nginx \
  --compute-pool=my_xs_compute_pool \
  --spec-path=work/service-spec.yaml \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

Create a Service if not exists,

```shell
snow spcs service create nginx \
  --compute-pool=my_xs_compute_pool \
  --spec-path=work/service-spec.yaml \
  --if-not-exists \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

Create with minimum instances `1` (**default**) and maximum instances to be `3`,

```shell
snow spcs service create nginx \
  --compute-pool=my_xs_compute_pool \
  --spec-path=work/service-spec.yaml \
  --min-instances=1 \
  --max-instances=3 \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

Create service that uses a specific warehouse `cheatsheets_spcs_wh_s` for all its queries,

```shell
snow spcs service create nginx \
  --compute-pool=my_xs_compute_pool \
  --spec-path=work/service-spec.yaml \
  --query-warehouse='cheatsheets_spcs_wh_s' \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### Status

Check service status,

> [!NOTE]
> It will take few minutes for the service to be in `READY` status

```shell
snow spcs service status nginx \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### Describe

Get more details about the service,

```shell
snow spcs service describe nginx \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### Check Logs of Service

Check the logs of service with the container named `nginx` with instance `0`,

> [!NOTE]
> Find `instanceId` and `containerName` using the command `describe` command.

```shell
snow spcs service logs nginx \
  --container-name=nginx \
  --instance-id=0 \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### List

List all available services,

```shell
snow spcs service list  \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

Query services `in` database,

```shell
snow spcs service list  --in database CHEATSHEETS_DB \
  --role='cheatsheets_spcs_demo_role'
```

Query services `in` database and like `ng%`,

```shell
snow spcs service list  --in database CHEATSHEETS_DB --like 'ng%' \
  --role='cheatsheets_spcs_demo_role'
```

#### Service Endpoints

List the service endpoint for the service `nginx`,

```shell
snow spcs service list-endpoints nginx  \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

> [!NOTE]
> Open the `ingress_url` on the browser will take you to NGINX home page after
> authentication

#### Suspend a service

Suspend the service,

```shell
snow spcs service suspend nginx  \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### Resume a service

Resume the service,

```shell
snow spcs service resume nginx  \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

> [!NOTE]
> Resume service will take few minutes, use the `status` command to check the status

#### Supported properties on Service

You can `set/unset` the following properties on a service even after it's created,

| Option              | Description                                                              |
| :------------------ | :----------------------------------------------------------------------- |
| `--min-instances`   | Minimum number of service instance(s), typically used while scaling down |
| `--max-instances`   | Maximum number of service instance(s), typically used while scaling up   |
| `--auto-resume`     | Enable auto resume                                                       |
| `--no-auto-resume`  | Disable auto resume                                                      |
| `--query-warehouse` | The Warehouse to use while doing query from the service                  |
| `--comment`         | Comment for the service                                                  |

##### Set

Add a comment to the service,

```shell
snow spcs service set --comment 'the nginx service' nginx  \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

Use service `describe` to check on the updated property

##### Unset

Remove the comment from the service,

```shell
snow spcs service unset --comment nginx  \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### Upgrade

Upgrade the service `nginx` with new specification e.g a tag upgrade or probe updates etc.,

```shell
snow spcs service upgrade nginx \
  --spec-path=work/service-spec_V2.yaml \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

#### Drop

Drop a service named `nginx`

```shell
snow spcs service drop nginx \
  --database='CHEATSHEETS_DB' \
  --schema='DATA_SCHEMA' \
  --role='cheatsheets_spcs_demo_role'
```

> [!NOTE]
> SPCS has compute associated with it, run the [clean up](https://raw.githubusercontent.com/Snowflake-Labs/sf-cheatsheets/main/samples/spcs_cleanup.sql) script to clean the Snowflake resources created as part of this cheatsheet.
>
> ```shell
> curl https://raw.githubusercontent.com/Snowflake-Labs/sf-cheatsheets/main/samples/spcs_cleanup.sql |
> snow sql --stdin
> ```

## References

- [Accelerate Development and Productivity with DevOps in Snowflake](https://www.snowflake.com/blog/devops-snowflake-accelerating-development-productivity/)

### Quickstarts

- [Snowflake Developers::Quickstart](https://quickstarts.snowflake.com/guide/getting-started-with-snowflake-cli/#0)
- [Snowflake Developers::Getting Started With Snowflake CLI](https://youtu.be/ooyZh56NePA?si=3yV3s2z9YwPWVJc-)
- [Intro to Snowpark Container Services](https://quickstarts.snowflake.com/guide/intro_to_snowpark_container_services/index.html?index=../..index#0)
- [Build a Data App and run it on Snowpark Container Services](https://quickstarts.snowflake.com/guide/build_a_data_app_and_run_it_on_Snowpark_container_services/index.html?index=../..index#0)

### Documentation

- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/index)
- [Execute Immediate Jinja Templating](https://docs.snowflake.com/en/sql-reference/sql/execute-immediate-from)
- [Snowpark Native App Framework](https://docs.snowflake.com/en/developer-guide/native-apps/native-apps-about)
- [Snowpark Container Services](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/overview)

### Tutorials

- [Snowflake Native App Tutorial](https://docs.snowflake.com/en/developer-guide/native-apps/tutorials/getting-started-tutorial)
- [Snowpark Container Services Tutorial](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/overview-tutorials)

[^1]: https://docs.snowflake.com/developer-guide/snowflake-cli-v2/connecting/specify-credentials#how-to-use-environment-variables-for-snowflake-credentials
[^2]: https://docs.snowflake.com/en/sql-reference/sql/execute-immediate
[^3]: https://github.com/snowflakedb/native-apps-templates
[^4]: https://docs.snowflake.com/en/sql-reference/sql/create-compute-pool
[^5]: https://docs.snowflake.com/en/developer-guide/snowpark-container-services/specification-reference
