---
title: Snowflake Postgres and pg_lake: Developer Cheatsheet
description: Developer quick reference for Snowflake Postgres instances and pg_lake Iceberg integration
authors:
  - kamesh-sampath_snow <kamesh.sampath@snowflake.com>
date: 2026-06-07
version: "2.0"
tags: [snowflake-postgres, pg_lake, iceberg, postgres, data-engineering]
---

# Snowflake Postgres and pg_lake: Developer Cheatsheet

Managed Postgres instances inside Snowflake. `pg_lake` adds Iceberg table support —
write from Postgres, read from Snowflake, no external S3 required for the simplest path.

> [!IMPORTANT]
> Community cheatsheet: not official Snowflake documentation.
> For the authoritative reference, see [Snowflake Postgres docs](https://docs.snowflake.com/en/user-guide/snowflake-postgres/about).

## Table of Contents

- [Quick Start](#quick-start)
- [Create and Configure an Instance](#create-and-configure-an-instance)
- [Networking: Connect Your IP](#networking-connect-your-ip)
- [Connect with psql](#connect-with-psql)
- [Manage Instances](#manage-instances)
- [pg_lake: Enable and Use](#pg_lake-enable-and-use)
- [Expose pg_lake Tables to Snowflake](#expose-pg_lake-tables-to-snowflake)
- [Customer-Managed S3 Storage](#customer-managed-s3-storage)
- [Tips and Gotchas](#tips-and-gotchas)
- [References](#references)

## Quick Start

Grant the privilege, create an instance, allow your IP, and connect — four commands:

```sql
GRANT CREATE POSTGRES INSTANCE ON ACCOUNT TO ROLE your_role;

CREATE POSTGRES INSTANCE my_pg
  COMPUTE_FAMILY = 'STANDARD_M' STORAGE_SIZE_GB = 50
  POSTGRES_VERSION = 17 AUTHENTICATION_AUTHORITY = POSTGRES;
-- Save the credentials from the result — shown only once.
```

Allow your IP before connecting:

```sql
CREATE OR REPLACE NETWORK RULE my_pg_rule
  TYPE = IPV4 VALUE_LIST = ('YOUR_IP/32') MODE = POSTGRES_INGRESS;
ALTER POSTGRES INSTANCE my_pg SET NETWORK_POLICY = 'my_pg_rule';
```

Connect:

```shell
psql "host=<host> port=5432 dbname=postgres user=snowflake_admin \
  sslmode=require connect_timeout=10"
```

Enable pg_lake and create your first Iceberg table:

```sql
CREATE EXTENSION pg_lake CASCADE;
CREATE TABLE events (id INT, name TEXT, ts TIMESTAMPTZ) USING iceberg;
```

Expose to Snowflake:

```sql
CREATE OR REPLACE CATALOG INTEGRATION my_pg_catalog
  CATALOG_SOURCE = SNOWFLAKE_POSTGRES TABLE_FORMAT = ICEBERG
  CATALOG_NAMESPACE = 'public'
  REST_CONFIG = (POSTGRES_INSTANCE = 'my_pg' CATALOG_NAME = 'postgres'
                 ACCESS_DELEGATION_MODE = VENDED_CREDENTIALS)
  ENABLED = TRUE;

CREATE OR REPLACE ICEBERG TABLE sf_events
  CATALOG = 'my_pg_catalog' CATALOG_TABLE_NAME = 'events';

SELECT * FROM sf_events;
```

> [!NOTE]
> `pg_lake` requires `STANDARD` or `HIGH_MEMORY` compute family. `BURSTABLE` is not supported.

## Create and Configure an Instance

```sql
CREATE POSTGRES INSTANCE <name>
  COMPUTE_FAMILY = '<family>' STORAGE_SIZE_GB = <10–65535>
  AUTHENTICATION_AUTHORITY = POSTGRES
  [ POSTGRES_VERSION = { 16 | 17 | 18 } ]
  [ NETWORK_POLICY = '<policy>' ] [ HIGH_AVAILABILITY = { TRUE | FALSE } ];
```

Compute families:

| Family | vCPU | RAM | pg_lake |
| --- | --- | --- | --- |
| `BURSTABLE` | 2 | 1 GB | No |
| `STANDARD_S` | 2 | 8 GB | Yes |
| `STANDARD_M` | 4 | 16 GB | Yes |
| `STANDARD_L` | 8 | 32 GB | Yes |
| `HIGH_MEMORY_M` | 4 | 32 GB | Yes |
| `HIGH_MEMORY_L` | 8 | 64 GB | Yes |

List and inspect:

```sql
SHOW POSTGRES INSTANCES;
DESCRIBE POSTGRES INSTANCE <name>;
```

## Networking: Connect Your IP

```sql
CREATE OR REPLACE NETWORK RULE <rule>
  TYPE = IPV4 VALUE_LIST = ('YOUR_IP/32') MODE = POSTGRES_INGRESS;
CREATE OR REPLACE NETWORK POLICY <policy>
  ALLOWED_NETWORK_RULE_LIST = ('<rule>');
ALTER POSTGRES INSTANCE <name> SET NETWORK_POLICY = '<policy>';
```

Add IPs to an existing rule:

```sql
ALTER NETWORK RULE <rule> SET VALUE_LIST = ('IP1/32', 'IP2/32', 'CIDR/24');
```

## Connect with psql

Get hostname from `DESCRIBE POSTGRES INSTANCE <name>` (the `host` column).

```shell
psql "host=<host> port=5432 dbname=postgres user=snowflake_admin \
  sslmode=require connect_timeout=10"
```

Save as a named service (`~/.pg_service.conf`):

```ini
[my_pg]
host=<host>
port=5432
dbname=postgres
user=snowflake_admin
sslmode=require
```

```shell
psql "service=my_pg connect_timeout=10"
```

> [!IMPORTANT]
> Always include `connect_timeout=10`. Without it, psql hangs for 2+ minutes against
> a suspended instance or an instance with no matching network rule.

## Manage Instances

```sql
ALTER POSTGRES INSTANCE <name> SET COMPUTE_FAMILY = 'STANDARD_L' STORAGE_SIZE_GB = 200;
ALTER POSTGRES INSTANCE <name> SET COMPUTE_FAMILY = 'STANDARD_L' APPLY IMMEDIATELY;
ALTER POSTGRES INSTANCE <name> SUSPEND;
ALTER POSTGRES INSTANCE <name> RESUME;
ALTER POSTGRES INSTANCE <name> SET POSTGRES_VERSION = 18 APPLY IMMEDIATELY;
ALTER POSTGRES INSTANCE <name> REGENERATE_CREDENTIALS;
DROP POSTGRES INSTANCE <name>;
```

Check status during async operations:

```sql
DESCRIBE POSTGRES INSTANCE <name>;
-- STATE column: Creating → Restoring → Ready
```

Custom Postgres settings (JSON):

```sql
ALTER POSTGRES INSTANCE <name>
  SET POSTGRES_SETTINGS = ( 'work_mem' = '128MB' );
```

## pg_lake: Enable and Use

Connect to Postgres and enable the extension:

```sql
CREATE EXTENSION pg_lake CASCADE;
```

Verify it loaded:

```sql
SELECT name, installed_version FROM pg_available_extensions WHERE name = 'pg_lake';
```

Create Iceberg tables with `USING iceberg`:

```sql
CREATE TABLE orders (
  order_id BIGINT PRIMARY KEY, customer TEXT,
  amount NUMERIC(12,2), created_at TIMESTAMPTZ DEFAULT now()
) USING iceberg;
```

Standard DML — no special syntax:

```sql
INSERT INTO orders VALUES (1, 'alice', 99.99, now());
UPDATE orders SET amount = 109.99 WHERE order_id = 1;
DELETE FROM orders WHERE order_id = 1;
SELECT * FROM orders WHERE customer = 'alice';
```

pg_lake storage patterns:

| Pattern | Storage | Setup | Best for |
| --- | --- | --- | --- |
| **Shared Iceberg** | Snowflake-managed | Catalog integration only | Simplest path to Snowflake analytics |
| **Stages** | Postgres internal | Internal storage integration | Bidirectional file exchange |
| **Customer-managed S3** | Your S3 bucket | IAM + storage integration | Full data ownership |

## Expose pg_lake Tables to Snowflake

Shared Iceberg (recommended — no S3 needed):

```sql
CREATE OR REPLACE CATALOG INTEGRATION <catalog>
  CATALOG_SOURCE = SNOWFLAKE_POSTGRES TABLE_FORMAT = ICEBERG
  CATALOG_NAMESPACE = 'public'
  REST_CONFIG = (POSTGRES_INSTANCE = '<instance>'
                 CATALOG_NAME = 'postgres'
                 ACCESS_DELEGATION_MODE = VENDED_CREDENTIALS)
  ENABLED = TRUE;
```

Create individual Snowflake Iceberg tables:

```sql
CREATE OR REPLACE ICEBERG TABLE <sf_table>
  CATALOG = '<catalog>' CATALOG_TABLE_NAME = '<pg_table>';
ALTER ICEBERG TABLE <sf_table> SET AUTO_REFRESH = TRUE;
ALTER ICEBERG TABLE <sf_table> REFRESH;
```

Sync an entire Postgres database at once:

```sql
CREATE DATABASE <sf_db>
  LINKED_CATALOG = (CATALOG = <catalog> ALLOWED_WRITE_OPERATIONS = NONE);
```

Grant access to other roles:

```sql
GRANT USAGE ON INTEGRATION <catalog> TO ROLE analyst_role;
GRANT USAGE ON DATABASE <sf_db> TO ROLE analyst_role;
GRANT CREATE ICEBERG TABLE ON SCHEMA <sf_db>.public TO ROLE analyst_role;
```

Control refresh interval:

```sql
ALTER CATALOG INTEGRATION <catalog> SET REFRESH_INTERVAL_SECONDS = 60;
```

> [!NOTE]
> pg_lake Iceberg tables are **read-only** in Snowflake. `ALLOWED_WRITE_OPERATIONS = NONE` is required.

## Customer-Managed S3 Storage

```sql
CREATE STORAGE INTEGRATION <integration>
  TYPE = EXTERNAL_STAGE STORAGE_PROVIDER = POSTGRES_EXTERNAL_STORAGE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::ACCOUNT_ID:role/YOUR_ROLE'
  STORAGE_ALLOWED_LOCATIONS = ('s3://YOUR_BUCKET/prefix/')
  ENABLED = TRUE;
```

Get IAM values for the trust policy:

```sql
DESCRIBE INTEGRATION <integration>;
-- Copy STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID, update IAM trust policy.
```

Attach to instance:

```sql
ALTER POSTGRES INSTANCE <name> SET STORAGE_INTEGRATION = '<integration>';
```

→ [Full IAM setup](https://docs.snowflake.com/en/user-guide/snowflake-postgres/postgres-pg_lake)

## Tips and Gotchas

- **`BURSTABLE` + pg_lake = failure.** The extension simply won't enable. Use `STANDARD_S` or higher.
- **Credentials shown once.** On CREATE and REGENERATE_CREDENTIALS, the password appears in the
  result row only — save it immediately.
- **No network policy = connection hangs.** Always use `connect_timeout=10` in psql so failures are immediate.
- **pg_lake tables are read-only in Snowflake.** The Postgres side is the write path.
- **Resize does not propagate to replicas.** Apply `COMPUTE_FAMILY` changes to each read replica separately.

## References

- [Snowflake Postgres overview](https://docs.snowflake.com/en/user-guide/snowflake-postgres/about)
- [Create a Snowflake Postgres instance](https://docs.snowflake.com/en/user-guide/snowflake-postgres/postgres-create-instance)
- [Manage instances](https://docs.snowflake.com/en/user-guide/snowflake-postgres/managing-instances)
- [Networking and network policies](https://docs.snowflake.com/en/user-guide/snowflake-postgres/postgres-network)
- [pg_lake and data movement](https://docs.snowflake.com/en/user-guide/snowflake-postgres/postgres-pg_lake)
- [Snowflake Postgres extensions](https://docs.snowflake.com/en/user-guide/snowflake-postgres/postgres-extensions)
- [Catalog-linked databases](https://docs.snowflake.com/en/user-guide/tables-iceberg-catalog-linked-database)
