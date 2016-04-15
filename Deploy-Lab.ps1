###########################################################################################
#
# File:		Deploy-Lab.ps1
#
# Purpose: 	Build an Azure Lab 
# Version: 	1.0
# Date:		14-04-2016
#
# Author:	Paul-Christiaan Diks
# 			StartReady
#
###########################################################################################

#Azure Modules available?
$AzureModule = Get-Module -Name Azure
$AzureRMModules = Get-Module -Name AzureRM*

if ($AzureModule -eq $null -OR $AzureRMModules -eq $null){
	Write-Host "Azure Modules not found!"
	Read-Host "Press Enter to start your favorite browser with instructions"
	start "https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/"
	exit
}

#Connect to your Azure account
Login-AzureRmAccount

#Are there multiple subscriptions?
Write-Host "Getting available subscriptions" -ForegroundColor Green
$Subscriptions=Get-AzureRmSubscription

if ($Subscriptions.Count -gt 1){
	$Teller=1
	Write-Host "Multiple subscriptions found. Select the one to use:" -ForegroundColor Yellow
	ForEach ($Subscription in $Subscriptions){
		Write-Host $Teller":" $Subscription.SubscriptionName $Subscription.SubscriptionId
		$Teller++
	}
	$SelectedSubscription = Read-Host "Select the number to use"
	$SelectedSubscription = $SelectedSubscription - 1
	Select-AzureRMSubscription -SubscriptionId $SelectedSubscription
}

#Retrieve available Resource Groups, Automation Accounts and Locations
#$ResourceGroups = Get-AzureRmResourceGroup
#$AutomationAccounts = Get-AzureRmAutomationAccount
#$Resources = Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute
#$Locations = $resources.ResourceTypes.Where{($_.ResourceTypeName -eq 'virtualMachines')}.Locations

#####################################
# Change the following to your needs
#####################################
$ResourceGroupName = "DevTestLab"
$AutomationAccountName = "DevTestAutomationAccount"
$Location = "West Europe"

#Does the Resource Group already exist
Try{
	Get-AzureRmResourceGroup -$ResourceGroupName
}
Catch{
	Write-Host "Resource Group does not exist" -ForegroundColor Yellow
	$Answer = Read-Host "Do you want to create it (y/n)"
	if ($Answer.tolower() -eq "n"){
		exit
	}
	else {
		Write-Host "Creating Resource Group..." -ForegroundColor Yellow
		#$New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
	}
}

Try{
	Get-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName
}
Catch{
	Write-Host "Automation Account does not exist" -ForegroundColor Yellow
	$Answer = Read-Host "Do you want to create it (y/n)"
	if ($Answer.tolower() -eq "n"){
		exit
	}
	else {
		Write-Host "Creating Automation Account..." -ForegroundColor Yellow
		#New-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -Location $Location
	}	
}

$RegistrationInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName

#Set the parameter values for the template
$Params = @{
    accountName = $AutomationAccountName
    regionId = $Location
    registrationKey = $RegistrationInfo.PrimaryKey
    registrationUrl = $RegistrationInfo.Endpoint
    dscCompilationJobId = [System.Guid]::NewGuid().toString()
    runbookJobId = [System.Guid]::NewGuid().toString()
    jobScheduleId = [System.Guid]::NewGuid().toString()
    timestamp = (Get-Date).toString()
}

$TemplateURI = 'https://raw.githubusercontent.com/azureautomation/automation-packs/master/102-sample-automation-setup/azuredeploy.json'

New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateParameterObject $Params -TemplateUri $TemplateURI
