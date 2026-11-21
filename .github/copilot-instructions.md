# The Week13 AI Agent — Project Context

## Overview
To facilitate and enchance the current workflow at work by developing a system for the OT department consisting of a database, a backend system and a front end user interface. The database consists of multiple existing Excel files of clients (Elderly living in care and attention home) consisting client details such as name, Age, Cognitive level, diet, supplement, restrains and activities group. The back end system will be able to perform analysis such as trends of cognitive levels, physical conditions, group performance on a timely basis or upon request, send emails to destinate groups on a timely basis, process front end request of enquiries and analysis using AI. The front end system wil be able to generate client profiles when called upon with search functions. This will allow user to enter new, delete and modify client details, display results of analysis, allow user to extract reports in pdf, word or Excel format. 

## Tech Stack
- **Frontend**: React 19 + Vite + Tailwind CSS v4 + TypeScript (port 3000)
- **Gateway**: Node.js 20 + Express + TypeScript + Supabase Auth (port 3001)
- **AI Brain**: Python 3.11 + FastAPI + LangGraph (port 8000)
- **Database**: Supabase (PostgreSQL + pgvector + JSONB) — Free tier for POC
- **AI Model**: OpenRouter (POC) → TBC (production)
- **Embedding**: qwen/qwen3-embedding-8b (4096 dimensions)
- **Deployment**: Railway (3 services) + GitHub Actions CI/CD

## Monorepo Structure
```
frontend/    — React app (components/, pages/, contexts/, hooks/, lib/, types/)
gateway/     — Express API gateway (routes/, middleware/, services/, types/)
ai-brain/    — Python FastAPI + LangGraph (api/, agents/, ingestion/, rag/, models/, core/)
supabase/    — Database migrations and seed data
shared/      — API contracts shared across services
reference/   — Design docs, implementation plan, progress tracker
```

## Key Conventions
- Gateway is TypeScript (not JavaScript)
- AI Brain uses Pydantic models for all data schemas
- LangGraph StateGraphs for all agent orchestration
- Supabase RLS enforces access control (students see own data, instructors see course_code-scoped data)
- Agent traces (JSONB) must accompany every AI response
- "Intent over Syntax" — grading prioritizes logic correctness over prompt wording

## Build & Run
- Local dev: `docker compose up` (starts all 3 services + network)
- Frontend: `cd frontend && npm run dev`
- Gateway: `cd gateway && npm run dev`
- AI Brain: `cd ai-brain && uvicorn app.main:app --reload`

## Reference Documents
- `reference/IMPLEMENTATION_PLAN.md` — Full phased plan with steps, files, and dependencies
- `reference/PROGRESS.md` — Step-level progress tracker, error log, cost tracking
- `reference/*.md` — Original design/requirements documents

## Important
- Always check `reference/PROGRESS.md` before starting work to know current state
- Update `reference/PROGRESS.md` after completing any implementation step
- Log errors and solutions in the Error Log section of PROGRESS.md
