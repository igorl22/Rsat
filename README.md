# RSAT PowerShell — установка с FoD ISO на флешке

Этот репозиторий предназначен прежде всего для **офлайн-установки RSAT с флешки**, на которой находятся ISO Windows Features on Demand.

## Структура флешки

Скрипт ожидает следующую структуру:

```text
F:\FoD\21H2\<FoD ISO-файл>.iso
F:\FoD\22H2_23H2\<FoD ISO-файл>.iso
F:\FoD\24H2\<FoD ISO-файл>.iso
```

Буква флешки может быть любой. Скрипт ищет папку `FoD` автоматически.

## Самый простой запуск

1. Скачайте репозиторий: **Code → Download ZIP**.
2. Распакуйте папку на флешку рядом с папкой `FoD` или в любое другое место.
3. Запустите двойным щелчком:

```text
Start-RSAT-USB.cmd
```

Файл сам запросит права администратора и запустит PowerShell.

## Что делает автоматический скрипт

`scripts/Install-RSAT-From-USB.ps1`:

1. Определяет сборку установленной Windows.
2. Выбирает правильную папку FoD.
3. Находит ISO на подключённой флешке.
4. Монтирует ISO.
5. Находит каталог с CAB-пакетами.
6. Показывает меню компонентов RSAT.
7. Устанавливает компоненты с параметрами `-Source` и `-LimitAccess`.
8. Показывает результат и отключает ISO.

## Соответствие версий

| Сборка Windows | Версия | Папка на флешке |
|---|---|---|
| 22000 | Windows 11 21H2 | `FoD\21H2` |
| 22621 / 22631 | Windows 11 22H2 / 23H2 | `FoD\22H2_23H2` |
| 26100 | Windows 11 24H2 | `FoD\24H2` |

## Меню установки

После запуска можно выбрать:

```text
[1] ADUC + модуль Active Directory PowerShell
[2] Group Policy Management
[3] DHCP Management Tools
[4] Все отсутствующие компоненты RSAT
[5] ADUC + Group Policy + DHCP
```

Для большинства рабочих компьютеров удобен вариант **5**.

## Запуск непосредственно из PowerShell

Откройте PowerShell от имени администратора и выполните:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\Install-RSAT-From-USB.ps1
```

Установить ADUC без меню:

```powershell
.\scripts\Install-RSAT-From-USB.ps1 -Component ADUC
```

Установить все RSAT без меню:

```powershell
.\scripts\Install-RSAT-From-USB.ps1 -Component All
```

Если автоматический поиск флешки не сработал, укажите её букву:

```powershell
.\scripts\Install-RSAT-From-USB.ps1 -UsbRoot F:\
```

## Проверка после установки

Проверить установленные RSAT:

```powershell
.\scripts\Get-RSAT-Status.ps1
```

Запуск консолей:

```powershell
dsa.msc       # Active Directory Users and Computers
gpmc.msc      # Group Policy Management
dhcpmgmt.msc  # DHCP Management
```

Проверить модуль Active Directory:

```powershell
Import-Module ActiveDirectory
Get-Module ActiveDirectory
```

## Частые ошибки

### ISO не найден

Проверьте, что ISO лежит внутри соответствующей папки:

```text
<буква флешки>:\FoD\24H2\
```

### 0x800f081f или 0x800f0912

Обычно FoD ISO не соответствует сборке Windows либо это не Features on Demand ISO.

Проверьте сборку:

```powershell
(Get-CimInstance Win32_OperatingSystem).BuildNumber
```

### 0x800f0954

При использовании нового автоматического скрипта WSUS не должен участвовать, поскольку установка выполняется с `-LimitAccess`. Временно менять `UseWUServer` обычно не требуется.

## Дополнительные скрипты

В папке `scripts` также оставлены отдельные команды для ручной установки, проверки RSAT и сценария через Windows Update. Основной рекомендуемый файл для этой флешки — `Start-RSAT-USB.cmd`.
