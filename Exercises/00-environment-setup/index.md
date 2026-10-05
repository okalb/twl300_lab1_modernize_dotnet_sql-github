---
title: "Exercise 0: Environment setup"
nav_order: 2
---

# Exercise 0: Environment setup

Create the lab environment that the remaining exercises use. You open the repository in a development container that plays the role of **APP01**, confirm that the local **SQL01** SQL Server container is reachable, sign in to Azure, and run the setup script that predeploys the Azure infrastructure.

> **Warning:** The setup script creates billable Azure resources, including a Container App that keeps one replica running and an Azure SQL logical server with a public endpoint and a firewall rule that allows all IP addresses. Complete [Clean up](../../Cleanup.md) when you finish the lab.

## Review the prerequisites

Confirm that you have everything listed in [Prerequisites](../../Index.md#prerequisites):

- A GitHub account with a GitHub Copilot plan that includes Copilot Chat (Ask and Agent modes) and GitHub Copilot CLI.
- An Azure subscription in which you have the **Owner** role.
- GitHub Codespaces, or Docker Desktop and Visual Studio Code with the Dev Containers extension on an x64 (Intel or AMD) computer.

## Open the development container

Use **one** of the following options.

### Option A: GitHub Codespaces (recommended)

1. On the repository page on GitHub, select **Code**, select the **Codespaces** tab, and then select **Create codespace on main**.

    > **Note:** The development container requests a 4-core machine with 16 GB of memory because SQL Server runs inside it. Codespaces usage is billed to your account or uses your included monthly usage.

1. Wait for the codespace to finish setting up. The first start installs the remaining lab tools, starts the **SQL01** container, creates and seeds the **CaldovaInventory** database, and copies the application workspace to `/home/vscode/LabFiles/CaldovaInventory`. This can take several minutes.

### Option B: VS Code Dev Containers on your computer

1. Make sure that Docker Desktop is running.

1. Clone this repository, and then open the repository folder in Visual Studio Code.

1. Open the Command Palette, and then run **Dev Containers: Reopen in Container**.

1. Wait for the container to finish setting up. The first start can take several minutes.

> **Warning:** Don't rebuild the development container during the lab. A rebuild recreates `/home/vscode/LabFiles/CaldovaInventory` and resets the SQL01 database, which discards your work.

## Verify the lab environment

1. Select **Terminal**, then select **New Terminal**. The terminal opens PowerShell in the repository folder.

1. Confirm that the application workspace exists.

    ```powershell
    Test-Path /home/vscode/LabFiles/CaldovaInventory/Program.cs
    ```

    Confirm that the command returns **True**. If it returns **False**, the setup didn't finish. Run the setup again, and then repeat this step:

    ```powershell
    bash "$env:LAB_REPO_ROOT/.devcontainer/post-create.sh"
    ```

1. Confirm that APP01 can reach SQL01 on TCP port 1433.

    ```powershell
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $client.Connect("SQL01", 1433)
        "TcpTestSucceeded : $($client.Connected)"
    }
    finally {
        $client.Dispose()
    }
    ```

1. Confirm that the output includes:

    ```text
    TcpTestSucceeded : True
    ```

    > **Warning:** Don't continue if the connection fails. SQL Server must be reachable on TCP port 1433 before the application can access inventory data. Run `bash "$env:LAB_REPO_ROOT/.devcontainer/post-create.sh"` to start and seed SQL01 again, and then repeat the test.

1. Confirm that the lab tools are installed.

    ```powershell
    dotnet --version
    az version --query '"azure-cli"' --output tsv
    copilot --version
    Get-Command sqlcmd, bcp | Select-Object Name, Source
    ```

    Confirm that the .NET version starts with **8.** and that each command returns a value.

## Sign in to Azure

1. Sign in to Azure.

    ```powershell
    az login --use-device-code
    ```

1. Azure CLI displays a code and the address `https://microsoft.com/devicelogin`. Open the address in a browser, enter the code, and sign in with an account that has the **Owner** role on the subscription that you want to use.

1. When prompted in the terminal for the subscription, enter the number of the subscription that you want to use for the lab, and then select **Enter**.

1. Confirm the active subscription.

    ```powershell
    az account show --query "{name:name, id:id}" --output table
    ```

## Deploy the Azure infrastructure

The setup script predeploys the Azure resources that Exercises 9 to 12 use. It registers the required resource providers, deploys `infra/arm/azuredeploy.json` to a dedicated resource group, and connects the Container App to Azure SQL Database and Azure Container Registry.

1. Choose an Azure region that offers Azure Container Apps and Azure SQL Database. To list the region names that your subscription can use, run:

    ```powershell
    az account list-locations --query "[?metadata.regionType=='Physical'].name" --output tsv
    ```

1. Run the setup script. Replace `<region>` with the region name that you chose. You can also replace `rg-caldova-lab` with another resource group name.

    ```powershell
    ./scripts/setup/Deploy-LabInfrastructure.ps1 -ResourceGroupName rg-caldova-lab -Location <region>
    ```

1. When prompted, enter and confirm a password for the Azure SQL administrator account **caldovaadmin**. The password must:

    - Be 8 to 128 characters long.
    - Contain characters from at least three of these categories: uppercase letters, lowercase letters, digits, and symbols.
    - Not contain three or more consecutive characters from the login name **caldovaadmin**.

    > **Note:** Remember this password. You enter it again in Exercise 9. Don't record it in the evidence files, in screenshots, or in Copilot prompts.

1. Wait for the script to finish. The deployment can take several minutes. When it completes, the script displays the resource group, the Azure SQL server and administrator login, the container registry, the Container Apps environment, the Container App, and the application URL. The application URL shows a placeholder page until you deploy the Caldova image in Exercise 10.

1. Record the resource group name. You enter it in Exercise 9 and during cleanup.

> **Note:** If the script fails, fix the reported problem, and then run the same command again with the same password. The script reuses the existing resource group and resource names. If you rerun it after Exercise 10, it resets the Container App to the placeholder image; repeat the **Configure the predeployed Container App** section of Exercise 10 afterward.

The lab environment is ready. Continue with Exercise 1.

---

[Lab index](../../Index.md) · [Exercise 1: Open the application workspace →](../01-open-the-application-workspace/index.md)
