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

1. Export developer certificate:

   ```pwsh
   New-Item -Path $env:USERPROFILE/.aspnet/https -ItemType Directory -Force
   dotnet dev-certs https --trust
   dotnet dev-certs https -ep "$env:USERPROFILE/.aspnet/https/aspnetapp.pfx" -p "<YourStrong@Passw0rd>"
   $distro = (wsl -l -q | Select-Object -First 1) -Replace "`0", ""
   $username = wsl --distribution $distro whoami
   Copy-Item ~\.aspnet\https\ \\wsl.localhost\$distro\home\$username\.aspnet\https\ -Recurse
   ```

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
   .\scripts\Grant-GraphPermissionToManagedIdentity.ps1 -TenantId "b461d90e-0c15-44ec-adc2-51d14f9f5731" -IdentityName "githubdemo-sql" -Permissions @("User.Read.All", "GroupMember.Read.All", "Application.Read.All")
   ```

   Do not set the current user as Entra admin:

   ```bash
   az webapp connection create sql --resource-group "GitHubDemo" --name "githubdemo-web" --slot "staging" --target-resource-group "GitHubDemo" --server "githubdemo-sql" --database "MoviesStaging" --system-identity --client-type dotnet --connection "MoviesStaging" --new

   az webapp connection create sql --resource-group "GitHubDemo" --name "githubdemo-web" --target-resource-group "GitHubDemo" --server "githubdemo-sql" --database "Movies" --system-identity --client-type dotnet --connection "Movies" --new
   ```

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
   -v ~/.aspnet/https:/https githubdemo
   ```

## Notes

To lint repository locally run (from WSL):

```bash
docker run -e DEFAULT_BRANCH=main -e RUN_LOCAL=true -e FIX_JSON_PRETTIER=true -e FIX_JSON=true -e FIX_YAML_PRETTIER=true -e VALIDATE_JSCPD=false -e VALIDATE_DOTNET_SLN_FORMAT_ANALYZERS=false -e VALIDATE_DOTNET_SLN_FORMAT_STYLE=false -v .:/tmp/lint --rm ghcr.io/super-linter/super-linter:latest
```

You can find the Azure DevOps version [here](https://dev.azure.com/ondfisk/AzureDevOpsDemo).
