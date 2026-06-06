---
authors:
  - Kamesh Sampath<kamesh.sampath@snowflake.com>
date: "2026-06-06"
version: "1.0"
tags: [cortex-code, coco, cheatsheet, developer]
---

# Cortex Code (CoCo) — Developer Cheatsheet

> [!IMPORTANT]
> Community cheatsheet — not official Snowflake documentation. For the authoritative reference,
> see [Cortex Code CLI docs](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-cli).

## Table of Contents

- [Quick Start](#quick-start)
- [Start Here By Role](#start-here-by-role)
- [The 7 Trigger Characters](#the-7-trigger-characters)
- [Slash Commands You'll Actually Use](#slash-commands-youll-actually-use)
- [Keyboard Shortcuts That Matter](#keyboard-shortcuts-that-matter)
- [Working with Your Codebase](#working-with-your-codebase)
- [Snowflake Data Shortcuts](#snowflake-data-shortcuts)
- [Agent Modes](#agent-modes)
- [Skills](#skills)
- [Scheduling](#scheduling)
- [Memory Across Sessions](#memory-across-sessions)
- [Environment Variables](#environment-variables)
- [Settings Worth Knowing](#settings-worth-knowing)
- [CLI Subcommands](#cli-subcommands)
- [MCP Integration](#mcp-integration)
- [Hooks](#hooks)
- [Tips & Gotchas](#tips--gotchas)
- [Further Reading](#further-reading)
- [References](#references)

## Quick Start

Install on macOS/Linux:

```shell
# run in terminal
curl -sL https://sfc-repo.snowflakecomputing.com/cortex/install.sh | bash
```

Common launch options:

```shell
# run in terminal
cortex                                                          # launch in current directory
cortex -c my_connection -w /path/to/project                     # set connection and working dir
cortex --continue                                               # resume last session
cortex -p "list all Python files" --output-format stream-json   # one-off prompt (scripting)
```

## Start Here By Role

| If you're a... | Focus on |
| --- | --- |
| **DB / Data Developer** | `#TABLE`, `/sql`, `cortex search table-details`, Semantic Views, SQL timeout |
| **App Developer** (Streamlit, Native Apps) | `@{file}`, `/diff`, `/worktree`, `$snowflake-apps`, `$deploy-to-spcs` |
| **Data / ML Engineer** | `/lineage`, `$machine-learning`, `$cortex-agent`, `$dynamic-tables`, fdbt |
| **Platform / Infra** | `/plan`, `/team`, `/bg`, Hooks, MCP, Scheduling, Memory |

## The 7 Trigger Characters

| Trigger | Name | What it does | Example |
| --- | --- | --- | --- |
| `/` | Slash command | Invoke a slash command | `/sql SELECT current_user()` |
| `!` | Bash shell | Run a terminal command inline | `! git status` |
| `@` | File reference | Reference a file by path (no inject) | `@src/app.py review this` |
| `@{` | File inject | Inject full file contents into prompt | `@{schema.sql} write tests` |
| `#` | Table reference | Autocomplete table name, load schema | `#DB.PUBLIC.ORDERS summarize` |
| `$` | Skill invoke | Invoke a skill by name | `$semantic-view create a view for sales` |
| `%` | Agent mention | Mention a Cortex Agent | `%my_sales_agent what was Q1 revenue?` |

> [!TIP]
> `@{file}` is the most useful trigger for developers: inject a config, schema, or source file
> into context without manually copying content.

## Slash Commands You'll Actually Use

**Execution & modes:**

| Command | What it does |
| --- | --- |
| `/plan` / `Ctrl+P` | Enter plan mode — CoCo presents a plan before making changes |
| `/bypass` | Auto-approve all tool calls |
| `/team` / `Ctrl+G` | Enable parallel teammates mode |
| `/bg` | Launch a background agent, keep chatting |
| `/agents` | View and manage running subagents |

**SQL & data:**

| Command | What it does |
| --- | --- |
| `/sql <query>` | Execute SQL inline (`--limit N` for row cap) |
| `/sql-readonly` | Toggle SQL write protection |
| `/table` | Open interactive table viewer |
| `/connections` | Manage Snowflake connections |
| `/doctor` | Diagnose connection issues |

**Code & git:**

| Command | What it does |
| --- | --- |
| `/diff` | Review git changes fullscreen (`--staged` for staged) |
| `/worktree <create\|list\|switch\|delete>` | Manage git worktrees |

**Skills & config:** `/skill` `/rules` `/hooks` `/mcp` `/settings` `/permissions`

**Utilities:** `/copy` `/share` `/secrets` `/compact` `/rewind` `/new` `/resume` `/fork` `/index` `/tgrep`

## Keyboard Shortcuts That Matter

| Shortcut | Action |
| --- | --- |
| `Ctrl+P` | Toggle plan mode |
| `Ctrl+G` | Toggle team mode |
| `Ctrl+S` | Open subagent picker |
| `Ctrl+O` | Cycle view mode (compact → expanded → transcript) |
| `Ctrl+T` | Open table viewer |
| `Ctrl+C` | Interrupt / cancel |
| `Alt+T` | Open/close fullscreen task viewer |
| `Shift+Tab` | Cycle permission level (Confirm → Plan → Bypass) |
| `Ctrl+R` | History search (reverse) |
| `Ctrl+J` | Insert newline in input (for multiline prompts) |
| `Esc Esc` | Clear entire input |
| `Ctrl+A` | Move to start of input |
| `Ctrl+E` | Move to end of input |

## Working with Your Codebase

| Trigger | Example | What happens |
| --- | --- | --- |
| `@file` | `@src/auth.py what does this do?` | References the path (no content injection) |
| `@{file}` | `@{schema.sql} write tests for this` | Injects full file contents into context |
| `@{f1} @{f2}` | `@{schema.sql} @{models.py} do these match?` | Inject multiple files at once |

For semantic code search: `/tgrep status` to check, `/index --rebuild` after major changes.

Ask naturally — CoCo uses tgrep internally: `"find where authentication errors are handled"`

## Snowflake Data Shortcuts

Reference a table to load its schema instantly:

```text
#SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS how many orders this year?
```

Run SQL (use `Ctrl+J` for newlines in multiline queries):

```text
/sql SELECT COUNT(*), SUM(O_TOTALPRICE) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
     WHERE O_ORDERDATE >= '1995-01-01'
/sql SELECT O_ORDERSTATUS, COUNT(*) AS cnt
     FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS GROUP BY 1
/sql SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER --limit 10
```

Discover objects and check docs before writing queries:

```shell
# run in terminal
cortex search object "TPCH orders"
cortex search table-details "SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS"
cortex search docs "dynamic tables target lag"
cortex lineage SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS --direction downstream --tree
```

Or from within CoCo: `!cortex search table-details "SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS"`

`SNOWFLAKE_SAMPLE_DATA` is in every Snowflake account (no setup). Other schemas: `TPCDS_SF10TCL` (retail), `WEATHER`.

## Agent Modes

| Mode | How to activate | When to use |
| --- | --- | --- |
| **Plan** | `/plan` or `Ctrl+P` | Any multi-file or risky change — CoCo drafts a plan before touching anything |
| **Bypass** | `/bypass` or `Shift+Tab` | Auto-approve all tool calls (careful on prod) |
| **Team** | `/team` or `Ctrl+G` | Spawn parallel agents for large tasks |
| **Background** | `/bg` | Fire off a task, keep chatting; results arrive as a notification |

Git worktrees for parallel safe work: `/worktree create <branch>` gives each agent its own branch.

## Skills

Invoke with `$` prefix in the CoCo prompt: `$cortex-agent build a Q&A agent over my warehouse`

**Manage:**

```text
/skill              # browse installed skills
/skill list         # list all
```

```shell
# run in terminal
cortex skill list
cortex skill find "<query>"
cortex skill add <name>
```

Custom skills: place a `.md` file in `.cortex/skills/` (project) or `~/.snowflake/cortex/skills/` (global).

**Bundled skills:**

| Skill | What it does |
| --- | --- |
| `$cortex-agent` | Build, debug, deploy Cortex Agents |
| `$semantic-view` | Create/manage semantic views for Cortex Analyst |
| `$snowflake-apps` | Scaffold and deploy Snowflake App Runtime apps |
| `$deploy-to-spcs` | Deploy containers to Snowpark Container Services |
| `$machine-learning` | Train models, use Model Registry, run ML jobs |
| `$dynamic-tables` | Build incremental pipelines with Dynamic Tables |
| `$lineage` | Trace upstream/downstream column-level lineage |
| `$warehouse` | Analyze and right-size warehouse costs |

## Scheduling

```text
/loop                        # interactive scheduler
/loop "every day at 9am"     # natural language
/loop "0 9 * * 1-5"          # standard cron (Mon–Fri 9am)
/automation                  # schedule a recurring agent task
```

> [!NOTE]
> Scheduled tasks are session-scoped and expire after 3 days. Max 50 per session.

## Memory Across Sessions

Enable once, then memories persist across every CoCo session.

```shell
# run in terminal — enable memory (pick one)
export CORTEX_ENABLE_MEMORY=1        # environment variable
# or set in ~/.snowflake/cortex/settings.json: "enableMemory": true
```

**remember** — save something CoCo should know in every future session:

```text
cortex memory remember "use conventional commits: feat:, fix:, docs:, chore:, refactor:, test:"
cortex memory remember "production db is read-only, use role PROD_READ for queries"
cortex memory remember "default warehouse is COMPUTE_WH_M, only use XL for full-table scans"
cortex memory remember "prefer async/await over .then() in this codebase"
```

**recall** — find a specific memory by topic:

```text
cortex memory recall "commit format"
cortex memory recall "production access"
cortex memory recall "warehouse sizing"
```

**list / drop** — manage stored memories:

```text
cortex memory list               # show all memories with IDs
cortex memory drop <id>          # remove a specific memory by ID
```

> [!TIP]
> Natural language works too:
> * Say "remember that we deploy to us-east-1" and CoCo stores it.
> * Say "what's our commit convention?" and CoCo recalls it from memory without a command.

## Environment Variables

| Variable | Effect |
| --- | --- |
| `CORTEX_ENABLE_MEMORY` | Enable cross-session memory (alternative to settings) |
| `COCO_DISABLE_CRON` | Disable `/loop` and all scheduling tools |
| `COCO_DISABLE_ROUTINES` | Disable routines |
| `CORTEX_CODE_STREAMING` | Enable code streaming |
| `CORTEX_AGENT_USE_LOCAL_ORCHESTRATOR` | Use local orchestrator (developer/debug mode) |
| `CTX_STEP_ENFORCEMENT` | Enforce ctx step tracking discipline |
| `CORTEX_BROWSER_HEADLESS` | Run browser automation without a visible window |
| `CORTEX_CODE_ENABLE_SNOWFLAKE_MANAGED_MCP_SERVERS` | Enable Snowflake-managed MCP servers |
| `CORTEX_DISABLE_TODO_TOOL` | Disable the todo/task tool |

## Settings Worth Knowing

Configure via `/settings` or edit `~/.snowflake/cortex/settings.json`.

| Key | Default | What it does |
| --- | --- | --- |
| `agentMode` | `standard` | Agent behavior profile (`standard` or `code`) |
| `autoAcceptPlans` | `false` | Skip the "approve plan?" prompt |
| `enableMemory` | `false` | Enable cross-session memory |
| `tgrepEnabled` | `true` | Enable semantic code search |
| `sqlDefaultTimeoutSeconds` | `180` | Max wait for SQL queries |
| `diffDisplayMode` | `unified` | `unified` (git-style) or `side_by_side` |
| `bashDefaultTimeoutMs` | `180000` | Timeout for shell commands |
| `mcpWait` | `false` | Wait for all MCP servers before starting (useful in CI) |
| `disableCron` | `false` | Disable `/loop` scheduling |

## CLI Subcommands

Run outside the interactive session — useful in scripts, CI, and automation.

| Command | What it does |
| --- | --- |
| `cortex search object "<query>"` | Find tables, views, schemas by name or description |
| `cortex search table-details "DB.SCHEMA.TABLE"` | Full column metadata for a table |
| `cortex search docs "<query>"` | Search Snowflake product docs |
| `cortex search marketplace "<query>"` | Search Marketplace listings |
| `cortex lineage DB.SCHEMA.TABLE --direction both --tree` | Trace upstream and downstream lineage |
| `cortex connections list` | List available connections |
| `cortex connections set <name>` | Switch active connection |
| `cortex semantic-views list` | List semantic views in the account |
| `cortex worktree create <branch>` | Create a git worktree (also available via `/worktree`) |
| `cortex skill list` | List installed skills |
| `cortex memory remember "<text>"` | Store a memory (requires `enableMemory: true`) |
| `cortex update` | Update to the latest version |

For the full command list: [CLI Reference](https://docs.snowflake.com/en/user-guide/cortex-code/cli-reference)

## MCP Integration

Config file: `~/.snowflake/cortex/mcp.json` | Manage: `cortex mcp add | list | remove` | In-session: `/mcp`

Tool naming inside CoCo: `mcp__<server>__<tool>` (e.g. `mcp__github__create_pull_request`)

Supported transports: `http`, `sse`, `stdio`

**Add a server (example: GitHub):**

```shell
# run in terminal
cortex mcp add
# ↳ transport=stdio, command=npx, args=-y @modelcontextprotocol/server-github
# ↳ env: GITHUB_PERSONAL_ACCESS_TOKEN=<your-token>
```

Other popular servers (all via `npx -y @modelcontextprotocol/server-<name>`):
`filesystem`, `postgres`, `brave-search`, `slack`

Set `mcpWait: true` in settings if MCP tools must be ready before the first prompt (CI/automation).

For setup details: [MCP docs](https://docs.snowflake.com/en/user-guide/cortex-code/extensibility)

## Hooks

Hooks fire shell scripts in response to lifecycle events.
Configure in `~/.snowflake/cortex/hooks/`.

| Event | When it fires |
| --- | --- |
| `UserPromptSubmit` | User submits a prompt |
| `PreToolUse` | Before any tool call |
| `PostToolUse` | After any tool call |
| `PermissionRequest` | When a permission prompt appears |
| `Stop` | Agent stops |
| `SessionStart` | Session begins |
| `SessionEnd` | Session ends |
| `PreCompact` | Before conversation compaction |

View and test configured hooks:

```text
/hooks
```

## Tips & Gotchas

- **`/plan` before anything risky.** CoCo reads the codebase, drafts a plan, and waits for your approval.
  For multi-file changes this is the difference between a clean refactor and a mess.
- **`#TABLE` loads schema automatically.** Type `#` then the table name — CoCo fetches column definitions before
  writing any SQL. No need to describe the table.
- **`/bg` for long jobs.** Fire off a background agent to run a big refactor or analysis while you keep
  chatting. Results arrive as a notification.
- **`cortex search docs` is semantic.** "how do I set target lag for dynamic tables" finds the right page
  faster than a Google search.
- **Secrets stay out of chat.** Use `/secrets` to store API keys and tokens. CoCo injects them at runtime
  without exposing them in the session transcript.

## References

- [Cortex Code CLI](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-cli)
- [CLI Reference (slash commands, batch mode)](https://docs.snowflake.com/en/user-guide/cortex-code/cli-reference)
- [Keyboard Shortcuts](https://docs.snowflake.com/en/user-guide/cortex-code/keyboard-shortcuts)
- [Bundled Skills](https://docs.snowflake.com/en/user-guide/cortex-code/bundled-skills)
- [Settings Reference](https://docs.snowflake.com/en/user-guide/cortex-code/settings)
- [Extensibility (hooks, plugins, MCP)](https://docs.snowflake.com/en/user-guide/cortex-code/extensibility)
- [Changelog](https://docs.snowflake.com/en/user-guide/cortex-code/changelog)

## Further Reading

Concepts behind intent-driven development and why tools like CoCo change how builders work:

- [Infrastructure as Intent: The Field Velocity Blueprint](https://blogs.kameshs.dev/infrastructure-as-intent-the-field-velocity-blueprint-e6217ef30f14)
- [The Ghost in the Machine: Why AI Needs the Spirit of UML](https://blogs.kameshs.dev/the-ghost-in-the-machine-why-ai-needs-the-spirit-of-uml-0d8864e583e2)
- [Intent-Driven Development: The Shift Developers Can't Ignore](https://blogs.kameshs.dev/intent-driven-development-the-shift-developers-cant-ignore-ef434f94d56c)
- [Intent Compression Ratio: Measuring the Power of Intent](https://blogs.kameshs.dev/intent-compression-ratio-measuring-the-power-of-intent-ceb6faf2e2f9)
- [ICR and Token Economics](https://blogs.kameshs.dev/icr-and-token-economics-9a014a75b399)
