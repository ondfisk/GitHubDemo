# GitHub Demo

This project demonstrates a number of capabilities in GitHub and Microsoft Azure:

- Continuous Planning using _GitHub Issues_
- Continuous Integration using _GitHub Repositories_ and _GitHub Actions_
- Continuous Deployment to _App Services_ and _Azure SQL_ using _GitHub Actions_
- Continuous Security using _GitHub Advanced Security_
- Continuous Monitoring using _Azure Monitor_ and _Application Insights_
- Continuous Quality using unit tests and _GitHub Actions_
- Database migration using _Entity Framework_ and _GitHub Actions_
- Blue/green deployments to _App Services_ using _Deployment Slots_
- Local development environments using _Dev Containers_

## Prerequisites

1. Create a _Microsoft Entra application (SPN)_ and connect it to _GitHub_ cf. <https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect>.
1. Create SQL admin group:

   ```bash
   GROUP="GitHub Demo Movie Database Admins"
   GROUP_MAIL_NICKNAME=github-demo-movie-database-admins
   az ad group create --display-name "$GROUP" --mail-nickname $GROUP_MAIL_NICKNAME
   ```

1. Add yourself to the group:

   ```bash
   ME=$(az ad signed-in-user show --query id --output tsv)
   az ad group member add --group "$GROUP" --member-id $ME
   ```

1. Add the _SPN_ to the group.
1. Update [`/infrastructure/main.bicepparam`](/infrastructure/main.bicepparam).
1. Deploy the _infrastructure_ pipeline
1. Execute scripts:

   ```powershell
   .\scripts\Grant-GraphPermissionToManagedIdentity.ps1 -TenantId "b461d90e-0c15-44ec-adc2-51d14f9f5731" -IdentityName "ondfisk-githubdemo-sql" -Permissions @("User.Read.All", "GroupMember.Read.All", "Application.Read.All")

   # Answer no to: Do you want to set current user as Entra admin?

   .\scripts\New-AzureWebSitesSqlConnection.ps1 -ResourceGroupName "GitHubDemo" -WebAppName "ondfisk-githubdemo-web" -DeploymentSlotName "staging" -SqlServerName "ondfisk-githubdemo-sql" -DatabaseName "MoviesStaging"

   .\scripts\New-AzureWebSitesSqlConnection.ps1 -ResourceGroupName "GitHubDemo" -WebAppName "ondfisk-githubdemo-web" -SqlServerName "ondfisk-githubdemo-sql" -DatabaseName "Movies"
   ```

1. Deploy the _application_ pipeline
1. Before running the app locally; apply migrations on the local database:

   ```bash
   dotnet ef database update --project src/MyApp/
   ```

## Notes

To lint repository locally run:

```bash
docker run -e DEFAULT_BRANCH=main -e RUN_LOCAL=true -e VALIDATE_CSHARP=false -e VALIDATE_CSS=false -e VALIDATE_CSS_PRETTIER=false -e VALIDATE_DOTNET_SLN_FORMAT_ANALYZERS=false -e VALIDATE_DOTNET_SLN_FORMAT_STYLE=false -e VALIDATE_DOTNET_SLN_FORMAT_WHITESPACE=false -e VALIDATE_JSCPD=false -v .:/tmp/lint --rm ghcr.io/super-linter/super-linter:latest
```

You can find the Azure DevOps version [here](https://dev.azure.com/ondfisk/AzureDevOpsDemo).
