Get Start Time
$startDTM = (Get-Date)

# Meta Information of script
$workingFile = $MyInvocation.MyCommand.Definition
$runAs = [Environment]::UserDomainName + "\" + [Environment]::UserName
$creationDate = (Get-ChildItem $workingFile).CreationTime 
$creationDate = Get-Date -Date "$creationDate" -Format "yyyy-MM-dd"
$lastModified = (Get-ChildItem $workingFile).LastWriteTime
$lastModified = Get-Date -Date "$lastModified" -Format "yyyy-MM-dd HH:mm:ss"
$author = "Valdir"
$version = "1"
$share = " "
$logPath = " "
$dbServer = " "
$dbName = " "

# Database
$conString = "Server=$dbServer;Database=$dbName;Integrated Security=SSPI"

# Dates
$date = Get-Date -Format d
$dateDB = Get-Date -Format yyyyMM

# Import Logging Functions
. "\Logging Functions\Logging_Functions.ps1"
$logName = "$date.log"

$global:logFile = $logPath + $logName

# Create Logging File
LogStart -logPath $logPath -logName $logName -workingFile $workingFile -author $author -version $version -created $creationDate -modified $lastModified -runAs $runAs
LogWrite -level "INFO" -message "Try to connect to OneView"

# HPEOneView Cmdlets
Write-Host "Checking Module HPEOneview and HPEiLOCmdlets" -ForegroundColor White -BackgroundColor Blue
LogWrite -level "INFO" -message  "Checking Module HPEOneview and HPEiLOCmdlets"

If (-not (Get-Module HPEOneView.550 -ListAvailable)) {
    Install-Module HPEOneView.550 -Force 
    Write-Host "Installing Module HPE Oneview" -ForegroundColor White -BackgroundColor Blue
    LogWrite -level "INFO" -message "Installing Module HPE Oneview"
}
Import-Module HPEOneView.550
Write-Host "Importing Module HPE Oneview"
LogWrite -level "INFO" -message "Importing Module HPE Oneview"

##########################################################################################################################################

# Credential and Connections

Write-Host "Entry with your credential OneView" -ForegroundColor White -BackgroundColor Blue
LogWrite -level "INFO" -message "Entry with your Oneview Credential"

Start-Sleep -Seconds 3
$GetCredential = Get-Credential

# Credentials For the OneView
Write-Host "Creating Credential for OneView Connection" -ForegroundColor White -BackgroundColor Blue   
LogWrite -level "INFO" -message "Creating Credential for OneView Connection"
try {
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $GetCredential.UserName, ($GetCredential.Password)
}
catch {
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1
}

try {
    $Connection1 = Connect-HPOVMgmt -Hostname hdhx0773 -AuthLoginDomain euro1 -Credential $credential 
    Write-Host "Connecting OneView Host $($Connection1.name)" -ForegroundColor White -BackgroundColor Blue
    LogWrite -level "INFO" -message "Connecting OneView Host $($Connection1.name)"
 
    $Connection2 = Connect-HPOVMgmt -Hostname hdhx0777 -AuthLoginDomain euro1 -Credential $credential 
    Write-Host "Connecting OneView Host $($Connection2.name)" -ForegroundColor White -BackgroundColor Blue    
    LogWrite -level "INFO" -message "Connecting OneView Host $($Connection2.name)"
   
    $Connection3 = Connect-HPOVMgmt -Hostname hdhm220b1r35e3xflmcl -AuthLoginDomain euro1 -Credential $credential
    Write-Host "Connecting OneView Host $($Connection3.name)" -ForegroundColor White -BackgroundColor Blue    
    LogWrite -level "INFO" -message "Connecting OneView Host $($Connection3.name)"
     
    $Connection4 = Connect-HPOVMgmt -Hostname hdhm402a0r17e3xflmcl -AuthLoginDomain euro1 -Credential $credential
    Write-Host "Connecting OneView Host $($Connection4.name)" -ForegroundColor White -BackgroundColor Blue 
    LogWrite -level "INFO" -message  "Connecting OneView Host $($Connection4.name)"
    
    $Connection5 = Connect-HPOVMgmt -Hostname hdhx0776 -AuthLoginDomain euro1 -Credential $credential
    Write-Host "Connecting OneView Host $($Connection5.name)" -ForegroundColor White -BackgroundColor Blue 
    LogWrite -level "INFO" -message "Connecting OneView Host $($Connection5.name)"
}
catch {
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1
}

