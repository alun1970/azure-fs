<# 
 Shared module: config, logging, prerequisites, authentication, utilities.
#>

# ---------------- Configuration ----------------
$AgaveConfig = @{
    SubscriptionId = "a54b676b-eb6a-4510-8e7e-50c6648638f4"         # TODO: set real subscription
    TenantId       = "043c2251-51b7-4d73-9ad0-874c2833ebcd"
    ResourceGroup  = "rg-agave-nv"
    StorageAccount = "anvstore001"
    FileShare      = "data"
    KeyVaultName   = "agave-nv-keyvault"
    LogDir         = "$PSScriptRoot\..\..\Logs"
}

if (-not (Test-Path $AgaveConfig.LogDir)) { New-Item -ItemType Directory -Path $AgaveConfig.LogDir -Force | Out-Null }

# ---------------- Logging ----------------
function Write-AgaveLog {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS','DEBUG')]$Level='INFO'
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch($Level){
        'INFO' {'Cyan'} 'WARN' {'Yellow'} 'ERROR' {'Red'} 'SUCCESS' {'Green'} 'DEBUG' {'DarkGray'}
    }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $color
    try {
        Add-Content -Path (Join-Path $AgaveConfig.LogDir "agave-fs.log") -Value "[$ts][$Level] $Message"
    } catch {}
}

# ---------------- Admin check ----------------
function Test-AgaveAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ---------------- Prerequisites ----------------
function Initialize-AzPrereqs {
    # Only try to install Az.Accounts if it's really missing
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        Write-AgaveLog "Az.Accounts missing; installing for current user..." INFO
        Install-Module Az.Accounts -Scope CurrentUser -Force -ErrorAction Stop
    }
    
    # Import available modules
    $availableModules = @('Az.Accounts', 'Az.Resources', 'Az.Profile')
    foreach ($module in $availableModules) {
        if (Get-Module -ListAvailable -Name $module) {
            try {
                Import-Module $module -ErrorAction SilentlyContinue
            } catch {
                # Ignore import errors for optional modules
            }
        }
    }
    
    # Only check for critical cmdlets - don't try to install if they're missing
    if (-not (Get-Command Get-AzADUser -ErrorAction SilentlyContinue)) {
        Write-AgaveLog "Get-AzADUser cmdlet not available. You may need to install Az.Resources manually." WARN
        Write-AgaveLog "Run: Install-Module Az.Resources -Scope CurrentUser -Force" INFO
    }
}

# ---------------- Authentication ----------------
function Connect-AgaveAzure {
    [CmdletBinding()]
    param(
        [switch]$DeviceCode,
        [string]$SubscriptionId = $AgaveConfig.SubscriptionId,
        [string]$TenantId = $AgaveConfig.TenantId
    )
    Initialize-AzPrereqs
    $needLogin = $true
    try {
        $ctx = Get-AzContext -ErrorAction Stop
        if ($ctx -and $ctx.Tenant.Id -eq $TenantId -and ($SubscriptionId -eq "" -or $ctx.Subscription.Id -eq $SubscriptionId)) {
            Write-AgaveLog "Using existing context: $($ctx.Account)" INFO
            $needLogin = $false
        }
    } catch {}
    if ($needLogin) {
        Write-AgaveLog "Authenticating to Azure (Tenant: $TenantId)..." INFO
        if ($DeviceCode) {
            Connect-AzAccount -Tenant $TenantId -Subscription $SubscriptionId -UseDeviceAuthentication -ErrorAction Stop | Out-Null
        } else {
            try {
                Connect-AzAccount -Tenant $TenantId -Subscription $SubscriptionId -ErrorAction Stop | Out-Null
            } catch {
                Write-AgaveLog "Fallback to device code auth..." WARN
                Connect-AzAccount -Tenant $TenantId -Subscription $SubscriptionId -UseDeviceAuthentication -ErrorAction Stop | Out-Null
            }
        }
        Write-AgaveLog "Authenticated." SUCCESS
    }
    if ($SubscriptionId) {
        Set-AzContext -Subscription $SubscriptionId | Out-Null
    }
}

