#!/bin/sh
# Deploy updates for Payload CMS site
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SITE_DIR=$(dirname "$SCRIPT_DIR")
cd "$SITE_DIR"

docker compose pull
# run migrations in a temporary container
docker compose run --rm payload pnpm payload migrate
# restart services with updated images
docker compose up -d
