# Azure File Share - Security Model

## Overview: Identity-Based Access Control

This solution uses **Azure Active Directory (Azure AD) identity-based authentication** with **Role-Based Access Control (RBAC)**. There are **NO service principals**, **NO embedded credentials**, and **NO shared secrets** in the script.

---

## 1. Public Information in Script (Not Sensitive)

The following information is visible in the script but **cannot be exploited** without proper Azure AD authentication:

```plaintext
Tenant ID:       043c2251-51b7-4d73-9ad0-874c2833ebcd
Key Vault Name:  agave-nv-keyvault
Storage Account: anvstore001
File Share:      data
Network Path:    \\anvstore001.file.core.windows.net\data
```

**Why this is safe:**
- ✅ These are just addresses/identifiers (like phone numbers)
- ✅ Cannot access anything without valid Azure AD user credentials
- ✅ No security risk if script is shared or leaked
- ✅ Similar to how GitHub repos can contain Azure resource names

---

## 2. Authentication Flow (User Identity)

When someone runs the script, here's what happens:

```
┌─────────────┐
│ User runs   │
│ script      │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Script calls:                           │
│ az login --tenant <TenantID>            │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Azure AD Login Prompt Appears           │
│ (Browser-based authentication)          │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ User enters THEIR credentials:          │
│ robin.cave@agave-nv.com + password      │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Azure AD validates user identity        │
│ (May require MFA if configured)         │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Azure CLI stores encrypted token        │
│ locally (~/.azure/tokens)               │
└─────────────────────────────────────────┘
```

**Key Security Features:**
- ✅ Each user authenticates with **their own Azure AD account**
- ✅ No service principal or application credentials
- ✅ Supports Multi-Factor Authentication (MFA)
- ✅ Token stored securely in Windows Credential Manager
- ✅ Token expires and requires re-authentication

---

## 3. RBAC Permissions (Admin Must Grant First)

Before a user can access the file share, an **admin must grant permissions** using:

```powershell
.\agave-nv-share.ps1 -RunAddUser -Username "robin.cave@agave-nv.com"
```

This creates **TWO Azure RBAC role assignments** for the user:

### Role 1: Storage File Data SMB Share Contributor
```yaml
Role:     Storage File Data SMB Share Contributor
Assignee: robin.cave@agave-nv.com (User's Azure AD identity)
Scope:    /subscriptions/.../storageAccounts/anvstore001
Purpose:  Read and write files on the Azure File Share
```

### Role 2: Key Vault Secrets User
```yaml
Role:     Key Vault Secrets User
Assignee: robin.cave@agave-nv.com (User's Azure AD identity)
Scope:    /subscriptions/.../vaults/agave-nv-keyvault
Purpose:  Read the storage account key from Key Vault
```

**Security Implications:**
- ✅ Permissions tied to **individual user identity**
- ✅ Can be revoked per user at any time
- ✅ Follows principle of least privilege
- ✅ Auditable (who accessed what, when)

---

## 4. Key Vault Access (Identity-Based)

The storage account key is stored in Azure Key Vault and retrieved using the user's identity:

```
┌─────────────────────────────────────────┐
│ User authenticated as:                  │
│ robin.cave@agave-nv.com                 │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Script executes:                        │
│ az keyvault secret show                 │
│   --vault-name agave-nv-keyvault        │
│   --name anvstore001-storage-key        │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Azure RBAC Check:                       │
│ Does robin.cave@agave-nv.com have       │
│ "Key Vault Secrets User" role?          │
└──────┬──────────────────────────────────┘
       │
       ├─── YES ─────┐           ┌─── NO ─────┐
       │             │           │            │
       ▼             ▼           ▼            ▼
   ┌───────┐    ┌────────┐  ┌─────────┐  ┌──────┐
   │Returns│    │Storage │  │ Access  │  │Script│
   │Secret │───▶│Account │  │ Denied  │  │Fails │
   │Value  │    │Key     │  │ 403     │  │      │
   └───────┘    └────────┘  └─────────┘  └──────┘
```

**Key Security Features:**
- ✅ Storage key never stored in script or config files
- ✅ Retrieved dynamically based on user's identity
- ✅ If permissions revoked, user immediately loses access
- ✅ Fully auditable in Azure Activity Log

---

## 5. Storage Account Access (SMB Authentication)

Once the user has the storage key, they can mount the file share:

```
┌─────────────────────────────────────────┐
│ Script mounts file share:               │
│ \\anvstore001.file.core.windows.net\data│
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Windows sends SMB authentication:       │
│ • Storage Account: anvstore001          │
│ • Storage Key: (from Key Vault)         │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Azure Storage validates key             │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Additional RBAC Check:                  │
│ Does user have Storage File Data        │
│ SMB Share Contributor role?             │
└──────┬──────────────────────────────────┘
       │
       ├─── YES ─────┐           ┌─── NO ─────┐
       │             │           │            │
       ▼             ▼           ▼            ▼
   ┌───────┐    ┌────────┐  ┌─────────┐  ┌──────┐
   │Access │    │File    │  │ Access  │  │Cannot│
   │Granted│───▶│Share   │  │ Denied  │  │Read/ │
   │       │    │Mounted │  │         │  │Write │
   └───────┘    └────────┘  └─────────┘  └──────┘
```

