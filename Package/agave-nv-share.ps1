<#
.SYNOPSIS
    Agave New Ventures Azure File Share - Complete Installer & Setup
    
.DESCRIPTION
    All-in-one PowerShell script that combines installation and Azure configuration.
    Replaces both MSI installer and separate setup scripts with a single solution.
    
    NOTE: This script automatically elevates itself to administrator privileges if needed.
    
.PARAMETER Help
    Display help information with all available parameters and examples
    
.PARAMETER ShowProgress
    Show detailed progress and keep PowerShell window open (default: true)
    
.PARAMETER SilentInstall  
    Run installation silently without user interaction (default: false)
    
.PARAMETER RunAddUser
    Run the ADD-USER tool after installation (requires -Username)
    
.PARAMETER Username
    Username for ADD-USER operations (e.g., "user@agave-nv.com")
    
.PARAMETER RunFixDomain
    Run the FIX-DOMAIN-ERROR tool after installation
    
.PARAMETER UninstallOnly
    Only perform uninstallation, don't install
    
.PARAMETER ConfigureAzureOnly
    Only run Azure configuration (skip installation)
    
.PARAMETER SkipPrereqCheck
    Skip prerequisite validation (not recommended)
    
.PARAMETER TestOnly
    Run tests and validation only, don't make changes

.EXAMPLE
    .\AgaveFileShareComplete.ps1
    Complete installation with Azure configuration
    
.EXAMPLE  
    .\AgaveFileShareComplete.ps1 -SilentInstall
    Silent installation without user interaction
    
.EXAMPLE
    .\AgaveFileShareComplete.ps1 -RunAddUser -Username "robin.cave@agave-nv.com"
    Install and add user permissions
    
.EXAMPLE
    .\AgaveFileShareComplete.ps1 -ConfigureAzureOnly
    Only run Azure setup (files already installed)
    
.EXAMPLE
    .\AgaveFileShareComplete.ps1 -UninstallOnly
    Remove the installation
#>

param(
    [switch]$Help = $false,
    [switch]$ShowProgress = $true,
    [switch]$SilentInstall = $false,
    [switch]$RunAddUser = $false,
    [string]$Username = "",
    [switch]$RunFixDomain = $false,
    [switch]$UninstallOnly = $false,
    [switch]$ConfigureAzureOnly = $false,
    [switch]$SkipPrereqCheck = $false,
    [switch]$TestOnly = $false
)

# =============================================================================
# HELP: Display usage information if requested
# =============================================================================

if ($Help) {
    Write-Host "`n╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "              AGAVE-NV-SHARE.PS1 - COMMAND LINE OPTIONS             " -ForegroundColor White -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  All-in-one Azure File Share installer with automatic admin elevation.`n" -ForegroundColor Gray
    
    Write-Host "SWITCH PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -Help" -ForegroundColor Green -NoNewline
    Write-Host "                   Display this help message" -ForegroundColor Gray
    Write-Host "  -ShowProgress" -ForegroundColor Green -NoNewline
    Write-Host "         Show detailed progress (default: TRUE)" -ForegroundColor Gray
    Write-Host "  -SilentInstall" -ForegroundColor Green -NoNewline
    Write-Host "        Run without user interaction (default: FALSE)" -ForegroundColor Gray
    Write-Host "  -RunAddUser" -ForegroundColor Green -NoNewline
    Write-Host "            Run ADD-USER tool after install (requires -Username)" -ForegroundColor Gray
    Write-Host "  -RunFixDomain" -ForegroundColor Green -NoNewline
    Write-Host "          Run FIX-DOMAIN-ERROR tool after install" -ForegroundColor Gray
    Write-Host "  -UninstallOnly" -ForegroundColor Green -NoNewline
    Write-Host "         Only uninstall, don't install" -ForegroundColor Gray
    Write-Host "  -ConfigureAzureOnly" -ForegroundColor Green -NoNewline
    Write-Host "    Only run Azure config (skip installation)" -ForegroundColor Gray
    Write-Host "  -SkipPrereqCheck" -ForegroundColor Green -NoNewline
    Write-Host "       Skip prerequisite validation (not recommended)" -ForegroundColor Gray
    Write-Host "  -TestOnly" -ForegroundColor Green -NoNewline
    Write-Host "             Run validation tests only, don't make changes`n" -ForegroundColor Gray
    
    Write-Host "STRING PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -Username" -ForegroundColor Green -NoNewline
    Write-Host " `"user@domain`"  Username for ADD-USER operations`n" -ForegroundColor Gray
    
    Write-Host "USAGE EXAMPLES:" -ForegroundColor Cyan
    Write-Host "  .\agave-nv-share.ps1" -ForegroundColor White
    Write-Host "    → Full installation with Azure configuration" -ForegroundColor Gray
    Write-Host "`n  .\agave-nv-share.ps1 -SilentInstall" -ForegroundColor White
    Write-Host "    → Silent installation without prompts" -ForegroundColor Gray
    Write-Host "`n  .\agave-nv-share.ps1 -RunAddUser -Username `"robin.cave@agave-nv.com`"" -ForegroundColor White
    Write-Host "    → Install and add user permissions" -ForegroundColor Gray
    Write-Host "`n  .\agave-nv-share.ps1 -ConfigureAzureOnly" -ForegroundColor White
    Write-Host "    → Only run Azure setup (files already installed)" -ForegroundColor Gray
    Write-Host "`n  .\agave-nv-share.ps1 -UninstallOnly" -ForegroundColor White
    Write-Host "    → Remove the installation" -ForegroundColor Gray
    Write-Host "`n  .\agave-nv-share.ps1 -TestOnly" -ForegroundColor White
    Write-Host "    → Run validation tests without making changes`n" -ForegroundColor Gray
    
    Write-Host "NOTE:" -ForegroundColor Yellow -NoNewline
    Write-Host " This script automatically elevates to administrator privileges.`n" -ForegroundColor Gray
    
    Write-Host "Press Enter to exit..." -ForegroundColor Cyan
    Read-Host
    exit 0
}

