---
description: "Use when updating progress, logging errors, recording implementation decisions, or tracking API costs during development. Covers how to maintain the PROGRESS.md file."
---
# Progress Tracking Protocol

## When to Update
- **After completing any step**: Update status from ⬜ to ✅
- **When starting a step**: Update status from ⬜ to 🟡
- **When blocked**: Update status to ❌ with explanation in Notes
- **When encountering errors**: Add to Error Log immediately
- **When making decisions**: Add to Decisions section

## File Location
`reference/PROGRESS.md`

## Status Symbols
- ⬜ Not Started
- 🟡 In Progress
- ✅ Complete
- ❌ Blocked

## Error Log Format
When logging errors, include enough detail to avoid repeating the same mistake:

| Date | Phase/Step | Error | Root Cause | Solution | Resolved |
|------|-----------|-------|------------|----------|----------|
| YYYY-MM-DD | Phase X Step Y | Brief error description | Why it happened | How it was fixed | ✅/❌ |

## API Cost Tracking
For POC budget forecasting, log every AI API call:

| Date | Operation | Model | Input Tokens | Output Tokens | Cost ($) |
|------|-----------|-------|-------------|--------------|----------|

## Rules
- Never skip updating progress — it's the shared state across parallel agents and chat sessions
- Be specific in Notes column — future agents will read this for context
- If a step was partially completed, keep it 🟡 and explain what's left in Notes
