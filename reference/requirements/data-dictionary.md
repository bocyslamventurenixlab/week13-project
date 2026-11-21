# Provisional OT Data Dictionary

This is a discovery checklist derived from the project brief, not an approved final database schema. Confirm exact field names, types, allowed values, historical meaning, and access rules against the source workbooks and OT stakeholders before finalizing the schema or importing data. Do not copy real client data into this document.

The user approved a provisional starter model before a workbook sample is available. The first migration uses `full_name` as required, `age_years` as a nullable non-negative integer, and the remaining listed attributes as nullable text. The follow-up migration adds `created_by`, `archived_at`, and `archived_by`; the staff-role table stores one of `otm`, `ot`, `psynurse`, `ota`, `st`, or `dt`. This model is for contract development only; revise it after inspecting a blank or anonymized workbook, and before any real-data import.

The initial importer recognizes common name, age, cognitive-level, diet, supplement, restraint, and activity-group header variants. Unknown or duplicate mapped columns, missing name headers, invalid rows, and formula cells produce issues; `can_import` remains false if any issue exists. The parser does not write to the database or deduplicate records.

| Domain | Fields indicated by the brief | To confirm |
| --- | --- | --- |
| Client identity | Name, age | Stable identifier, date-of-birth handling, name changes, duplicate resolution |
| Cognitive status | Cognitive level | Scale, allowed values, observation date, assessor, change/history semantics |
| Diet | Diet | Controlled vocabulary, restrictions/allergies distinction, effective dates |
| Supplements | Supplement | Product/value format, dosage or schedule scope, effective dates |
| Restraints | Restraints | Approved terminology, status/history, authorization and access restrictions |
| Activities | Activity group | Group identifiers, membership history, participation versus assignment |
| Physical condition | Not specified beyond analysis goal | Measures, units, scale, collection frequency, assessor, missing-value rules |
| Record history | Multi-year records are mentioned | Source workbook, import batch, created/updated dates, correction and deletion history |

## Import requirements to validate

- Inventory workbook versions, sheets, headers, formulas, merged cells, date formats, and historical schema changes.
- Preserve source provenance and report row-level validation errors without silently discarding data.
- Determine stable identity matching and duplicate review rules before any records are merged.
- Define dry-run, retry, and rerun behavior; imports must not create duplicates or overwrite newer corrections.
- Use synthetic or anonymized examples for development and automated tests.
