# RSAT PowerShell — Windows 11

Набор PowerShell-команд и готовых скриптов для установки RSAT в среде с WSUS и без прямого доступа к Windows Update.

## Содержимое

- `scripts/Install-RSAT-Online.ps1` — установка RSAT через Windows Update.
- `scripts/Install-RSAT-From-FoD.ps1` — установка RSAT из смонтированного ISO Features on Demand.
- `scripts/Install-RSAT-ADUC.ps1` — установка Active Directory Users and Computers.
- `scripts/Install-RSAT-GroupPolicy.ps1` — установка Group Policy Management.
- `scripts/Install-RSAT-DHCP.ps1` — установка DHCP Management Tools.
- `scripts/Install-RSAT-All.ps1` — установка всех доступных компонентов RSAT.
- `scripts/Get-RSAT-Status.ps1` — проверка состояния компонентов.
- `scripts/Set-WSUS-TemporaryBypass.ps1` — временно отключить использование WSUS.
- `scripts/Restore-WSUS.ps1` — вернуть использование WSUS.

## Запуск

Откройте PowerShell **от имени администратора**.

Проверка состояния:

```powershell
Get-WindowsCapability -Online -Name 'Rsat*' |
    Select-Object Name, State
```

Установка ADUC:

```powershell
.\scripts\Install-RSAT-ADUC.ps1
```

Установка с FoD ISO:

```powershell
.\scripts\Install-RSAT-From-FoD.ps1 -Source 'D:\LanguagesAndOptionalFeatures'
```

Либо для вашей структуры:

```powershell
.\scripts\Install-RSAT-From-FoD.ps1 -Source 'F:\FoD\24H2'
```

## Соответствие версий FoD

ISO Features on Demand должно соответствовать сборке Windows:

- Windows 11 21H2 — build 22000
- Windows 11 22H2 / 23H2 — build 22621 / 22631
- Windows 11 24H2 — build 26100

Проверить текущую сборку:

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber
```

## Частые ошибки

### 0x800f0954

Обычно компьютер пытается получить компонент через WSUS. Временно переключите установку на Windows Update:

```powershell
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name UseWUServer -Value 0
Restart-Service wuauserv
```

После установки верните значение:

```powershell
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name UseWUServer -Value 1
Restart-Service wuauserv
```

### 0x800f081f / 0x800f0912

Чаще всего источник FoD не соответствует версии Windows либо указан неправильный каталог. Используйте подходящий ISO и параметр `-LimitAccess`.
