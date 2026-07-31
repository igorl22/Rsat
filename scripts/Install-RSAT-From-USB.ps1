#requires -RunAsAdministrator
[CmdletBinding()]
param(
    [ValidateSet('Menu','ADUC','GroupPolicy','DHCP','All')]
    [string]$Component = 'Menu',

    [string]$UsbRoot
)

$ErrorActionPreference = 'Stop'

function Write-Section {
    param([string]$Text)
    Write-Host "`n=== $Text ===" -ForegroundColor Cyan
}

function Get-WindowsFoDTag {
    $build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber

    switch ($build) {
        { $_ -eq 22000 } { return [pscustomobject]@{ Build = $build; Tag = '21H2'; Folder = '21H2' } }
        { $_ -in 22621,22631 } { return [pscustomobject]@{ Build = $build; Tag = '22H2/23H2'; Folder = '22H2_23H2' } }
        { $_ -ge 26100 -and $_ -lt 27000 } { return [pscustomobject]@{ Build = $build; Tag = '24H2'; Folder = '24H2' } }
        default { throw "Unsupported or unknown Windows 11 build: $build. Add the matching FoD ISO and update the build mapping." }
    }
}

function Get-CandidateUsbRoots {
    param([string]$PreferredRoot)

    if ($PreferredRoot) {
        if (-not (Test-Path -LiteralPath $PreferredRoot)) {
            throw "USB path does not exist: $PreferredRoot"
        }
        return ,(Get-Item -LiteralPath $PreferredRoot).FullName
    }

    $roots = @()
    $volumes = Get-CimInstance Win32_LogicalDisk | Where-Object {
        $_.DriveType -in 2,3 -and $_.DeviceID -ne $env:SystemDrive
    }

    foreach ($volume in $volumes) {
        $root = "$($volume.DeviceID)\"
        if (Test-Path -LiteralPath (Join-Path $root 'FoD')) {
            $roots += $root
        }
    }

    if (-not $roots) {
        throw 'No drive containing a FoD folder was found. Connect the USB flash drive or use -UsbRoot F:\.'
    }

    return $roots
}

function Find-FoDIso {
    param(
        [string[]]$Roots,
        [string]$VersionFolder
    )

    $matches = @()
    foreach ($root in $Roots) {
        $folder = Join-Path $root "FoD\$VersionFolder"
        if (Test-Path -LiteralPath $folder) {
            $matches += Get-ChildItem -LiteralPath $folder -Filter '*.iso' -File -Recurse -ErrorAction SilentlyContinue
        }
    }

    if (-not $matches) {
        $searched = ($Roots | ForEach-Object { Join-Path $_ "FoD\$VersionFolder" }) -join ', '
        throw "No ISO file was found. Searched: $searched"
    }

    if ($matches.Count -gt 1) {
        Write-Host 'Several ISO files were found:' -ForegroundColor Yellow
        for ($i = 0; $i -lt $matches.Count; $i++) {
            Write-Host "[$($i + 1)] $($matches[$i].FullName)"
        }
        $choice = Read-Host 'Choose ISO number'
        if ($choice -notmatch '^\d+$' -or [int]$choice -lt 1 -or [int]$choice -gt $matches.Count) {
            throw 'Invalid ISO selection.'
        }
        return $matches[[int]$choice - 1]
    }

    return $matches[0]
}

function Mount-FoDIso {
    param([string]$ImagePath)

    $existing = Get-DiskImage -ImagePath $ImagePath -ErrorAction SilentlyContinue
    $mountedByScript = $false

    if (-not $existing -or -not $existing.Attached) {
        Write-Host "Mounting ISO: $ImagePath"
        Mount-DiskImage -ImagePath $ImagePath | Out-Null
        $mountedByScript = $true
    }

    $driveLetter = $null
    for ($attempt = 0; $attempt -lt 15 -and -not $driveLetter; $attempt++) {
        Start-Sleep -Milliseconds 500
        $driveLetter = Get-DiskImage -ImagePath $ImagePath |
            Get-Volume |
            Where-Object DriveLetter |
            Select-Object -First 1 -ExpandProperty DriveLetter
    }

    if (-not $driveLetter) {
        throw 'The ISO was mounted, but its drive letter could not be determined.'
    }

    [pscustomobject]@{
        SourceRoot = "$driveLetter`:"
        MountedByScript = $mountedByScript
    }
}

