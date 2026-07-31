#requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$capability = 'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0'
Write-Host "Installing $capability..."
Add-WindowsCapability -Online -Name $capability
Write-Host 'ADUC and Active Directory PowerShell module installed.'
