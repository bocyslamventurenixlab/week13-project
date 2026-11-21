---
description: "Use when creating or modifying app-level models, enums, or schemas that map to database tables. Also use when writing database migrations, ingestion pipelines, or any service that reads from or writes to a database. Covers enum/type alignment, error handling at storage boundaries, and contract validation in tests."
applyTo: "**/models/**,**/migrations/**,**/ingestion/**,**/pipelines/**,**/schemas/**"
---
# Cross-Service Contracts — DB Schema ↔ App Code Alignment

## The Core Problem

Database schemas and app-level types (enums, models, field names) are often created in separate steps — sometimes by different agents or in different sessions. Unit tests mock the database client entirely, so mismatches between app code and the real schema are invisible until runtime. The result: all tests pass, but the first real request fails with a 500.

## Rules

### Rule 1: Read the migration before defining the model

When creating or modifying any app-level type that maps to a database table, ALWAYS read the relevant migration file(s) first. Never guess column names, enum values, types, or constraints.

```
# WRONG workflow — define model from memory or assumptions
class StatusType(str, Enum):
    ACTIVE = "active"       # ← might not match DB enum
    INACTIVE = "inactive"   # ← might not match DB enum

# RIGHT workflow
# Step 1: Read the migration → CREATE TYPE status AS ENUM ('enabled', 'disabled');
# Step 2: Define model to match exactly
class StatusType(str, Enum):
    ACTIVE = "enabled"
    INACTIVE = "disabled"
```

This applies to:
- Enum string values
- Column names and types (e.g., `snake_case` in SQL vs app naming)
- NOT NULL constraints (know which fields must be provided)
- Foreign key relationships
- Check constraints (e.g., `CHECK (value BETWEEN 1 AND 17)`)

### Rule 2: When creating a migration, check if app models already exist

The reverse is equally dangerous. If you're writing a new migration and app-level models already reference the table, read those models first to ensure the migration doesn't break them.

```
# Before writing: ALTER TABLE orders ADD COLUMN status ...
# Check: Does the app already have an Order model? What field names does it expect?
```

### Rule 3: Every pipeline that writes to a DB must have a top-level try/except

Any function that inserts, updates, or deletes database records must wrap the operation in error handling that surfaces the actual failure reason — not a generic 500.

```python
# WRONG — unhandled exception becomes opaque 500
async def process(data):
    db.table("items").insert(record).execute()

# RIGHT — structured error with context
async def process(data):
    try:
        db.table("items").insert(record).execute()
    except Exception as e:
        logger.exception("Failed to insert item")
        raise ServiceError(f"Database insert failed: {e}")
```

This is especially important for:
- Enum value mismatches (DB rejects unknown enum members)
- NOT NULL violations (missing required fields)
- Foreign key violations (referencing nonexistent parent rows)
- Type mismatches (e.g., sending a string where DB expects integer)

### Rule 4: Tests must assert the exact values being sent to the database

When mocking a database client, don't just verify the mock was called — assert the exact payload, especially enum values, field names, and types.

```python
# WRONG — proves the function ran, but not that it sent correct data
mock_db.table("items").insert.assert_called_once()

# RIGHT — proves the actual values match what the DB expects
call_args = mock_db.table("items").insert.call_args[0][0]
assert call_args["status"] == "enabled"        # exact DB enum value
assert call_args["priority"] is not None       # NOT NULL field
assert isinstance(call_args["count"], int)     # correct type
```

### Rule 5: Define enum values as constants derived from a single source of truth

If both a migration and app code need the same set of values, define them once and reference everywhere. At minimum, add a comment linking to the source.

```python
class MaterialType(str, Enum):
    """Maps to DB enum 'material_type' — see migrations/003_create_materials.sql"""
    VIDEO = "video"        # Must match: CREATE TYPE material_type AS ENUM ('video', ...)
    DOCUMENT = "document"
```

If the project supports shared constants (e.g., a `shared/` package), define enum values there. Otherwise, the migration SQL is the source of truth — app code must conform to it.

### Rule 6: Synchronous calls inside async functions must be offloaded

When an async pipeline calls a synchronous library (e.g., a blocking HTTP client, a PDF parser, a sync DB driver), wrap it with `asyncio.to_thread()` or equivalent to avoid blocking the event loop.

```python
# WRONG — blocks the entire event loop during the HTTP call
async def generate_description(text: str):
    response = sync_client.completions.create(...)

# RIGHT — offloads to a thread
async def generate_description(text: str):
    response = await asyncio.to_thread(sync_client.completions.create, ...)
```

## Checklist

- [ ] Read the migration SQL before defining any app model/enum that maps to a DB table
- [ ] Read existing app models before writing a migration that modifies their table
- [ ] Enum string values in app code exactly match the DB enum definition
- [ ] All NOT NULL columns are provided in every insert
- [ ] DB-writing functions have top-level try/except with meaningful error messages
- [ ] Tests assert exact payload values sent to mocked DB client (not just "was called")
- [ ] Enum classes have a comment linking to the source migration
- [ ] Synchronous library calls inside async functions are offloaded to threads
