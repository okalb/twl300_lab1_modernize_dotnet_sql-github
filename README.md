# Modernize a .NET application and SQL Server database with GitHub Copilot and CLI

Use GitHub Copilot in Visual Studio Code and GitHub Copilot CLI to assess a .NET and SQL Server workload, externalize its database connection string, migrate the inventory data to Azure SQL Database, and deploy and validate the API in Azure Container Apps. Copilot accelerates the work, but you remain responsible for validating its claims, edits, and recommendations.

| | |
| --- | --- |
| **Level** | 300 |
| **Duration** | 120 minutes, plus environment setup |
| **Products** | GitHub Copilot, GitHub Copilot CLI, .NET 8, SQL Server 2022, Azure SQL Database, Azure Container Registry, Azure Container Apps |

## Get started

1. Read the [lab overview and prerequisites](Index.md).
1. Complete [Exercise 0: Environment setup](Exercises/00-environment-setup/index.md). It creates the development container, starts the local SQL01 database, and predeploys the Azure resources.
1. Work through Exercises 1 to 12, and then complete [Clean up](Cleanup.md).

> **Warning:** This lab creates billable Azure resources with public endpoints. Delete the lab resource group when you finish. See [Clean up](Cleanup.md).

## Repository contents

| Path | Contents |
| --- | --- |
| `Index.md` | Lab scenario, environment, objectives, exercise list, prerequisites, and costs |
| `Exercises/` | One folder per exercise (Exercise 0 to Exercise 12) |
| `Cleanup.md`, `Summary.md` | Cleanup steps, summary, and additional resources |
| `labfiles/CaldovaInventory/` | Starter ASP.NET Core application, SQL scripts, reference solution, and evidence templates. The development container copies it to `/home/vscode/LabFiles/CaldovaInventory`. |
| `infra/arm/azuredeploy.json` | ARM template for the predeployed Azure resources |
| `infra/parameters/` | Example parameter file (no secrets) |
| `scripts/setup/` | `Deploy-LabInfrastructure.ps1`, `Register-ResourceProviders.ps1`, and `Configure-ContainerApp.ps1` |
| `.devcontainer/`, `docker-compose.yml` | Development container (APP01) and the SQL01 SQL Server container |
| `images/` | Screenshots used by the exercises |

> **Note:** The `sa` password in `labfiles/CaldovaInventory/Program.cs` and `docker-compose.yml` is a synthetic credential for the local SQL01 container. Removing it from the source code is part of the lab. Don't reuse it anywhere else.
