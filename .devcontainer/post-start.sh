#!/usr/bin/env bash
# Runs every time the development container starts.
# - Maps the host name SQL01 to the SQL Server port published inside this container.
# - Starts (or restarts) the SQL01 container and waits until it's healthy.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! grep -qiE '^[^#]*[[:space:]]sql01([[:space:]]|$)' /etc/hosts; then
  echo '127.0.0.1 SQL01' | sudo tee -a /etc/hosts > /dev/null
fi

for _ in $(seq 1 60); do
  if docker info > /dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! docker info > /dev/null 2>&1; then
  echo "Docker isn't available in the development container. Rebuild the container, and then try again." >&2
  exit 1
fi

docker compose --file "${REPO_ROOT}/docker-compose.yml" up --detach --wait
echo "SQL01 is running and healthy."
