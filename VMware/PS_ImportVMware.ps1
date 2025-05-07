###############################################################################################
# Import VmWare Data Informations to DB dbo.vmware_Details
###############################################################################################

# Database Variables
$sqlserver = " "
$database = " "
$table = "  "

# Get date for csv-archive
$creationDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$YYYYMM = Get-Date -format yyyyMM
$date = Get-Date -format MM-dd-yyyy
$folderdate = $Date

# CSV Variable
$sourcePath = " "
$csvdelimiter = ";"
$filePath = " "

# Mail Variables
$from = " "
$to  = " "

###############################################################################################
###############################################################################################

# Get Start Time
$startDTM = (Get-Date)

$author = "Valdir"
$version = "1.0"

# Import Logging Functions 
. "\Logging_Functions.ps1"

# Logging Direction
$logPath = " "

###############################################################################################
###############################################################################################

# Meta Information of script
$workingFile = $MyInvocation.MyCommand.Definition
$runAs = [Environment]::UserDomainName + "\" +[Environment]::UserName
$creationDate = (Get-ChildItem $workingFile).CreationTime 
$creationDate = Get-Date -Date "$creationDate" -Format "yyyy-MM-dd HH:mm:ss"
$lastModified = (Get-ChildItem $workingFile).LastWriteTime
$lastModified = Get-Date -Date "$lastModified" -Format "yyyy-MM-dd HH:mm:ss"

# Database Connection String
$conString = "Server=$sqlserver;Database=$database;Integrated Security=SSPI;MultipleActiveResultSets=true"

###############################################################################################
###############################################################################################

$logName = "$date.log"
$global:logFile = $logPath + $logName

# Create Logging File
LogStart -logPath $logPath -logName $logName -workingFile $workingFile -runAs $runAs -author $author -version $version -created $creationDate -modified $lastModified

$errors = 0
$warnings = 0

###############################################################################################
###############################################################################################

Try {
    # Create CSV-Folder
    New-Item -ItemType Directory -Path $filePath\$folderdate -Force
    LogWrite -level "INFO" -message "CSV-Folder Created"
    Write-Host "CSV-Folder Created" -ForegroundColor White -BackgroundColor Blue
}
Catch {
    $err = $_.Exception
    $message = "[] " + $err.Message + " " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1
}

Try {
    # Copy Original File to Another diretory
    Copy-Item $sourcePath\VMWare_tech_inventory.csv $filePath\$folderdate\VMWare_tech_inventory.csv -Force
    LogWrite -level "INFO" -message "Copy CSV to Folder $date"
    Write-Host "Copy CSV to folder $Date" -ForegroundColor White -BackgroundColor Blue
}
Catch {
    $err = $_.Exception
    $message = "[] " + $err.Message + " " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1
}

###############################################################################################
###############################################################################################

Try {
    # Open SQL Connection
    Clear-Host
    $con = New-Object System.Data.SqlClient.SqlConnection
    $con.ConnectionString = $conString
    $con.Open()
    $com = New-Object System.Data.SqlClient.SqlCommand
    $com.Connection = $con
    LogWrite -level "INFO" -message "Connection established with DB"
    Write-Host "Connection established with DB" -ForegroundColor White -BackgroundColor Blue
}
Catch {
    $err = $_.Exception
    $message = "[] " + $err.Message + " " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1
}

###############################################################################################
###############################################################################################

# Import CSV
$csvfile = Import-csv $filePath\$folderdate\VMware_tech_inventory.csv -Delimiter "$csvdelimiter"
LogWrite -level "INFO" -message "Importing CSV"
Write-Host "Importing CSV" -ForegroundColor White -BackgroundColor Blue

###############################################################################################
###############################################################################################

# Create Insert Array for VMware Data
ForEach ($row in $csvfile){
Try {
    # Create Object for Database tupel
    $Host_Name = $row.VMhost
    $Host_Name = $Host_Name.split(".")
    $host_Name = $Host_Name[0]

    $obj = New-Object PSObject

    $obj | Add-Member -MemberType NoteProperty -Name YYYYMM -Value $YYYYMM
    $obj | Add-Member -MemberType NoteProperty -Name Creation_Date -Value $creationDate
    $obj | Add-Member -MemberType NoteProperty -Name DC_Name -Value $row.DCname
    $obj | Add-Member -MemberType NoteProperty -Name Cluster -Value $row.VMCluster
    $obj | Add-Member -MemberType NoteProperty -Name Host_Name -Value $Host_Name
    $obj | Add-Member -MemberType NoteProperty -Name Host_DC -Value $row.hostdc
    $obj | Add-Member -MemberType NoteProperty -Name Server_Name -Value $row.VMname
    $obj | Add-Member -MemberType NoteProperty -Name Server_DC -Value $row.VMdc
    $obj | Add-Member -MemberType NoteProperty -Name CPU -Value $row.VMcpu
    $obj | Add-Member -MemberType NoteProperty -Name RAM -Value $row.VMmem
    $obj | Add-Member -MemberType NoteProperty -Name Status -Value $row.VMstatus
    $obj | Add-Member -MemberType NoteProperty -Name Last_Backup -Value $row.VMbackup

    LogWrite -level "INFO" -message "Object $Host_Name Created"
    Write-Host "Object $Host_Name Created" -ForegroundColor White -BackgroundColor Blue
} 
Catch {
    $err = $_.Exception
    $message = "[] " + $err.Message + " " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "WARNING" -message "§message"
    $errors = $errors + 1
}
Try {    
    # Create insert statement
    $properties = $obj.PSObject.Properties
    $i = 0
    $com.CommandText = "INSERT INTO " + $table + " (" + [string]::Join(",", ($properties | % { $_.Name })) + ") VALUES (" + [string]::Join(",", ($properties | % { $i++; "@$i" })) + ")"  
    $com.Parameters.Clear() 
    $i = 0
    $clear = $properties | % { $i++; $com.Parameters.AddWithValue("@$i", $_.Value) }
    $com.ExecuteScalar()
    LogWrite -level "INFO" -message "$Host_Name write success"
    Write-Host "Object $Host_Name write success" -ForegroundColor White -BackgroundColor Blue

} 
Catch {
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1
}
}
# Close SQL Connection
$con.Close()
LogWrite -level "INFO" -message "End Connection"
Write-Host "End Connection" -ForegroundColor White -BackgroundColor Blue

# Get Start Time
$endDTM = (Get-Date)
$ts = New-TimeSpan -Seconds $(($endDTM - $startDTM).totalseconds)
"Elapsed Time: $ts"

if($errors -gt 0){
    $subject = "Import VMware has failed"
    $body = "Import of VMwareFiles to Services_idr/dbo.VMware_Inventory has failed with $errors Error(s)"
    LogEmail -from $from -to $to -subject $subject -body $body -attachment $global:logFile
    LogWrite -level "INFO" -message "Error-E-Mail to $to sent successfully from $from"
}

# Close Log File
LogFinish -logPath $global:logFile -processingTime $ts -errors $errors -warnings $warnings -NoExit $True