---
authors:
  - Kamesh Sampath <kamesh.sampath@snowflake.com>
date: "2026-06-08"
version: "1.0"
tags: [snowflake, security, rbac, stored-procedures, tasks, dynamic-tables, data-engineering]
---

# Snowflake Executor Role — Developer Cheatsheet

The role Snowflake uses to check privileges at runtime: not who calls the object,
but whose grants apply when it executes.

> [!IMPORTANT]
> Community cheatsheet — not official Snowflake documentation.
> For the authoritative reference, see
> [Snowflake Security docs](https://docs.snowflake.com/en/guides-overview-secure).

## Table of Contents

- [The Executor Role Model](#the-executor-role-model)
- [Per-Object Quick Reference](#per-object-quick-reference)
- [Stored Procedures](#stored-procedures)
- [Tasks](#tasks)
- [Dynamic Tables](#dynamic-tables)
- [UDFs and UDTFs](#udfs-and-udtfs)
- [Alerts](#alerts)
- [Streamlit Apps](#streamlit-apps)
- [Masking and Row Access Policies](#masking-and-row-access-policies)
- [Decision Matrix](#decision-matrix)
- [Tips and Gotchas](#tips-and-gotchas)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## The Executor Role Model

When Snowflake runs a stored procedure, task, UDF, or dynamic table, it evaluates
privileges against a specific role. That role is the **executor role**: whose grants
are checked, not necessarily the role of the person who triggered execution.

Two context functions expose this at query time:

| Function | Returns |
| --- | --- |
| `CURRENT_ROLE()` | The session role of the user running the query |
| `INVOKER_ROLE()` | The role Snowflake uses for the currently executing object |

These return the same value at the top-level session. They diverge inside objects.

## Per-Object Quick Reference

| Object | Default Executor | Configurable? | Syntax | Extra Privilege Required |
| --- | --- | --- | --- | --- |
| **Stored Procedure** | Owner role | Yes | `EXECUTE AS OWNER \| CALLER \| RESTRICTED CALLER` | `USAGE` on proc |
| **Task** | Owner role | No | — | `EXECUTE TASK` (account-level) |
| **Dynamic Table** | Owner role as SYSTEM user | Yes (user) | `EXECUTE AS USER <name>` | `IMPERSONATE` on target user |
| **UDF / UDTF** | Owner role | No | — | `USAGE` on function |
| **Alert** | Owner role | No | — | `EXECUTE ALERT` (account-level) |
| **Streamlit App** | Owner role | No | — | Owner must have data privileges |
| **Masking / Row Policy** | Context-dependent | Via policy body | `INVOKER_ROLE()` or `CURRENT_ROLE()` | Enterprise Edition |

> [!NOTE]
> Dynamic tables run as an internal SYSTEM user by default.
> The owner role's grants apply, but `CURRENT_USER()` returns a system identity, not a
> named user. Use `EXECUTE AS USER` when policies or audit trails require a real user.

## Stored Procedures

The `EXECUTE AS` clause sets the execution context at creation time. Default is owner's rights.

Owner's rights: runs with the procedure owner's privileges:

```sql
CREATE OR REPLACE PROCEDURE myschema.clean_old_orders()
  RETURNS VARCHAR
  LANGUAGE SQL
  EXECUTE AS OWNER
AS
BEGIN
  DELETE FROM orders WHERE created_at < DATEADD(year, -7, CURRENT_DATE());
  RETURN 'done';
END;
```

Caller's rights: runs with the caller's current role:

```sql
CREATE OR REPLACE PROCEDURE myschema.get_my_orders(region VARCHAR)
  RETURNS TABLE (order_id NUMBER, status VARCHAR)
  LANGUAGE SQL
  EXECUTE AS CALLER
AS
BEGIN
  RETURN TABLE(SELECT order_id, status FROM orders WHERE o_region = :region);
END;
```

Restricted caller's rights (Native Apps only):

```sql
CREATE OR REPLACE PROCEDURE CORE.PROCESS_CONSUMER_DATA()
  RETURNS STRING
  LANGUAGE SQL
  EXECUTE AS RESTRICTED CALLER
AS
BEGIN
  RETURN 'processed';
END;
```

Grant a caller grant to a Native App (run in consumer account):

```sql
GRANT CALLER USAGE ON DATABASE consumer_db TO APPLICATION my_app;
```

Change execution rights on an existing procedure:

```sql
ALTER PROCEDURE myschema.clean_old_orders() EXECUTE AS CALLER;
```

Key behavioral differences:

| Behavior | Owner's Rights | Caller's Rights |
| --- | --- | --- |
| Privileges used | Owner role | Caller's current role |
| Session variables | Cannot read or set | Can read and set |
| Database/schema context | Proc's own db/schema | Caller's current db/schema |
| Source code visibility | Hidden from non-owners | Visible to callers |
| Nested procs | Entire chain runs as owner's rights | Only if full chain is caller's rights |

> [!IMPORTANT]
> Once an owner's rights procedure is anywhere in a nested call chain, every procedure
> called from it also runs as owner's rights, even those individually set to `EXECUTE AS CALLER`.

## Tasks

Tasks always run as the task owner role. `EXECUTE TASK` is account-level and must be
granted separately. OWNERSHIP alone does not allow a task to run.

Minimum privilege set for a role to own and execute a task:

```sql
GRANT EXECUTE TASK ON ACCOUNT TO ROLE task_runner_role;
GRANT OWNERSHIP ON TASK mydb.myschema.my_task TO ROLE task_runner_role;
GRANT USAGE ON WAREHOUSE task_wh TO ROLE task_runner_role;
```

Resume a task (requires both OWNERSHIP and EXECUTE TASK):

```sql
ALTER TASK mydb.myschema.my_task RESUME;
```

> [!TIP]
> `EXECUTE TASK` is granted at the account level, not the object level. Creating a task
> does not imply it. A role can own a task and still fail to resume it.

## Dynamic Tables

Background refreshes run as the owner role. The owner role must retain SELECT on all
source objects and USAGE on the warehouse at all times, not just at creation.

Create a dynamic table (owner role needs SELECT on sources + USAGE on warehouse):

```sql
CREATE OR REPLACE DYNAMIC TABLE mydb.myschema.dt_orders
  TARGET_LAG = '10 minutes'
  WAREHOUSE = transform_wh
AS
  SELECT order_id, customer_key, total_price
  FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;
```

Use `EXECUTE AS USER` when masking policies or audit attribution require a named user:

```sql
GRANT IMPERSONATE ON USER svc_transform TO ROLE transform_role;
GRANT ROLE transform_role TO USER svc_transform;

CREATE OR REPLACE DYNAMIC TABLE mydb.myschema.dt_orders
  TARGET_LAG = '10 minutes'
  WAREHOUSE = transform_wh
  EXECUTE AS USER svc_transform
AS
  SELECT order_id, customer_key, total_price
  FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;
```

Activate secondary roles during refresh:

```sql
CREATE OR REPLACE DYNAMIC TABLE mydb.myschema.dt_orders
  TARGET_LAG = '10 minutes'
  WAREHOUSE = transform_wh
  EXECUTE AS USER svc_transform
    USE SECONDARY ROLES ALL
AS
  SELECT ...;
```

Revert to the default SYSTEM user:

```sql
ALTER DYNAMIC TABLE mydb.myschema.dt_orders UNSET EXECUTE AS USER;
```

> [!IMPORTANT]
> If the owner role loses SELECT on any source table or USAGE on the warehouse after
> creation, scheduled refreshes fail and the dynamic table may auto-suspend.
> Transfer ownership only after verifying the new owner role holds all required privileges.

## UDFs and UDTFs

UDFs always execute in the owner's context. This is not configurable.

Grant a role the right to call a UDF:

```sql
GRANT USAGE ON FUNCTION mydb.myschema.mask_ssn(VARCHAR) TO ROLE analyst_role;
```

> [!NOTE]
> Since BCR 2023_03: handler code that reads files from a stage executes in the owner's
> context. Callers must pass file locations via `BUILD_SCOPED_FILE_URL()`. User stages
> are not accessible from owner-context UDFs or stored procedures.

## Alerts

Alerts run as the alert owner role. Like tasks, OWNERSHIP alone does not allow an alert to fire.

Minimum privilege set:

```sql
GRANT EXECUTE ALERT ON ACCOUNT TO ROLE alert_owner_role;
GRANT OWNERSHIP ON ALERT mydb.myschema.my_alert TO ROLE alert_owner_role;
GRANT USAGE ON WAREHOUSE monitor_wh TO ROLE alert_owner_role;
```

## Streamlit Apps

Streamlit apps run with owner's rights. The app owner role must hold privileges on any
Snowflake objects the app queries, not the viewer's role.

Grant data access to the Streamlit owner role:

```sql
GRANT USAGE ON DATABASE analytics_db TO ROLE streamlit_owner_role;
GRANT USAGE ON SCHEMA analytics_db.public TO ROLE streamlit_owner_role;
GRANT SELECT ON TABLE analytics_db.public.orders TO ROLE streamlit_owner_role;
```

> [!TIP]
> A user with `VIEWER` on your app can see any data the owner role can access, even if
> the viewer has no direct grants on the underlying tables. Scope the owner role's
> grants to exactly what the app needs.

## Masking and Row Access Policies

Policy body functions evaluate differently depending on the executing object:

| Context | `INVOKER_ROLE()` returns | `CURRENT_ROLE()` returns |
| --- | --- | --- |
| Direct table query | Session role | Session role |
| View query | View owner role | Session role |
| Owner's rights stored proc | Proc owner role | Session role |
| Caller's rights stored proc | Session role | Session role |
| Task | Task owner role | Session role |
| UDF | UDF owner role | Session role |

Use `INVOKER_ROLE()` when the policy enforces based on the executing object's owner:

```sql
CREATE OR REPLACE MASKING POLICY mask_total AS
(val NUMBER) RETURNS NUMBER ->
CASE
  WHEN INVOKER_ROLE() IN ('FINANCE_ROLE') THEN val
  ELSE -1
END;
```

Use `IS_GRANTED_TO_INVOKER_ROLE()` to check role hierarchy (not just exact match):

```sql
CREATE OR REPLACE MASKING POLICY mask_ssn AS
(val VARCHAR) RETURNS VARCHAR ->
CASE
  WHEN IS_GRANTED_TO_INVOKER_ROLE('PAYROLL') THEN val
  WHEN IS_GRANTED_TO_INVOKER_ROLE('ANALYST') THEN REGEXP_REPLACE(val, '[0-9]', '*', 7)
  ELSE '*******'
END;
```

Use `CURRENT_ROLE()` when the policy enforces based on the session role:

```sql
CREATE OR REPLACE MASKING POLICY mask_by_session AS
(val VARCHAR) RETURNS VARCHAR ->
CASE
  WHEN CURRENT_ROLE() IN ('ANALYST') THEN val
  ELSE '********'
END;
```

## Decision Matrix

| Goal | Use | Notes |
| --- | --- | --- |
| Let a low-privilege role call a proc doing privileged work | `EXECUTE AS OWNER` | Caller needs only `USAGE` on the proc; owner's grants do the rest |
| Proc must read the caller's session variables or current db | `EXECUTE AS CALLER` | Owner mode is isolated from caller session state |
| Native App proc needs consumer account object access | `EXECUTE AS RESTRICTED CALLER` | Consumer uses `GRANT CALLER` to explicitly authorize access |
| Dynamic table refresh needs `CURRENT_USER()` in policy | `EXECUTE AS USER <name>` | Default SYSTEM user fails policy conditions that check user identity |
| Masking policy based on who runs the query | `CURRENT_ROLE()` in policy | Evaluates session role regardless of object ownership |
| Masking policy based on who owns the executing object | `INVOKER_ROLE()` in policy | Evaluates view owner, proc owner, task owner, not session role |

## Tips and Gotchas

- **Ownership transfer on dynamic tables requires a privilege pre-flight.** Grant the new
  owner role SELECT on all source tables and USAGE on the warehouse *before* transferring
  ownership. Transferring first causes the next scheduled refresh to fail and the table
  to auto-suspend.
- **`EXECUTE TASK` and `EXECUTE ALERT` are account-level.** Neither is implied by
  OWNERSHIP. A role can own a task or alert and still be blocked from running it.
  Grant both `EXECUTE TASK ON ACCOUNT` and `EXECUTE ALERT ON ACCOUNT` explicitly.
- **`INVOKER_ROLE()` on a view returns the view owner, not the session role.** If your
  masking policy uses `INVOKER_ROLE()` and is applied to a table accessed via a view,
  the function evaluates the view owner role. Use `CURRENT_ROLE()` if the intent is to
  enforce based on who is running the query.
- **Owner's rights procs hide source code from callers.** `GET_DDL()` on an owner's rights
  proc returns nothing for non-owners. This is intentional. Use it for IP protection.
- **Caller's rights requires the entire call chain.** A single owner's rights proc anywhere
  in a nested call hierarchy converts all downstream procs to owner's rights, regardless
  of their individual `EXECUTE AS` settings.

## Troubleshooting

| Error or Symptom | Cause | Fix |
| --- | --- | --- |
| `Cannot execute task, EXECUTE TASK privilege must be granted to owner role` | `EXECUTE TASK` is account-level; OWNERSHIP does not imply it | `GRANT EXECUTE TASK ON ACCOUNT TO ROLE <owner_role>` |
| Dynamic table refreshes fail after `GRANT OWNERSHIP` | New owner role lacks SELECT on sources or USAGE on warehouse | Grant privileges to new role before transfer; `ALTER DYNAMIC TABLE ... RESUME` |
| `User stage file access is not allowed within an owner's rights SP or UDF` | Owner-context objects cannot access user stages | Use named internal stages; pass paths via `BUILD_SCOPED_FILE_URL()` |
| Masking policy unmasks data through a view despite unprivileged session role | `INVOKER_ROLE()` evaluates the view owner, not the session role | Switch to `CURRENT_ROLE()` for session-role-based enforcement |
| Owner's rights proc fails: `SQL variable ... is not defined` | Owner mode cannot read caller's session variables | Pass the variable as an explicit proc parameter |
| Nested proc unexpectedly runs as owner's rights | Entire chain inherits owner's rights once any proc in it is owner's rights | Extract logic into standalone procs; restructure so owner's rights proc does not call caller's rights procs |
| `Insufficient privileges to execute ALERT` | `EXECUTE ALERT` is account-level; OWNERSHIP does not imply it | `GRANT EXECUTE ALERT ON ACCOUNT TO ROLE <owner_role>` |

## References

- [Caller's Rights and Owner's Rights Stored Procedures](https://docs.snowflake.com/en/developer-guide/stored-procedure/stored-procedures-rights)
- [Restricted Caller's Rights](https://docs.snowflake.com/en/developer-guide/restricted-callers-rights)
- [Dynamic Table Access Control](https://docs.snowflake.com/en/user-guide/dynamic-tables/privileges)
- [Dynamic Tables: EXECUTE AS USER](https://docs.snowflake.com/en/release-notes/2026/other/2026-02-18-dynamic-tables-execute-as-user)
- [INVOKER_ROLE Function](https://docs.snowflake.com/en/sql-reference/functions/invoker_role)
- [IS_GRANTED_TO_INVOKER_ROLE Function](https://docs.snowflake.com/en/sql-reference/functions/is_granted_to_invoker_role)
- [Advanced Column-Level Security Topics](https://docs.snowflake.com/en/user-guide/security-column-advanced)
- [Task Access Control](https://docs.snowflake.com/en/user-guide/tasks-intro)
