# PowerShell script to execute the verification test cases
param (
    [string]$EnvironmentTag = "lab-devops"
)

Write-Host "==============================================" -ForegroundColor Green
Write-Host "Running Infrastructure Verification Tests..." -ForegroundColor Green
Write-Host "Environment Tag: $EnvironmentTag" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green

# Check if Python is installed
try {
    $null = python --version
} catch {
    Write-Error "Python is not installed or not in PATH. Please install Python 3.x to run tests."
    exit 1
}

# Create virtual environment if it doesn't exist
if (-not (Test-Path "venv")) {
    Write-Host "Creating Python virtual environment..." -ForegroundColor Yellow
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create virtual environment."
        exit 1
    }
}

# Activate virtual environment and install requirements
Write-Host "Activating virtual environment & installing dependencies..." -ForegroundColor Yellow
& .\venv\Scripts\Activate.ps1

python -m pip install --upgrade pip
python -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to install dependencies from requirements.txt."
    exit 1
}

# Run pytest
Write-Host "Running pytest verification..." -ForegroundColor Yellow
$env:ENVIRONMENT_TAG = $EnvironmentTag
python -m pytest -v test_infrastructure.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[FAIL] Some infrastructure verification test cases failed!" -ForegroundColor Red
} else {
    Write-Host "`n[SUCCESS] All infrastructure verification test cases passed successfully!" -ForegroundColor Green
}

Write-Host "==============================================" -ForegroundColor Green
