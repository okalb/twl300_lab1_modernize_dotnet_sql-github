#!/usr/bin/env bash
# Runs when the development container is created. Safe to run again: if setup
# failed, run this script again from any terminal:
#   bash "$LAB_REPO_ROOT/.devcontainer/post-create.sh"
#
# Copies the starter workspace to ~/LabFiles/CaldovaInventory, installs the
# remaining APP01 tools, starts SQL01, and seeds the CaldovaInventory database.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_SOURCE="${REPO_ROOT}/labfiles/CaldovaInventory"
WORKSPACE_TARGET="${HOME}/LabFiles/CaldovaInventory"

echo "Preparing the lab workspace..."
if [ ! -d "${WORKSPACE_TARGET}" ]; then
  mkdir -p "$(dirname "${WORKSPACE_TARGET}")"
  cp -a "${WORKSPACE_SOURCE}" "${WORKSPACE_TARGET}"
fi

echo "Installing the SQL Server command-line tools (sqlcmd and bcp)..."
if [ ! -x /opt/mssql-tools18/bin/sqlcmd ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if ! grep -rqs "packages.microsoft.com/${ID}/${VERSION_ID}/prod" /etc/apt/sources.list /etc/apt/sources.list.d/; then
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | sudo gpg --dearmor --yes --output /usr/share/keyrings/microsoft-prod.gpg
    curl -fsSL "https://packages.microsoft.com/config/${ID}/${VERSION_ID}/prod.list" \
      | sudo tee /etc/apt/sources.list.d/mssql-release.list > /dev/null
  fi
  sudo apt-get update
  sudo ACCEPT_EULA=Y apt-get install --yes mssql-tools18 unixodbc-dev
fi

echo "Installing the Azure Container Apps extension for Azure CLI..."
az extension add --name containerapp --upgrade --only-show-errors --yes

echo "Installing GitHub Copilot CLI..."
npm install --global @github/copilot

echo "Starting SQL01..."
bash "${REPO_ROOT}/.devcontainer/post-start.sh"

echo "Seeding the CaldovaInventory database on SQL01..."
# init.sql recreates the three source rows. It runs twice so that the identity
# values start at 1, as on the original SQL01 server: on a brand-new table,
# DBCC CHECKIDENT ... RESEED, 0 makes the first row 0.
for _ in 1 2; do
  # shellcheck disable=SC2016  # $MSSQL_SA_PASSWORD expands inside the SQL01 container.
  docker compose --file "${REPO_ROOT}/docker-compose.yml" exec -T sql01 \
    bash -c '/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -b -i /scripts/init.sql'
done

echo
echo "The lab environment is ready."
echo "Workspace: ${WORKSPACE_TARGET}"
