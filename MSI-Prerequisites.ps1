# =============================================================================
# MSI DEPLOYMENT PREREQUISITES CHECKLIST
# =============================================================================
# Run this before deploying the MSI to understand what's needed
# =============================================================================

Write-Host @"

=================================================================== 
          MSI DEPLOYMENT PREREQUISITES CHECKLIST
===================================================================

✅ WHAT THE MSI HANDLES AUTOMATICALLY:
• Installs all required files
• Creates Start Menu shortcuts
• Sets up registry entries for Explorer integration
• Provides guided setup with error messages
• Automatically installs Azure CLI if missing
• Comprehensive prerequisite checking
• Graceful failure handling with clear error messages

❌ WHAT MUST BE DONE BEFORE MSI DEPLOYMENT:

1. AZURE PERMISSIONS (Critical - IT Admin Task)
   For each user who will use the file share:
   
   Grant Key Vault Access:
   az role assignment create \
     --assignee "user@agave-nv.com" \
     --role "Key Vault Secrets User" \
     --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.KeyVault/vaults/agave-nv-keyvault"

   Grant Storage Access:
   az role assignment create \
     --assignee "user@agave-nv.com" \
     --role "Storage File Data SMB Share Contributor" \
     --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.Storage/storageAccounts/anvstore001"

   💡 TIP: Use ADD-USER.bat for easier permission management

2. USER REQUIREMENTS (User's Machine)
   • Valid Microsoft Entra ID account in tenant: 043c2251-51b7-4d73-9ad0-874c2833ebcd
   • Windows 10 or later (MSI will check this)
   • Internet connection (MSI will check this)
   • Port 445 not blocked (MSI will check and report if blocked)
   • Local administrator rights for installation

3. NETWORK REQUIREMENTS (Usually OK, but MSI will verify)
   • Outbound HTTPS (443) to:
     - login.microsoftonline.com
     - management.azure.com  
     - agave-nv-keyvault.vault.azure.net
   • Outbound SMB (445) to:
     - anvstore001.file.core.windows.net

===================================================================
                        DEPLOYMENT METHODS
===================================================================

🖥️  MANUAL DEPLOYMENT:
• Send MSI file to user
• User double-clicks and follows wizard
• User runs setup from Start Menu after installation

🏢 INTUNE DEPLOYMENT:
• Upload MSI as Win32 app
• Set install command: msiexec /i AgaveFileShareSetup.msi /quiet
• Set detection rule: Registry key exists at:
  HKLM\SOFTWARE\Agave New Ventures\FileShare
• Deploy to user groups who have Azure permissions

📋 GROUP POLICY DEPLOYMENT:
• Place MSI in network share
• Create Group Policy for software installation
• Assign to computer or user groups
• Set to install on startup/login

🔄 SCCM DEPLOYMENT:
• Import MSI into SCCM
• Create application with install command: msiexec /i AgaveFileShareSetup.msi /quiet
• Deploy to collections with appropriate users

===================================================================
                          ERROR SCENARIOS
===================================================================

If setup fails, the MSI provides clear error messages for:

❌ "Azure permissions insufficient"
   → User needs Key Vault and Storage permissions (run ADD-USER.bat)

❌ "Port 445 blocked - SMB/Azure Files access not available"  
   → Network/ISP blocks SMB. Contact network administrator

❌ "Cannot connect to login.microsoftonline.com:443"
   → Firewall blocking HTTPS. Check corporate firewall

❌ "User not in Microsoft Entra ID or MFA issues"
   → User account not in correct tenant or MFA problems

❌ "Windows version: 6.x (minimum required: 10.0)"
   → User needs Windows 10 or later

All errors are logged to: %TEMP%\AgaveFileShare-Setup.log

===================================================================
                        SUPPORT PROCESS  
===================================================================

When users report issues:
1. Ask them to check Start Menu for "Test File Share Connection"
2. Request the log file: %TEMP%\AgaveFileShare-Setup.log
3. Most common issue: Missing Azure permissions (run ADD-USER.bat)
4. Second most common: Port 445 blocked by ISP

===================================================================

Ready to create the MSI? Run: Create-MSI.ps1

"@ -ForegroundColor Cyan

Read-Host "`nPress Enter to continue..."