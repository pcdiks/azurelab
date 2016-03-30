#*******************************************************************************
#* File:           InstallDC.ps1
#* Purpose:        Create Domain Controller 
#* Usage:          COMMAND_LINE_USAGE_GOES_HERE
#* Version:        2.1.0 (14-04-2011)
#* Technology:     POWERSHELL,WMI,ADSI,ETC.
#* Requirements:   Windows 2008 R2 Server
#*                 Powershell 1.0
#* History:	   	   0.0 27-02-2008;Paul-Christiaan Diks;Initial Version
#*				   1.0.0;29-03-2016;Paul-Christiaan Diks;Initial Version
#*		   		   1.x;dd-mm-2008;AUTHOR;DESCRIPTION_OF_CHANGES_GOES_HERE
#* ToDo			   
#* Copyright(C)2008 StartReady.com
#*******************************************************************************

Param(
  [string]$DCPassword,
  [string]$NetBiosName,
  [string]$DomainFqdn
)

# ---------------------------------------------------------------------------------------------------
function Write-Logfile
# Appends specified text to specified logfile, existing file is not overwritten
# Change code to use a scriptblock, so it can be piped into
# ---------------------------------------------------------------------------------------------------
{
param($OutputObject, [string]$OutputFile)
	
	
	if ($OutputFile -ne '')
	{
		$Date = '***' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + '***'
		if ($OutputObject -is [Array])
		{
			for ($i=0;$i -le ($OutputObject.Count - 1);$i++)
			{
				Out-File -InputObject ($Date + "`t" + $OutputObject[$i]) -FilePath $OutputFile -Append -NoClobber
				Out-Host -InputObject ($OutputObject[$i])
			}
		}
		else
		{
			Out-File -InputObject ($Date + "`t" + $OutputObject) -FilePath $OutputFile -Append -NoClobber
			Out-Host -InputObject ($OutputObject)
		}
	}
}


cls

#Oude errors verwijderen
$Error.Clear()

############################################################
# Variables
############################################################
Set-Variable -Name ScriptDir -Value C:\StartReady\Scripts\DC01 -Option constant
Set-Variable -Name SoftwareDir -Value C:\StartReady\Software\DC01 -Option constant
Set-Variable -Name LogDir -Value C:\StartReady\Logs\DC01 -Option constant
Set-Variable -Name CertDir -Value C:\StartReady\Certs -Option constant
Set-Variable -name Separator -Value **************************************** -Option constant
Set-Variable -name LogFile -Value ($LogDir + "\" + $env:computername.ToLower() + ".log") -Option constant


############################################################
#LogDirectory aanmaken
############################################################
If (!(Test-Path $LogDir)) { New-Item $LogDir -Type Directory | Out-Null }

Write-Logfile $Separator $LogFile
Write-LogFile ("Deployment of " + $env:computername.ToLower() + " started.") $LogFile
Write-Logfile $Separator $LogFile

############################################################
#Read Variables from file and set some
############################################################
Write-Logfile $Separator $LogFile
Write-Logfile "Start reading variables from config file" $LogFile
$NetBios=$NetBiosName
$ADDomain=$DomainFqdn
$Password=$DCPassword
if ($Password -eq "") {$Password="Welkom01"}
if ($NetBios -eq "") {$NetBios="test"}
if ($ADDomain -eq "") {$ADDomain="test.intra"}

############################################################
#Install dependencies
############################################################
Write-Logfile "Installing dependencies" $LogFile

Write-Logfile "Installing RSAT-AD-Tools..." $LogFile
Add-WindowsFeature -Name RSAT-AD-Tools, Rsat-AD-PowerShell -LogPath $LogDir\RSAT-AD-Tools.log
Write-Logfile "Installing AD-Domain-Services..." $LogFile
Add-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -LogPath $LogDir\AD-Domain-Services.log
Write-Logfile "Installing DNS..." $LogFile
Add-WindowsFeature -Name DNS -IncludeAllSubFeature -IncludeManagementTools -LogPath $LogDir\DNS.log
Write-Logfile "Installing DPMC..." $LogFile
Add-WindowsFeature -Name GPMC -IncludeAllSubFeature -IncludeManagementTools -LogPath $LogDir\GPMC.log
#Add-WindowsFeature -Name NET-Framework-Core -Source R:\Sources\SxS -LogPath $LogDir\Net-Telnet.log

############################################################
#Install AD Forest
############################################################
Write-Logfile "Install New Active Directory Forest" $LogFile
$Percentage=[math]::Floor($Percentage+$Stap)
$Progress.SimpleStatusUpdateMessage2($ReportServer,"Installing Active Directory Forest","$Percentage", 5)

Import-Module ADDSDeployment
$SafePassword=ConvertTo-SecureString -String $Password -AsPlainText -Force
Install-ADDSForest -CreateDnsDelegation:$False `
-DatabasePath "C:\Windows\NTDS" `
-SysvolPath "C:\Windows\SYSVOL" `
-DomainMode "Win2012" `
-DomainName $ADDomain `
-DomainNetbiosName $NetBios `
-ForestMode "Win2012" `
-InstallDns:$true `
-NoRebootOnCompletion:$True `
-SafeModeAdministratorPassword $SafePassword `
-Force:$true `
-LogPath $LogDir\Install-ADDSForest.txt

if ($? -eq $FALSE)
{
	Write-Logfile "Error installing New Active Directory Forest, Deployment cannot continu!" $LOG_FILE
	#Resolve-Error -LogFile $LogFile -SeparatorString $Separator -IsCritical $True
    exit 1
}
else
{
    Restart-Computer
    exit 0
}

############################################################
#Done!
############################################################