# ---------------- Helpers ----------------
function Get-AgaveUNC { "\\$($AgaveConfig.StorageAccount).file.core.windows.net\$($AgaveConfig.FileShare)" }

function Test-AgaveShareAccess {
    $unc = Get-AgaveUNC
    Write-AgaveLog "Testing access to $unc" INFO
    try {
        Get-ChildItem $unc -ErrorAction Stop | Out-Null
        Write-AgaveLog "Share access OK." SUCCESS
        return $true
    } catch {
        Write-AgaveLog "Share access failed: $($_.Exception.Message)" ERROR
        return $false
    }
}

function Mount-AgaveShare {
    param(
        [string]$DriveLetter = "Z:"
    )
    $drive = $DriveLetter.TrimEnd(':')
    $unc = Get-AgaveUNC
    if (Get-PSDrive -Name $drive -ErrorAction SilentlyContinue) {
        Write-AgaveLog "Removing existing mapping $DriveLetter" WARN
        cmd.exe /c "net use $DriveLetter /delete /y" | Out-Null
    }
    Write-AgaveLog "Mapping $DriveLetter -> $unc (persistent)" INFO
    cmd.exe /c "net use $DriveLetter $unc /persistent:yes" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-AgaveLog "Drive mapped." SUCCESS
    } else {
        Write-AgaveLog "Map failed (exit $LASTEXITCODE)" ERROR
    }
}

function Add-AgaveNetworkLocation {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$UNCPath = (Get-AgaveUNC)
    )
    
    try {
        $guid = [System.Guid]::NewGuid().ToString("B")
        Write-AgaveLog "Creating network location using correct registry structure..." INFO
        Write-AgaveLog "GUID: $guid" DEBUG
        Write-AgaveLog "UNC Path: $UNCPath" DEBUG
        
        # Create the main CLSID entry
        $clsidPath = "HKCU:\Software\Classes\CLSID\$guid"
        New-Item -Path $clsidPath -Force | Out-Null
        Set-ItemProperty -Path $clsidPath -Name "(Default)" -Value $Name
        Set-ItemProperty -Path $clsidPath -Name "System.IsPinnedToNameSpaceTree" -Value 0x1 -Type DWord
        Set-ItemProperty -Path $clsidPath -Name "SortOrderIndex" -Value 0x42 -Type DWord
        
        # DefaultIcon - using imageres.dll for network folder icon
        New-Item -Path "$clsidPath\DefaultIcon" -Force | Out-Null
        Set-ItemProperty -Path "$clsidPath\DefaultIcon" -Name "(Default)" -Value "%SystemRoot%\System32\imageres.dll,-1002"
        
        # InProcServer32 - hex value for %SystemRoot%\system32\shell32.dll
        New-Item -Path "$clsidPath\InProcServer32" -Force | Out-Null
        $shell32Path = [byte[]](0x25,0x00,0x53,0x00,0x79,0x00,0x73,0x00,0x74,0x00,0x65,0x00,0x6d,0x00,0x52,0x00,0x6f,0x00,0x6f,0x00,0x74,0x00,0x25,0x00,0x5c,0x00,0x73,0x00,0x79,0x00,0x73,0x00,0x74,0x00,0x65,0x00,0x6d,0x00,0x33,0x00,0x32,0x00,0x5c,0x00,0x73,0x00,0x68,0x00,0x65,0x00,0x6c,0x00,0x6c,0x00,0x33,0x00,0x32,0x00,0x2e,0x00,0x64,0x00,0x6c,0x00,0x6c,0x00,0x00,0x00)
        Set-ItemProperty -Path "$clsidPath\InProcServer32" -Name "(Default)" -Value $shell32Path -Type Binary
        Set-ItemProperty -Path "$clsidPath\InProcServer32" -Name "ThreadingModel" -Value "Apartment"
        
        # Instance
        New-Item -Path "$clsidPath\Instance" -Force | Out-Null
        Set-ItemProperty -Path "$clsidPath\Instance" -Name "CLSID" -Value "{0E5AAE11-A475-4c5b-AB00-C66DE400274E}"
        
        # Instance\InitPropertyBag
        New-Item -Path "$clsidPath\Instance\InitPropertyBag" -Force | Out-Null
        Set-ItemProperty -Path "$clsidPath\Instance\InitPropertyBag" -Name "Attributes" -Value 0x11 -Type DWord
        Set-ItemProperty -Path "$clsidPath\Instance\InitPropertyBag" -Name "TargetFolderPath" -Value $UNCPath
        
        # ShellFolder
        New-Item -Path "$clsidPath\ShellFolder" -Force | Out-Null
        Set-ItemProperty -Path "$clsidPath\ShellFolder" -Name "FolderValueFlags" -Value 0x28 -Type DWord
        Set-ItemProperty -Path "$clsidPath\ShellFolder" -Name "Attributes" -Value 0xF080004D -Type DWord
        
        # Pin to Desktop NameSpace (This PC)
        $desktopNamespacePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$guid"
        New-Item -Path $desktopNamespacePath -Force | Out-Null
        Set-ItemProperty -Path $desktopNamespacePath -Name "(Default)" -Value $Name
        
        # Pin to MyComputer NameSpace (This PC alternative)
        $myComputerNamespacePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\$guid"
        New-Item -Path $myComputerNamespacePath -Force | Out-Null
        Set-ItemProperty -Path $myComputerNamespacePath -Name "(Default)" -Value $Name
        
        Write-AgaveLog "Registry entries created successfully" SUCCESS
        Write-AgaveLog "Network location '$Name' should now appear in:" INFO
        Write-AgaveLog "  • This PC in Windows Explorer" INFO
        Write-AgaveLog "  • Explorer navigation pane" INFO
        Write-AgaveLog "Restart Explorer or press F5 to refresh if not visible immediately" WARN
        
        return $guid
        
    } catch {
        Write-AgaveLog "Failed to create network location: $($_.Exception.Message)" ERROR
        throw
    }
}

