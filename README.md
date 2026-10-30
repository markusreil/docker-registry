# Docker Registry + Joxit UI

Private Docker image registry (`registry:2`) with the Joxit web UI, served
behind the shared nginx reverse proxy. No host ports are published; all
traffic flows through the proxy network.

## Architecture

- `registry` — upstream `registry:2` image, storage on the `registry-data`
  named volume, exposed on container port 5000.
- `registry-ui` — upstream `joxit/docker-registry-ui` image (stateless),
  pointed at `https://registry.<BASE_DOMAIN>`, exposed on container port 80.
- No custom builds: both services use 3rd-party upstream images as-is, so
  there are no per-service build directories, Dockerfiles, or entrypoints.
  Upstream images manage their own users; no PUID/PGID handling applies.
- TLS: each service declares the full downstream proxy contract
  (`VIRTUAL_HOST`, `VIRTUAL_PORT`, `ACME_HOST`, `GEN_SELF_SIGNED_CERT`).
  Self-signed cert generation defaults to `true` in this deployment
  (LAN/self-signed variant); override to `false` in `.env` for an
  internet-facing deployment using real ACME certificates.

## Quickstart

```sh
cp env.example .env
# edit .env accordingly before starting the cluster
# (make sure the proxy cluster is up first so the web-proxy network exists)
docker compose config
docker compose up -d
docker compose ps
```

## Operational notes

- Start the proxy cluster before this stack (external `web-proxy` network).
- Registry data persists in the `registry-data` named volume (local driver by
  default). For NFS-backed storage, set
  `COMPOSE_FILE=docker-compose.yml:docker-compose.nfs.yml` in `.env` and
  fill in `NFS_DEVICE` / `NFS_OPTS`; the override file redefines only the
  volume driver.
- The UI talks to the registry server-side through its nginx proxy
  (`NGINX_PROXY_PASS_URL=http://registry:5000`, `SINGLE_REGISTRY=true`), so
  the browser never contacts the registry directly and no CORS setup is
  needed. `PULL_URL` only controls the hostname shown in `docker pull`
  commands. `BASE_DOMAIN` defaults to `localhost`, which always resolves
  and needs no DNS setup for local testing.
- Image deletion from the UI additionally requires `REGISTRY_STORAGE_DELETE_ENABLED=true`
  on the registry; this stack leaves deletes at the UI toggle only.

- Large pushes go through the proxy, whose global `client_max_body_size`
  would reject big layers with 413. The `registry` service sets the
  per-service `NGINX_MAX_BODY_SIZE=0` (unlimited, via
  `REGISTRY_NGINX_MAX_BODY_SIZE`); the proxy renders it as a per-vhost
  override, so the global default still applies everywhere else.

## Garbage collection

Deleting tags through the UI leaves empty repository directories behind
(the catalog still lists them, and tag lookups log 404 `NAME_UNKNOWN`).
Prune them with the registry's garbage collector:

```sh
bin/garbage-collect.sh
```

The script stops the registry first (it must not be running while it
collects), runs the collector, and restarts the registry afterwards —
equivalent to:

```sh
docker compose stop registry
docker compose run --rm registry registry garbage-collect /etc/docker/registry/config.yml
docker compose start registry
```

`docker compose run` reuses the service's volumes and environment (including
the NFS override when `COMPOSE_FILE` selects it), so storage resolves the
same way as the running container. A `Path not found:
/docker/registry/v2/repositories` error simply means storage is empty and
there is nothing to collect.
