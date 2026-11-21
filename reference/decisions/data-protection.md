# OT Data Protection Requirements

## Status

Initial safeguards for planning; organizational, privacy, and security review is still required. This document does not establish legal compliance or independently verify production-data approval.

The user reports that the organization has approved Supabase/Railway for real care-client records. The approval's scope, conditions, and evidence are not recorded here yet. The selected base access boundary is assigned clients: OTM may create/edit/soft-archive assigned clients, while OT, PsyNurse, OTA, ST, and DT are read-only. Additional field-level or home/team restrictions remain to be confirmed.

## Safeguards required before real-data use

- Use only synthetic or anonymized records in local development, tests, and CI.
- Approve the hosting provider, data location, access model, retention, backup, incident response, and deletion/correction process before production import.
- Define least-privilege permissions for OTM, OT, PsyNurse, OTA, ST, and DT. Role names alone do not constitute an access policy.
- Enforce and test database grants and row-level security for every exposed table; do not rely solely on UI or gateway checks.
- Preserve the authenticated staff user's JWT for database reads so RLS applies. The Supabase `service_role` bypasses RLS and must not be used for ordinary staff access.
- Keep secrets out of source control and logs; restrict privileged database credentials to services that require them.
- Minimize sensitive fields in logs, exports, email content, and AI prompts/traces. Apply approved audit retention and access controls.
- Disable external AI/model calls on real client information until the organization explicitly approves the provider, data flow, retention, and safeguards.
- Require human review for consequential care decisions; AI output is assistance, not clinical judgment.
- Verify backup restoration and access-denial behavior before a production pilot.
- Keep physical deletion unavailable to staff; preserve archive actor and timestamp for review.

## Decisions required

- Applicable organizational policies, privacy/security reviewer, and approval evidence.
- Data categories and role-by-role permissions, including home/team/client-assignment boundaries.
- Retention and deletion/correction schedule for client data, audit events, AI traces, exports, and backups.
- Approved deployment region, storage, encryption, key management, backup, and incident-response procedures.
- Whether any identifiable or pseudonymized client data may be sent to email, external AI, or embedding providers.