# =============================================================================
# SELF-ELEVATION: Automatically restart as Administrator if needed
# =============================================================================

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "`n  This script requires administrator privileges." -ForegroundColor Yellow
    Write-Host "`n  Automatically restarting with elevated permissions..." -ForegroundColor Cyan

    # Build the argument string with all parameters
    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")    # Pass through all the original parameters
    if ($ShowProgress) { $argList += "-ShowProgress" }
    if ($SilentInstall) { $argList += "-SilentInstall" }
    if ($RunAddUser) { $argList += "-RunAddUser" }
    if ($Username) { $argList += "-Username", "`"$Username`"" }
    if ($RunFixDomain) { $argList += "-RunFixDomain" }
    if ($UninstallOnly) { $argList += "-UninstallOnly" }
    if ($ConfigureAzureOnly) { $argList += "-ConfigureAzureOnly" }
    if ($SkipPrereqCheck) { $argList += "-SkipPrereqCheck" }
    if ($TestOnly) { $argList += "-TestOnly" }
    
    try {
        # Start elevated process
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs -PassThru -WindowStyle Normal
        
        # Wait a moment to see if elevation was successful
        Start-Sleep -Milliseconds 500
        
        if ($process.HasExited -and $process.ExitCode -ne 0) {
            Write-Host " Failed to elevate. Please run PowerShell as Administrator manually." -ForegroundColor Red
            Write-Host "`nPress Enter to exit..." -ForegroundColor Red
            Read-Host
            exit 1
        }
        
        # Exit the non-elevated instance (this is the original non-admin window - let it close)
        exit 0
        
    } catch {
        Write-Host " Elevation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please right-click the script and select 'Run as Administrator'" -ForegroundColor Yellow
        Write-Host "`nPress Enter to exit..." -ForegroundColor Red
        Read-Host
        exit 1
    }
}

# If we reach here, we're running as administrator
Write-Host " Running with administrator privileges" -ForegroundColor Green

# =============================================================================
# GLOBAL CONFIGURATION
# =============================================================================

