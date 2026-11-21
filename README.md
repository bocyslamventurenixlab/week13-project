# OT Care Management System

A staged system for consolidating OT client records, supporting authorized staff workflows, and providing analysis and reports.

## Current development state

The repository is at the provisional data-foundation stage. The Excel parser validates the starter fields from the project brief, but it does not write to the database. Validate its header mapping against a blank or anonymized source workbook before any real import.

Use synthetic or anonymized data in development, tests, and CI. The user reports that Supabase/Railway hosting is approved; document the approval's scope and conditions before production data is loaded.

## Run AI Brain tests

Requirements: Python 3.11+ and [uv](https://docs.astral.sh/uv/).

```sh
uv sync --project ai-brain --extra test --locked
uv run --project ai-brain --extra test --locked pytest ai-brain/tests -q
```

The frontend, gateway, and FastAPI service scaffolds are planned but not yet available.

See [the implementation plan](reference/IMPLEMENTATION_PLAN.md) and [progress tracker](reference/PROGRESS.md) for phase status and open decisions.
