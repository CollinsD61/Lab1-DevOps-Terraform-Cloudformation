# PowerShell deployment script for CloudFormation Nested Stacks
param (
    [string]$StackName = "lab-devops-cf-stack",
    [string]$BucketName,
    [string]$KeyName,
    [string]$AdminIpCidr = "0.0.0.0/0",
    [string]$Region = "us-east-1"
)

if (-not $BucketName) {
    Write-Error "Please specify an S3 bucket name using -BucketName <bucket_name> to upload templates."
    exit 1
}
if (-not $KeyName) {
    Write-Error "Please specify your existing AWS Key Pair name using -KeyName <key_name>."
    exit 1
}

Write-Host "==============================================" -ForegroundColor Green
Write-Host "Deploying AWS Stack: $StackName" -ForegroundColor Green
Write-Host "Using S3 Bucket: $BucketName" -ForegroundColor Green
Write-Host "AWS Region: $Region" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green

# Verify AWS CLI is installed
try {
    $null = aws --version
} catch {
    Write-Error "AWS CLI is not installed or not in PATH. Please install AWS CLI first."
    exit 1
}

# Create S3 Bucket if it doesn't exist
$bucketExists = aws s3api head-bucket --bucket $BucketName --region $Region 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Bucket '$BucketName' does not exist. Creating bucket..." -ForegroundColor Yellow
    if ($Region -eq "us-east-1") {
        aws s3api create-bucket --bucket $BucketName --region $Region
    } else {
        aws s3api create-bucket --bucket $BucketName --region $Region --create-bucket-configuration LocationConstraint=$Region
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create S3 bucket '$BucketName'. Please verify naming rules or permissions."
        exit 1
    }
    Write-Host "S3 bucket created successfully." -ForegroundColor Green
} else {
    Write-Host "Bucket '$BucketName' already exists. Reusing it." -ForegroundColor Cyan
}

# Upload nested templates
Write-Host "Uploading nested templates to s3://$BucketName/templates/..." -ForegroundColor Yellow
aws s3 sync templates/ "s3://$BucketName/templates/" --exclude "*" --include "*.yaml"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to upload templates to S3."
    exit 1
}
Write-Host "Templates uploaded successfully." -ForegroundColor Green

# Deploy CloudFormation Stack
Write-Host "Deploying master CloudFormation stack..." -ForegroundColor Yellow
aws cloudformation deploy `
    --template-file master.yaml `
    --stack-name $StackName `
    --region $Region `
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM `
    --parameter-overrides `
        TemplateBucket=$BucketName `
        TemplateFolder="templates/" `
        KeyName=$KeyName `
        AdminIpCidr=$AdminIpCidr

if ($LASTEXITCODE -ne 0) {
    Write-Error "CloudFormation Stack deployment failed."
    exit 1
}

Write-Host "==============================================" -ForegroundColor Green
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "You can check output values in AWS Console or run:" -ForegroundColor Green
Write-Host "aws cloudformation describe-stacks --stack-name $StackName --region $Region" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Green
