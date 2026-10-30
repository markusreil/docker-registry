#!/bin/sh
# Run the registry garbage collector.
# The registry must not be running while it collects, so this stops it
# first and restarts it afterwards (even on failure/interrupt).
# Extra args are passed through to `registry garbage-collect`, e.g.:
#   bin/garbage-collect.sh --delete-untagged
set -eu
cd "$(dirname "$0")/.."

docker compose stop registry
trap 'docker compose start registry' EXIT INT TERM
docker compose run --rm registry registry garbage-collect "$@" /etc/docker/registry/config.yml
trap - EXIT INT TERM
docker compose start registry
