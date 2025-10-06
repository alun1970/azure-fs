# Agave New Ventures File Share - Unified PowerShell Solution

## 🚀 Ultra-Simple Deployment

**Everything is now in ONE script!** No more multiple files to manage.

### Quick Start (Recommended)
1. **Right-click `AgaveFileShareComplete.ps1`** → **"Run with PowerShell"**
2. Click **"Yes"** when prompted for administrator privileges
3. That's it! ✅

### Alternative Methods

#### PowerShell Command Line
```powershell
# Open PowerShell as Administrator, then run:
.\AgaveFileShareComplete.ps1
```

#### Force Execution Policy Bypass
```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\AgaveFileShareComplete.ps1"
```

### Advanced Usage

#### Standard Installation
```powershell
.\AgaveFileShareComplete.ps1
```

#### Silent Installation  
```powershell
.\AgaveFileShareComplete.ps1 -SilentInstall
```

#### Install + Add User Permissions
```powershell
.\AgaveFileShareComplete.ps1 -RunAddUser -Username "robin.cave@agave-nv.com"
```

#### Azure Configuration Only (files already installed)
```powershell
.\AgaveFileShareComplete.ps1 -ConfigureAzureOnly
```

#### Uninstall Everything
```powershell
.\AgaveFileShareComplete.ps1 -UninstallOnly
```

#### Test Mode (no changes made)
```powershell
.\AgaveFileShareComplete.ps1 -TestOnly
```

## 📁 What This Script Does

### Installation Phase:
- Creates installation directory: `C:\Program Files\Agave New Ventures\Azure File Share`
- Installs all tools (ADD-USER.bat, FIX-DOMAIN-ERROR.bat, USER-GUIDE.md)
- Sets up File Explorer integration ("Agave New Ventures Data" in sidebar)
- Creates Start Menu shortcuts

### Azure Configuration Phase:
- Checks/installs Azure CLI if needed
- Tests Azure authentication
- Validates Key Vault access
- Configures file share connectivity
- Runs comprehensive diagnostics

### All-in-One Features:
- **Complete prerequisite checking** (Windows version, admin rights, PowerShell, internet, SMB connectivity)
- **Embedded tools** - no separate .bat files needed for deployment
- **Rich logging** - detailed logs saved to `%TEMP%\AgaveFileShare-Setup.log`
- **Error handling** - graceful failures with helpful messages
- **Flexible modes** - silent, test-only, configure-only, uninstall

## ✅ Requirements

- **Windows 10+**
- **PowerShell 5.0+**
- **Administrator rights**
- **Internet connection**

## 📊 Advantages of Unified Script

- **True single file deployment** - just copy `AgaveFileShareComplete.ps1`
- **No batch files needed** - PowerShell handles admin privileges natively
- **No dependencies** - all tools embedded in script
- **Easy customization** - edit one file for all changes
- **Better error handling** - comprehensive diagnostics
- **Smallest footprint** - 37.3KB vs previous 464KB MSI (92% reduction)
- **Simplified maintenance** - literally one script to rule them all
- **Built-in security** - `#Requires -RunAsAdministrator` directive

## 🆘 Troubleshooting

### "Execution Policy" Error
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Manual PowerShell Execution
```powershell
powershell.exe -ExecutionPolicy Bypass -File "AgaveFileShareComplete.ps1"
```

### View Detailed Logs
```powershell
Get-Content "$env:TEMP\AgaveFileShare-Setup.log"
```

## 🎯 Migration from Previous Versions

This unified script **replaces**:
- ❌ MSI installer (AgaveFileShareSetup.msi)
- ❌ Separate SETUP-Enhanced.ps1
- ❌ Individual AgaveFileShareInstaller.ps1
- ❌ Separate ADD-USER.bat and FIX-DOMAIN-ERROR.bat files

Everything is now combined into **one powerful script** that handles installation, configuration, and troubleshooting.