---
title: "Modernize a .NET application and SQL Server database with GitHub Copilot and CLI"
description: "Use GitHub Copilot in Visual Studio Code and GitHub Copilot CLI to assess a .NET and SQL Server workload, externalize its database connection string, migrate the inventory data to Azure SQL Database, and deploy and validate the API in Azure Container Apps."
level: 300
duration: 120 minutes
---

# Modernize a .NET application and SQL Server database with GitHub Copilot and CLI

Caldova operates a .NET inventory API backed by SQL Server. The application works with the prepared SQL Server Database, but the starter implementation stores its database connection string directly in source code and its cloud deployment assumptions require validation. Caldova wants to improve configuration security, migrate the inventory data to Azure SQL Database, deploy the application with Azure Container Apps, and establish a validated modernization path based on observable evidence.

In this exercise, you act as part of the Microsoft technical team. You use GitHub Copilot in Visual Studio Code and GitHub Copilot CLI to assess the .NET application and SQL Server workload, identify and prioritize modernization concerns, externalize the database connection string, and validate the updated application locally. Then you'll migrate the inventory data from SQL Server to Azure SQL Database, build and upload the application image to Azure Container Registry, update a predeployed Azure Container App, validate the cloud workload, and create an evidence-based modernization recommendation. Copilot accelerates the work, but you remain responsible for validating its claims, edits, and recommendations.

## Environment

### Lab environment (APP01 and SQL01)

The lab environment runs in a development container that you create in Exercise 0. It keeps the two roles from the original hosted lab:

- **APP01** is the development container. It hosts Visual Studio Code, GitHub Copilot, GitHub Copilot CLI, the .NET SDK, Azure CLI, SQL command-line utilities, the application source files, and the workspace.
- **SQL01** is a SQL Server 2022 container that runs inside the development container. It hosts the source **CaldovaInventory** database.

APP01 communicates with SQL01 over TCP port 1433.

### Azure

In Exercise 0, you run a setup script that predeploys the Azure infrastructure in a dedicated resource group that you name. This reduces the time required to complete the rest of the lab.

The predeployed Azure environment includes:

- Azure SQL logical server
- Azure SQL Database
- Azure Container Registry
- Azure Container Apps Environment
- Azure Container App
- User-assigned managed identity
- Log Analytics workspace

Resource names can include a deployment-specific suffix and can vary between lab instances. The instructions use Azure CLI commands to discover the assigned resource names instead of requiring you to manually enter the generated names.

Don't create replacement Azure resources during the exercise. You use the predeployed infrastructure to complete the migration and application deployment.

During the Azure portion of the exercise, you:

- Initialize the predeployed CaldovaInventory Azure SQL Database.
- Export the source inventory data from SQL01.
- Import and reconcile the inventory data in Azure SQL Database.
- Build and upload the caldova-inventory:v1 application image to the predeployed Azure Container Registry.
- Use the preconfigured managed identity and registry integration.
- Update the existing Azure Container App to use the built image.
- Validate the deployed application on port 8080.
- Validate cloud health, inventory read, and inventory write operations.
- Record verified migration and deployment evidence.

### Database

The prepared source inventory in the CaldovaInventory SQL Server Database contains:

| SKU | Name | Quantity |
| --- | --- | --- |
| CAL-100 | Pressure controller | 12 |
| CAL-200 | Industrial gateway | 7 |
| CAL-300 | Safety relay | 25 |

During local application validation, you create an additional inventory item:

| SKU | Name | Quantity |
| --- | --- | --- |
| CAL-400 | Field sensor | 18 |

CAL-400 is included with the source records migrated to Azure SQL Database.

After the application is deployed to Azure Container Apps, you create:

| SKU | Name | Quantity |
| --- | --- | --- |
| CAL-500 | Cloud gateway | 10 |

The final cloud validation confirms that the deployed application can read and write inventory data in Azure SQL Database.

### Working with files in this lab

Use **Visual Studio Code** to open, review, and update the application, configuration, SQL, and evidence files.

Use the **Visual Studio Code integrated PowerShell terminal** for PowerShell, .NET, Azure CLI, sqlcmd, and bcp commands unless a step explicitly says otherwise.

When a step references a file:

1. Confirm that the open Visual Studio Code folder is **/home/vscode/LabFiles/CaldovaInventory**.

2. Use the Explorer to expand the folders in the stated path and select the file.

3. Make changes only in the working copy under **/home/vscode/LabFiles/CaldovaInventory** unless a step explicitly directs you to another location.

4. Select **Ctrl+S** (**Cmd+S** on macOS) to save changes before running commands that use the file.

5. Review Copilot-generated changes before accepting them and verify important claims against the referenced source files or observed command results.

6. Treat Copilot output as a proposed analysis or change until you verify it against the application, database, configuration, or deployment evidence.

