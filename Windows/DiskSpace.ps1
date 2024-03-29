﻿#-------------------------------------------------------------
# Check Disk Space using label reference "Support Mount Point"
#-------------------------------------------------------------
Param
(
    [string]$computer = " ",
    [string]$label = "",
    [int]$warning = 80,
    [int]$critic = 95

)
#-------------------------------------------------------------
#STATUS
#-------------------------------------------------------------
$OK = 0
$WARNING = 1
$CRITICAL = 2
$UNKNOWN = 3
$MSG = ""
#-------------------------------------------------------------
#Check Server Volumes
#-------------------------------------------------------------
If (Test-Connection -ComputerName $computer -Count 2 -Quiet) {
    $objects = Get-WmiObject -computer $computer win32_volume | Select-Object label, name, @{Name = ”Capacity”; expression = { [math]::round((($_.Capacity / 1024) / 1024)) } }, @{Name = ”Freespace”; expression = { [math]::round((($_.Freespace / 1024) / 1024)) } } | Where-Object { $_.label -match $label }
    $rcrit = @()
    $rwar = @()
    $rok = @()
    Foreach ($object in $objects) {
        $per = 100 - ([math]::round($object.Freespace * 100 / $object.capacity))  
        if ($per -igt $critic) {
            $rcrit += "$($Object.label) $($per)% in use and $([math]::round($object.Freespace)) GB free (CRITICAL)"
        }
        elseif ($per -ilt $critic -and $per -igt $warning) {
            $rwar += "$($Object.label) $($per)% in use and $([math]::round($object.Freespace)) GB free (WARNING)"
        }
        else {
            $rok += "$($Object.label) $($per)% in use and $([math]::round($object.Freespace)) GB free (OK)"
        }
    }
    $MSG = "$($rcrit.count) CRITICAL / $($rwar.Count) WARNING / $($rok.count) OK alerts found"
    
    if ($rcrit.count -gt 0) {
        write-host "2:CRITICAL - $($MSG) `n$($rcrit  -join "`n")"# `n$($rwar -join "`n")"
        exit $CRITICAL
    }
    if ($rwar.count -gt 0) {
        write-host "1:WARNING - $($MSG) `n$([string]$rwar)"
        exit $WARNING
    }
    write-host "0:OK - $($MSG)"# `n$([string]$rok)"
    exit $OK
}
else {
    write-output "2:CRITICAL - $computer NOT FOUND"
    exit $CRITICAL
}