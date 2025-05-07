#--------------------------------------------------------------------------
# Need Module of Powershell on Commvault
# https://documentation.commvault.com/commvault/v11/article?p=124529_1.htm
#---------------------------------------------------------------------------

#-------------------------------------------------------------
#    Monitor for Backups
#-------------------------------------------------------------
Param
(
    $server = " ",
    $completedtime = "24"
)
$GetCredential = Get-Credential
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $GetCredential.UserName, ($GetCredential.Password)
Connect-CVServer -Server $server -Credential $credential

$bkp_run = Get-CVJob -CompletedTime $completedtime | Where-Object { $_.status -eq 'Running' -and $_.destClientName -eq $server }
$bkp_fail = Get-CVJob -CompletedTime $completedtime | Where-Object { $_.status -eq 'Failed' -and $_.destClientName -eq $server }
$bkp_comple = Get-CVJob -CompletedTime $completedtime | Where-Object { $_.status -eq 'Completed' -and $_.destClientName -eq $server }
$bkp_erro = Get-CVJob -CompletedTime $completedtime | Where-Object { $_.status -match 'erro' -and $_.destClientName -eq $server }

## XML Output for PRTG
Write-Host "<?xml version=`"1.0`" encoding=`"UTF-8`" ?>"  
Write-Host "<prtg>"

Write-Host "<result>"  
Write-Host "<channel>Running Backups</channel>"  
write-host "<unit>#</unit>"
Write-Host "<value>"$bkp_run.Count "</value>"
Write-Host "</result>"
Write-Host "<result>"  
Write-Host "<channel>Backups w/ Errors</channel>"  
write-host "<unit>#</unit>"
Write-Host "<value>"$bkp_erro.Count "</value>"
Write-Host "<LimitMode>1</LimitMode>"
Write-Host "<LimitMaxWarning>1</LimitMaxWarning>"
Write-Host "<LimitWarningMsg>Completed w/ one or more errors</LimitWarningMsg>"
Write-Host "</result>"
Write-Host "<result>"  
Write-Host "<channel>Backups Completed</channel>"  
write-host "<unit>#</unit>"
Write-Host "<value>"$bkp_comple.Count "</value>"
Write-Host "</result>"
Write-Host "<result>"  
Write-Host "<channel>Backup Failed</channel>"  
write-host "<unit>#</unit>"
Write-Host "<value>"$bkp_fail.Count "</value>"
Write-Host "<LimitMode>1</LimitMode>"
Write-Host "<LimitMaxError>1</LimitMaxError>"
Write-Host "<LimitWarningMsg>Backup Failed </LimitWarningMsg>"
Write-Host "</result>"
Write-Host "<Text> Log saved in \\itls0255\f$\Monitoramento Prtg </Text>"

Write-Host "</prtg>"