#*******************************************************************************
#* File:            InstallMember.ps1
#* Purpose:         Create Member Server 
#
#* Requirements:    Windows 2012 R2 Server
#* Copyright(C)2016 StartReady.com
#*******************************************************************************

Param(
  [string]$User,
  [string]$Password,
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
Set-Variable -Name ScriptDir -Value C:\StartReady\Scripts\MS01 -Option constant
Set-Variable -Name SoftwareDir -Value C:\StartReady\Software\MS01 -Option constant
Set-Variable -Name LogDir -Value C:\StartReady\Logs\MS01 -Option constant
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
$ADDomain=$DomainFqdn
$UPassword=$Password
$ADUser=$User
if ($UPassword -eq "") {$UPassword="Welkom01"}
if ($ADUser -eq "") {$ADUser="Administrator"}
if ($ADDomain -eq "") {$ADDomain="test.intra"}

############################################################
#Install dependencies
############################################################
Write-Logfile "Installing dependencies" $LogFile

Write-Logfile "Installing RSAT-AD-Tools..." $LogFile
Add-WindowsFeature -Name RSAT-AD-Tools, Rsat-AD-PowerShell -LogPath $LogDir\RSAT-AD-Tools.log

############################################################
#Create Desktop Shortcut
############################################################
Write-Logfile "Add logoff shortcut to the all users desktop" $LogFile
$ShortCutName="C:\Users\Public\Desktop\Logoff.lnk"
$Executable="C:\Windows\System32\Logoff.exe"
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortCutName)
$Shortcut.TargetPath = $Executable
$Shortcut.Description="Logoff from Windows"
$Shortcut.IconLocation="%SystemRoot%\system32\SHELL32.dll,44"
$Shortcut.Save()

############################################################
#Join Active Directory Domain
############################################################
Write-Logfile "Joining domain $ADDomain..." $LogFile
$SafePassword=ConvertTo-SecureString -String $UPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($ADUser,$SafePassword)
Add-Computer -DomainName $ADDomain -Credential $Credential

if ($? -eq $FALSE)
{
	Write-Logfile "Error joining domain, deployment cannot continu!" $LOG_FILE
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
