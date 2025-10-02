# =============================================================================
# CREATE COMPLETE MSI INSTALLER PACKAGE
# =============================================================================
# This creates a professional Windows Installer (.msi) package that:
# - Installs Azure CLI if not present
# - Handles all authentication and setup
# - Creates Explorer integration
# - Provides proper uninstallation
# =============================================================================

Write-Host "Creating Complete MSI Installer Package..." -ForegroundColor Cyan

# Check if WiX is available
$wixPath = Get-Command "candle.exe" -ErrorAction SilentlyContinue
if (-not $wixPath) {
    Write-Host @"
ERROR: WiX Toolset is required to create MSI packages.

Please install WiX Toolset:
1. Download from: https://wixtoolset.org/
2. Install WiX Toolset v3.11 or later
3. Add to PATH environment variable
4. Run this script again

Alternative: Use the PowerShell executable option instead.
"@ -ForegroundColor Red
    exit 1
}

# Create comprehensive WiX source file
$wixSource = @"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" 
           Name="Agave New Ventures File Share Access" 
           Language="1033" 
           Version="1.0.0.0" 
           Manufacturer="Agave New Ventures" 
           UpgradeCode="12345678-1234-1234-1234-123456789012">
    
    <Package InstallerVersion="200" 
             Compressed="yes" 
             InstallScope="perMachine" 
             Description="Secure access to Agave New Ventures shared files with comprehensive prerequisite checking"
             Comments="Configures Azure File Share access with Windows Explorer integration and automatic dependency installation" />

    <MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed." />
    <MediaTemplate EmbedCab="yes" />

    <!-- Prerequisite Checks -->
    <Condition Message="This application requires Windows 10 or later.">
      <![CDATA[Installed OR (VersionNT >= 1000)]]>
    </Condition>

    <Condition Message="Administrator privileges are required to install this application.">
      <![CDATA[Installed OR Privileged]]>
    </Condition>

    <!-- UI Configuration with Custom Welcome -->
    <UI>
      <UIRef Id="WixUI_InstallDir" />
      <Property Id="WIXUI_INSTALLDIR" Value="INSTALLFOLDER" />
      
      <!-- Custom welcome text -->
      <Publish Dialog="WelcomeDlg" Control="Next" Event="NewDialog" Value="InstallDirDlg">1</Publish>
      <Publish Dialog="ExitDialog" 
               Control="Finish" 
               Event="DoAction" 
               Value="RunSetupAction">WIXUI_EXITDIALOGOPTIONALCHECKBOX = 1 and NOT Installed</Publish>
    </UI>
    
    <Property Id="WIXUI_EXITDIALOGOPTIONALCHECKBOXTEXT" Value="Run file share setup now (recommended)" />
    <Property Id="WIXUI_EXITDIALOGOPTIONALCHECKBOX" Value="1" />

    <!-- Custom Actions -->
    <CustomAction Id="RunSetupAction"
                  FileKey="SetupEnhancedPS1"
                  ExeCommand="powershell.exe -ExecutionPolicy Bypass -File &quot;[INSTALLFOLDER]SETUP-Enhanced.ps1&quot;"
                  Execute="immediate"
                  Impersonate="yes"
                  Return="asyncNoWait" />

    <!-- Custom Action for prerequisites check -->
    <CustomAction Id="CheckPrerequisites"
                  FileKey="SetupEnhancedPS1"
                  ExeCommand="powershell.exe -ExecutionPolicy Bypass -File &quot;[INSTALLFOLDER]SETUP-Enhanced.ps1&quot; -SkipPrereqCheck"
                  Execute="immediate"
                  Impersonate="no"
                  Return="check" />

    <!-- Directory Structure -->
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="CompanyFolder" Name="Agave New Ventures">
          <Directory Id="INSTALLFOLDER" Name="FileShare Setup" />
        </Directory>
      </Directory>
      <Directory Id="ProgramMenuFolder">
        <Directory Id="ApplicationProgramsFolder" Name="Agave New Ventures" />
      </Directory>
      <Directory Id="DesktopFolder" Name="Desktop" />
    </Directory>

    <!-- Components -->
    <DirectoryRef Id="INSTALLFOLDER">
      <Component Id="MainFiles" Guid="11111111-1111-1111-1111-111111111111">
        <File Id="SetupEnhancedPS1" 
              Source="SETUP-Enhanced.ps1" 
              KeyPath="yes" 
              Checksum="yes" />
        <File Id="UserGuide" 
              Source="USER-GUIDE.md" />
        <File Id="AddUser" 
              Source="ADD-USER.bat" />
      </Component>
      
      <!-- Registry entries for uninstall detection -->
      <Component Id="RegistryEntries" Guid="33333333-3333-3333-3333-333333333333">
        <RegistryKey Root="HKLM" Key="SOFTWARE\Agave New Ventures\FileShare">
          <RegistryValue Name="InstallPath" Type="string" Value="[INSTALLFOLDER]" />
          <RegistryValue Name="Version" Type="string" Value="1.0.0.0" />
          <RegistryValue Name="InstallDate" Type="string" Value="[Date]" />
        </RegistryKey>
      </Component>
    </DirectoryRef>

    <!-- Start Menu Shortcuts -->
    <DirectoryRef Id="ApplicationProgramsFolder">
      <Component Id="StartMenuShortcuts" Guid="22222222-2222-2222-2222-222222222222">
        <Shortcut Id="SetupShortcut"
                  Name="Setup File Share Access"
                  Description="Configure secure access to Agave New Ventures shared files"
                  Target="powershell.exe"
                  Arguments="-ExecutionPolicy Bypass -File &quot;[INSTALLFOLDER]SETUP-Enhanced.ps1&quot;"
                  WorkingDirectory="INSTALLFOLDER"
                  Icon="PowerShellIcon" />
        <Shortcut Id="TestShortcut"
                  Name="Test File Share Connection"
                  Description="Test connection to Agave New Ventures file share"
                  Target="powershell.exe"
                  Arguments="-ExecutionPolicy Bypass -File &quot;[INSTALLFOLDER]SETUP-Enhanced.ps1&quot; -TestOnly"
                  WorkingDirectory="INSTALLFOLDER"
                  Icon="PowerShellIcon" />
        <Shortcut Id="UserGuideShortcut"
                  Name="User Guide"
                  Description="Instructions for using the file share"
                  Target="[#UserGuide]"
                  WorkingDirectory="INSTALLFOLDER" />
        <RemoveFolder Id="CleanupStartMenu" On="uninstall" />
        <RegistryValue Root="HKCU" 
                       Key="Software\Agave New Ventures\FileShare" 
                       Name="StartMenuCreated" 
                       Type="integer" 
                       Value="1" 
                       KeyPath="yes" />
      </Component>
    </DirectoryRef>

    <!-- Desktop Shortcut (optional) -->
    <DirectoryRef Id="DesktopFolder">
      <Component Id="DesktopShortcut" Guid="44444444-4444-4444-4444-444444444444">
        <Shortcut Id="DesktopSetupShortcut"
                  Name="Agave File Share Setup"
                  Description="Setup access to Agave New Ventures shared files"
                  Target="powershell.exe"
                  Arguments="-ExecutionPolicy Bypass -File &quot;[INSTALLFOLDER]SETUP-Enhanced.ps1&quot;"
                  WorkingDirectory="INSTALLFOLDER"
                  Icon="PowerShellIcon" />
        <RegistryValue Root="HKCU" 
                       Key="Software\Agave New Ventures\FileShare" 
                       Name="DesktopShortcutCreated" 
                       Type="integer" 
                       Value="1" 
                       KeyPath="yes" />
      </Component>
    </DirectoryRef>

    <!-- Icons -->
    <Icon Id="PowerShellIcon" SourceFile="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" />

    <!-- Features -->
    <Feature Id="MainFeature" Title="File Share Access" Level="1" Description="Core file share access functionality">
      <ComponentRef Id="MainFiles" />
      <ComponentRef Id="RegistryEntries" />
    </Feature>
    
    <Feature Id="StartMenuFeature" Title="Start Menu Shortcuts" Level="1" Description="Start menu shortcuts for easy access">
      <ComponentRef Id="StartMenuShortcuts" />
    </Feature>
    
    <Feature Id="DesktopFeature" Title="Desktop Shortcut" Level="2" Description="Desktop shortcut for quick access">
      <ComponentRef Id="DesktopShortcut" />
    </Feature>

    <!-- Installation Properties -->
    <Property Id="ARPPRODUCTICON" Value="PowerShellIcon" />
    <Property Id="ARPURLINFOABOUT" Value="https://agave-nv.com" />
    <Property Id="ARPHELPLINK" Value="https://agave-nv.com/support" />
    <Property Id="ARPNOREPAIR" Value="1" />
    <Property Id="ARPNOMODIFY" Value="1" />
    <Property Id="ARPINSTALLLOCATION" Value="[INSTALLFOLDER]" />
    
    <!-- License -->
    <WixVariable Id="WixUILicenseRtf" Value="license.rtf" />
    
    <!-- Custom welcome banner -->
    <WixVariable Id="WixUIBannerBmp" Value="banner.bmp" />
    <WixVariable Id="WixUIDialogBmp" Value="dialog.bmp" />
    
  </Product>
