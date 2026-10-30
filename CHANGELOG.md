# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial registry + Joxit UI compose project with self-signed cert opt-in enabled.
- NFS storage override (`docker-compose.nfs.yml`) selectable via `COMPOSE_FILE`, with `NFS_DEVICE` / `NFS_OPTS` vars.
- Fixed registry UI 404 by proxying API calls server-side (`NGINX_PROXY_PASS_URL=http://registry:5000`, `SINGLE_REGISTRY=true`) instead of browser-direct `REGISTRY_URL`.
- Set per-service `NGINX_MAX_BODY_SIZE=0` (unlimited) on the registry via `REGISTRY_NGINX_MAX_BODY_SIZE`; removed the manual `vhostd` override file.
- Enabled registry manifest deletes via `REGISTRY_STORAGE_DELETE_ENABLED` (wired from `.env`) so the Joxit UI delete toggle works.
- Added `bin/garbage-collect.sh` wrapper that stops the registry, runs the garbage collector, and restarts it.

### Changed

### Deprecated

### Removed

### Fixed

### Security
