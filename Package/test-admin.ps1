Write-Host "Testing Admin Functions" -ForegroundColor Yellow

Write-Host "Loading common module..." -ForegroundColor Cyan
. "$PSScriptRoot\afs-common.ps1"

Write-Host "Testing logging..." -ForegroundColor Cyan
Write-AgaveLog "Test message" INFO

Write-Host "Testing admin check..." -ForegroundColor Cyan
$isAdmin = Test-AgaveAdmin
Write-Host "Admin: $isAdmin" -ForegroundColor White

Write-Host "Testing config..." -ForegroundColor Cyan
Assert-AgaveConfig

Write-Host "Testing UNC..." -ForegroundColor Cyan
$unc = Get-AgaveUNC
Write-Host "UNC: $unc" -ForegroundColor White

Write-Host "Testing scopes..." -ForegroundColor Cyan
$scopes = Get-AgaveScope
Write-Host "Storage: $($scopes.Storage)" -ForegroundColor White

Write-Host "Testing share access..." -ForegroundColor Cyan
$result = Test-AgaveShareAccess
Write-Host "Share access: $result" -ForegroundColor White

Write-Host "All tests complete!" -ForegroundColor Green