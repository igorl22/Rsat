Get-WindowsCapability -Online -Name 'Rsat*' |
    Select-Object Name, State |
    Sort-Object Name |
    Format-Table -AutoSize
