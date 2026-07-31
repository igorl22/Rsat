#requires -RunAsAdministrator
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Source,

    [string[]]$Capability = @(
        'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0',
        'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0',
        'Rsat.DHCP.Tools~~~~0.0.1.0'
    )
)

$ErrorActionPreference = 'Stop'

Write-Host "Windows build: $([Environment]::OSVersion.Version.Build)"
Write-Host "FoD source: $Source"

foreach ($name in $Capability) {
    Write-Host "Installing $name..."
    Add-WindowsCapability -Online -Name $name -Source $Source -LimitAccess
}

Get-WindowsCapability -Online -Name 'Rsat*' |
    Where-Object Name -in $Capability |
    Select-Object Name, State |
    Format-Table -AutoSize
