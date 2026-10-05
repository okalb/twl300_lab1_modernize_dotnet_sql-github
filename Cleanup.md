---
title: "Clean up"
nav_order: 15
---

# Clean up

Remove the Azure resources and the local SQL01 data after you finish the lab.

## Clean up the session

1. Verify the resource group variable.

    ```powershell
    $resourceGroup
    ```

    If the variable is empty, set it to the name of the lab resource group that you created in Exercise 0.

    ```powershell
    $resourceGroup = Read-Host "Enter the name of the lab resource group that you created in Exercise 0"
    ```

1. Delete the Azure resource group.

    ```powershell
    az group delete --name $resourceGroup --yes
    ```

    > **Warning:** This deletes every resource in the specified resource group, including the migrated data in Azure SQL Database. Confirm the resource-group name before running the command.

1. Verify that the resource group no longer exists.

    ```powershell
    az group exists --name $resourceGroup
    ```

1. Confirm that the result is **false**.

1. Remove the local connection string, sensitive variables, and export file.

    ```powershell
    Remove-Item Env:ConnectionStrings__Inventory -ErrorAction SilentlyContinue
    Remove-Variable azureConnectionString, sqlAdminPassword -ErrorAction SilentlyContinue
    Remove-Item /home/vscode/LabFiles/CaldovaInventory/InventoryItems.bcp -Force -ErrorAction SilentlyContinue
    ```

1. Save both evidence files.

1. Close GitHub Copilot CLI if it's still open.

    ```text
    /exit
    ```

## Remove the local environment

1. Copy anything that you want to keep from `/home/vscode/LabFiles/CaldovaInventory/evidence`. The next steps delete the local database and the development container.

1. Stop the SQL01 container and delete its data.

    ```powershell
    docker compose --file "$env:LAB_REPO_ROOT/docker-compose.yml" down --volumes
    ```

    > **Warning:** This permanently deletes the local **CaldovaInventory** database on SQL01.

    If the command reports that it can't find `docker-compose.yml`, run the following commands instead:

    ```powershell
    docker rm --force sql01
    docker volume rm caldova-lab_sql01-data
    ```

1. Delete the development container:

    - **GitHub Codespaces:** On GitHub, open your list of codespaces, select the **...** menu next to the codespace for this lab, and then select **Delete**. Deleting the codespace stops charges for its compute and storage.
    - **VS Code Dev Containers:** Close the Visual Studio Code window, and then delete the lab container and its volumes in Docker Desktop.

> **Note:** The resource provider registrations from Exercise 0 apply to the whole subscription. Deleting the resource group doesn't unregister them.

---

[← Exercise 12: Record migration evidence and complete the modernization brief](Exercises/12-record-migration-evidence-and-complete-the-modernization-brief/index.md) · [Lab index](Index.md) · [Summary and additional resources →](Summary.md)
