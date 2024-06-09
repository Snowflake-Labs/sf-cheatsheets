# Warehouses

Warehouses are the compute horses that does the processing of queries, running Machine Learning algorithms etc.,

## Valid Sizes

- X-Small
- Small
- Medium
- Large
- X-Large
- 2X-Large
- 3X-Large
- 4X-Large
- 5X-Large
- 6X-Large

Check [overview](https://docs.snowflake.com/en/user-guide/warehouses-overview) for details on size and its associated credits.

## Create Warehouse

Create warehouse requires only one parameter the **NAME** of the warehouse.
e.g.
<code>CREATE WAREHOUSE <mark>MY_FIRST_WH</mark></code>

| Property            | Description                                                 | Default  |
| :------------------ | :---------------------------------------------------------- | :------: |
| WAREHOUSE_SIZE      | The warehouse compute size.                                 | X-small  |
| WAREHOUSE_TYPE      | The type of warehouse, `STANDARD` or `SNOWPARK-OPTIMIZED`.  | STANDARD |
| MIN_CLUSTER_COUNT   | Minimum number of servers to scale down to.                 |    1     |
| MIN_CLUSTER_COUNT   | Maximum number of servers to scale out to.                  |    1     |
| MAX_CLUSTER_COUNT   | Minimum number of servers to scale down to.                 |    3     |
| AUTO_SUSPEND        | Idle number of **seconds** before suspending the warehouse. |   300    |
| AUTO_RESUME         | On-demand start of the warehouse .                          |   TRUE   |
| INITIALLY_SUSPENDED | Start warehouse automatically after successful creation.    |   TRUE   |

Check the [docs](https://docs.snowflake.com/en/sql-reference/sql/create-warehouse) for more details on
the parameters and other available options.

Create a Warehouse named `MY_FIRST_WH` with defaults:

```sql
CREATE WAREHOUSE MY_FIRST_WH
```

## CREATE WAREHOUSE MY_SMALL_WH

Create Warehouse named `MY_SMALL_WH` with size as `Small`:

```sql
CREATE WAREHOUSE MY_SMALL_WH
WAREHOUSE_SIZE = 'Small'
```

Create Warehouse named `MY_SMALL_STARTED_WH` with size as `Small` and start it automatically after create:

```sql
CREATE WAREHOUSE MY_SMALL_STARTED_WH
WAREHOUSE_SIZE = 'Small'
INITIALLY_SUSPENDED = FALSE
```

Create Warehouse named `MY_LONG_RUNNING_WH` with size as `Small` and make to automatically suspend after `10 mins(600 seconds)`:

```sql
CREATE WAREHOUSE MY_LONG_RUNNING_WH
WAREHOUSE_SIZE = 'Small'
AUTO_SUSPEND = 600
```

> [!TIP]
>
> - Use bigger Warehouse size for _CPU_ or _Memory_ intensive operations.
> - Adjust _MIN_CLUSTER_COUNT_ and _MAX_CLUSTER_COUNT_ to increase concurrency i.e. process more queries in parallel

## Check Warehouse Properties

Check a particular warehouse properties

```sql
SHOW WAREHOUSES LIKE 'MY_SMALL_WH';
```

## List All Warehouses

```sql
SHOW WAREHOUSES
```

## Working With Warehouse

Use a particular warehouse

```sql
USE WAREHOUSE MY_SMALL_WH
```

Manually start a warehouse,

```sql
ALTER WAREHOUSE MY_SMALL_WH RESUME
```

Manually suspend a warehouse,

```sql
ALTER WAREHOUSE MY_SMALL_WH SUSPEND
```

Change the size of the warehouse

```sql
ALTER WAREHOUSE MY_SMALL_WH
SET
WAREHOUSE_SIZE = 'Small'
WAIT_FOR_COMPLETION = TRUE; -- 1
```

1. `WAIT_FOR_COMPLETION` ensures all existing operations are complete before modifying the size

## Drop Warehouse

```sql
DROP WAREHOUSE MY_SMALL_WH
```

> [!IMPORTANT]
>
> Warehouse's cant be `UNDROPPED`.

## References

- [Warehouses](https://docs.snowflake.com/en/user-guide/warehouses)
- [SQL Commands Reference](https://docs.snowflake.com/en/sql-reference/commands-warehouse)