**Security Layers:**
1. ✅ Storage account key authentication (SMB)
2. ✅ Azure RBAC role check (Data plane permissions)
3. ✅ Both must pass for access

---

## 6. What Happens if an Unauthorized Person Gets the Script?

### Scenario: Attacker has the script

```
┌──────────────────────────────────────────────┐
│ Attacker runs: .\agave-nv-share.ps1          │
└──────┬───────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│ Script calls: az login --tenant <TenantID>   │
└──────┬───────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│ Azure AD Login Prompt:                       │
│ "Sign in to your account"                    │
└──────┬───────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│ Attacker enters random credentials           │
│ OR Tries to use their own account            │
└──────┬───────────────────────────────────────┘
       │
       ├─── No Agave-NV Account ───┐
       │                            │
       ▼                            ▼
   ┌──────────┐            ┌────────────────┐
   │ Azure AD │            │  Access Denied │
   │ Rejects  │            │  Wrong Tenant  │
   └──────────┘            └────────────────┘
       │
       │
       ├─── Has Agave-NV Account but No Permissions ───┐
       │                                                │
       ▼                                                ▼
   ┌──────────────────────┐               ┌────────────────────┐
   │ Azure AD Accepts     │               │ Key Vault Check:   │
   │ Login (Step 1)       │──────────────▶│ "Key Vault Secrets │
   └──────────────────────┘               │  User" role?       │
                                          └──────┬─────────────┘
                                                 │
                                                 ▼
                                          ┌────────────────────┐
                                          │ NO ROLE ASSIGNED   │
                                          │ Access Denied 403  │
                                          │ Script FAILS       │
                                          └────────────────────┘
```

**Bottom Line:**
- ❌ Cannot authenticate without valid Agave-NV Azure AD account
- ❌ Cannot access Key Vault without "Key Vault Secrets User" role
- ❌ Cannot access file share without "Storage File Data SMB Share Contributor" role
- ✅ **Script is safe to distribute** - it contains no secrets

---

## 7. Security Best Practices Implemented

| Security Control | Implementation | Benefit |
|-----------------|----------------|---------|
| **Authentication** | Azure AD user identity | No shared credentials |
| **Authorization** | Azure RBAC | Granular per-user permissions |
| **Secret Management** | Azure Key Vault | Storage key never exposed |
| **Audit Trail** | Azure Activity Log | Track all access attempts |
| **Least Privilege** | Two specific roles only | Minimal permissions granted |
| **Token Security** | Azure CLI credential store | Encrypted local token storage |
| **MFA Support** | Azure AD conditional access | Can enforce multi-factor auth |
| **Revocation** | RBAC role removal | Instant access revocation |

---

## 8. How to Revoke Access

Admin can revoke a user's access at any time:

```powershell
# Remove Key Vault access
az role assignment delete --assignee "robin.cave@agave-nv.com" \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/.../vaults/agave-nv-keyvault"

# Remove Storage access
az role assignment delete --assignee "robin.cave@agave-nv.com" \
  --role "Storage File Data SMB Share Contributor" \
  --scope "/subscriptions/.../storageAccounts/anvstore001"
```

**Effect:** User immediately loses access to:
- ✅ Key Vault (cannot retrieve storage key)
- ✅ File Share (cannot read/write files)

---

## 9. Comparison: This Model vs. Service Principal

| Aspect | This Model (User Identity) | Service Principal |
|--------|---------------------------|-------------------|
| Authentication | User's Azure AD account | Shared secret/certificate |
| Credentials in script | ❌ None | ⚠️ Client secret or cert |
| Audit trail | ✅ Per-user identity | ⚠️ All actions under SP name |
| Access revocation | ✅ Per-user immediate | ⚠️ Affects all users |
| MFA support | ✅ Yes | ❌ No |
| Secret rotation | ✅ Not needed | ⚠️ Must rotate periodically |
| Security risk if leaked | ✅ None (no secrets) | ⚠️ High (shared secret) |

---

## 10. Summary: Why This Is Secure

✅ **No embedded credentials** - Script contains only resource identifiers  
✅ **User-based authentication** - Each user authenticates with their own Azure AD account  
✅ **RBAC enforcement** - Permissions must be explicitly granted per user  
✅ **Key Vault protection** - Storage key retrieved via identity-based access  
✅ **Audit trail** - All access attempts logged per user  
✅ **Revocation** - Admin can instantly revoke access  
✅ **MFA compatible** - Supports Azure AD conditional access policies  
✅ **Safe to share** - Script can be distributed freely without security risk  

---

## Conclusion

An unauthorized person obtaining this script **cannot gain access** because:
1. They don't have valid Agave-NV Azure AD credentials
2. Even with credentials, they don't have RBAC role assignments
3. Even with role assignments, all access is logged and auditable

The security model follows **Microsoft's recommended best practices** for Azure File Share access using identity-based authentication and RBAC.
