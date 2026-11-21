# OT Care Management System — Implementation Plan

## Objective and approved direction

Build a secure OT system that consolidates Excel-based client records, provides staff with authorized client profiles and updates, supports trend analysis and report exports, and later adds scheduled communications and AI-assisted enquiries.

The selected target stack is React/Vite, an Express/TypeScript gateway, FastAPI/LangGraph, Supabase, and Railway. This supersedes the self-hosted stack proposal in `reference/week13-project.md` for planning purposes, but does not approve hosted processing of real client data. Use synthetic or anonymized data until required organizational/privacy approvals are recorded.

The separate `.github/week13-prd.md` currently describes a vinyl-collector PWA and is not an OT requirement. Decide whether to archive or replace it before implementation. Existing student/instructor access examples in `.github/copilot-instructions.md` also need OT-specific alignment.

## Phase 0: Requirements, privacy, and project alignment — sequential

1. **Define workflows and data dictionary.** Confirm workbook formats, fields/history, duplicates, correction workflow, staff workflows, report contents, recipient groups, and success criteria.
   - Files: `reference/requirements/ot-workflows.md`, `reference/requirements/data-dictionary.md`
2. **Approve security and architecture decisions.** Use assigned-client access as the base boundary. OTM may create/edit/soft-archive assigned clients; OT, PsyNurse, OTA, ST, and DT are read-only. Decide any home/team/field-level exceptions, audit, retention, backup, email provider/scheduler, and AI data handling. Record the reported Supabase/Railway approval scope before production import.
   - Files: `reference/decisions/architecture.md`, `reference/decisions/data-protection.md`
3. **Establish project tracking and resolve conflicting guidance.** Create the progress tracker and decide how to handle the unrelated vinyl PRD and stale student/instructor examples. Do not silently delete or repurpose either source.
   - Files: `reference/IMPLEMENTATION_PLAN.md`, `reference/PROGRESS.md`, `.github/week13-prd.md`, `.github/copilot-instructions.md`

**Gate:** Do not import or process real client data until the workbook mapping is validated, role permissions are tested, and the reported hosting approval's scope and conditions are recorded.

## Phase 1: Shared contracts and secure data foundation

1. Define canonical client, history, analysis, and error contracts.
   - Files: `shared/openapi.yaml`, `shared/types/client.ts`, `shared/types/analysis.ts`
2. Create the provisional Supabase schema, least-privilege grants, assigned-client RLS, OTM-only writes, soft archive, and policy tests.
   - Files: `supabase/migrations/0001_client_records.sql`, `supabase/migrations/0002_role_permissions_and_archive.sql`, `supabase/tests/client_rls.test.sql`, `supabase/seed.sql`
3. Bootstrap the frontend, gateway, and AI service, including local containers and environment templates.
   - Files: `frontend/package.json`, `frontend/vite.config.ts`, `frontend/tsconfig.json`, `frontend/src/main.tsx`, `frontend/src/App.tsx`, `gateway/package.json`, `gateway/tsconfig.json`, `gateway/src/index.ts`, `ai-brain/pyproject.toml`, `ai-brain/uv.lock`, `ai-brain/app/main.py`, `frontend/Dockerfile`, `gateway/Dockerfile`, `ai-brain/Dockerfile`, `docker-compose.yml`, `.env.example`
4. Build a repeatable, validated Excel parser with row-level errors. Unknown workbook headers, formulas, and duplicate mappings must block import; defer database writes and duplicate resolution until the source workbook and identity rules are confirmed.
   - Files: `ai-brain/ingestion/__init__.py`, `ai-brain/ingestion/excel_import.py`, `ai-brain/ingestion/validation.py`, `ai-brain/tests/ingestion/test_excel_import.py`
5. Extend CI for the AI service and document local setup; run focused parser and RLS validation.
   - Files: `.github/workflows/ci.yml`, `README.md`, `reference/PROGRESS.md`

After contracts are defined, database migrations and service scaffolding can proceed in parallel because their file ownership is separate. The importer follows the scaffolding and schema; CI validation follows all Phase 1 tasks.

## Phase 2: Staff authentication and client workflows

1. Implement JWT verification, OT role authorization, client search/profile CRUD, validation, structured storage errors, and unit tests. Create records without `RETURNING`, then fetch them after the assignment trigger has run so the row satisfies the read policy.
   - Files: `gateway/src/middleware/auth.ts`, `gateway/src/middleware/authorize.ts`, `gateway/src/routes/clients.ts`, `gateway/src/services/clientService.ts`, `gateway/tests/auth.test.ts`, `gateway/tests/clients.test.ts`
2. Build sign-in and protected navigation, searchable client records, profile/history views, and authorized create/edit flows.
   - Files: `frontend/src/contexts/AuthContext.tsx`, `frontend/src/components/ProtectedRoute.tsx`, `frontend/src/pages/LoginPage.tsx`, `frontend/src/pages/ClientSearchPage.tsx`, `frontend/src/pages/ClientProfilePage.tsx`, `frontend/src/pages/ClientFormPage.tsx`, `frontend/src/pages/ClientSearchPage.test.tsx`, `frontend/src/contexts/AuthContext.test.tsx`
