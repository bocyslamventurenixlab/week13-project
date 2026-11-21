---
description: "Use when creating or modifying Dockerfiles, service entry points, or server startup code. Covers dynamic PORT binding for cloud platforms (Railway, Render, Fly.io) and Docker CMD patterns."
applyTo: "**/Dockerfile,**/index.ts,**/main.py,**/main.ts,**/server.ts,**/server.py,docker-compose*.yml"
---
# Deployment — Dynamic PORT & Docker Patterns

## The Core Problem

Cloud platforms (Railway, Render, Fly.io) inject a `PORT` environment variable at runtime. Services that hardcode ports or ignore this variable fail to start on deployment, even if they work perfectly in local Docker.

## Rules

### Rule 1: Every service must read PORT from environment

Every service entry point must read `PORT` from environment variables with a sensible fallback default for local dev. NEVER hardcode a port without an env override.

**Node.js / Express:**
```typescript
const PORT = process.env.PORT || 3001
app.listen(Number(PORT), '0.0.0.0', () => { ... })
```

**Python / FastAPI:**
```python
# Via CLI (Dockerfile CMD):
uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}

# Or in code:
import os
port = int(os.environ.get("PORT", 8000))
```

**Static file serving (frontend):**
```bash
serve -s dist -l ${PORT:-3000}
```

### Rule 2: Always bind to `0.0.0.0`

NEVER bind to `127.0.0.1` or `localhost` — these reject connections from outside the container.

```typescript
// WRONG — unreachable from Docker network or platform proxy
app.listen(PORT, 'localhost')
app.listen(PORT, '127.0.0.1')

// RIGHT — accepts connections from any interface
app.listen(PORT, '0.0.0.0')
```

```python
# WRONG
uvicorn app.main:app --host 127.0.0.1

# RIGHT
uvicorn app.main:app --host 0.0.0.0
```

### Rule 3: Docker CMD must use shell form for env interpolation in CLI args

Docker's exec form (`CMD ["cmd", "arg"]`) does NOT interpolate environment variables. If PORT is passed as a CLI argument, use shell form.

```dockerfile
# WRONG — exec form, $PORT is treated as literal string
CMD ["uvicorn", "app.main:app", "--port", "$PORT"]

# RIGHT — shell form, env var interpolated at runtime
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
```

**Exception:** If the app reads PORT from `process.env` internally (like Node.js), exec form is fine for the command:
```dockerfile
# OK — Node reads process.env.PORT in code
CMD ["node", "dist/index.js"]
```

### Rule 4: HEALTHCHECK must use dynamic PORT

```dockerfile
# WRONG — hardcoded port breaks when platform assigns different port
HEALTHCHECK CMD curl -f http://localhost:3001/health

# RIGHT — reads PORT at runtime
HEALTHCHECK CMD node -e "require('http').get('http://localhost:'+(process.env.PORT||3001)+'/health', (r) => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"
```

```dockerfile
# Python equivalent
HEALTHCHECK CMD python -c "import os, urllib.request; urllib.request.urlopen(f'http://localhost:{os.environ.get(\"PORT\", 8000)}/health')"
```

### Rule 5: EXPOSE is documentation only

`EXPOSE` in Dockerfile does not bind or enforce a port. It documents the intended default. Keep it matching the fallback default, but never rely on it.

```dockerfile
EXPOSE 8000  # Documents default — actual port comes from CMD + $PORT
```

## Checklist

- [ ] Every service reads `PORT` from environment with a fallback default
- [ ] Server binds to `0.0.0.0` (not localhost or 127.0.0.1)
- [ ] Docker CMD uses shell form when PORT is passed as a CLI argument
- [ ] Docker HEALTHCHECK uses dynamic PORT
- [ ] `EXPOSE` value matches the fallback default port
- [ ] Fallback port in CMD matches fallback in app code (no mismatch)
