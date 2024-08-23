# Azure DevOps Demo

This project demonstrates a number of capabilities in Azure DevOps and Microsoft Azure:

- Continuous Planning using *GitHub Issues*
- Continuous Integration using *GitHub Repositories* and *GitHub Actions*
- Continuous Deployment to *App Services* and *Azure SQL* using *GitHub Actions*
- Continuous Security using *GitHub Advanced Security*
- Continuous Monitoring using *Azure Monitor* and *Application Insights*
- Continuous Quality using unit tests and *GitHub Actions*
- Database migration using *Entity Framework* and *GitHub Actions*
- Blue/green deployments to *App Services* using *Deployment Slots*

## Prerequisites

1. Create SQL admin group:

    ```bash
    GROUP="Movie Database Admins"
    GROUP_MAIL_NICKNAME=movie-database-admins
    az ad group create --display-name "$GROUP" --mail-nickname $GROUP_MAIL_NICKNAME
    ```

1. Add yourself to the group:

    ```bash
    ME=$(az ad signed-in-user show --query id --output tsv)
    az ad group member add --group "$GROUP" --member-id $ME
    ```

1. Add the *Azure Service Connection* to the group.
1. Update [`/infrastructure/main.bicepparam`](/infrastructure/main.bicepparam).
1. Deploy the *infrastructure* pipeline
1. Connect web app to SQL database,

    **Notes**:

    - Commands must be run in *Azure Cloud Shell* as the SQL Server firewall is configured to block requests from outside Azure.
    - When running the commands, answer `n` to the question *"Do you want to set current user as Entra admin? (y/n)"*

    ```bash
    RESOURCE_GROUP=MyWebApp
    SQL_SERVER=sql-968b52419901
    WEBAPP=web-968b52419901
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