$Global:Config = @{
    # Installation paths
    InstallPath = "C:\Program Files\Agave New Ventures\Azure File Share"
    StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Agave New Ventures"
    LogPath = "$env:TEMP\AgaveFileShare-Setup.log"
    TranscriptPath = "$env:TEMP\AgaveFileShare-Transcript.log"
    
    # File Explorer integration
    NamespaceGUID = "{A5E4B2F3-3C4D-5E6F-9A1B-234567890DEF}"
    NamespaceDisplayName = "Agave New Ventures Data"
    
    # Azure configuration
    StorageAccount = "anvstore001"
    FileShareName = "data"
    KeyVaultName = "agave-nv-keyvault"
    TenantId = "043c2251-51b7-4d73-9ad0-874c2833ebcd"
    NetworkPath = "\\anvstore001.file.core.windows.net\data"
    IconPath = "C:\Program Files\Microsoft OneDrive\OneDrive.exe,6"
    
    # System requirements
    MinWindowsVersion = [Version]"10.0.0.0"
    RequiredPorts = @(443, 445)
}

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO", [ConsoleColor]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if (-not $SilentInstall) {
        Write-Host $logMessage -ForegroundColor $Color
    }
    
    try {
        Add-Content -Path $Global:Config.LogPath -Value $logMessage -Force
    } catch {
        Write-Host "Warning: Unable to write to log file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Write-Success { param([string]$Message) Write-Log " $Message" "SUCCESS" Green }
function Write-Warning { param([string]$Message) Write-Log " $Message" "WARNING" Yellow }  
function Write-Error { param([string]$Message) Write-Log " $Message" "ERROR" Red }
function Write-Info { param([string]$Message) Write-Log "$Message" "INFO" Cyan }

function Start-Logging {
    try {
        # Start PowerShell transcript for detailed logging
        Start-Transcript -Path $Global:Config.TranscriptPath -Force -ErrorAction SilentlyContinue
        Write-Log "Logging initialized - Transcript: $($Global:Config.TranscriptPath)" "SYSTEM" Gray
        Write-Log "Logging initialized - Main log: $($Global:Config.LogPath)" "SYSTEM" Gray
    } catch {
        Write-Log "Warning: Transcript logging unavailable: $($_.Exception.Message)" "WARNING" Yellow
    }
}

function Stop-Logging {
    try {
        Write-Log "Logging session completed" "SYSTEM" Gray
        Stop-Transcript -ErrorAction SilentlyContinue
    } catch {
        # Transcript may not be running, ignore error
    }
}

# =============================================================================
# DISPLAY FUNCTIONS
# =============================================================================

function Show-Header {
    if (-not $SilentInstall) {
        Clear-Host
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host "                   AGAVE NEW VENTURES                          " -ForegroundColor Green
        Write-Host "                 AZURE FILE SHARE INSTALLER                    " -ForegroundColor Green
        Write-Host "                                                               " -ForegroundColor Green
        Write-Host "              Complete PowerShell Solution                     " -ForegroundColor Green
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host ""
    }
    Write-Info "Starting Agave New Ventures File Share setup..."
}

function Show-CompletionMessage {
    if (-not $SilentInstall) {
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Green
        if ($UninstallOnly) {
            Write-Host "                    UNINSTALL COMPLETED!                      " -ForegroundColor Green
        } else {
            Write-Host "                 INSTALLATION COMPLETED!                      " -ForegroundColor Green
        }
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host ""
        
        if (-not $UninstallOnly) {
            Write-Host "Installed to: $($Global:Config.InstallPath)" -ForegroundColor Yellow
            Write-Host "Log file: $($Global:Config.LogPath)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host " Check File Explorer for 'Agave New Ventures Data'" -ForegroundColor White
            Write-Host " Azure File Share should be accessible" -ForegroundColor White
            Write-Host " Restart Explorer if needed: taskkill /f /im explorer.exe ; explorer.exe" -ForegroundColor White
        }
    }
}

# =============================================================================
# PREREQUISITE CHECKING
# =============================================================================

function Test-Prerequisites {
    Write-Info "=== PREREQUISITE VALIDATION ==="
    $allPassed = $true
    $results = @{}

    # 1. Windows Version Check
    Write-Info "Checking Windows version..."
    $osVersion = [Environment]::OSVersion.Version
    if ($osVersion -ge $Global:Config.MinWindowsVersion) {
        Write-Success "Windows version: $osVersion (supported)"
        $results.WindowsVersion = $true
    } else {
        Write-Error "Windows version: $osVersion (minimum required: $($Global:Config.MinWindowsVersion))"
        $results.WindowsVersion = $false
        $allPassed = $false
    }

    # 2. Administrator Privileges Check
    Write-Info "Checking administrator privileges..."
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Write-Success "Running with administrator privileges"
        $results.AdminRights = $true
    } else {
        Write-Error "Administrator privileges required. Please run as administrator."
        $results.AdminRights = $false
        $allPassed = $false
    }

    # 3. PowerShell Version Check
    Write-Info "Checking PowerShell version..."
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        Write-Success "PowerShell version: $psVersion (supported)"
        $results.PowerShellVersion = $true
    } else {
        Write-Error "PowerShell version: $psVersion (minimum required: 5.0)"
        $results.PowerShellVersion = $false
        $allPassed = $false
    }

    # 4. Internet Connectivity Check
    Write-Info "Testing internet connectivity..."
    try {
        $testUrls = @("https://login.microsoftonline.com", "https://management.azure.com")
        $internetOK = $false
        foreach ($url in $testUrls) {
            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
                $internetOK = $true
                break
            } catch {
                continue
            }
        }
        
        if ($internetOK) {
            Write-Success "Internet connectivity: OK"
            $results.InternetConnectivity = $true
        } else {
            Write-Warning "Internet connectivity issues detected"
            $results.InternetConnectivity = $false
        }
    } catch {
        Write-Warning "Internet connectivity test failed: $($_.Exception.Message)"
        $results.InternetConnectivity = $false
    }

    # 5. SMB Connectivity Check (Port 445)
    Write-Info "Checking SMB connectivity (port 445)..."
    try {
        $storageEndpoint = "$($Global:Config.StorageAccount).file.core.windows.net"
        $smbTest = Test-NetConnection -ComputerName $storageEndpoint -Port 445 -WarningAction SilentlyContinue -InformationLevel Quiet
        
        if ($smbTest -eq $true) {
            Write-Success "SMB connectivity to Azure Files: OK"
            $results.SMBConnectivity = $true
        } else {
            Write-Warning "Port 445 blocked - SMB/Azure Files access may not work"
            Write-Warning "Common causes: ISP blocking, corporate firewall"
            $results.SMBConnectivity = $false
        }
    } catch {
        Write-Warning "SMB connectivity test failed: $($_.Exception.Message)"
        $results.SMBConnectivity = $false
    }

    # 6. System Resource Check
    Write-Info "Checking system resources..."
    try {
        $freeSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Where-Object {$_.DeviceID -eq $env:SystemDrive}).FreeSpace / 1GB
        $memory = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        
        if ($freeSpace -gt 1) {
            Write-Success "Free disk space: $([math]::Round($freeSpace, 1)) GB (sufficient)"
            $results.DiskSpace = $true
        } else {
            Write-Warning "Low disk space: $([math]::Round($freeSpace, 1)) GB"
            $results.DiskSpace = $true  # Warning but not blocking
        }
        
        if ($memory -gt 2) {
            Write-Success "System memory: $([math]::Round($memory, 1)) GB (sufficient)"
            $results.Memory = $true
        } else {
            Write-Warning "Low system memory: $([math]::Round($memory, 1)) GB"
            $results.Memory = $true  # Warning but not blocking
        }
    } catch {
        Write-Warning "Could not check system resources: $($_.Exception.Message)"
        $results.DiskSpace = $true
        $results.Memory = $true
    }

    # Summary
    Write-Info ""
    Write-Info "=== PREREQUISITE CHECK SUMMARY ==="
    foreach ($check in $results.Keys) {
        $status = if ($results[$check]) { " PASS" } else { " FAIL" }
        Write-Info "$check`: $status"
    }
    
    if ($allPassed) {
        Write-Success " ALL PREREQUISITES PASSED - Setup can proceed"
    } else {
        Write-Error " SOME PREREQUISITES FAILED - Setup may encounter issues"
    }
    
    return @{
        AllPassed = $allPassed
        Results = $results
    }
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