function Resolve-FoDSource {
    param([string]$MountedRoot)

    $possible = @(
        (Join-Path $MountedRoot 'LanguagesAndOptionalFeatures'),
        $MountedRoot
    )

    foreach ($path in $possible) {
        if (Test-Path -LiteralPath $path) {
            $cab = Get-ChildItem -LiteralPath $path -Filter '*.cab' -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($cab) { return $path }
        }
    }

    throw "No CAB packages were found in $MountedRoot or LanguagesAndOptionalFeatures. This may be the wrong ISO."
}

function Select-Component {
    param([string]$Requested)

    if ($Requested -ne 'Menu') { return $Requested }

    Write-Host ''
    Write-Host '[1] ADUC + Active Directory PowerShell module'
    Write-Host '[2] Group Policy Management'
    Write-Host '[3] DHCP Management Tools'
    Write-Host '[4] All missing RSAT components'
    Write-Host '[5] ADUC + Group Policy + DHCP'

    switch (Read-Host 'Choose an option') {
        '1' { 'ADUC' }
        '2' { 'GroupPolicy' }
        '3' { 'DHCP' }
        '4' { 'All' }
        '5' { 'Core' }
        default { throw 'Invalid menu selection.' }
    }
}

function Get-CapabilityNames {
    param([string]$Selection)

    switch ($Selection) {
        'ADUC' { @('Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0') }
        'GroupPolicy' { @('Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0') }
        'DHCP' { @('Rsat.DHCP.Tools~~~~0.0.1.0') }
        'Core' {
            @(
                'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0',
                'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0',
                'Rsat.DHCP.Tools~~~~0.0.1.0'
            )
        }
        'All' {
            @(Get-WindowsCapability -Online -Name 'Rsat.*' |
                Where-Object State -eq 'NotPresent' |
                Select-Object -ExpandProperty Name)
        }
        default { throw "Unknown component selection: $Selection" }
    }
}

$iso = $null
$mount = $null

try {
    Write-Section 'Windows detection'
    $windows = Get-WindowsFoDTag
    Write-Host "Windows build: $($windows.Build)"
    Write-Host "Required FoD set: $($windows.Tag)"

    Write-Section 'USB and ISO detection'
    $roots = Get-CandidateUsbRoots -PreferredRoot $UsbRoot
    $iso = Find-FoDIso -Roots $roots -VersionFolder $windows.Folder
    Write-Host "Selected ISO: $($iso.FullName)" -ForegroundColor Green

    $mount = Mount-FoDIso -ImagePath $iso.FullName
    $source = Resolve-FoDSource -MountedRoot $mount.SourceRoot
    Write-Host "FoD source: $source" -ForegroundColor Green

    Write-Section 'RSAT selection'
    $selection = Select-Component -Requested $Component
    $capabilities = Get-CapabilityNames -Selection $selection

    if (-not $capabilities) {
        Write-Host 'All requested RSAT components are already installed.' -ForegroundColor Green
        return
    }

    Write-Section 'Installation'
    foreach ($capability in $capabilities) {
        $current = Get-WindowsCapability -Online -Name $capability
        if ($current.State -eq 'Installed') {
            Write-Host "Already installed: $capability" -ForegroundColor DarkGreen
            continue
        }

        Write-Host "Installing: $capability" -ForegroundColor Yellow
        Add-WindowsCapability -Online -Name $capability -Source $source -LimitAccess | Out-Host
    }

    Write-Section 'Result'
    Get-WindowsCapability -Online -Name 'Rsat.*' |
        Where-Object State -eq 'Installed' |
        Select-Object Name, State |
        Format-Table -AutoSize

    Write-Host 'RSAT installation completed.' -ForegroundColor Green
}
catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Common causes: wrong FoD ISO for this Windows build, missing CAB files, or a damaged ISO.' -ForegroundColor Yellow
    exit 1
}
finally {
    if ($mount -and $mount.MountedByScript -and $iso) {
        try {
            Dismount-DiskImage -ImagePath $iso.FullName -ErrorAction Stop
            Write-Host "ISO dismounted: $($iso.FullName)"
        }
        catch {
            Write-Warning "Could not dismount ISO automatically: $($_.Exception.Message)"
        }
    }
}
