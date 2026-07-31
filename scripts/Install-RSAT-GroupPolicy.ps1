#requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$capability = 'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0'
Write-Host "Installing $capability..."
Add-WindowsCapability -Online -Name $capability
Write-Host 'Group Policy Management tools installed.'
