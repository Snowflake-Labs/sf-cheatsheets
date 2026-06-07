---
title: Apache Iceberg on Snowflake: Developer Cheatsheet
description: Developer quick reference for Iceberg tables on Snowflake
authors:
  - kamesh-sampath_snow <kamesh.sampath@snowflake.com>
date: 2026-06-07
version: "4.0"
tags: [iceberg, snowflake, sql, data-engineering, external-volume, open-catalog, cld]
---

# Apache Iceberg on Snowflake: Developer Cheatsheet

Iceberg tables on Snowflake: open-format data in your cloud (or Snowflake-managed) storage,
queryable with Snowflake SQL, interoperable with Spark, Flink, and Trino.

> [!IMPORTANT]
> Community cheatsheet: not official Snowflake documentation.
> For the authoritative reference, see [Apache Iceberg Tables docs](https://docs.snowflake.com/en/user-guide/tables-iceberg).

## Table of Contents

- [Storage Options](#storage-options)
- [Start Here By Role](#start-here-by-role)
- [Quick Start: Snowflake-Managed Storage](#quick-start-snowflake-managed-storage)
- [External Volume Setup](#external-volume-setup)
- [Create Iceberg Tables](#create-iceberg-tables)
- [Catalog-Linked Database: Bulk Sync from External Catalog](#catalog-linked-database-bulk-sync-from-external-catalog)
- [Ingest Data](#ingest-data)
- [Schema Evolution](#schema-evolution)
- [Query and DML](#query-and-dml)
- [Time Travel](#time-travel)
- [Manage Tables](#manage-tables)
- [Tips and Gotchas](#tips-and-gotchas)
- [References](#references)

## Storage Options

| Option | Setup required | DML | Best for |
| --- | --- | --- | --- |
| **Snowflake-managed** | None | Full | Getting started fast |
| **AWS S3** | S3 bucket + IAM role | Full | AWS shops |
| **Azure Data Lake Storage** | ADLS container + service principal | Full | Azure shops |
| **GCS** | GCS bucket + service account | Full | GCP shops |
| **Open Catalog (Polaris)** | Polaris catalog + REST integration | Read-only | Multi-engine (Spark, Flink, Trino) |

> [!NOTE]
> Snowflake-managed storage does not support Tri-Secret Secure. Accounts with TSS
> enabled may be blocked after May 26, 2026 — contact Snowflake Support to enable.

## Start Here By Role

| If you are a... | Focus on |
| --- | --- |
| **Data Engineer** | Quick Start, External Volume, Create Tables, CLD, Ingest, Schema Evolution |
| **App Developer** | Quick Start, Query and DML, Manage Tables |
| **Data Analyst** | Quick Start, Query and DML, Time Travel |
| **ML / AI Engineer** | Query and DML (VARIANT), Schema Evolution, Ingest Data |
| **Platform / Infra** | Storage Options, External Volume Setup, Manage Tables, Tips |

## Quick Start: Snowflake-Managed Storage

Create the namespace:

```sql
CREATE DATABASE IF NOT EXISTS iceberg_db;
CREATE SCHEMA IF NOT EXISTS iceberg_db.iceberg_schema;
```

Create an Iceberg table — no external volume needed:

```sql
CREATE ICEBERG TABLE iceberg_db.iceberg_schema.events (
  event_id   VARCHAR,
  event_type VARCHAR,
  ts         TIMESTAMP_NTZ,
  payload    VARIANT
)
  CATALOG         = 'SNOWFLAKE'
  EXTERNAL_VOLUME = 'SNOWFLAKE_MANAGED'
  BASE_LOCATION   = 'events/';
```

Insert and verify:

```sql
INSERT INTO events VALUES ('1', 'click', CURRENT_TIMESTAMP(), PARSE_JSON('{"page":"/home"}'));
SELECT * FROM events LIMIT 5;
```

Check table format:

```sql
DESC ICEBERG TABLE iceberg_db.iceberg_schema.events;
```

> [!TIP]
> `EXTERNAL_VOLUME = 'SNOWFLAKE_MANAGED'` is reserved — no `CREATE EXTERNAL VOLUME` step needed.

## External Volume Setup

Cloud parameters:

| Cloud | STORAGE_PROVIDER | Extra required fields |
| --- | --- | --- |
| AWS | `S3` | `STORAGE_AWS_ROLE_ARN` |
| Azure | `AZURE` | `STORAGE_AZURE_TENANT_ID` |
| GCP | `GCS` | none |

Create the volume (AWS):

```sql
CREATE OR REPLACE EXTERNAL VOLUME my_iceberg_vol
  STORAGE_LOCATIONS = (
    (
      NAME                 = 'my-s3-location'
      STORAGE_PROVIDER     = 'S3'
      STORAGE_BASE_URL     = 's3://YOUR_BUCKET/iceberg/'
      STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::ACCOUNT_ID:role/YOUR_ROLE'
    )
  )
  ALLOW_WRITES = TRUE;
```

Get IAM values for the trust policy:

```shell
snow sql --query "DESC EXTERNAL VOLUME my_iceberg_vol" --format json \
  | jq -r '.[1].property_value | fromjson | .STORAGE_AWS_IAM_USER_ARN, .STORAGE_AWS_EXTERNAL_ID'
```

Verify:

```sql
DESC EXTERNAL VOLUME my_iceberg_vol;
SHOW EXTERNAL VOLUMES;
```

→ [Full cloud setup guides](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume)

> [!IMPORTANT]
> `ALLOW_WRITES = TRUE` is required. External volumes default to read-only.

## Create Iceberg Tables

Standard (customer-managed storage):

```sql
CREATE ICEBERG TABLE orders (
  order_id VARCHAR, customer VARCHAR,
  amount NUMBER(10, 2), created_at TIMESTAMP_NTZ
)
  CATALOG = 'SNOWFLAKE' EXTERNAL_VOLUME = 'my_iceberg_vol' BASE_LOCATION = 'orders/';
```

With schema evolution enabled:

```sql
CREATE ICEBERG TABLE orders_ev (order_id VARCHAR, customer VARCHAR)
  CATALOG = 'SNOWFLAKE' EXTERNAL_VOLUME = 'my_iceberg_vol'
  BASE_LOCATION = 'orders_ev/' ENABLE_SCHEMA_EVOLUTION = TRUE;
```

Register an externally written table (from Spark/Flink):

```sql
CREATE ICEBERG TABLE ext_orders
  CATALOG = 'SNOWFLAKE' EXTERNAL_VOLUME = 'my_iceberg_vol'
  BASE_LOCATION = 'ext_orders/'
  METADATA_FILE_PATH = 'ext_orders/metadata/00001-abc123.metadata.json';
```

Clone:

```sql
CREATE ICEBERG TABLE orders_clone CLONE orders;
```

> [!IMPORTANT]
> `BASE_LOCATION` is permanent — cannot be changed after creation.
> A clone shares the source table's base location.

## Catalog-Linked Database: Bulk Sync from External Catalog

**When to use:** you have an external Iceberg catalog (Open Catalog/Polaris, AWS Glue, Unity
Catalog) with many tables and want Snowflake to auto-discover all of them — without running
`CREATE ICEBERG TABLE` for each one.

First create a catalog integration pointing to the external catalog:

```sql
CREATE OR REPLACE CATALOG INTEGRATION my_ext_catalog
  CATALOG_SOURCE = ICEBERG_REST
  TABLE_FORMAT = ICEBERG
  CATALOG_NAMESPACE = 'default'
  REST_CONFIG = (CATALOG_URI = 'https://my-catalog-endpoint')
  REST_AUTHENTICATION = (TYPE = OAUTH ...)
  ENABLED = TRUE;
```

Create the catalog-linked database — Snowflake auto-discovers namespaces and tables:

```sql
CREATE DATABASE my_linked_db
  LINKED_CATALOG = (CATALOG = 'my_ext_catalog');
```

Query tables directly — no registration step:

```sql
USE DATABASE my_linked_db;
SELECT * FROM my_namespace.my_iceberg_table LIMIT 20;
```

Check sync status:

```sql
SELECT SYSTEM$CATALOG_LINK_STATUS('my_linked_db');
SELECT SYSTEM$GET_CATALOG_LINKED_DATABASE_CONFIG('my_linked_db');
```

**Individual table vs CLD — the decision:**

| | Individual `CREATE ICEBERG TABLE` | Catalog-Linked Database |
| --- | --- | --- |
| Tables to register | A few specific tables | Many tables from an external catalog |
| Discovery | Manual, one by one | Automatic — Snowflake polls and syncs |
| Write support from Snowflake | Full (if `CATALOG = 'SNOWFLAKE'`) | Supported for externally managed tables |
| Best for | Selective access, Snowflake-as-catalog | External catalog with existing ecosystem |

## Ingest Data

| Method | Best for |
| --- | --- |
| `INSERT / COPY INTO` | Batch loads |
| Snowpipe | Automated micro-batch from cloud storage |
| Snowpipe Streaming | Low-latency streaming |
| `CREATE ... AS SELECT` | One-shot conversion from native table |

Bulk load from staged files (Parquet):

```sql
COPY INTO orders FROM @my_stage/orders/
  FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
```

Convert a native table:

```sql
CREATE ICEBERG TABLE orders_iceberg
  CATALOG = 'SNOWFLAKE' EXTERNAL_VOLUME = 'my_iceberg_vol' BASE_LOCATION = 'orders_iceberg/'
AS SELECT * FROM orders_native;
```

## Schema Evolution

Enable:

```sql
ALTER ICEBERG TABLE orders SET ENABLE_SCHEMA_EVOLUTION = TRUE;
```

Column operations:

```sql
ALTER ICEBERG TABLE orders ADD COLUMN status VARCHAR;
ALTER ICEBERG TABLE orders RENAME COLUMN status TO order_status;
ALTER ICEBERG TABLE orders DROP COLUMN order_status;
ALTER ICEBERG TABLE orders ALTER COLUMN amount SET DATA TYPE NUMBER(12, 2);
```

> [!NOTE]
> Only widening type changes are supported (`INT → BIGINT`, `VARCHAR(100) → VARCHAR(500)`).

## Query and DML

```sql
SELECT * FROM orders WHERE order_status = 'PENDING';
INSERT INTO orders VALUES ('001', 'alice', 99.99, CURRENT_TIMESTAMP());
UPDATE orders SET order_status = 'SHIPPED' WHERE order_id = '001';
DELETE FROM orders WHERE order_status = 'CANCELLED';
MERGE INTO orders t USING updates s ON t.order_id = s.order_id
  WHEN MATCHED     THEN UPDATE SET t.order_status = s.order_status
  WHEN NOT MATCHED THEN INSERT VALUES (s.order_id, s.customer, s.amount, s.created_at);
```

## Time Travel

```sql
SELECT * FROM orders AT (OFFSET => -60 * 30);
SELECT * FROM orders AT (TIMESTAMP => '2026-01-01 00:00:00'::TIMESTAMP_NTZ);
SELECT * FROM orders BEFORE (STATEMENT => 'YOUR_QUERY_ID');
```

Restore:

```sql
CREATE OR REPLACE ICEBERG TABLE orders CLONE orders
  AT (TIMESTAMP => '2026-01-01 00:00:00'::TIMESTAMP_NTZ);
```

## Manage Tables

```sql
SHOW ICEBERG TABLES IN SCHEMA iceberg_db.iceberg_schema;
DESC ICEBERG TABLE orders;
SELECT SYSTEM$ICEBERG_METADATA('iceberg_db.iceberg_schema.orders');
ALTER ICEBERG TABLE orders REFRESH;
DROP ICEBERG TABLE orders;
```

Table sizes across schema:

```sql
SELECT table_name, bytes, row_count FROM information_schema.tables
WHERE table_schema = 'ICEBERG_SCHEMA' AND table_type = 'ICEBERG'
ORDER BY bytes DESC;
```

## Tips and Gotchas

- **`BASE_LOCATION` is permanent.** Cannot be changed after table creation: pick a meaningful path.
- **`ALLOW_WRITES = TRUE` on the volume.** Every DML silently fails without it.
- **External catalog tables are read-only** unless using write support for externally managed tables.
  DML with `CATALOG = 'SNOWFLAKE'` works fully; external REST catalog tables are limited.
- **Clone shares data files.** A cloned Iceberg table writes to the same base location as the source.
- **`REFRESH` after external writes.** Run before querying if Spark or Flink wrote to the same volume.
- **CLD requires a REST catalog.** `CREATE DATABASE ... LINKED_CATALOG` only works with an Iceberg
  REST catalog (Open Catalog, Glue, Unity Catalog) — not with `CATALOG = 'SNOWFLAKE'`.

## References

- [Apache Iceberg Tables overview](https://docs.snowflake.com/en/user-guide/tables-iceberg)
- [Create and manage Iceberg tables](https://docs.snowflake.com/en/user-guide/tables-iceberg-manage)
- [Catalog-linked database for Iceberg](https://docs.snowflake.com/en/user-guide/tables-iceberg-catalog-linked-database)
- [Configure external volume](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume)
- [Iceberg data types](https://docs.snowflake.com/en/user-guide/tables-iceberg-data-types)
- [Iceberg with Open Catalog](https://docs.snowflake.com/en/user-guide/tables-iceberg-open-catalog)
- [Snowpipe Streaming with Iceberg](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/data-load-snowpipe-streaming-overview)
