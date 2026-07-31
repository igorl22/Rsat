#requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'

if (-not (Test-Path $path)) {
    New-Item -Path $path -Force | Out-Null
}

Set-ItemProperty -Path $path -Name UseWUServer -Type DWord -Value 0
Restart-Service wuauserv -Force
Write-Host 'WSUS temporarily bypassed. Windows Update will be used for optional components.'
