  

| Section | Content |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| WHAT: Objectives/Goals | To facilitate and enchance the current workflow at work by developing a system for the OT department consisting of a database, a backend system and a front end user interface. The database consists of multiple existing Excel files of clients (Elderly living in care and attention home) consisting client details such as name, Age, Cognitive level, diet, supplement, restrains and activities group. The back end system will be able to perform analysis such as trends of cognitive levels, physical conditions, group performance on a timely basis or upon request, send emails to destinate groups on a timely basis, process front end request of enquiries and analysis using AI. The front end system wil be able to generate client profiles when called upon with search functions. This will allow user to enter new, delete and modify client details, display results of analysis, allow user to extract reports in pdf, word or Excel format. |
| WHAT: Users/Target Audiences | OTM, OT, PsyNurse, OTA, ST, DT |
| WHY: ROI/Value | Time Savings: Reduce document review, data entry, manual report time, extracting data from multiple files.
Accuracy: Ensure that the data extracted is accurate, able to extract records over several years, allow fraud detection
Engagement: Provide a simple, centralized tool for information retreieval, amendment and analysis
New Value: Provide valuable insights on client of an elderly home from the overall OT perspective. |
| HOW: Strategy | Containerized Infrastructure (Docker): Deploy the entire ecosystem (Database, Backend, AI Engine, and Frontend) as isolated, containerized services using Docker and Docker Compose for easy deployment, backup, and environment consistency.

Hybrid Architecture (Code + Automation):
- Use Python (FastAPI) for core business logic, statistical analysis (cognitive trends, physical condition scoring), and local AI agent integration.
- Use self-hosted n8n for internal scheduled tasks (e.g., generating weekly/monthly summary notifications, report delivery, batch data sync).

Progressive Rollout:
Stage 1: Ingest and consolidate existing Excel client logs into a centralized relational database.
Stage 2: Develop core CRUD operations and role-based access for care staff (OT, Nurses, Assistants).
Stage 3: Enable local AI semantic search and trend analysis with automated report generation. |
| HOW: Technologies | Containerization & Orchestration: Docker & Docker Compose (running locally on the internal server for complete network isolation).
Database Layer: PostgreSQL with the pgvector extension (handles relational client records, medical history, diet/restraint records, and vector embeddings for semantic document search).
Local AI / LLM Engine: Ollama running locally on the server (using open-source models like Llama 3, Qwen 2.5, or DeepSeek for local inference without API fees or data leakage).
Backend Framework: Python (FastAPI) (ideal for data manipulation with Pandas/NumPy, asynchronous API endpoints, and direct integration with local LLMs).
Workflow Automation: n8n (Self-Hosted Community Edition via Docker) (handles scheduled jobs, automated email dispatch to care teams, and file ingestion).
Frontend User Interface: React / Vite or HTML5/CSS3 + Tailwind + Vanilla JS/Alpine.js (lightweight web interface with search, profile view, trend charts using Chart.js, and export to PDF/Excel).
Vibe Coding & Development Tools: Visual Studio Code / GitHub Codespaces with GitHub Copilot to accelerate development. |
  
