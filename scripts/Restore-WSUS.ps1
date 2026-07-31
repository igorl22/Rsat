#requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
Set-ItemProperty -Path $path -Name UseWUServer -Type DWord -Value 1
Restart-Service wuauserv -Force
Write-Host 'WSUS usage restored.'
