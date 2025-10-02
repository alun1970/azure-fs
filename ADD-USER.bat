@echo off
REM =============================================================================
REM ADD NEW USER TO AZURE FILE SHARE
REM =============================================================================
REM This script grants the necessary Azure permissions for a new user
REM =============================================================================

title Add New User to Azure File Share

echo.
echo =============================================================================
echo          ADD NEW USER TO AZURE FILE SHARE
echo =============================================================================
echo.

REM Check if Azure CLI is available
az --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Azure CLI is not installed or not in PATH
    echo Please install Azure CLI from: https://aka.ms/installazurecliwindows
    pause
    exit /b 1
)

REM Check if authenticated
az account show >nul 2>&1
if %errorlevel% neq 0 (
    echo You need to sign in to Azure first...
    az login
    if %errorlevel% neq 0 (
        echo ERROR: Azure login failed
        pause
        exit /b 1
    )
)

echo Current Azure account:
az account show --query "user.name" --output tsv
echo.

REM Get user email
set /p USER_EMAIL="Enter the new user's email address: "

if "%USER_EMAIL%"=="" (
    echo ERROR: No email address provided
    pause
    exit /b 1
)

echo.
echo Adding permissions for: %USER_EMAIL%
echo.

REM Add Key Vault permissions
echo Adding Key Vault access...
az role assignment create --assignee "%USER_EMAIL%" --role "Key Vault Secrets User" --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.KeyVault/vaults/agave-nv-keyvault"

if %errorlevel% neq 0 (
    echo [ERROR] Failed to add Key Vault permissions
    echo Check that the user email is correct and exists in Microsoft Entra ID
    pause
    exit /b 1
)

echo [SUCCESS] Key Vault permissions added

REM Add Storage permissions
echo Adding Storage File Share access...
az role assignment create --assignee "%USER_EMAIL%" --role "Storage File Data SMB Share Contributor" --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.Storage/storageAccounts/anvstore001"

if %errorlevel% neq 0 (
    echo [ERROR] Failed to add Storage permissions
    pause
    exit /b 1
)

echo [SUCCESS] Storage permissions added

echo.
echo =============================================================================
echo          ✅ USER PERMISSIONS ADDED SUCCESSFULLY
echo =============================================================================
echo.
echo User: %USER_EMAIL%
echo.
echo Permissions granted:
echo  ✅ Key Vault Secrets User (agave-nv-keyvault)
echo  ✅ Storage File Data SMB Share Contributor (anvstore001)
echo.
echo The user can now:
echo  1. Download and run the setup package
echo  2. Sign in with their email when prompted
echo  3. Access the Azure File Share automatically
echo.
echo NOTE: It may take a few minutes for permissions to propagate.
echo =============================================================================

echo.
echo Do you want to add another user? (Y/N)
set /p choice=
if /i "%choice%"=="Y" goto :start

pause
exit /b 0

:start
goto :start_over

:start_over
echo.
set /p USER_EMAIL="Enter another user's email address (or press Enter to exit): "
if "%USER_EMAIL%"=="" (
    echo Exiting...
    pause
    exit /b 0
)
goto :add_user

:add_user
echo.
echo Adding permissions for: %USER_EMAIL%
echo.

REM Add Key Vault permissions
echo Adding Key Vault access...
az role assignment create --assignee "%USER_EMAIL%" --role "Key Vault Secrets User" --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.KeyVault/vaults/agave-nv-keyvault" >nul 2>&1

if %errorlevel% neq 0 (
    echo [WARNING] Key Vault permissions may already exist or user not found
) else (
    echo [SUCCESS] Key Vault permissions added
)

REM Add Storage permissions
echo Adding Storage File Share access...
az role assignment create --assignee "%USER_EMAIL%" --role "Storage File Data SMB Share Contributor" --scope "/subscriptions/a54b676b-eb6a-4510-8e7e-50c6648638f4/resourceGroups/rg-agave-nv/providers/Microsoft.Storage/storageAccounts/anvstore001" >nul 2>&1

if %errorlevel% neq 0 (
    echo [WARNING] Storage permissions may already exist or user not found
) else (
    echo [SUCCESS] Storage permissions added
)

echo [SUCCESS] Permissions configured for %USER_EMAIL%
goto :start_over