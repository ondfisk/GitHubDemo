# GitHub Demo

This repository demonstrates a number of capabilities in GitHub and Microsoft Azure:

- Continuous Planning using _GitHub Issues_
- Continuous Integration using _GitHub Repositories_ and _GitHub Actions_
- Continuous Deployment to _App Services_ and _Azure SQL_ using _GitHub Actions_
- Continuous Security using _GitHub Advanced Security_
- Continuous Monitoring using _Azure Monitor_ and _Application Insights_
- Continuous Quality using unit tests and _GitHub Actions_
- Database migration using _Entity Framework_ and _GitHub Actions_
- Blue/green deployments to _App Services_ using _Deployment Slots_
- Local development environments using _Dev Containers_

## Run locally (in a _Dev Container_)

1. Create and export development certificate from Windows:

   ```pwsh
   New-Item $env:USERPROFILE/.aspnet/https -ItemType Directory -Force
   dotnet dev-certs https -ep $env:USERPROFILE/.aspnet/https/aspnetapp.pfx --password "<YourStrong@Passw0rd>"
   dotnet dev-certs https --trust
   ```

1. Copy development certificate to WSL:

   ```bash
   sudo cp /mnt/c/Users/[Windows-Username]/.aspnet/https/aspnetapp.pfx ~/.aspnet/https
   ```

1. Fork the repository.
1. Clone repository to WSL and open in Visual Studio Code.
1. Open in _Dev Container_.
1. Run locally:

   ```bash
   # Update packages
   dotnet outdated --upgrade

   # Restore
   dotnet restore

   # Build
   dotnet build

   # Set development connection string:
   dotnet user-secrets set "ConnectionStrings:Default" "Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres" --project src/MovieApi/

   # Update database:
   dotnet ef database update --project src/MovieApi/

   # Test
   dotnet test

   # Run
   dotnet watch run --project src/MovieApi/
   ```

1. Browse to <https://localhost:8001/Movies> to inspect API:

   ```json
   [
      {
         "id": 5,
         "title": "12 Angry Men",
         "director": "Sidney Lumet",
         "year": 1957
      },
      {
         "id": 8,
         "title": "Pulp Fiction",
         "director": "Quentin Tarantino",
         "year": 1994
      },
      ...
   ]
   ```

## Deploy to Azure

1. Login to Azure and GitHub:

   ```bash
   az login
   gh auth login
   ```

1. Declare input variables

   ```bash
   SUBSCRIPTION=$(az account show --query id --output tsv)
   RESOURCE_GROUP="GitHubDemo"
   GITHUB_ORGANIZATION="ondfisk"
   REPOSITORY="GitHubDemo"
   APP_REGISTRATION_DISPLAY_NAME="$GITHUB_ORGANIZATION-$REPOSITORY"
   ```

1. Create a _Microsoft Entra application (SPN)_ and connect it to _GitHub_:

   ```bash
   CLIENT_ID=$(az ad app create --display-name $APP_REGISTRATION_DISPLAY_NAME --query appId --output tsv)
   OBJECT_ID=$(az ad sp create --id $CLIENT_ID --query id --output tsv)

   az role assignment create --assignee $OBJECT_ID --role "Owner" --scope "/subscriptions/$SUBSCRIPTION"

   az ad app federated-credential create --id $CLIENT_ID --parameters "{ \"name\": \"$GITHUB_ORGANIZATION-$REPOSITORY-Environment-Staging\", \"issuer\": \"https://token.actions.githubusercontent.com\", \"subject\": \"repo:$GITHUB_ORGANIZATION/$REPOSITORY:environment:Staging\", \"description\": \"Deploy to staging environment\", \"audiences\": [ \"api://AzureADTokenExchange\" ] }"

   az ad app federated-credential create --id $CLIENT_ID --parameters "{ \"name\": \"$GITHUB_ORGANIZATION-$REPOSITORY-Environment-Production\", \"description\": \"Deploy to production environment\", \"issuer\": \"https://token.actions.githubusercontent.com\", \"subject\": \"repo:$GITHUB_ORGANIZATION/$REPOSITORY:environment:Production\", \"audiences\": [ \"api://AzureADTokenExchange\" ] }"
   ```

1. Set repository secrets:

   ```bash
   TENANT=$(az account show --query tenantId --output tsv)

   gh secret set AZURE_TENANT_ID --body "$TENANT"
   gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION"
   gh secret set AZURE_CLIENT_ID --body "$CLIENT_ID"
   gh secret set AZURE_CLIENT_DISPLAY_NAME --body "$APP_REGISTRATION_DISPLAY_NAME"
   ```

1. Push the changes to trigger the _infrastructure_ workflow.

1. Grant _SPN_ access to PostgreSQL server:

   ```bash
   DATABASE_SERVER=$(az postgres flexible-server list --resource-group $RESOURCE_GROUP --query [].name --output tsv)

   az postgres flexible-server microsoft-entra-admin create --display-name "$APP_REGISTRATION_DISPLAY_NAME" --object-id $OBJECT_ID --resource-group $RESOURCE_GROUP --server-name $DATABASE_SERVER --type ServicePrincipal
   ```

1. Grant web app permission to database:

   ```bash
   WEB_APP=$(az webapp list --resource-group $RESOURCE_GROUP --query [].name --output tsv)
   SLOT="staging"
   DATABASE="Movies"
   STAGING_DATABASE="MoviesStaging"

   az webapp connection create postgres-flexible --resource-group $RESOURCE_GROUP --name $WEB_APP --target-resource-group $RESOURCE_GROUP --server $DATABASE_SERVER --database $DATABASE --system-identity --client-type dotnet --connection $DATABASE --new --opt-out configinfo

   az webapp connection create postgres-flexible --resource-group $RESOURCE_GROUP --name $WEB_APP --slot $SLOT --target-resource-group $RESOURCE_GROUP --server $DATABASE_SERVER --database $STAGING_DATABASE --system-identity --client-type dotnet --connection $STAGING_DATABASE --new --opt-out configinfo
   ```

1. Run the _application_ workflow from GitHub.

## Clean up

```bash
az group delete --name $RESOURCE_GROUP
az ad app delete --id $CLIENT_ID
```

## Notes

To lint repository locally run (from WSL):

```bash
docker run -e DEFAULT_BRANCH=main -e RUN_LOCAL=true -e VALIDATE_GIT_COMMITLINT=false -e VALIDATE_JSCPD=false -e FIX_JSON=true -e FIX_JSON_PRETTIER=true -e FIX_JSONC=true -e FIX_JSONC_PRETTIER=true -e FIX_MARKDOWN=true -e FIX_MARKDOWN_PRETTIER=true -e FIX_YAML_PRETTIER=true -v .:/tmp/lint --rm ghcr.io/super-linter/super-linter:latest
```

## Links

- [Azure DevOps version](https://dev.azure.com/ondfisk/AzureDevOpsDemo).