function Remove-AgaveNetworkLocation {
    param(
        [string]$Name = "Agave Data"
    )
    
    try {
        Write-AgaveLog "Removing network location: $Name" INFO
        $found = $false
        
        # Search both Desktop and MyComputer namespaces
        $namespacePaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace"
        )
        
        foreach ($namespacePath in $namespacePaths) {
            if (Test-Path $namespacePath) {
                Get-ChildItem -Path $namespacePath -ErrorAction SilentlyContinue | ForEach-Object {
                    $guid = $_.PSChildName
                    $defaultValue = (Get-ItemProperty -Path $_.PSPath -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
                    
                    if ($defaultValue -eq $Name) {
                        Write-AgaveLog "Found network location with GUID: $guid in $namespacePath" INFO
                        
                        # Remove namespace entry
                        Remove-Item -Path $_.PSPath -Recurse -Force
                        Write-AgaveLog "Removed namespace entry: $guid" SUCCESS
                        
                        # Remove CLSID entry
                        $clsidPath = "HKCU:\Software\Classes\CLSID\$guid"
                        if (Test-Path $clsidPath) {
                            Remove-Item -Path $clsidPath -Recurse -Force
                            Write-AgaveLog "Removed CLSID entry: $guid" SUCCESS
                        }
                        
                        # Also check and remove from the other namespace
                        $otherNamespacePath = if ($namespacePath -match "Desktop") {
                            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\$guid"
                        } else {
                            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$guid"
                        }
                        
                        if (Test-Path $otherNamespacePath) {
                            Remove-Item -Path $otherNamespacePath -Recurse -Force
                            Write-AgaveLog "Removed cross-reference namespace entry" SUCCESS
                        }
                        
                        $found = $true
                    }
                }
            }
        }
        
        if ($found) {
            Write-AgaveLog "Network location '$Name' removed successfully" SUCCESS
            Write-AgaveLog "Restart Explorer or press F5 to refresh" INFO
        } else {
            Write-AgaveLog "Network location '$Name' not found" WARN
        }
        
    } catch {
        Write-AgaveLog "Failed to remove network location: $($_.Exception.Message)" ERROR
        throw
    }
}

