---
name: docker
description: >
  Docker and docker-compose patterns for this project: Dockerfile best practices
  (non-root user, layer caching, slim images), docker-compose orchestration
  (healthchecks, depends_on, volume mounts, environment passthrough), container
  lifecycle (restart vs rebuild vs recreate), and production readiness.
  Use PROACTIVELY when writing or modifying Dockerfiles, docker-compose.yml,
  .dockerignore, or any container-related configuration -- even for small changes.
  Also use when debugging container behavior, environment variable issues, or
  stale code after deployments.
---

# Docker Development Patterns

## Project conventions

See CLAUDE.md for full project structure. Key Docker context:

- Python 3.12+ required (pyproject.toml)
- Agents live in `apps/<name>/` with their own Dockerfile + docker-compose
- Temporal infra (server, PostgreSQL, UI) runs alongside worker + server
- Dev uses volume mounts for hot-reload; production uses baked images
- Secrets via `.env` file (docker-compose reads automatically), never in images

## Dockerfile rules

### Base image
- Use `python:3.12-slim` (not `alpine` — binary wheels break, not `latest` — unpinned)
- Always pin major.minor: `python:3.12-slim`, not `python:3-slim`

### Layer caching
Copy dependency files BEFORE application code — deps change less often:
```dockerfile
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
```

### Non-root user (security)
```dockerfile
RUN addgroup --system app && adduser --system --ingroup app app
USER app
```

### Environment
```dockerfile
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
```
`PYTHONUNBUFFERED=1` is critical — without it, container logs are buffered and `docker compose logs` shows nothing until the buffer flushes.

`PYTHONDONTWRITEBYTECODE=1` prevents `.pyc` creation. Important because volume mounts can expose host `__pycache__/` into the container — stale bytecache has caused bugs where the container ran old code despite source changes. See `docs/03_issues/issue-LLM_Activity_Returns_Mock_Despite_Valid_Key.md`.

### NO HEALTHCHECK in Dockerfile
When one image serves multiple service types (HTTP server + gRPC worker), a Dockerfile HEALTHCHECK will break the non-HTTP service. The worker has no port 8000 — the check fails, Docker marks it unhealthy, `restart: on-failure` triggers a restart loop. The worker never stabilizes.

**Rule:** Healthchecks belong in docker-compose (per service), NEVER in the Dockerfile.

See `docs/03_issues/issue-Dockerfile_Healthcheck_Kills_Worker.md` for the full incident.

### No secrets in image
```dockerfile
# NEVER do this:
ENV API_KEY=secret123
COPY .env .

# Instead: pass at runtime via docker-compose environment or --env-file
```

### Combined RUN commands
```dockerfile
# Bad: 3 layers
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# Good: 1 layer, cleanup in same step
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
```

## Container lifecycle (critical — often misunderstood)

These commands do very different things. Using the wrong one causes stale code, missing env vars, or unchanged behavior after "deploying":

| Command | Image rebuilt? | Container recreated? | env_file re-read? | Use when |
|---------|---------------|---------------------|-------------------|----------|
| `docker compose restart <svc>` | No | No (same container) | No | **Never for code/config changes** |
| `docker compose up -d <svc>` | No (cached) | Only if compose config changed | Yes | Compose YAML changes only |
| `docker compose up -d --build <svc>` | Yes | Yes | Yes | **Code changes (standard deploy)** |
| `docker compose down && up -d --build` | Yes | Yes (fresh) | Yes | Nuclear reset |

**The most common mistake:** Using `restart` after changing code or `.env` and wondering why nothing changed. `restart` just sends SIGTERM + SIGSTART to the same container with the same image and same env vars. For code changes, always `up -d --build`.

### Why this matters for Temporal workers

The Temporal worker (`python worker.py`) injects config at startup via constructor injection. If the container isn't recreated after an env var change, the worker runs with stale credentials for its entire lifetime. There's no hot-reload for workers — only a fresh process reads fresh config.

### Volume mounts and bytecache

With `volumes: [".:/app"]`, the host directory is mounted into the container. This includes `__pycache__/` directories. Even with `PYTHONDONTWRITEBYTECODE=1` (prevents NEW bytecache), existing `.pyc` files on the host can be read by the container. If the host Python version differs from the container, or if stale `.pyc` exists from before a refactor, the container runs old code.

