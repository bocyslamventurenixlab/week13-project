# Architecture Decision Record: OT System

## Status

Selected as the target architecture for planning; operational and data-protection approval remains open.

## Decision

Use the repository's stated stack for the OT care-management system:

- Frontend: React 19, Vite, Tailwind CSS v4, and TypeScript.
- Gateway: Node.js 20, Express, TypeScript, and Supabase Auth.
- AI service: Python 3.11, FastAPI, and LangGraph.
- Database: Supabase PostgreSQL with pgvector and JSONB.
- POC model integration: OpenRouter; production model/provider remains undecided.
- Deployment: Railway, with Docker-based local development.

This selection supersedes the self-hosted Docker/PostgreSQL/Ollama/n8n proposal in `reference/week13-project.md` for this plan. The user reports that hosted processing has organizational approval; document the approval's scope and conditions before production data is loaded.

## Constraints and outstanding decisions

- Do not load real client records until hosting, access, retention, backup, and organizational/privacy requirements are approved.
- Confirm whether local development uses hosted Supabase or a local Supabase stack and document environment boundaries.
- Staff data requests must preserve the authenticated user's JWT so Supabase RLS can enforce assigned-client access. Do not use the `service_role` key for ordinary staff read paths because it bypasses RLS.
- OTM can manage assigned clients; other listed roles are read-only. Physical deletion is disabled; archiving is a privileged operation that retains actor and timestamp.
- Client creation is followed by a separate authorized read after the database assigns the creator. Do not depend on `INSERT ... RETURNING` for this flow, because the row is not visible under the assigned-client read policy until the assignment trigger has run.
- Confirm the approved email provider and scheduler; n8n is not assumed by this decision.
- Confirm whether an external model or embedding service may process client-derived data. Keep those integrations disabled for real data until explicitly approved.
- Document approved service-to-service authentication, secret storage, and production environment ownership before deployment.
