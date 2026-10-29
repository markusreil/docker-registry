# AGENTS.md

Project rules for agents working in this repo. See README.md for overview.

- All config lives in `.env` (hidden, never tracked); `env.example` is the
  tracked source of truth. Keep both in the same order/shape with one
  `# --- <service> ---` section per service and a comment per variable.
  Never commit `.env`.
- Every required var uses `${VAR:?...}` fail-fast interpolation; optional
  vars use `${VAR:-default}` explicitly and are documented as optional.
- No `container_name:`, no host `ports:` — services attach to the shared
  external proxy network (`NGINX_PROXY_NETWORK`, default `web-proxy`) and
  advertise via `expose:` + `VIRTUAL_HOST` / `VIRTUAL_PORT` (+ TLS opt-ins).
- Proxied services declare the complete downstream contract: `VIRTUAL_HOST`
  always, `VIRTUAL_PORT` where defaults do not fit, `NGINX_MAX_BODY_SIZE`
  where uploads need more than the default (here the registry sets it
  unlimited via `REGISTRY_NGINX_MAX_BODY_SIZE`), and for HTTPS `ACME_HOST`
  plus `GEN_SELF_SIGNED_CERT` wired from `.env` (here defaulting to `true`).
  Never hardcode variant-specific TLS config.
- Hostnames come from `x-hosts` anchors derived from `BASE_DOMAIN` (default
  `localhost`: always resolves, ideal for local testing); never
  copy-paste literal hostnames.
- Named volumes for stateful data (`registry-data`); no data bind mounts.
  NFS storage goes through the tracked `docker-compose.nfs.yml` override
  (selected via `COMPOSE_FILE` in `.env`), never profiles or service
  duplication.
- Both services are upstream images with no custom entrypoint: no first-run
  seeding, no PUID/PGID handling. Document if that ever changes.
- `restart: unless-stopped` on all services; keep Homepage labels
  (`group`, `name`, `icon`, `href`, `description`) on proxied services.
- Update `CHANGELOG.md` under `## [Unreleased]` with every change.
- Verify with: `cp env.example .env` (first run), `docker compose config`,
  `docker compose build`, `docker compose up -d`, `docker compose ps`.
