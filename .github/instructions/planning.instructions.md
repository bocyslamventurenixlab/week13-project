---
description: "Use when creating implementation plans, breaking down features into phases, planning project work, or organizing development tasks into execution steps. Covers phased planning methodology with parallelization strategy."
---
# Phased Planning Methodology

When creating an implementation plan, follow this structured approach:

## 1. Research First
- Read all relevant reference documents and existing code before planning
- Identify existing patterns to reuse (don't reinvent)
- Check reference/PROGRESS.md for current state if the project is in-progress

## 2. De-duplicate
- Reference documents often have overlapping content
- Consolidate repeated concepts into single canonical definitions
- Never create duplicate steps for the same work described in multiple docs

## 3. Structure as Phases
Organize work into sequential phases, each containing parallelizable steps:

```
Phase N: [Name] — [Goal sentence]
  Step N.1: [Task] → [Agent: Coder/Designer]
    Files: [explicit file list]
  Step N.2: [Task] → [Agent]
    Files: [explicit file list]
  Execution: [N.1 | N.2] parallel → N.3 sequential
```

## 4. Parallelization Rules
- Steps touching **different files** → run in parallel
- Steps touching **same files** → run sequentially
- Steps with **data dependencies** → run sequentially
- Design system/primitives → must complete before component work

## 5. File Assignment
Every step MUST list exact files to create or modify. This:
- Prevents parallel agents from conflicting
- Makes progress trackable
- Ensures nothing is forgotten

## 6. Validate Before Integration
Every phase that produces testable logic MUST include a final validation step before moving to the next phase that depends on it:

- **Pure logic** (chunkers, parsers, calculators): Unit test with mocked dependencies
- **Service layers** (database queries, API handlers): Unit test with mocked Supabase/HTTP clients  
- **Middleware** (auth, role guards): Unit test with mock request/response objects
- **Skip for now**: Integration tests that require live services — defer to the final testing phase

The validation step should be numbered as the last sub-step of the phase (e.g., Step 2.4 after Steps 2.1-2.3). It includes:
1. Adding test framework config if not yet present
2. Writing focused unit tests for pure logic and service functions
3. Updating CI to run the new tests

This prevents bugs from compounding across phases and catches structural issues early.

## 7. Dependency Map
Include a visual dependency graph showing which phases can overlap:
```
Phase 0 → Phase 1 → [Phase 2 | Phase 3] parallel → Phase 4
```

## 8. Edge Cases & Open Questions
- List potential problems and how to handle them
- Surface decisions that need user input before proceeding
- Note deferred items explicitly (e.g., "blocked until X is provided")

## 9. Progress Integration
- Plans should reference `reference/IMPLEMENTATION_PLAN.md` for storage
- Progress should be tracked in `reference/PROGRESS.md`
- Both files should be updated as work proceeds