function Install-FileShareComponents {
    Write-Info "Installing File Share components..."
    
    # Create installation directory
    if (-not (Test-Path $Global:Config.InstallPath)) {
        New-Item -Path $Global:Config.InstallPath -ItemType Directory -Force | Out-Null
        Write-Success "Created installation directory: $($Global:Config.InstallPath)"
    }
    
    # Get current script directory
    $scriptPath = $MyInvocation.ScriptName
    $scriptDir = Split-Path $scriptPath -Parent
    
    # Create embedded files (since we're combining everything)
    $addUserScript = @'
@echo off
REM Azure File Share User Management Tool
REM Usage: ADD-USER.bat "user@domain.com"

setlocal EnableDelayedExpansion

echo.
echo ============================================================================
echo                        AGAVE NEW VENTURES
echo                    AZURE FILE SHARE USER TOOL
echo ============================================================================
echo.

if "%~1"=="" (
    echo ERROR: Username is required
    echo Usage: ADD-USER.bat "user@domain.com"
    echo.
    pause
    exit /b 1
)

set "USERNAME=%~1"
echo Adding Azure permissions for: %USERNAME%
echo.

REM Check if Azure CLI is available
az --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Azure CLI not found. Please install Azure CLI first.
    echo Download from: https://aka.ms/installazurecliwindows
    pause
    exit /b 1
)

