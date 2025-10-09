<#
 User script: authenticate (if needed), map drive, test access.
 Usage:
   .\agave-user.ps1
   .\agave-user.ps1 -Drive X: -Remap
   .\agave-user.ps1 -TestOnly
#>

[CmdletBinding()]
param(
    [string]$Name = "Agave Data",
    [switch]$Remove,
    [switch]$DeviceCode,
    [switch]$TestOnly,
    [switch]$Help
)

# Import shared module (corrected path)
Import-Module "$PSScriptRoot\afs-common.ps1" -Force

# Show help if requested
if ($Help) {
    Write-Host $("=" * 60) -ForegroundColor Yellow
    Write-Host "AZURE FILE SHARE USER SCRIPT - HELP" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Cyan
    Write-Host "  Creates Azure File Share network location in 'This PC' (OneDrive-style)"
    Write-Host "  Adds registry entries for integrated Windows Explorer experience"
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Cyan
    Write-Host "  -Name <name>         Display name for network location (default: 'Agave Data')"
    Write-Host "  -Remove              Remove the network location"
    Write-Host "  -DeviceCode          Use device code authentication flow"
    Write-Host "  -TestOnly            Only test access, don't create network location"
    Write-Host "  -Help                Show this help message"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Cyan
    Write-Host "  # Create network location in This PC"
    Write-Host "  .\afs-user.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Create with custom name"
    Write-Host "  .\afs-user.ps1 -Name 'Company Files'" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Remove network location"
    Write-Host "  .\afs-user.ps1 -Remove" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Use device code authentication"
    Write-Host "  .\afs-user.ps1 -DeviceCode" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Test access only (no registry changes)"
    Write-Host "  .\afs-user.ps1 -TestOnly" -ForegroundColor White
    Write-Host ""
    Write-Host "WHAT IT DOES:" -ForegroundColor Cyan
    Write-Host "  1. Authenticates to Azure (if not -TestOnly)"
    Write-Host "  2. Creates registry entries for network location"
    Write-Host "  3. Adds folder icon to 'This PC' and Explorer sidebar"
    Write-Host "  4. Tests access to verify connection works"
    Write-Host ""
    Write-Host "REQUIREMENTS:" -ForegroundColor Cyan
    Write-Host "  • Valid Azure credentials for the tenant"
    Write-Host "  • RBAC permissions on the storage account"
    Write-Host "  • Network connectivity to Azure"
    Write-Host ""
    Write-Host "SHARE LOCATION:" -ForegroundColor Cyan
    Write-Host "  \\anvstore001.file.core.windows.net\data"
    Write-Host ""
    Write-Host $("=" * 60) -ForegroundColor Yellow
    exit 0
}

Write-AgaveLog "Agave user operation start." INFO

if ($Remove) {
    Write-AgaveLog "Removing network location..." INFO
    Remove-AgaveNetworkLocation -Name $Name
    Write-AgaveLog "User script complete." SUCCESS
    exit 0
}

if (-not $TestOnly) {
    Connect-AgaveAzure -DeviceCode:$DeviceCode
}

if (-not $TestOnly) {
    Write-AgaveLog "Creating network location in 'This PC'..." INFO
    Add-AgaveNetworkLocation -Name $Name
    Write-AgaveLog "Network location '$Name' added to Windows Explorer" SUCCESS
}

Test-AgaveShareAccess | Out-Null

if (-not $TestOnly) {
    Write-AgaveLog "Network location setup complete. Check 'This PC' in Windows Explorer." SUCCESS
} else {
    Write-AgaveLog "Test completed successfully." SUCCESS
}

Write-AgaveLog "User script complete." SUCCESS