# Development Progress

## Current status

Phase 0 — Requirements, privacy, and project alignment: 🟡 In Progress

The OT system scope and repository-stack direction are confirmed for planning. Assigned-client access is the base boundary; OTM may create/edit/soft-archive assigned clients, and other listed roles are read-only. The user reports that Supabase/Railway hosting has organizational approval; document the approval's scope and conditions before production import. Workbook structure, workflow rules, email/scheduler choices, and external AI data handling remain open. No application services exist yet. Use synthetic or anonymized data in development, tests, and CI.

## Phase tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 0. Requirements, privacy, and project alignment | 🟡 | Initial requirements and decision records drafted. Workbook structure remains unknown; hosting approval scope must be recorded. The vinyl PRD and student/instructor examples have not been changed pending repository-owner direction. |
| 1. Shared contracts and secure data foundation | 🟡 | Provisional read contract and importer added; AI Brain tests are wired into CI. Both migrations applied to isolated PostgreSQL; 17 role/access assertions passed. Five importer tests pass. Validate mappings against the actual workbook; parser does not write to the database. Supabase CLI/pgTAP runner and TypeScript compiler are unavailable locally. |
| 2. Staff authentication and client workflows | ⬜ | Depends on Phase 1 contracts, schema, and approved role matrix. |
| 3. Analytics, reports, and scheduled communications | ⬜ | Depends on Phase 2 and approved analysis, export, recipient, and schedule rules. |
| 4. Privacy-gated AI assistance | ⬜ | Depends on Phase 2 and explicit approval for model/provider data flows. |
| 5. Deployment and controlled pilot | ⬜ | Depends on Phases 3 and 4, deployment review, and production-data approval. |

## Decisions

| Topic | Decision / status |
| --- | --- |
| Product scope | OT care-client management system, based on `reference/week13-project.md`. |
| Target stack | Use repository context: React/Vite, Express/TypeScript, FastAPI/LangGraph, Supabase, Railway. Production suitability for real client records remains subject to review. |
| Base access boundary | Assigned clients; additional team/home restrictions remain to be defined. |
| Staff write/delete rules | OTM may create/edit and soft-archive assigned clients; OT, PsyNurse, OTA, ST, and DT are read-only. |
| Hosted-data approval | User reports organizational approval for Supabase/Railway; scope and evidence are not yet recorded in this repository. |
| Provisional schema | User approved a starter model based on the brief; validate against a blank/anonymized workbook before real import. |
| Import behavior | Unknown/duplicate headers, formula cells, and row validation issues block import; no database persistence or deduplication is implemented yet. |
| Test data | Synthetic or anonymized data only until workbook mappings and required approvals are recorded; never commit real client records. |
| Separate vinyl PRD | `.github/week13-prd.md` conflicts with the OT scope; disposition pending. |

## Error log

| Date | Phase/Step | Error | Root Cause | Solution | Resolved |
| --- | --- | --- | --- | --- | --- |
| 2026-11-19 | Phase 1 Task 1.2 validation | Anonymous RLS test expected an empty result but received a permission error | Anonymous users have no table SELECT grant, so the query is rejected before row-level filtering | Assert the missing SELECT grant directly instead of querying the table as anon | ✅ |
| 2026-11-19 | Phase 1 Task 1.2 validation | OTM create with `RETURNING` failed the read policy | The new row is not visible to the assigned-client read policy until the after-insert assignment trigger completes | Insert without `RETURNING`, then fetch the new row in a separate authorized query | ✅ |
| 2026-11-19 | Phase 1 Task 1.3 setup | Legacy pip could not install the new PEP 621 project in editable mode | The available pip version lacks the required editable-build support | Use `uv run --project ai-brain --extra test --python 3.11 pytest ai-brain/tests/ingestion -q` | ✅ |

## AI API cost tracking

No AI API calls have been made.
