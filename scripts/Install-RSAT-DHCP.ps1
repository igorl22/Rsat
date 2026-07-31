#requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$capability = 'Rsat.DHCP.Tools~~~~0.0.1.0'
Write-Host "Installing $capability..."
Add-WindowsCapability -Online -Name $capability
Write-Host 'DHCP Management tools installed.'