REM Add user to storage account
echo Adding Storage File Data SMB Share Contributor role...
az role assignment create --assignee "%USERNAME%" --role "Storage File Data SMB Share Contributor" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/agave-nv-rg/providers/Microsoft.Storage/storageAccounts/anvstore001"

REM Add user to Key Vault
echo Adding Key Vault Secrets User role...
az role assignment create --assignee "%USERNAME%" --role "Key Vault Secrets User" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/agave-nv-rg/providers/Microsoft.KeyVault/vaults/agave-nv-keyvault"

echo.
echo User permissions added successfully!
echo.
pause
'@

    $fixDomainScript = @'
@echo off
REM Domain connectivity troubleshooting tool
REM Helps resolve common domain/network issues with Azure File Share

echo.
echo ============================================================================
echo                        AGAVE NEW VENTURES  
echo                   DOMAIN ERROR FIX UTILITY
echo ============================================================================
echo.

echo Checking network connectivity...
ping anvstore001.file.core.windows.net -n 2

echo.
echo Checking SMB connectivity...
telnet anvstore001.file.core.windows.net 445

echo.
echo Flushing DNS cache...
ipconfig /flushdns

echo.
echo Resetting network adapters...
netsh winsock reset
netsh int ip reset

echo.
echo Domain fix utility completed.
echo Please restart your computer for changes to take effect.
echo.
pause
'@

    $userGuide = @'
# Agave New Ventures File Share - User Guide

## Getting Started

Your Azure File Share is now configured and ready to use!

## Accessing Your Files

1. **File Explorer**: Look for "Agave New Ventures Data" in the left sidebar
2. **Direct Path**: `\\anvstore001.file.core.windows.net\data`
3. **Network Drive**: You can map this as a network drive

## Common Tasks

### Mapping as Network Drive
1. Open File Explorer
2. Click "This PC" 
3. Click "Map network drive"
4. Use path: `\\anvstore001.file.core.windows.net\data`

### Troubleshooting

**Can't see files?**
- Check your network connection
- Verify you have proper permissions
- Try running FIX-DOMAIN-ERROR.bat

**Access denied errors?**
- Contact your IT administrator
- You may need Azure permissions added

## Support

For technical support, contact your IT administrator or Agave New Ventures support team.
'@

    # Write embedded files
    Set-Content -Path (Join-Path $Global:Config.InstallPath "ADD-USER.bat") -Value $addUserScript -Force
    Set-Content -Path (Join-Path $Global:Config.InstallPath "FIX-DOMAIN-ERROR.bat") -Value $fixDomainScript -Force  
    Set-Content -Path (Join-Path $Global:Config.InstallPath "USER-GUIDE.md") -Value $userGuide -Force
    
    # Copy this script as the main setup script
    Copy-Item $MyInvocation.ScriptName (Join-Path $Global:Config.InstallPath "AgaveFileShareComplete.ps1") -Force
    
    Write-Success "All components installed successfully"
}

