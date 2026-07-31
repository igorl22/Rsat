#requires -RunAsAdministrator
param(
    [string[]]$Capability = @(
        'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0',
        'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0',
        'Rsat.DHCP.Tools~~~~0.0.1.0'
    ),
    [switch]$BypassWSUS
)

$ErrorActionPreference = 'Stop'
$path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
$oldValue = $null

try {
    if ($BypassWSUS) {
        if (Test-Path $path) {
            $oldValue = (Get-ItemProperty -Path $path -Name UseWUServer -ErrorAction SilentlyContinue).UseWUServer
        }
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Set-ItemProperty -Path $path -Name UseWUServer -Type DWord -Value 0
        Restart-Service wuauserv -Force
    }

    foreach ($name in $Capability) {
        Write-Host "Installing $name..."
        Add-WindowsCapability -Online -Name $name
    }
}
finally {
    if ($BypassWSUS -and $null -ne $oldValue) {
        Set-ItemProperty -Path $path -Name UseWUServer -Type DWord -Value $oldValue
        Restart-Service wuauserv -Force
    }
}
