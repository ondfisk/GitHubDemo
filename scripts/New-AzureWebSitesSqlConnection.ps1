param (
    [string]
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $WebAppName,

    [string]
    $DeploymentSlotName,

    [ValidateNotNullOrEmpty()]
    $SqlServerResourceGroupName = $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $SqlServerName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $DatabaseName
)

az extension add --upgrade --name serviceconnector-passwordless

if ($DeploymentSlotName) {
    az webapp connection create sql --resource-group $ResourceGroupName --name $WebAppName --slot $DeploymentSlotName --target-resource-group $SqlServerResourceGroupName --server $SqlServerName --database $DatabaseName --system-identity --client-type dotnet --connection $DatabaseName --new
}
else {
    az webapp connection create sql --resource-group $ResourceGroupName --name $WebAppName --target-resource-group $SqlServerResourceGroupName --server $SqlServerName --database $DatabaseName --system-identity --client-type dotnet --connection $DatabaseName --new
}
