---
title: "Summary and additional resources"
nav_order: 16
---

# Summary

In this Azure portion of the exercise, you:

- Signed in to Azure and identified the resources predeployed in your lab resource group.
- Discovered the deployment-generated Azure resource names instead of creating new resources.
- Initialized the predeployed Azure SQL Database.
- Exported four inventory records from SQL01 and imported them into Azure SQL Database.
- Built and uploaded the application image to the predeployed Azure Container Registry.
- Verified managed-identity access to the registry.
- Configured the predeployed Container App to use the image and Azure SQL secret reference.
- Validated the cloud health, read, and write paths on port 8080.
- Recorded migration evidence and updated the modernization brief.
- Deleted the lab resource group and the local SQL01 container during cleanup.

## Additional resources

### GitHub Copilot

- [Ask GitHub Copilot questions in your IDE](https://docs.github.com/copilot/using-github-copilot/copilot-chat/asking-github-copilot-questions-in-your-ide)
- [Install GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli)
- [Use GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli/use-copilot-cli/overview)

### .NET and ASP.NET Core

- [.NET support policy](https://dotnet.microsoft.com/platform/support/policy/dotnet-core)
- [Configuration in ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/configuration/)
- [Safe storage of app secrets in development in ASP.NET Core](https://learn.microsoft.com/aspnet/core/security/app-secrets)

### Azure Container Apps

- [Build and deploy an app to Azure Container Apps](https://learn.microsoft.com/azure/container-apps/tutorial-code-to-cloud)
- [Manage environment variables in Azure Container Apps](https://learn.microsoft.com/azure/container-apps/environment-variables)
- [Manage secrets in Azure Container Apps](https://learn.microsoft.com/azure/container-apps/manage-secrets)
- [Manage revisions in Azure Container Apps](https://learn.microsoft.com/azure/container-apps/revisions-manage)
- [Revisions in Azure Container Apps](https://learn.microsoft.com/azure/container-apps/revisions)
- [Use managed identity to pull images in Azure Container Apps](https://learn.microsoft.com/azure/container-apps/managed-identity-image-pull)

### Azure Container Registry

- [Azure Container Registry overview](https://learn.microsoft.com/azure/container-registry/container-registry-intro)
- [Azure Container Registry quickstart: Build and run an image with ACR Tasks (Azure CLI)](https://learn.microsoft.com/azure/container-registry/container-registry-quickstart-task-cli)
- [Azure CLI az acr reference](https://learn.microsoft.com/cli/azure/acr)

### Azure SQL Database

- [Azure SQL Database documentation](https://learn.microsoft.com/azure/azure-sql/database/)
- [Create and configure an Azure SQL Database with the Azure CLI](https://learn.microsoft.com/azure/azure-sql/database/scripts/create-and-configure-database-cli)
- [Configure Azure SQL Database firewall rules](https://learn.microsoft.com/azure/azure-sql/database/firewall-configure)
- [Connectivity architecture](https://learn.microsoft.com/azure/azure-sql/database/connectivity-architecture)

### SQL Server command-line tools and data migration

- [sqlcmd utility](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility)
- [bcp utility](https://learn.microsoft.com/sql/tools/bcp-utility)
- [Import and export bulk data by using the bcp utility](https://learn.microsoft.com/sql/relational-databases/import-export/import-and-export-bulk-data-by-using-the-bcp-utility)

### Azure CLI

- [Azure CLI documentation](https://learn.microsoft.com/cli/azure/)
- [Azure CLI extensions overview](https://learn.microsoft.com/cli/azure/azure-cli-extensions-overview)
- [Azure CLI az containerapp reference](https://learn.microsoft.com/cli/azure/containerapp)

---

[← Clean up](Cleanup.md) · [Lab index](Index.md)