**Prevention:** Delete bytecache on host before rebuilding:
```bash
find apps/<name> -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null
docker compose up -d --build worker
```

### Cleaning up local processes after Docker migration

When migrating from local development (venv + `python worker.py`) to Docker, kill ALL local processes that connect to Docker-exposed ports. A forgotten local worker listening on `localhost:7233` (port-mapped to Docker Temporal) will compete with the Docker worker for tasks — and may lack credentials, returning wrong results.

```bash
# Check for rogue processes
ps aux | grep worker.py | grep -v grep

# Also check for stale test servers
ps aux | grep temporal-test-server | grep -v grep
```

This is invisible in Docker logs because the rogue process runs on the host, not in the container. The Temporal Event History identity field reveals which process actually ran each activity (see temporal skill).

## docker-compose patterns

### Service healthchecks
```yaml
services:
  server:
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
      interval: 10s
      timeout: 3s
      start_period: 10s
      retries: 3

  worker:
    # NO healthcheck — worker has no HTTP endpoint
    # Temporal Server monitors worker connection via gRPC heartbeat
```

### depends_on with conditions
```yaml
  worker:
    depends_on:
      temporal:
        condition: service_started
  server:
    depends_on:
      temporal:
        condition: service_started
```

### Volume mounts for dev hot-reload
```yaml
  server:
    volumes:
      - .:/app  # Code changes visible immediately
    command: uvicorn server:app --host 0.0.0.0 --reload --port 8000
```
Server auto-reloads via uvicorn `--reload`. Worker needs `docker compose up -d --build worker` after code changes (not `restart` — see lifecycle table above).

### Environment: env_file vs ${VAR} substitution
Docker Compose has TWO separate env mechanisms — do not confuse them:

| Mechanism | What it does | Where `.env` is read from |
|-----------|-------------|--------------------------|
| `${VAR:-}` in YAML | Substitutes values **into the compose file** before execution | `.env` in **CWD** (where `make` runs) |
| `env_file:` | Loads variables **into the container** at runtime | Path relative to **compose file** |

**Project pattern:** Root `.env` (gitignored) holds all secrets. Agents read it via `env_file`:
```yaml
  worker:
    env_file:
      - ../../.env                              # Root .env → into container
    environment:
      - TEMPORAL_HOST=temporal:7233             # Override for Docker network
```
`environment:` overrides `env_file` — so `TEMPORAL_HOST` stays Docker-internal even if root `.env` has `localhost:7233`.

### Network: all on same bridge
```yaml
networks:
  temporal-network:
    driver: bridge
```
Service names become DNS hostnames — `temporal:7233` not `localhost:7233`.

**Port mapping caveat:** `ports: ["7233:7233"]` exposes Temporal to `localhost:7233` on the host. Any local process (old venv worker, test runner) can connect and compete for tasks. This is by design for development but causes hard-to-debug issues when forgotten processes are running.

## .dockerignore

Always create alongside Dockerfile:
```
.venv/
__pycache__/
*.pyc
.pytest_cache/
.ruff_cache/
.git/
.env
```

`__pycache__/` is especially important — without it, `COPY . .` bakes stale bytecache into the image.

## Checklist

Before committing Docker changes, verify:

- [ ] Base image pinned to major.minor (not `:latest`)
- [ ] `requirements.txt` copied before application code (layer caching)
- [ ] Non-root user (`USER app`)
- [ ] `PYTHONUNBUFFERED=1` and `PYTHONDONTWRITEBYTECODE=1` set
- [ ] No secrets in image (no `COPY .env`, no hardcoded keys)
- [ ] `.dockerignore` present and excludes `.venv/`, `__pycache__/`, `.git/`, `.env`
- [ ] `--host 0.0.0.0` on uvicorn (otherwise port mapping fails)
- [ ] Services on same Docker network as Temporal
- [ ] Health checks defined in docker-compose ONLY (NOT in Dockerfile — breaks multi-service images)
- [ ] Worker service has NO healthcheck (Temporal Server monitors via gRPC heartbeat)
- [ ] `restart: on-failure` on worker and server services
- [ ] After code changes: `up -d --build`, never just `restart`
- [ ] No local `python worker.py` processes running on host (check with `ps aux | grep worker.py`)