LogWrite -level "INFO" -message "Getting the Information of Servers"
# Build CSV File and Exporting
Get-HPOVServer -ApplianceConnection $ConnectedSessions | Select-Object servername, shortmodel, mpmodel, mpfirmwareVersion |
ForEach-Object {
  new-object psobject -Property @{
    ServerName      = $_.servername
    Model           = $_.shortmodel
    iLO_version     = $_.mpmodel
    FirmwareVersion = $_.mpfirmwareVersion
  }
} | Select-Object ServerName, Model, iLO_version, FirmwareVersion | 
Export-Csv -Delimiter ";" -Path  -NoTypeInformation  | Format-Table 
LogWrite -level "INFO" -message "Disconnect from all OneView Appliances"

#Disconnect from all OneView
Disconnect-HPOVMgmt $ConnectedSessions

# OPEN SQL Connection
LogWrite -level "INFO" -message "Try to open database connection"
$con = New-Object System.Data.SqlClient.SqlConnection
$con.ConnectionString = $conString
$con.Open()
$com = New-Object System.Data.SqlClient.SqlCommand
$com.Connection = $con
LogWrite -level "INFO" -message "Connection established"

#Import CSV
LogWrite -level "INFO" -message "Open CSV "

try{
    $data = Import-Csv : “;“
   }
catch{
    $message = $Error[0].Exception.Message + " Error at line " + $Error[0].InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message $message
    $Error.Clear()
    exit
    }

 #Process each item
Foreach ($element in $Data) {
    $capacity_GB = $element.memoryMb / 1024


 # Create Object for database tupel
    $obj = New-Object PSObject
    
    $obj | Add-Member -MemberType NoteProperty -Name YYYYMM -Value $dateDB
    $obj | Add-Member -MemberType NoteProperty -Name Creation_Date -Value $creationDate
    $obj | Add-Member -MemberType NoteProperty -Name Host -Value $element.Host
    $obj | Add-Member -MemberType NoteProperty -Name ServerName -Value $element.ServerName
    $obj | Add-Member -MemberType NoteProperty -Name Memory_GB -Value $capacity_GB
    $obj | Add-Member -MemberType NoteProperty -Name Model -Value $element.Model
    $obj | Add-Member -MemberType NoteProperty -Name iLO_Version -Value $element.iLO_Version
    $obj | Add-Member -MemberType NoteProperty -Name FirmwareVersion -Value $element.FirmwareVersion
    $obj | Add-Member -MemberType NoteProperty -Name PartNumber -Value $element.partNumber
    $obj | Add-Member -MemberType NoteProperty -Name SerialNumber -Value $element.SerialNumber
    $obj | Add-Member -MemberType NoteProperty -Name Platafom -Value $element.Platafom
    $obj | Add-Member -MemberType NoteProperty -Name OV_Appliance -Value $element.OV_Appliance
        
 # Create insert statement
    try{    
        $properties = $obj.PSObject.Properties
        $i = 0
        $com.CommandText = "INSERT INTO " + $table + " (" + [string]::Join(",", ($properties | %{$_.Name})) + ") VALUES (" + [string]::Join(",", ($properties | %{$i++; "@$i"})) + ")"  
        $com.Parameters.Clear() 
        $i = 0
        $clear = $properties | %{$i++; $com.Parameters.AddWithValue("@$i", $_.Value)}
        $com.ExecuteScalar()
        LogWrite -level "INFO" -message "Inserting into database"
      } 
    catch{
        $err = $_.Exception
        $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
        LogWrite -level "ERROR" -message "$message"
        $errors = $errors + 1
        }

}
# Close SQL Connection
$con.Close()
LogWrite -level "INFO" -message "End Connection"

# Get End Time
$endDTM = (Get-Date)
$ts = New-TimeSpan -Seconds $(($endDTM-$startDTM).totalseconds)
"Elapsed Time: $ts"

# Close Log File
LogFinish -logPath "$logPath\$date.log" -processingTime $ts -errors $errors -warnings $warnings -NoExit $True

# Write Mail if Error
if ($errors -gt 0){
    try{
        Write-Output "0"
        LogEmail -from " " -to " " -subject "Error running Script $workingFile" -body "There have been $errors errors" -attachment $global:logFile
    }
    catch{
        Write-Output "Sending Email failed"
    }
}