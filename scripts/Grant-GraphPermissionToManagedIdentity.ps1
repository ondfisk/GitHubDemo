param (
    [string]
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $TenantId,

    [string]
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $IdentityName = "githubdemo-sql",

    [string[]]
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $Permissions
)

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

# Log in as a user with the "Global Administrator" or "Privileged Role Administrator" role
Connect-MgGraph -TenantId $TenantId -Scopes "AppRoleAssignment.ReadWrite.All,Application.Read.All"

# Search for Microsoft Graph
$graph = Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'";

$identity = Get-MgServicePrincipal -Filter "DisplayName eq '$IdentityName'"

if ($identity.Count -gt 1) {
    Write-Output "More than 1 principal found with that name, please find your principal and copy its object ID. Replace the above line with the syntax $identity = Get-MgServicePrincipal -ServicePrincipalId <your_object_id>"
    Exit
}

# Find app permissions within Microsoft Graph application
$roles = $graph.AppRoles | Where-Object { ($_.Value -in $Permissions) }

# Assign the managed identity app roles for each permission
foreach ($appRole in $roles) {
    $appRoleAssignment = @{
        principalId = $identity.Id
        resourceId  = $graph.Id
        appRoleId   = $appRole.Id
    }

    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $appRoleAssignment.principalId -BodyParameter $appRoleAssignment
}