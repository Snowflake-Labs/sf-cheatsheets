# Snowflake Developer Cheatsheets

Single-file, copy-paste-ready quick references for Snowflake features developers reach for daily.
Not docs. Not tutorials. The 5–10 things you actually use, verified once, formatted to fit in your
peripheral vision.

> Community resource — not official Snowflake documentation.
> For authoritative reference, see [docs.snowflake.com](https://docs.snowflake.com).

## Cheatsheets

| Cheatsheet | What it covers |
| --- | --- |
| [Executor Role](executor-role-cheatsheet.md) | `EXECUTE AS OWNER/CALLER`, task/dynamic table execution context, masking policy context functions, troubleshooting permission errors |
| [Snowflake CLI](snowflake-cli-cheatsheet.md) | `snow` CLI commands, connection management, SQL execution, object management |
| [SPCS](spcs-cheatsheet.md) | Snowpark Container Services setup, compute pools, service specs, image registry |
| [Warehouses](warehouses-cheatsheet.md) | Warehouse sizing, auto-suspend, multi-cluster, resource monitors, cost controls |
| [Iceberg](iceberg-cheatsheet.md) | Iceberg table creation, catalog integration, storage options, time travel |
| [Snowflake Postgres](snowflake-postgres-cheatsheet.md) | Snowflake Postgres instances, pg_lake, CLD setup, managed storage |
| [GitHub Authentication](snowflake-gh-authn-cheatsheet.md) | OIDC-first auth, GitHub Actions integration, PAT fallback |
| [RAG Evaluation](rag-evaluation-cheatsheet.md) | RAGAS metrics, Cortex evaluation functions, evaluation dataset setup |
| [Cortex Code](cortex-code-cheatsheet.md) | Cortex Code CLI commands, sessions, skills, context management |

## Why a cheatsheet, not just asking an agent?

> A cheatsheet is the answer you already verified, ready the moment you need it.
> An AI agent is the answer you hope is right, arriving after a round-trip.

Agents re-generate every time. That means hallucination risk (confidently wrong flags, deprecated
syntax, commands that don't exist), 2–10 second round-trip latency, and no offline use. A cheatsheet
has been manually verified once, survives a plane flight or an air-gapped VPC, and can be pinned in
Slack, bookmarked, or pasted into onboarding docs. It also builds mental models in a way that
prompting doesn't.

The mistake is using an agent as a faster cheatsheet. Agents win on reasoning over *your specific
context* — debug this error, explain why this query is slow, generate this pipeline from a description.
That is not what a cheatsheet is for.

## Contributing

If you want to add a cheatsheet for your area, there is a Cortex Code skill that does the research,
drafts the content, runs the quality gate, and opens the PR:

```
$create-cheatsheet
```

The skill walks you through scope → draft → style/lint → developer value scorecard → PR in a single
session. The output is a 300–450 line markdown file that passes a 6-dimension quality rubric before
it ships. Conventional commit prefix for cheatsheets is `docs:`.

If you find an error or a gap in an existing cheatsheet, file an issue or open a PR directly.

## Issues

File all issues at <https://github.com/Snowflake-Labs/sf-cheatsheets/issues>

## License

[Apache License](./LICENSE)