7. Don't place passwords, tokens, connection-string secrets, or other confidential values in Copilot prompts, screenshots, evidence files, or the modernization brief.

8. Don't create replacement Azure infrastructure manually if a predeployed resource is missing or unavailable. Rerun the setup script from Exercise 0 instead, with the same password; it reuses the existing resource group and resource names. If you rerun it after Exercise 10, repeat the **Configure the predeployed Container App** section of Exercise 10 afterward.

### Objectives

After you complete this exercise, you'll be able to:

- Establish a working baseline for a .NET API and a remote SQL Server Database.
- Use GitHub Copilot to assess application and database modernization concerns.
- Externalize the application database connection string through .NET configuration.
- Use GitHub Copilot CLI as an independent review and validation surface.
- Validate local application health, database reads, and database writes.
- Migrate SQL Server data from SQL01 to Azure SQL Database.
- Build an application image in Azure Container Registry.
- Deploy and validate the API in Azure Container Apps.
- Record verified assessment and migration evidence.
- Prepare an evidence-based modernization brief.

## Exercises

| Exercise | Title |
| --- | --- |
| 0 | [Environment setup](Exercises/00-environment-setup/index.md) |
| 1 | [Open the application workspace](Exercises/01-open-the-application-workspace/index.md) |
| 2 | [Sign in to GitHub Copilot](Exercises/02-sign-in-to-github-copilot/index.md) |
| 3 | [Establish the application baseline](Exercises/03-establish-the-application-baseline/index.md) |
| 4 | [Document the application baseline](Exercises/04-document-the-application-baseline/index.md) |
| 5 | [Assess the workload with GitHub Copilot](Exercises/05-assess-the-workload-with-github-copilot/index.md) |
| 6 | [Externalize the database configuration](Exercises/06-externalize-the-database-configuration/index.md) |
| 7 | [Validate the updated application](Exercises/07-validate-the-updated-application/index.md) |
| 8 | [Validate the change with GitHub Copilot CLI](Exercises/08-validate-the-change-with-github-copilot-cli/index.md) |
| 9 | [Migrate the data to Azure SQL Database](Exercises/09-migrate-the-data-to-azure-sql-database/index.md) |
| 10 | [Build and deploy the application to Azure](Exercises/10-build-and-deploy-the-application-to-azure/index.md) |
| 11 | [Validate the cloud workload](Exercises/11-validate-the-cloud-workload/index.md) |
| 12 | [Record migration evidence and complete the modernization brief](Exercises/12-record-migration-evidence-and-complete-the-modernization-brief/index.md) |
| — | [Clean up](Cleanup.md) |
| — | [Summary and additional resources](Summary.md) |

Complete the exercises in order. Exercise 0 is new in this GitHub version of the lab: it creates the development container (APP01), starts SQL01, and predeploys the Azure resources.

## Prerequisites

- **GitHub account** with a GitHub Copilot plan that includes Copilot Chat (Ask and Agent modes) and GitHub Copilot CLI. If an organization manages your Copilot access, its policies must allow Copilot CLI.
- **Development environment:** GitHub Codespaces (recommended), or Docker Desktop with Visual Studio Code and the Dev Containers extension. The SQL Server 2022 container image runs only on x64 (Intel or AMD) processors. On a computer with an Arm processor, such as Apple silicon, use GitHub Codespaces.
- **Azure subscription** in which you have the **Owner** role. The setup script creates a resource group, deploys a role assignment (**AcrPull** for the managed identity), and registers resource providers at subscription scope. **Contributor** plus **User Access Administrator** on the subscription also works.
- **Network access** from the development container to Azure SQL Database on TCP port 1433, and to Azure, GitHub, and the Microsoft package and container registries.

## Costs, security, and cleanup

- **Billable resources:** The lab creates Azure SQL Database (Basic), Azure Container Registry (Basic), a Log Analytics workspace, and an Azure Container App that keeps one replica running. GitHub Codespaces also bills compute and storage while the codespace exists, or uses your included monthly usage. Complete [Clean up](Cleanup.md) as soon as you finish.
- **Public endpoints:** To keep the lab short, the Azure SQL logical server allows public network access with a firewall rule that allows all IP addresses (`0.0.0.0` to `255.255.255.255`), the container registry allows public network access, and the Container App has external ingress. Production environments should use private networking and Microsoft Entra authentication.
- **Regional availability:** Choose a region that offers Azure Container Apps and Azure SQL Database. Some subscription types restrict Azure SQL Database in some regions, and the database requests geo-redundant backup storage, which isn't available in every region. If the deployment fails for one of these reasons, run the setup script again with a new resource group name and another region.
- **Credentials:** The SQL01 `sa` password in the starter files is a synthetic credential for the local SQL01 container only. For Azure SQL Database, you choose your own administrator password in Exercise 0.
- **Data loss:** Cleanup deletes the lab resource group, including the migrated data in Azure SQL Database, and the local SQL01 database.
