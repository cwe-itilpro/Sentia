<#
 Deployment Template
 Last used: 08-20-2008
 cwe
#>

param(
 #[Parameter(Mandatory=$True)]
 [string]
 $subscriptionId = "cwesub01",

 #[Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName = "SentiaGroup",

 [string]
 $resourceGroupLocation = "westeurope",

 #[Parameter(Mandatory=$True)]
 [string]
 $deploymentName = "SentiaDep02",

 [string]
 $templateFilePath_storage_account = "azuredeploy.json",

 [string]
 $templateFilePath_azuredeploy_vnet = "azuredeploy_vnet.json"
    )
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# sign in
Write-Host "Logging in...";
Login-AzureRmAccount;

# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;

# Register RPs
$resourceProviders = @("microsoft.storage");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Start the deployment
Write-Host "Starting deployment...";

Register-AzureRmResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights'

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_storage_account;

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath_azuredeploy_vnet;

Set-AzureRmResourceGroup -Name Sentia_group -Tag @{ Company="Sentia"; Environment="Test" }

$definition = New-AzureRmPolicyDefinition -Name "AllowedResources" -Policy .\ResourceRules.json
$definition
$assignment = New-AzureRMPolicyAssignment -Name "Allowed Resources" -Scope $resourceGroup.ResourceId -PolicyDefinition $definition
$assignment