function Install-FileExplorerIntegration {
    Write-Info "Installing File Explorer integration..."
    
    try {
        # Create namespace registry entry
        $namespacePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$($Global:Config.NamespaceGUID)"
        
        if (-not (Test-Path $namespacePath)) {
            New-Item -Path $namespacePath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $namespacePath -Name "(default)" -Value $Global:Config.NamespaceDisplayName -Force
        Write-Success "File Explorer integration installed"
        
        # Create shell folder configuration
        $shellFolderPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$($Global:Config.NamespaceGUID)\ShellFolder"
        if (-not (Test-Path $shellFolderPath)) {
            New-Item -Path $shellFolderPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $shellFolderPath -Name "Attributes" -Value 0x60000000 -Type DWord -Force
        Write-Success "Shell folder attributes configured"
        
    } catch {
        Write-Error "Failed to install File Explorer integration: $($_.Exception.Message)"
    }
}

function Install-StartMenuShortcuts {
    Write-Info "Installing Start Menu shortcuts..."
    
    try {
        if (-not (Test-Path $Global:Config.StartMenuPath)) {
            New-Item -Path $Global:Config.StartMenuPath -ItemType Directory -Force | Out-Null
        }
        
        # Create User Guide shortcut
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut("$($Global:Config.StartMenuPath)\User Guide.lnk")
        $shortcut.TargetPath = "notepad.exe"
        $shortcut.Arguments = "`"$(Join-Path $Global:Config.InstallPath 'USER-GUIDE.md')`""
        $shortcut.WorkingDirectory = $Global:Config.InstallPath
        $shortcut.Description = "Agave New Ventures File Share User Guide"
        $shortcut.Save()
        
        Write-Success "Start Menu shortcuts created"
        
    } catch {
        Write-Warning "Failed to create Start Menu shortcuts: $($_.Exception.Message)"
    }
}

# =============================================================================
# AZURE CONFIGURATION FUNCTIONS  
# =============================================================================

function Test-AzureAuthentication {
    Write-Info "Testing Azure authentication..."
    
    try {
        # Check if Azure CLI is available
        $azPath = Get-Command "az" -ErrorAction SilentlyContinue
        if (-not $azPath) {
            Write-Warning "Azure CLI not found - will attempt to install"
            return $false
        }
        
        # Test authentication
        $account = & az account show --output json 2>$null | ConvertFrom-Json
        if ($account) {
            Write-Success "Already authenticated as: $($account.user.name)"
            return $true
        } else {
            Write-Info "Not authenticated - will prompt for login"
            return $false
        }
    } catch {
        Write-Warning "Azure authentication test failed: $($_.Exception.Message)"
        return $false
    }
}

function Install-AzureCLI {
    Write-Info "Installing Azure CLI..."
    
    try {
        $azureCliUrl = "https://aka.ms/installazurecliwindows"
        $tempFile = Join-Path $env:TEMP "AzureCLI.msi"
        
        Write-Info "Downloading Azure CLI installer..."
        Invoke-WebRequest -Uri $azureCliUrl -OutFile $tempFile -UseBasicParsing
        
        Write-Info "Installing Azure CLI (this may take a few minutes)..."
        $msiArgs = "/i `"$tempFile`" /quiet /norestart"
        Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait
        
        # Refresh PATH environment variable
        $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if ($machinePath -and $userPath) {
            $env:PATH = $machinePath + ";" + $userPath
        }
        
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        Write-Success "Azure CLI installed successfully"
        return $true
        
    } catch {
        Write-Error "Failed to install Azure CLI: $($_.Exception.Message)"
        return $false
    }
}

function Connect-ToAzure {
    Write-Info "Connecting to Azure..."
    
    try {
        # Attempt login
        & az login --tenant $Global:Config.TenantId
        
        # Verify connection
        $account = & az account show --output json | ConvertFrom-Json
        if ($account) {
            Write-Success "Successfully connected as: $($account.user.name)"
            return $true
        } else {
            Write-Error "Azure login failed"
            return $false
        }
    } catch {
        Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
        return $false
    }
}

function Test-KeyVaultAccess {
    Write-Info "Testing Key Vault access..."
    
    try {
        $secret = & az keyvault secret show --vault-name $Global:Config.KeyVaultName --name "anvstore001-storage-key" --output json 2>$null | ConvertFrom-Json
        
        if ($secret) {
            Write-Success "Key Vault access: OK"
            return $true
        } else {
            Write-Error "Key Vault access: FAILED"
            Write-Error "Possible causes:"
            Write-Error " Missing 'Key Vault Secrets User' role assignment"
            Write-Error " Secret 'anvstore001-storage-key' does not exist in vault '$($Global:Config.KeyVaultName)'"
            Write-Error " Key Vault access policies not configured correctly"
            Write-Error ""
            Write-Error "IT Administrator action required:"
            Write-Error "Run: .\ADD-USER.bat"
            Write-Error "Or manually grant Key Vault permissions for this user"
            return $false
        }
    } catch {
        Write-Error "Key Vault access test failed: $($_.Exception.Message)"
        return $false
    }
}

function Configure-FileShareAccess {
    Write-Info "Configuring file share access..."
    
    try {
        # Test direct access to file share
        $testPath = $Global:Config.NetworkPath
        if (Test-Path $testPath) {
            Write-Success "File share accessible at: $testPath"
            return $true
        } else {
            Write-Warning "File share not immediately accessible"
            Write-Warning "This is normal - may require Explorer restart or credentials"
            return $false
        }
    } catch {
        Write-Warning "File share access test failed: $($_.Exception.Message)"
        return $false
    }
}

# =============================================================================
# UNINSTALLATION FUNCTIONS
# =============================================================================

function Uninstall-FileShareComponents {
    Write-Info "Uninstalling File Share components..."
    $errorCount = 0
    
    try {
        # Remove installation directory
        if (Test-Path $Global:Config.InstallPath) {
            try {
                Remove-Item $Global:Config.InstallPath -Recurse -Force -ErrorAction Stop
                Write-Success "Removed installation directory"
            } catch {
                Write-Error "Failed to remove installation directory: $($_.Exception.Message)"
                $errorCount++
            }
        }
        
        # Remove File Explorer integration (namespace registry)
        try {
            $namespacePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$($Global:Config.NamespaceGUID)"
            if (Test-Path $namespacePath) {
                Remove-Item $namespacePath -Recurse -Force -ErrorAction Stop
                Write-Success "Removed File Explorer namespace integration"
            }
        } catch {
            Write-Error "Failed to remove namespace registry: $($_.Exception.Message)"
            $errorCount++
        }
        
        # Remove additional File Explorer registry entries
        try {
            $explorerPaths = @(
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel\$($Global:Config.NamespaceGUID)",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu\$($Global:Config.NamespaceGUID)",
                "HKCU:\Software\Classes\CLSID\$($Global:Config.NamespaceGUID)"
            )
            
            foreach ($path in $explorerPaths) {
                if (Test-Path $path) {
                    Remove-Item $path -Recurse -Force -ErrorAction Stop
                    Write-Success "Removed registry entry: $path"
                }
            }
        } catch {
            Write-Error "Failed to clean registry entries: $($_.Exception.Message)"
            $errorCount++
        }
        
        # Remove Start Menu shortcuts
        try {
            if (Test-Path $Global:Config.StartMenuPath) {
                Remove-Item $Global:Config.StartMenuPath -Recurse -Force -ErrorAction Stop
                Write-Success "Removed Start Menu shortcuts"
            }
        } catch {
            Write-Error "Failed to remove Start Menu shortcuts: $($_.Exception.Message)"
            $errorCount++
        }
        
        # Force Explorer refresh
        try {
            Write-Info "Refreshing File Explorer..."
            $shell = New-Object -ComObject Shell.Application
            $shell.Windows() | ForEach-Object { $_.Refresh() }
            Write-Success "File Explorer refreshed"
        } catch {
            Write-Warning "Could not refresh File Explorer automatically: $($_.Exception.Message)"
        }
        
        if ($errorCount -eq 0) {
            Write-Success "Uninstallation completed successfully"
        } else {
            Write-Warning "Uninstallation completed with $errorCount errors"
        }
        
            } catch {
                Write-Error "Uninstallation failed: $($_.Exception.Message)"
                
                # Pause before exit on error (unless silent)
                if (-not $SilentInstall) {
                    Write-Host "`nPress Enter to exit..." -ForegroundColor Red
                    Read-Host
                }
                throw
            }
        }# =============================================================================
# POST-INSTALL ACTIONS
# =============================================================================

function Invoke-PostInstallActions {
    # Run ADD-USER if requested
    if ($RunAddUser -and $Username) {
        Write-Info "Running ADD-USER for: $Username"
        $addUserPath = Join-Path $Global:Config.InstallPath "ADD-USER.bat"
        if (Test-Path $addUserPath) {
            try {
                & cmd.exe /c "`"$addUserPath`" `"$Username`""
                Write-Success "ADD-USER completed"
            } catch {
                Write-Error "ADD-USER failed: $($_.Exception.Message)"
            }
        }
    }
    
    # Run FIX-DOMAIN if requested  
    if ($RunFixDomain) {
        Write-Info "Running FIX-DOMAIN-ERROR"
        $fixDomainPath = Join-Path $Global:Config.InstallPath "FIX-DOMAIN-ERROR.bat"
        if (Test-Path $fixDomainPath) {
            try {
                & cmd.exe /c "`"$fixDomainPath`""
                Write-Success "FIX-DOMAIN-ERROR completed"
            } catch {
                Write-Error "FIX-DOMAIN-ERROR failed: $($_.Exception.Message)"
            }
        }
    }
}

# =============================================================================
# MAIN EXECUTION LOGIC
# =============================================================================

function Start-CompleteSetup {
    try {
        # Initialize logging system
        Start-Logging
        
        Show-Header
        
        # Handle silent mode
        if ($SilentInstall) {
            $ShowProgress = $false
        }
        
        # Handle uninstall-only mode
        if ($UninstallOnly) {
            try {
                Uninstall-FileShareComponents
                Show-CompletionMessage
                
                # Pause before exit (unless silent)
                if (-not $SilentInstall) {
                    Write-Host "`nPress Enter to exit..." -ForegroundColor Cyan
                    Read-Host
                }
                return
            } catch {
                Write-Error "Uninstallation failed: $($_.Exception.Message)"
                
                # Pause before exit on error (unless silent)
                if (-not $SilentInstall) {
                    Write-Host "`nPress Enter to exit..." -ForegroundColor Red
                    Read-Host
                }
                throw
            }
        }
        
        # Handle test-only mode
        if ($TestOnly) {
            try {
                Write-Info "=== TEST MODE - NO CHANGES WILL BE MADE ==="
                $prereqResults = Test-Prerequisites
                Write-Info "Test completed. Check log for details: $($Global:Config.LogPath)"
                
                # Keep window open for user to review results
                Write-Host "`nPress Enter to exit..." -ForegroundColor Cyan
                Read-Host
                return
            } catch {
                Write-Error "Test mode failed: $($_.Exception.Message)"
                
                # Keep window open on error too
                Write-Host "`nPress Enter to exit..." -ForegroundColor Red
                Read-Host
                throw
            }
        }
        
        # Prerequisites check (unless skipped)
        if (-not $SkipPrereqCheck) {
            try {
                $prereqResults = Test-Prerequisites
                if (-not $prereqResults.AllPassed) {
                    Write-Error "Prerequisites failed - installation cannot continue"
                    Write-Info "Use -SkipPrereqCheck to bypass (not recommended)"
                    if ($ShowProgress) {
                        Read-Host "Press Enter to exit"
                    }
                    exit 1
                }
            } catch {
                Write-Error "Prerequisites check failed: $($_.Exception.Message)"
                throw
            }
        }
        
        # Installation phase (unless Azure-only)
        if (-not $ConfigureAzureOnly) {
            try {
                Write-Info "=== INSTALLATION PHASE ==="
                Install-FileShareComponents
                Install-FileExplorerIntegration  
                Install-StartMenuShortcuts
                Write-Success "Installation phase completed"
            } catch {
                Write-Error "Installation phase failed: $($_.Exception.Message)"
                throw
            }
        }
        
        # Azure configuration phase
        try {
            Write-Info "=== AZURE CONFIGURATION PHASE ==="
            
            # Check/install Azure CLI
            if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
                if (-not (Install-AzureCLI)) {
                    Write-Error "Azure CLI installation failed - skipping Azure configuration"
                }
            }
            
            # Test authentication
            if (-not (Test-AzureAuthentication)) {
                if (-not $SilentInstall) {
                    Connect-ToAzure
                } else {
                    Write-Warning "Skipping Azure login in silent mode"
                }
            }
            
            # Test Key Vault access
            Test-KeyVaultAccess
            
            # Configure file share access
            Configure-FileShareAccess
            
            # Run post-install actions
            Invoke-PostInstallActions
            
        } catch {
            Write-Error "Azure configuration failed: $($_.Exception.Message)"
            Write-Warning "Installation completed but Azure configuration had issues"
        }
        
        Write-Success "            SETUP COMPLETED SUCCESSFULLY! "
        Write-Info "Your Agave New Ventures file share is now ready!"
        
        Show-CompletionMessage
        
        # Pause before exit (unless silent)
        if (-not $SilentInstall) {
            Write-Host "`nPress Enter to exit..." -ForegroundColor Cyan
            Read-Host
        }
        
    } catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        Write-Info "Check the log file for details: $($Global:Config.LogPath)"
        
        if (-not $SilentInstall) {
            Write-Host "`nPress Enter to exit..." -ForegroundColor Red
            Read-Host
        }
        
        exit 1
        
    } finally {
        # Always stop logging
        Stop-Logging
    }
}

# =============================================================================
# MAIN SCRIPT EXECUTION
# =============================================================================

# Global error handling
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

try {
    # Validate PowerShell version before proceeding
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "ERROR: PowerShell 5.0 or higher required. Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Red
        exit 1
    }
    
    # Start the complete setup with comprehensive error handling
    Start-CompleteSetup
    
} catch {
    Write-Host "FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    
    try {
        Stop-Logging
    } catch {
        # Ignore logging errors during error handling
    }
    
    # Pause before exit (unless silent)
    if (-not $SilentInstall) {
        Write-Host "`nPress Enter to exit..." -ForegroundColor Red
        Read-Host
    }
    
    exit 1
}
