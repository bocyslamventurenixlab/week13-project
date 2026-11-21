# OT Workflow Requirements

## Scope

The target system centralizes care-client information for the OT department. Intended users listed in the project brief are OTM, OT, PsyNurse, OTA, ST, and DT. The product must provide client lookup and profiles, authorized creation and amendment of records, analysis, and report exports.

## Confirmed workflow goals

1. Consolidate existing client records maintained in Excel.
2. Search for a client and view a profile containing relevant client details and history.
3. Allow authorized staff to add, amend, and delete records.
4. Analyze cognitive-level trends, physical-condition measures, and activity-group performance.
5. Generate reports in PDF, Word, or Excel formats.
6. Support staff enquiries and analysis using AI in a later, privacy-approved phase.
7. Send scheduled reports or notifications to designated staff groups after recipients and content are approved.

## Proposed rollout

1. Inventory, validate, and import existing workbook data into a centralized database.
2. Deliver authenticated client search, profiles, CRUD operations, and role-based access.
3. Add analysis, report generation, and scheduled communications.
4. Add privacy-gated AI assistance and semantic search.

## Confirmed decisions

- The base client-data access boundary is assigned clients. Define and test any additional role-, home-, or team-based restrictions before implementation.
- OTM may create and edit assigned clients and may soft-archive them. OT, PsyNurse, OTA, ST, and DT are read-only for their assigned clients.
- Hosted processing on Supabase/Railway has been reported as approved. Record the approval's scope and conditions in the project security review before production data is loaded.

## Decisions required before implementation

- Which workbook files and historical periods are in scope? Who owns each source and confirms its accuracy?
- How should duplicate clients, conflicting values, incomplete rows, corrections, deletions, and historical changes be handled?
- Are any field-level restrictions needed beyond the OTM write permission and assigned-client read access?
- Are any additional restrictions needed by care home, team, or record category beyond assigned-client access?
- What filters, time windows, definitions, and grouping rules should analyses use?
- What should happen when a measure is missing, changes definition, or has too few observations?
- Which reports are needed, how often are they delivered, who approves the content, and who receives them?
- Should profile access and exports be audited, and what audit details may be retained?
- What are the acceptance criteria for import accuracy, search, analysis, report contents, and delivery?

No client-specific examples or production records are included in this document.