3. Validate allowed/denied access, CRUD behavior, and database isolation against the approved permission matrix.
   - Files: `gateway/tests/clients.test.ts`, `supabase/tests/client_rls.test.sql`, `reference/PROGRESS.md`

Gateway and frontend implementation can proceed in parallel against Phase 1 contracts; integration validation follows both.

## Phase 3: Analytics, reports, and scheduled communications

1. Implement deterministic cognitive-level trends, approved physical-condition measures, and activity-group performance. Define missing-data behavior and time windows with OT stakeholders.
   - Files: `ai-brain/analytics/trends.py`, `ai-brain/api/routes/analytics.py`, `ai-brain/tests/analytics/test_trends.py`
2. Build dashboards with date/group filters and PDF, Word, and Excel exports.
   - Files: `frontend/src/pages/AnalyticsPage.tsx`, `frontend/src/components/CognitiveTrendChart.tsx`, `frontend/src/components/PhysicalConditionChart.tsx`, `frontend/src/components/GroupPerformanceChart.tsx`, `frontend/src/lib/exportReports.ts`, `frontend/src/lib/exportReports.test.ts`
3. Add scheduled summaries to approved staff groups using the selected scheduler/provider; record delivery outcomes and prevent unintended disclosure.
   - Files: `gateway/src/jobs/scheduledReports.ts`, `gateway/src/services/emailService.ts`, `gateway/tests/scheduledReports.test.ts`
4. Validate calculations, exports, authorization, recipients, and delivery failures; update progress.
   - Files: `ai-brain/tests/analytics/test_trends.py`, `frontend/src/lib/exportReports.test.ts`, `gateway/tests/scheduledReports.test.ts`, `reference/PROGRESS.md`

Tasks 1–3 can proceed in parallel after Phase 2; validation follows them.

## Phase 4: Privacy-gated AI assistance — parallel with Phase 3 after Phase 2

1. Add typed enquiry contracts and LangGraph workflows grounded in authorized records. Keep deterministic calculations as the source for numeric analysis; include required response traces and minimize/redact sensitive content. External model use remains disabled until approved.
   - Files: `ai-brain/models/enquiry.py`, `ai-brain/agents/enquiry_graph.py`, `ai-brain/rag/retrieval.py`, `ai-brain/core/redaction.py`, `ai-brain/tests/agents/test_enquiry_graph.py`, `supabase/migrations/0003_ai_traces.sql`
2. Add an authorized enquiry interface with clear AI labeling and explicit error states.
   - Files: `frontend/src/pages/EnquiryPage.tsx`, `frontend/src/components/AIResponse.tsx`, `frontend/src/pages/EnquiryPage.test.tsx`
3. Test role isolation, redaction, trace completeness, model failure, and grounded answers with synthetic records and mocked models. Require human review for consequential care decisions.
   - Files: `ai-brain/tests/agents/test_enquiry_graph.py`, `ai-brain/tests/core/test_redaction.py`, `reference/PROGRESS.md`

Tasks 1–2 can proceed in parallel after Phase 2; validation follows. Real-data AI use remains gated on approval.

## Phase 5: Deployment, operational readiness, and controlled pilot

1. Finalize Railway deployment, secret handling, health checks, and Docker behavior. Each service must honor its runtime port and bind to `0.0.0.0`.
   - Files: `frontend/Dockerfile`, `gateway/Dockerfile`, `ai-brain/Dockerfile`, `docker-compose.yml`, `.github/workflows/deploy.yml`, `.env.example`
2. Document import operations, backup/restore verification, incident handling, audit review, and escalation paths.
   - Files: `reference/runbooks/backup-restore.md`, `reference/runbooks/incident-response.md`, `README.md`, `reference/PROGRESS.md`
3. Validate with synthetic data first. Only conduct a limited real-data pilot after organizational approval, access review, and restore test; record acceptance and outstanding risks.
   - Files: `reference/acceptance-criteria.md`, `reference/PROGRESS.md`

## Dependency map

```text
Phase 0 → Phase 1 → Phase 2 → [Phase 3 | Phase 4] parallel → Phase 5
```

## Risks and open decisions

- Workbook structure, historical formats, duplicate clients, invalid values, and partial imports must be discovered before schema finalization.
- Assigned-client access is the confirmed base boundary. OTM-only writes and soft archive are approved; confirm any additional care home/team/field-level restrictions.
- Confirm report fields, email recipients, approval, export auditing, and schedule/retry behavior.
- Establish retention, correction/deletion, backups, incident response, and applicable organizational/privacy approvals before real-data use.
- Do not assume a free-tier hosted database or external AI provider is approved for care records. Keep sensitive data out of prompts and traces unless approved.
- Define missing-data and measure-change rules; AI must not be presented as clinical judgment.
