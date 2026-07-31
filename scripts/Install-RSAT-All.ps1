#requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$rsat = Get-WindowsCapability -Online -Name 'Rsat*' |
    Where-Object State -ne 'Installed'

foreach ($item in $rsat) {
    Write-Host "Installing $($item.Name)..."
    try {
        Add-WindowsCapability -Online -Name $item.Name -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed: $($item.Name) — $($_.Exception.Message)"
    }
}

Get-WindowsCapability -Online -Name 'Rsat*' |
    Select-Object Name, State |
    Sort-Object Name
