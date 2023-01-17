# Import the HPEOneView.550 PowerShell module
Import-Module HPEOneView.550
Clear-Host
$serverName = Read-Host -Prompt "Enter the server name"

while(!(Test-Connection -ComputerName $serverName -Count 1 -Quiet))
{
    Write-Host "Server is not reachable, Please check the server name or network connectivity"
    $serverName = Read-Host -Prompt "Enter the server name again"
}

Write-Host "Server is reachable"

$oneviewInstances = @("instance1","instance2","instance3")

$instanceChoice = $null

while($null -eq $instanceChoice)
{
    $i = 1
    Write-Host "Select an option for the OneView instance:"
    foreach($instance in $oneviewInstances)
    {
        Write-Host "$i. $instance"
        $i++
    }

    $instanceNumber = Read-Host -Prompt "Enter the number of your choice"
    if($instanceNumber -ge 1 -and $instanceNumber -le $oneviewInstances.Count)
    {
        $instanceChoice = $oneviewInstances[$instanceNumber - 1]
    }
    else
    {
        Write-Host "Invalid choice, please try again"
    }
}

$credential = Get-Credential -Message "Enter OneView Credentials"
$credOneView = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Credential.UserName, ($Credential.Password)
$credServer = Get-Credential -Message "Enter Server Credentials to add this server"

if($instanceChoice -eq 1){
    $Connection1 = Connect-HPOVMgmt -Hostname instance1 -AuthLoginDomain euro1 -Credential $credOneView 
}elseif($instanceChoice -eq 2){ 
     $Connection2 = Connect-HPOVMgmt -Hostname instance2 -AuthLoginDomain euro1 -Credential $credOneView 
}elseif($instanceChoice -eq 3){    
    $Connection3 = Connect-HPOVMgmt -Hostname instance3 -AuthLoginDomain euro1 -Credential $credOneView
}

$manageOrMonitor = Read-Host -Prompt "Will this server be managed or monitored? (1. Managed/2. Monitored)"
while(($manageOrMonitor -ne "1") -and ($manageOrMonitor -ne "2"))
{
    Write-Host "Invalid choice, please try again"
    $manageOrMonitor = Read-Host -Prompt "Will this server be managed or monitored? (1. Managed/2. Monitored)"
}

$manageOrMonitor = if($manageOrMonitor -eq "1"){":Managed"}else{"Monitored"}

if($instanceChoice -eq 1){
    $serverExists = (Get-HPOVServer -ServerName $serverName -ApplianceConnection $Connection1 -Scope AllResources )
}elseif($instanceChoice -eq 2){ 
    $serverExists = (Get-HPOVServer -ServerName $serverName -ApplianceConnection $Connection2 -Scope AllResources )
}elseif($instanceChoice -eq 3){    
    $serverExists = (Get-HPOVServer -ServerName $serverName -ApplianceConnection $Connection3 -Scope AllResources )
}

if ($null -eq $serverExists) {
    if($manageOrMonitor -eq 1){
        Add-HPOVServer -Hostname $serverName -ApplianceConnection $instanceChoice -Credential $credServer
        Write-Host "Server has been added"
    } elseif($manageOrMonitor -eq 2) {
        Add-HPOVServer -Hostname $serverName -ApplianceConnection $instanceChoice -Monitored -Credential $credServer
        Write-Host "Server has been added"
    }else{
        Write-Host "Server already exists"
    }
}