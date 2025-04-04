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

1. Export developer certificate (from Windows):

   ```pwsh
   New-Item -Path $env:USERPROFILE/.aspnet/https -ItemType Directory -Force
   dotnet dev-certs https --trust
   dotnet dev-certs https -ep "$env:USERPROFILE/.aspnet/https/aspnetapp.pfx" -p "<YourStrong@Passw0rd>"
   $distro = (wsl -l -q | Select-Object -First 1) -Replace "`0", ""
   $username = wsl --distribution $distro whoami
   Copy-Item ~\.aspnet\https\ \\wsl.localhost\$distro\home\$username\.aspnet\https\ -Recurse
   ```

1. Login to Azure CLI (or use Azure Cloud Shell in the Azure Portal):

   ```bash
   TENANT="..."
   SUBSCRIPTION="..."

   az login --tenant $TENANT
   az account set --subscription $SUBSCRIPTION
   ```

1. Create a _Microsoft Entra application (SPN)_ and connect it to _GitHub_:

   ```bash
   APP_DISPLAY_NAME="..."
   GITHUB_ORGANIZATION="..."
   REPOSITORY="..."

   CLIENT_ID=$(az ad app create --display-name $APP_DISPLAY_NAME --query appId --output tsv)

   OBJECT_ID=$(az ad sp create --id $CLIENT_ID --query id --output tsv)

   az role assignment create --assignee $OBJECT_ID --role "Owner" --scope "/subscriptions/$SUBSCRIPTION"

   az ad app federated-credential create --id $CLIENT_ID --parameters "{ \"name\": \"$GITHUB_ORGANIZATION-$REPOSITORY-Environment-Staging\", \"issuer\": \"https://token.actions.githubusercontent.com\", \"subject\": \"repo:$GITHUB_ORGANIZATION/$REPOSITORY:environment:Staging\", \"description\": \"Deploy to staging environment\", \"audiences\": [ \"api://AzureADTokenExchange\" ] }"

   az ad app federated-credential create --id $CLIENT_ID --parameters "{ \"name\": \"$GITHUB_ORGANIZATION-$REPOSITORY-Environment-Production\", \"description\": \"Deploy to production environment\", \"issuer\": \"https://token.actions.githubusercontent.com\", \"subject\": \"repo:$GITHUB_ORGANIZATION/$REPOSITORY:environment:Production\", \"audiences\": [ \"api://AzureADTokenExchange\" ] }"
   ```

1. In _GitHub Settings_ -> _Secrets and Variables_ -> _Actions_, set the following secrets:
   - `AZURE_CLIENT_ID`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`

1. In _GitHub Settings_ -> _Secrets and Variables_ -> _Actions_, set the following variables:
   - `CONTAINER_REGISTRY`: Name of your container registry
   - `DEPLOYMENT_SLOT`: `staging`
   - `LOCATION`: e.g. `swedencentral`
   - `RESOURCE_GROUP`: e.g. `GitHubDemo`
   - `WEBAPP`: Name of your web app

1. Create SQL admin group:

   ```bash
   GROUP_DISPLAY_NAME="GitHub Demo Movie Database Admins"
   GROUP_MAIL_NICKNAME="github-demo-movie-database-admins"
   GROUP=$(az ad group create --display-name "$GROUP_DISPLAY_NAME" --mail-nickname "$GROUP_MAIL_NICKNAME" --query id --output tsv)
   ```

1. Add yourself to the group:

   ```bash
   ME=$(az ad signed-in-user show --query id --output tsv)
   az ad group member add --group $GROUP --member-id $ME
   ```

1. Add the _SPN_ to the group:

   ```bash
   az ad group member add --group $GROUP --member-id $OBJECT_ID
   ```

1. Update [`/infrastructure/main.bicepparam`](/infrastructure/main.bicepparam).
1. Deploy the _infrastructure_ pipeline
1. Execute scripts:

   ```powershell
   $tenantId = "..."
   $sqlServerName = "..."

   .\scripts\Grant-GraphPermissionToManagedIdentity.ps1 -TenantId $tenantId -IdentityName $sqlServerName -Permissions @("User.Read.All", "GroupMember.Read.All", "Application.Read.All")
   ```

   ```bash
   RESOURCE_GROUP="GitHubDemo"
   WEBAPP="..."
   SQL_SERVER="..."
   SLOT="staging"
   DATABASE="Movies"
   STAGING_DATABASE="MoviesStaging"

   az webapp connection create sql --resource-group $RESOURCE_GROUP --name $WEBAPP --slot $SLOT --target-resource-group $RESOURCE_GROUP --server $SQL_SERVER --database $STAGING_DATABASE --system-identity --client-type dotnet --connection $STAGING_DATABASE --new

   az webapp connection create sql --resource-group $RESOURCE_GROUP --name $WEBAPP --target-resource-group $RESOURCE_GROUP --server $SQL_SERVER --database $DATABASE --system-identity --client-type dotnet --connection $DATABASE --new
   ```

   **Note**: Do not set the current user as Entra admin:

1. Deploy the _application_ pipeline
1. Run the app locally:

   ```bash
   # Set development connection string:
   dotnet user-secrets set "ConnectionStrings:Default" "Data Source=localhost,1433;Initial Catalog=Movies;User ID=sa;Password=<YourStrong@Passw0rd>;TrustServerCertificate=True" --project src/MovieApi/

   # Update database:
   dotnet ef database update --project src/MovieApi/

   # Run
   dotnet run --project src/MovieApi/
   ```

1. Build the container locally:

   ```bash
   dotnet publish src/MovieApi/ /t:PublishContainer -p ContainerImageTags=latest
   ```

1. Run container locally (from WSL):

   ```bash
   docker run -it --rm -p 8000:8000 -p 8001:8001 \
   -e ASPNETCORE_HTTP_PORTS=8000 \
   -e ASPNETCORE_HTTPS_PORTS=8001 \
   -e AZURE_SQL_CONNECTIONSTRING="Data Source=host.docker.internal,1433;Initial Catalog=Movies;User ID=sa;Password=<YourStrong@Passw0rd>;TrustServerCertificate=True" \
   -e ASPNETCORE_Kestrel__Certificates__Default__Password="<YourStrong@Passw0rd>" \
   -e ASPNETCORE_Kestrel__Certificates__Default__Path=/https/aspnetapp.pfx \
   -v ~/.aspnet/https:/https ondfisk-githubdemo
   ```

## Notes

To lint repository locally run (from WSL):

```bash
docker run -e DEFAULT_BRANCH=main -e RUN_LOCAL=true -e VALIDATE_GIT_COMMITLINT=false -e VALIDATE_JSCPD=false -e VALIDATE_DOTNET_SLN_FORMAT_ANALYZERS=false -e VALIDATE_DOTNET_SLN_FORMAT_STYLE=false -e FIX_JSON_PRETTIER=true -e FIX_JSON=true -e FIX_YAML_PRETTIER=true -v .:/tmp/lint --rm ghcr.io/super-linter/super-linter:latest
```

You can find the Azure DevOps version [here](https://dev.azure.com/ondfisk/AzureDevOpsDemo).
