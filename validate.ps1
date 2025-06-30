# Terraform validation and formatting script for Windows

Write-Host "🔍 Checking Terraform formatting..." -ForegroundColor Yellow
terraform fmt -check -recursive

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform files are not properly formatted. Running terraform fmt..." -ForegroundColor Red
    terraform fmt -recursive
} else {
    Write-Host "✅ All Terraform files are properly formatted" -ForegroundColor Green
}

Write-Host ""
Write-Host "🔍 Validating Terraform configuration..." -ForegroundColor Yellow

# Validate main module
Write-Host "Validating main module..." -ForegroundColor Cyan
terraform init -backend=false
terraform validate

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Main module validation passed" -ForegroundColor Green
} else {
    Write-Host "❌ Main module validation failed" -ForegroundColor Red
    exit 1
}

# Validate examples
$exampleDirs = Get-ChildItem -Path "examples" -Directory -ErrorAction SilentlyContinue

foreach ($exampleDir in $exampleDirs) {
    Write-Host ""
    Write-Host "Validating $($exampleDir.Name)..." -ForegroundColor Cyan
    
    Push-Location $exampleDir.FullName
    terraform init -backend=false
    terraform validate
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $($exampleDir.Name) validation passed" -ForegroundColor Green
    } else {
        Write-Host "❌ $($exampleDir.Name) validation failed" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
}

Write-Host ""
Write-Host "🎉 All validations passed!" -ForegroundColor Green