</Wix>
"@

# Create license file
$licenseRtf = @"
{\rtf1\ansi\deff0 {\fonttbl {\f0 Times New Roman;}}
\f0\fs24
AGAVE NEW VENTURES FILE SHARE ACCESS

This software configures secure access to company shared files.

By installing this software, you agree to:
- Use company files in accordance with company policies
- Maintain confidentiality of business information
- Report any access issues to IT support

This software is provided as-is for authorized users only.

© 2025 Agave New Ventures. All rights reserved.
}
"@

# Write files
$wixSource | Out-File -FilePath "AgaveFileShare.wxs" -Encoding UTF8
$licenseRtf | Out-File -FilePath "license.rtf" -Encoding UTF8

try {
    # Compile WiX source to object file
    Write-Host "Compiling WiX source..." -ForegroundColor Yellow
    & candle.exe "AgaveFileShare.wxs" -out "AgaveFileShare.wixobj"
    
    if ($LASTEXITCODE -ne 0) {
        throw "WiX compilation failed"
    }

    # Link to create MSI
    Write-Host "Creating MSI package..." -ForegroundColor Yellow
    & light.exe "AgaveFileShare.wixobj" -ext WixUIExtension -out "AgaveFileShareSetup.msi"
    
    if ($LASTEXITCODE -ne 0) {
        throw "MSI creation failed"
    }

    if (Test-Path "AgaveFileShareSetup.msi") {
        Write-Host "`n========================================================================" -ForegroundColor Green
        Write-Host "SUCCESS: Professional MSI installer created!" -ForegroundColor Green
        Write-Host "========================================================================" -ForegroundColor Green
        Write-Host "`nFile: AgaveFileShareSetup.msi" -ForegroundColor Cyan
        Write-Host "`nFeatures:" -ForegroundColor Yellow
        Write-Host "  ✅ Professional Windows Installer package" -ForegroundColor White
        Write-Host "  ✅ Proper installation/uninstallation" -ForegroundColor White
        Write-Host "  ✅ Start Menu shortcuts" -ForegroundColor White
        Write-Host "  ✅ Add/Remove Programs integration" -ForegroundColor White
        Write-Host "  ✅ Corporate deployment ready" -ForegroundColor White
        Write-Host "`nDeployment options:" -ForegroundColor Yellow
        Write-Host "  • Double-click installation for users" -ForegroundColor White
        Write-Host "  • Group Policy software deployment" -ForegroundColor White
        Write-Host "  • SCCM/Intune deployment" -ForegroundColor White
        Write-Host "  • Silent install: msiexec /i AgaveFileShareSetup.msi /quiet" -ForegroundColor White
        Write-Host "========================================================================" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Failed to create MSI package" -ForegroundColor Red
    }

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Clean up intermediate files
    Remove-Item "AgaveFileShare.wxs" -ErrorAction SilentlyContinue
    Remove-Item "AgaveFileShare.wixobj" -ErrorAction SilentlyContinue
    Remove-Item "license.rtf" -ErrorAction SilentlyContinue
}