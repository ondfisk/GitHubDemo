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
1. Connect web app to SQL database,

   **Notes**:

   - Commands must be run in _Azure Cloud Shell_ as the SQL Server firewall is configured to block requests from outside Azure.
   - When running the commands, answer `n` to the question _"Do you want to set current user as Entra admin? (y/n)"_

   ```bash
   RESOURCE_GROUP=GitHubDemo
   SQL_SERVER=ondfisk-githubdemo
   WEBAPP=ondfisk-githubdemo
   DATABASE=Movies

   az webapp connection create sql --resource-group $RESOURCE_GROUP --name $WEBAPP --target-resource-group $RESOURCE_GROUP --server $SQL_SERVER --database $DATABASE --system-identity --client-type dotnet --connection $DATABASE # --config-connstr (in preview; to be enabled later)

   SLOT=staging
   SLOT_DATABASE=MoviesStaging

   az webapp connection create sql --resource-group $RESOURCE_GROUP --name $WEBAPP --slot $SLOT --target-resource-group $RESOURCE_GROUP --server $SQL_SERVER --database $SLOT_DATABASE --system-identity --client-type dotnet --connection $SLOT_DATABASE # --config-connstr (in preview; not working for deployment slots yet)
   ```

1. Before running the app locally; apply migrations on the local database:

   ```bash
   dotnet ef database update
   ```

## Notes

To lint codebase locally you can run [Super-Linter](https://github.com/super-linter/super-linter):

```bash
docker run -e LOG_LEVEL=DEBUG -e RUN_LOCAL=true -e DEFAULT_BRANCH=main -e VALIDATE_CSS=false -e VALIDATE_CSS_PRETTIER=false -e VALIDATE_JSCPD=false -e VALIDATE_JSON_PRETTIER=false -v .:/tmp/lint ghcr.io/super-linter/super-linter:latest
```

You can find the Azure DevOps version [here](https://dev.azure.com/ondfisk/AzureDevOpsDemo).
