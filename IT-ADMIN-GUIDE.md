# 🔧 IT Administrator Setup Guide

## 📋 Prerequisites for End Users

Before deploying to a new user, ensure they have:

### ✅ **Microsoft Entra ID Access Requirements**
- Valid Microsoft Entra ID account in your tenant (`043c2251-51b7-4d73-9ad0-874c2833ebcd`)
- Member of the appropriate security group for file share access
- **Key Vault permissions**: `Key Vault Secrets User` role on `agave-nv-keyvault`

### ✅ **System Requirements** 
- Windows 10/11 (any edition)
- Internet connection
- Local administrator rights (for initial setup only)
- Port 445 not blocked by firewall/ISP

### ✅ **Software Requirements**
- PowerShell 5.1+ (included in Windows 10/11)
- Azure CLI (will be installed automatically if missing)

---

## 🚀 MSI Deployment Process

### **Step 1: Review Prerequisites**
```powershell
.\MSI-Prerequisites.ps1
```
This shows you exactly what's needed before deployment.

### **Step 2: Create the MSI Package**
```powershell
.\Create-MSI.ps1
```
Creates `AgaveFileShareSetup.msi` with all components embedded.

### **Step 3: Deploy via Your Preferred Method**

#### **Method 1: Microsoft Intune (Recommended)**
1. Upload `AgaveFileShareSetup.msi` as Win32 app
2. **Install command:** `msiexec /i AgaveFileShareSetup.msi /quiet`
3. **Detection rule:** Registry key exists at `HKLM\SOFTWARE\Agave New Ventures\FileShare`
4. **Requirements:** Windows 10 1809 or later
5. **Assign to user groups** who have Azure permissions
6. **Users automatically get Start Menu shortcuts** after installation

#### **Method 2: Group Policy Software Installation**
1. Place MSI in network share (e.g., `\\server\software\AgaveFileShareSetup.msi`)
2. Create Group Policy Object
3. Navigate to: Computer Configuration → Policies → Software Settings → Software Installation
4. Right-click → New → Package
5. Select the MSI file
6. Choose "Assigned" for automatic installation
7. Link GPO to appropriate OUs

#### **Method 3: System Center Configuration Manager (SCCM)**
1. Import MSI into SCCM console
2. Create Application:
   - **Install command:** `msiexec /i AgaveFileShareSetup.msi /quiet`
   - **Uninstall command:** `msiexec /x AgaveFileShareSetup.msi /quiet`
   - **Detection method:** Registry key `HKLM\SOFTWARE\Agave New Ventures\FileShare`
3. Deploy to appropriate collections
4. Set deployment as "Required" for automatic installation

#### **Method 4: Manual Distribution**
1. Send MSI file to users via email/network share
2. Users double-click MSI file
3. Standard Windows installer wizard guides them through
4. After installation, users run "Setup File Share Access" from Start Menu

---

## 🔑 Azure Permissions Setup

### **Grant User Access to Key Vault:**
```bash
# Replace USER_EMAIL with actual user email
az role assignment create \
  --assignee "USER_EMAIL@agave-nv.com" \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.KeyVault/vaults/agave-nv-keyvault"
```

### **Grant User Access to Storage Account:**
```bash
# For file share access
az role assignment create \
  --assignee "USER_EMAIL@agave-nv.com" \
  --role "Storage File Data SMB Share Contributor" \
  --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.Storage/storageAccounts/anvstore001"
```

### **Bulk User Setup Script:**
```bash
#!/bin/bash
# Add multiple users at once
USERS=("user1@agave-nv.com" "user2@agave-nv.com" "user3@agave-nv.com")

for user in "${USERS[@]}"; do
    echo "Adding permissions for $user"
    
    # Key Vault access
    az role assignment create \
      --assignee "$user" \
      --role "Key Vault Secrets User" \
      --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.KeyVault/vaults/agave-nv-keyvault"
    
    # Storage access
    az role assignment create \
      --assignee "$user" \
      --role "Storage File Data SMB Share Contributor" \
      --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.Storage/storageAccounts/anvstore001"
done
```

---

## 🛠️ Troubleshooting Common Issues

### **Issue: "Access Denied" during setup**
**Cause:** User doesn't have local admin rights or MSI wasn't installed properly  
**Solution:** Ensure MSI was installed with admin rights, or user runs "Setup File Share Access" as administrator

### **Issue: "Azure login failed"**
**Cause:** User not in Microsoft Entra ID or MFA issues  
**Solution:** Verify user account in Microsoft Entra ID, check MFA policies

### **Issue: "Key Vault access denied"**
**Cause:** Missing Key Vault permissions  
**Solution:** Add "Key Vault Secrets User" role for the user

### **Issue: "Port 445 blocked"**
**Cause:** ISP or firewall blocking SMB  
**Solution:** Use Azure Files via REST API or VPN

### **Issue: Sidebar doesn't appear**
**Cause:** Windows Explorer cache  
**Solution:** Restart Explorer process or reboot

---

## 📊 Monitoring and Maintenance

### **Check User Access:**
```bash
# List all users with Key Vault access
az role assignment list \
  --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.KeyVault/vaults/agave-nv-keyvault" \
  --query "[?roleDefinitionName=='Key Vault Secrets User'].principalName"
```

### **Monitor File Share Usage:**
- Use Azure Monitor metrics for storage account
- Check access logs in Microsoft Entra ID sign-in logs
- Monitor Key Vault access logs

### **Key Rotation:**
- Storage account keys rotate automatically with Key Vault integration
- Users don't need to reconfigure when keys rotate
- Monitor key rotation events in Activity Log

---

## 📦 MSI Package Contents

The MSI automatically includes all necessary files:
- `SETUP-Enhanced.ps1` (complete setup with validation, testing, and cleanup)
- `REMOVE.bat` (cleanup tool that uses SETUP-Enhanced.ps1)
- `USER-GUIDE.md` (user instructions)
- `ADD-USER.bat` (permission management tool)

**Single file deployment:** `AgaveFileShareSetup.msi` - contains everything needed.