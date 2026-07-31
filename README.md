# RSAT PowerShell — установка с FoD ISO на флешке

Этот репозиторий предназначен прежде всего для **офлайн-установки RSAT с флешки**, на которой находятся ISO Windows Features on Demand.

## Структура флешки

```text
F:\FoD\21H2\<FoD ISO-файл>.iso
F:\FoD\22H2_23H2\<FoD ISO-файл>.iso
F:\FoD\24H2\<FoD ISO-файл>.iso
```

Буква флешки может быть любой. Скрипт ищет папку `FoD` автоматически.

## Самый простой запуск

1. Скачайте репозиторий: **Code → Download ZIP**.
2. Распакуйте папку.
3. Запустите двойным щелчком:

```text
Start-RSAT-USB.cmd
```

Файл сам запросит права администратора, определит сборку Windows, выберет правильный FoD ISO, смонтирует его и покажет меню.

## Меню установки

```text
[1] ADUC + Active Directory PowerShell module
[2] Group Policy Management
[3] DHCP Management Tools
[4] My RSAT set (10 components)
[5] All missing RSAT components
```

Для рабочих компьютеров используйте вариант **4**.

## Мой набор RSAT — 10 компонентов

Вариант 4 устанавливает:

1. Active Directory DS/LDS Tools
2. Certificate Services Tools
3. DHCP Tools
4. DNS Tools
5. File Services Tools
6. Group Policy Management Tools
7. Remote Access Management Tools
8. Remote Desktop Services Tools
9. Server Manager Tools
10. WSUS Tools

Точные имена Windows Capability:

```text
Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Rsat.CertificateServices.Tools~~~~0.0.1.0
Rsat.DHCP.Tools~~~~0.0.1.0
Rsat.Dns.Tools~~~~0.0.1.0
Rsat.FileServices.Tools~~~~0.0.1.0
Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0
Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0
Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0
Rsat.ServerManager.Tools~~~~0.0.1.0
Rsat.WSUS.Tools~~~~0.0.1.0
```

Уже установленные компоненты пропускаются. Если какой-либо компонент отсутствует в конкретной сборке Windows, скрипт выводит предупреждение и продолжает установку остальных.

## Соответствие версий

| Сборка Windows | Версия | Папка на флешке |
|---|---|---|
| 22000 | Windows 11 21H2 | `FoD\21H2` |
| 22621 / 22631 | Windows 11 22H2 / 23H2 | `FoD\22H2_23H2` |
| 26100 | Windows 11 24H2 | `FoD\24H2` |

## Запуск без меню

Откройте PowerShell от имени администратора:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\Install-RSAT-From-USB.ps1 -Component MySet
```

Если флешка не найдена автоматически:

```powershell
.\scripts\Install-RSAT-From-USB.ps1 -Component MySet -UsbRoot F:\
```

## Проверка

```powershell
.\scripts\Get-RSAT-Status.ps1
```

Основные консоли:

```powershell
dsa.msc
gpmc.msc
dhcpmgmt.msc
dnsmgmt.msc
servermanager.exe
```

Установка выполняется с `-Source` и `-LimitAccess`, поэтому WSUS и Windows Update не используются.
