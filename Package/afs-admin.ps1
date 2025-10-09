<#
 Admin script: RBAC assignment & validation.
 Usage examples:
   .\agave-admin.ps1 -AddUser user@domain
   .\agave-admin.ps1 -ListRoles -User user@domain
#>

[CmdletBinding()]
param(
    [string]$AddUser,
    [string]$User,
    [switch]$ListRoles,
    [switch]$DeviceCode,
    [switch]$TestShare,
    [switch]$VerboseAuth,
    [switch]$DryRun,
    [switch]$Help
)

# Import shared module (updated path)
Import-Module "$PSScriptRoot\afs-common.ps1" -Force

# Show help if requested
if ($Help) {
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host "AZURE FILE SHARE ADMIN SCRIPT - HELP" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Cyan
    Write-Host "  Manages Azure File Share user access and RBAC permissions"
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Cyan
    Write-Host "  -AddUser <email>     Add user with Storage and KeyVault permissions"
    Write-Host "  -ListRoles -User <email>  List RBAC roles for specified user"
    Write-Host "  -TestShare           Test access to the Azure File Share"
    Write-Host "  -VerboseAuth         Show detailed authentication information"
    Write-Host "  -DeviceCode          Use device code authentication flow"
    Write-Host "  -DryRun              Preview changes without making them"
    Write-Host "  -Help                Show this help message"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Cyan
    Write-Host "  # Add a new user (dry run first)"
    Write-Host "  .\afs-admin.ps1 -AddUser 'user@agave-nv.com' -DryRun" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Actually add the user"
    Write-Host "  .\afs-admin.ps1 -AddUser 'user@agave-nv.com'" -ForegroundColor White
    Write-Host ""
    Write-Host "  # List user's current roles"
    Write-Host "  .\afs-admin.ps1 -ListRoles -User 'user@agave-nv.com'" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Test share access"
    Write-Host "  .\afs-admin.ps1 -TestShare" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Use device code auth with verbose output"
    Write-Host "  .\afs-admin.ps1 -DeviceCode -VerboseAuth -DryRun" -ForegroundColor White
    Write-Host ""
    Write-Host "REQUIREMENTS:" -ForegroundColor Cyan
    Write-Host "  • Run PowerShell as Administrator"
    Write-Host "  • Azure PowerShell modules (Az.Accounts, Az.Resources)"
    Write-Host "  • Valid Azure credentials for the tenant"
    Write-Host ""
    Write-Host "ROLES ASSIGNED:" -ForegroundColor Cyan
    Write-Host "  • Storage File Data SMB Share Contributor (on storage account)"
    Write-Host "  • Key Vault Secrets User (on key vault)"
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Yellow
    exit 0
}

# Propagate DryRun flag to shared functions
$script:DryRun = $DryRun.IsPresent

if (-not (Test-AgaveAdmin)) {
    Write-AgaveLog "Administrator privileges required." ERROR
    exit 1
}

Assert-AgaveConfig

# Check if required Azure modules are available
if (-not (Test-AgaveAzureModules)) {
    Write-AgaveLog "Please install required Azure modules and try again." ERROR
    Write-AgaveLog "Run: Install-Module Az.Resources -Scope CurrentUser -Force" INFO
    exit 1
}

Connect-AgaveAzure -DeviceCode:$DeviceCode

if ($VerboseAuth) {
    $ctx = Get-AzContext
    Write-AgaveLog "Context: Sub=$($ctx.Subscription.Name) Account=$($ctx.Account.Id)" DEBUG
}

if ($AddUser) {
    Write-AgaveLog "Processing RBAC for user: $AddUser" INFO
    $azureUser = Get-AzADUser -UserPrincipalName $AddUser -ErrorAction SilentlyContinue
    if (-not $azureUser) {
        Write-AgaveLog "User not found in tenant." ERROR
        exit 1
    }
    $scopes = Get-AgaveScope
    Set-AgaveRoleAssignment -ObjectId $azureUser.Id -RoleName "Storage File Data SMB Share Contributor" -Scope $scopes.Storage
    Set-AgaveRoleAssignment -ObjectId $azureUser.Id -RoleName "Key Vault Secrets User" -Scope $scopes.KeyVault
}

if ($ListRoles -and $User) {
    $u = Get-AzADUser -UserPrincipalName $User -ErrorAction SilentlyContinue
    if ($u) {
    $scopes = Get-AgaveScope
        Write-AgaveLog "Listing role assignments (may take a moment)..." INFO
        $assignments = Get-AzRoleAssignment -ObjectId $u.Id | Where-Object { $_.Scope -in $scopes.Values }
        $assignments | ForEach-Object {
            Write-AgaveLog "Role: $($_.RoleDefinitionName) Scope: $($_.Scope)" INFO
        }
    } else {
        Write-AgaveLog "User $User not found." ERROR
    }
}

if ($TestShare) {
    Test-AgaveShareAccess | Out-Null
}

Write-AgaveLog "Admin script complete." SUCCESS