# ---------------- RBAC Helpers (admin use) ----------------
function Assert-AgaveConfig {
    if ($AgaveConfig.SubscriptionId -eq '<SUBSCRIPTION_ID>' -or [string]::IsNullOrWhiteSpace($AgaveConfig.SubscriptionId)) {
        Write-AgaveLog "SubscriptionId not set in shared config file (afs-common.ps1)." ERROR
        throw "Set SubscriptionId in afs-common.ps1 before running admin operations."
    }
}

function Test-AgaveAzureModules {
    $requiredCmdlets = @('Get-AzADUser', 'Get-AzRoleAssignment', 'New-AzRoleAssignment')
    $missingCmdlets = @()
    
    foreach ($cmdlet in $requiredCmdlets) {
        if (-not (Get-Command $cmdlet -ErrorAction SilentlyContinue)) {
            $missingCmdlets += $cmdlet
        }
    }
    
    if ($missingCmdlets.Count -gt 0) {
        Write-AgaveLog "Missing required Azure cmdlets: $($missingCmdlets -join ', ')" ERROR
        Write-AgaveLog "Please install Az.Resources module: Install-Module Az.Resources -Scope CurrentUser -Force" WARN
        return $false
    }
    
    return $true
}

function Get-AgaveScope {
    @{
        Storage = "/subscriptions/$($AgaveConfig.SubscriptionId)/resourceGroups/$($AgaveConfig.ResourceGroup)/providers/Microsoft.Storage/storageAccounts/$($AgaveConfig.StorageAccount)"
        KeyVault = "/subscriptions/$($AgaveConfig.SubscriptionId)/resourceGroups/$($AgaveConfig.ResourceGroup)/providers/Microsoft.KeyVault/vaults/$($AgaveConfig.KeyVaultName)"
    }
}

function Set-AgaveRoleAssignment {
    param(
        [Parameter(Mandatory)][string]$ObjectId,
        [Parameter(Mandatory)][string]$RoleName,
        [Parameter(Mandatory)][string]$Scope
    )
    if ($script:DryRun) {
        Write-AgaveLog "[DryRun] Would verify/assign role '$RoleName' at scope $Scope for object $ObjectId" INFO
        return
    }
    $existing = Get-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $RoleName -Scope $Scope -ErrorAction SilentlyContinue
    if ($existing) {
        Write-AgaveLog "Role '$RoleName' already assigned at scope." INFO
    } else {
        Write-AgaveLog "Assigning role '$RoleName'..." INFO
        New-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $RoleName -Scope $Scope -ErrorAction Stop | Out-Null
        Write-AgaveLog "Role '$RoleName' assigned." SUCCESS
    }
}

# (Optional) Backwards-compatible aliases (commented out to avoid unapproved verb warnings)
# Set-Alias -Name Ensure-AzPrereqs -Value Initialize-AzPrereqs -Scope Local -ErrorAction SilentlyContinue
# Set-Alias -Name Map-AgaveShare -Value Mount-AgaveShare -Scope Local -ErrorAction SilentlyContinue
# Set-Alias -Name Get-AgaveScopes -Value Get-AgaveScope -Scope Local -ErrorAction SilentlyContinue
# Set-Alias -Name Ensure-AgaveRoleAssignment -Value Set-AgaveRoleAssignment -Scope Local -ErrorAction SilentlyContinue

# Export-ModuleMember can only be called from inside a module, commenting out for dot-sourcing
# Export-ModuleMember -Function * -Variable AgaveConfig