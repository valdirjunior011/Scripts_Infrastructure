####################################################################################################################
# NAME:                Script to disable users account and move them to different OU using CSV                     #
# CHANGE BY:           VALDIR JUNIOR                                                                               #
# COMMENT:             All you need is fill up the Disable user account csv with saMAccountName & OU to move to.   #
# VERSION HISTORY:     1.1                                                                                         #
# 1.0 12/19/2012 - Initial release                                                                                 #
# 1.1 06/01/2020 - First changed                                                                                   #
####################################################################################################################

Import-Module ActiveDiretory

$UsersToDisableList = IMPORT-CSV %USERPROFILE%\DisableUsers.csv  
$PrimaryDC = 'NAME SERVER' 
$DomainName = 'YOUR DOMAIN' 
Clear-Host 
Connect-QADService -service $PrimaryDC 
 
Function DisableUsers 
{ 
    Param( 
        [string] $_SamAccountName, 
        [string] $_MoveTOOU 
        ) 
    write-host ("User: $_SamAccountName") 
    Write-Host ("Move to OU: $_MoveTOOU") 
 
Get-ADUser $_SamAccountName | Set-ADUser -Enabled $false 
Start-Sleep -s 2 
Move-QADObject -Identity $_SamAccountName -NewParentContainer $_MoveTOOU 
Start-Sleep -s 2 
} 
 
FOREACH ($User in $UsersToDisableList) { 
    DisableUsers $User.SamAccountName $User.MoveTOOU 
}