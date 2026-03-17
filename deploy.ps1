param(
  [string]$ResourceGroupName = 'todo-rg',
  [string]$Location = 'eastus',
  [string]$WebAppName = 'todo-app-service'
)

# Ensure Azure CLI is available
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  Write-Error 'Azure CLI (az) is not installed or not found in PATH.'
  exit 1
}

Write-Host "Creating resource group '$ResourceGroupName' in '$Location'..."
az group create --name $ResourceGroupName --location $Location | Out-Null

Write-Host 'Deploying App Service via Bicep...'
az deployment group create --resource-group $ResourceGroupName --template-file azuredeploy.bicep --parameters webAppName=$WebAppName --output json | ConvertFrom-Json | Out-Null

$webAppUrl = az webapp show --resource-group $ResourceGroupName --name $WebAppName --query defaultHostName -o tsv
Write-Host "Deployment complete. App URL: https://$webAppUrl"
