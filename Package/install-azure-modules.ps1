# Install required Azure PowerShell modules for admin functions
Write-Host "Installing required Azure PowerShell modules..." -ForegroundColor Yellow

$modules = @('Az.Accounts', 'Az.Resources', 'Az.Profile')

foreach ($module in $modules) {
    Write-Host "Installing $module..." -ForegroundColor Cyan
    try {
        Install-Module $module -Scope CurrentUser -Force -AllowClobber
        Write-Host "✓ $module installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to install $module : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTesting cmdlets..." -ForegroundColor Yellow
$testCmdlets = @('Get-AzADUser', 'Get-AzRoleAssignment', 'New-AzRoleAssignment')

foreach ($cmdlet in $testCmdlets) {
    if (Get-Command $cmdlet -ErrorAction SilentlyContinue) {
        Write-Host "✓ $cmdlet is available" -ForegroundColor Green
    } else {
        Write-Host "✗ $cmdlet is not available" -ForegroundColor Red
    }
}

Write-Host "`nModule installation complete!" -ForegroundColor Yellow
Write-Host "Please restart PowerShell and then run the admin script." -ForegroundColor Cyan