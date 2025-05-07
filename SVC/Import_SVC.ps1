###############################################################################################
## Import SVC Disks informations to DB dbo.SVC_LUN
###############################################################################################

# Database variables 
$sqlserver = " " 
$database = " " 
$table = " " 

#get date for csv-archive
$CD_date = Get-Date -format "yyyy-MM-dd HH:mm:ss"
$YYYYMM = Get-Date -Format yyyyMM
$date = Get-Date -format MM-dd-yyyy
$folderdate = $date

# CSV variables 
$sourcePath = " "
$csvdelimiter = ";" 
$filePath = " \$folderdate"

# Mail variables
$from = " "
$to = " "

###############################################################################################
###############################################################################################

# Get Start Time
$startDTM = (Get-Date)

$author = "Valdir" 
$version = "1.2.1"

# Import Logging Functions
. " "

# Logging Direction
$logPath = "\\ \log\PS_ImportSVC\logs\"

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

try{
    #create CSV-Folder
    New-Item -ItemType directory -Path $filePath -Force
    LogWrite -level "INFO" -message "CSV-Folder Created"
    Write-Host "CSV-Folder Created" -ForegroundColor White -BackgroundColor Blue

}
catch{
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1   
}

try{
    #copy original file to another diretory 
    Copy-Item $sourcePath\SVC_vdisks.csv $filePath\SVC_vdisks.csv -Force
    Copy-Item $sourcePath\SVC2_vdisks.csv $filePath\SVC2_vdisks.csv -Force
    Copy-Item $sourcePath\SVC3_vdisks.csv $filePath\SVC3_vdisks.csv -Force
    LogWrite -level "INFO" -message "Copy CSV to Folder $Date"  
    Write-Host "Copy CSV to Folder $Date" -ForegroundColor White -BackgroundColor Blue
   
}
catch{
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1   
}

###############################################################################################
###############################################################################################


try{
# OPEN SQL Connection
$con = New-Object System.Data.SqlClient.SqlConnection
$con.ConnectionString = $conString
$con.Open()
$command = New-Object System.Data.SqlClient.SqlCommand
$command.Connection = $con
LogWrite -level "INFO" -message "Connection established with DB"
Write-Host "Connection established with DB" -ForegroundColor White -BackgroundColor Blue
}
catch{
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1
}

###############################################################################################
###############################################################################################

# Import first csv
$csvfile = Import-Csv $filePath\SVC_vdisks.csv -Delimiter "$csvdelimiter"
LogWrite -level "INFO" -message "Import First SVC CSV"
Write-Host "Import First SVC CSV" -ForegroundColor White -BackgroundColor Blue

###############################################################################################
###############################################################################################

# Create Insert Array for SVC1
ForEach ($row in $csvfile){
        #set servername from vdisk-name
        $servername = $row.vdisk_name
        $servername = $servername.split("_")
        $servername = $servername[0]
        LogWrite -level "DEBUG" -message "Detache $($row.vdisk_name) in two"
        LogWrite -level "DEBUG" -message "Server Name $servername"
        
        #if hdh is missing, add it
        if ($servername.startswith("u")){
            $servername = "hdh" + $servername
        }

        #vdisk_disk
        $vdisk = $row.vdisk_name
        $vdisk = $vdisk.split("_")
        $vdisk = $vdisk[1]
        LogWrite -level "DEBUG" -message "Disk $vdisk"

        #MDisk_Group_Name (DC)
        $mdisk_grp_dc = $row.mdisk_grp_name
        $mdisk_grp_dc = $mdisk_grp_dc.split("_")
        $mdisk_grp_dc = $mdisk_grp_dc[0].subString(2)
        LogWrite -level "DEBUG" -message "DC $mdisk_grp_dc"

        $mdisk_grp_str = $row.mdisk_grp_name
        $mdisk_grp_str = $mdisk_grp_str.split("_")
        $mdisk_grp_str = $mdisk_grp_str[1]
        LogWrite -level "DEBUG" -message "Storage $mdisk_grp_str"
        
        #byte to GiB/GB
        $GBCapacity = $row.capacity /1000/1000/1000
        $GiBCapacity = $row.capacity /1024/1024/1024
        LogWrite -level "DEBUG" -message "byte to GiB/GB"

    try{
        $obj = New-Object PSObject    

        #add further information items here
        $obj | Add-Member -MemberType NoteProperty -Name YYYYMM -value $YYYYMM
        $obj | Add-Member -MemberType NoteProperty -Name Creation_Date -Value $CD_date
        $obj | Add-Member -MemberType NoteProperty -Name SVC -Value '1'
        $obj | Add-Member -MemberType NoteProperty -Name VDisk_ID -Value $row.VDisk_ID
        $obj | Add-Member -MemberType NoteProperty -Name VDisk_Name -Value $row.vdisk_name.ToUpper() 
        $obj | Add-Member -MemberType NoteProperty -Name Server_Name -Value $servername.ToUpper()
        $obj | Add-Member -MemberType NoteProperty -Name VDisk_Disk -Value $vdisk
        $obj | Add-Member -MemberType NoteProperty -Name Copy_ID -Value $row.copy_id
        $obj | Add-Member -MemberType NoteProperty -Name Status -Value $row.status
        $obj | Add-Member -MemberType NoteProperty -Name Sync -Value $row.sync
        $obj | Add-Member -MemberType NoteProperty -Name Primary_Volume -Value $row.primary
        $obj | Add-Member -MemberType NoteProperty -Name Mdisk_Grp_ID -Value $row.mdisk_grp_id
        $obj | Add-Member -MemberType NoteProperty -Name Mdisk_Grp_Name -Value $row.mdisk_grp_name
        $obj | Add-Member -MemberType NoteProperty -Name MDisk_Grp_DC -Value $mdisk_grp_dc
        $obj | Add-Member -MemberType NoteProperty -Name MDisk_Grp_Storage_Device -Value $mdisk_grp_str
        $obj | Add-Member -MemberType NoteProperty -Name Capacity -Value $row.capacity
        $obj | Add-Member -MemberType NoteProperty -Name Capacity_GB -Value $GBCapacity
        $obj | Add-Member -MemberType NoteProperty -Name Capacity_GiB -Value $GiBCapacity
        $obj | Add-Member -MemberType NoteProperty -Name Type -Value $row.type
        $obj | Add-Member -MemberType NoteProperty -Name SE_Copy -Value $row.se_copy
        $obj | Add-Member -MemberType NoteProperty -Name Easy_Tier -Value $row.easy_tier
        $obj | Add-Member -MemberType NoteProperty -Name Easy_Tier_Status -Value $row.easy_tier_status
        $obj | Add-Member -MemberType NoteProperty -Name Compressed_Copy -Value $row.compressed_copy
        $obj | Add-Member -MemberType NoteProperty -Name Parent_MDisk_Grp_ID -Value $row.parent_mdisk_grp_id
        $obj | Add-Member -MemberType NoteProperty -Name Parent_MDisk_Grp_Name -Value $row.parent_mdisk_grp_name
        $obj | Add-Member -MemberType NoteProperty -Name Encrypt -Value $row.encrypt
        $obj | Add-Member -MemberType NoteProperty -Name Deduplicated_Copy -Value $row.deduplicated_copy

        $kyu = $row.vdisk_name.toupper() + " and  Copy ID" + $row.copy_id
        LogWrite -level "INFO" -message "object for $kyu created"
        Write-Host "object for $kyu created" -ForegroundColor White -BackgroundColor Blue

    }
    catch{
        $err = $_.Exception
        $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
        LogWrite -level "WARNING" -message "$message"
        $errors = $errors + 1
    }
  
###############################################################################################
###############################################################################################
    
        # Create insert statement
    try{    
        $properties = $obj.PSObject.Properties
        $i = 0
        $command.CommandText = "INSERT INTO " + $table + " (" + [string]::Join(",", ($properties | ForEach-Object{$_.Name})) + ") VALUES (" + [string]::Join(",", ($properties | ForEach-Object{$i++; "@$i"})) + ")"  
        $command.Parameters.Clear() 
        $i = 0
        $clear = $properties | ForEach-Object{$i++; $command.Parameters.AddWithValue("@$i", $_.Value)}
    }
    catch{
        $err = $_.Exception
        $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
        LogWrite -level "ERROR" -message "$message"
        $errors = $errors + 1
    }
    try{
        # Write to database
        $command.ExecuteScalar()
        LogWrite -level "INFO" -message "$kyu write success on DB"
        Write-Host "$kyu write success on DB" -ForegroundColor White -BackgroundColor Blue
    }
    catch{
        $err = $_.Exception
        $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
        LogWrite -level "ERROR" -message "$message"
        $errors = $errors + 1  
    }
}

###############################################################################################
###############################################################################################

# Import second csv
$csvfile2 = Import-Csv $filePath\SVC2_vdisks.csv -Delimiter "$csvdelimiter"
LogWrite -level "INFO" -message "Import Second SVC CSV"
Write-Host "Import Second SVC CSV" -ForegroundColor White -BackgroundColor Blue

###############################################################################################
###############################################################################################

# Create Insert Array for SVC2
ForEach ($row in $csvfile2){
    #set servername from vdisk-name
    $servername = $row.vdisk_name
    $servername = $servername.split("_")
    $servername = $servername[0]
    LogWrite -level "DEBUG" -message "Detache $($row.vdisk_name) in two"
    LogWrite -level "DEBUG" -message "Server Name $servername"
    
    #if hdh is missing, add it
    if ($servername.startswith("u")){
        $servername = "hdh" + $servername
    }

    #vdisk_disk
    $vdisk = $row.vdisk_name
    $vdisk = $vdisk.split("_")
    $vdisk = $vdisk[1]
    LogWrite -level "DEBUG" -message "Disk $vdisk"

    #MDisk_Group_Name (DC)
    $mdisk_grp_dc = $row.mdisk_grp_name
    $mdisk_grp_dc = $mdisk_grp_dc.split("_")
    $mdisk_grp_dc = $mdisk_grp_dc[0].subString(2)
    LogWrite -level "DEBUG" -message "DC $mdisk_grp_dc"

    $mdisk_grp_str = $row.mdisk_grp_name
    $mdisk_grp_str = $mdisk_grp_str.split("_")
    $mdisk_grp_str = $mdisk_grp_str[1]
    LogWrite -level "DEBUG" -message "Storage $mdisk_grp_str"

    #byte to GiB/GB
    $GBCapacity = $row.capacity /1000/1000/1000
    $GiBCapacity = $row.capacity /1024/1024/1024
    LogWrite -level "DEBUG" -message "byte to GiB/GB"

try{
    $obj = New-Object PSObject    

    #add further information items here
    $obj | Add-Member -MemberType NoteProperty -Name YYYYMM -value $YYYYMM
    $obj | Add-Member -MemberType NoteProperty -Name Creation_Date -Value $CD_date
    $obj | Add-Member -MemberType NoteProperty -Name SVC -Value '2'
    $obj | Add-Member -MemberType NoteProperty -Name VDisk_ID -Value $row.VDisk_ID
    $obj | Add-Member -MemberType NoteProperty -Name VDisk_Name -Value $row.vdisk_name.ToUpper() 
    $obj | Add-Member -MemberType NoteProperty -Name Server_Name -Value $servername.ToUpper()
    $obj | Add-Member -MemberType NoteProperty -Name VDisk_Disk -Value $vdisk
    $obj | Add-Member -MemberType NoteProperty -Name Copy_ID -Value $row.copy_id
    $obj | Add-Member -MemberType NoteProperty -Name Status -Value $row.status
    $obj | Add-Member -MemberType NoteProperty -Name Sync -Value $row.sync
    $obj | Add-Member -MemberType NoteProperty -Name Primary_Volume -Value $row.primary
    $obj | Add-Member -MemberType NoteProperty -Name Mdisk_Grp_ID -Value $row.mdisk_grp_id
    $obj | Add-Member -MemberType NoteProperty -Name Mdisk_Grp_Name -Value $row.mdisk_grp_name
    $obj | Add-Member -MemberType NoteProperty -Name MDisk_Grp_DC -Value $mdisk_grp_dc
    $obj | Add-Member -MemberType NoteProperty -Name MDisk_Grp_Storage_Device -Value $mdisk_grp_str
    $obj | Add-Member -MemberType NoteProperty -Name Capacity -Value $row.capacity
    $obj | Add-Member -MemberType NoteProperty -Name Capacity_GB -Value $GBCapacity
    $obj | Add-Member -MemberType NoteProperty -Name Capacity_GiB -Value $GiBCapacity
    $obj | Add-Member -MemberType NoteProperty -Name Type -Value $row.type
    $obj | Add-Member -MemberType NoteProperty -Name SE_Copy -Value $row.se_copy
    $obj | Add-Member -MemberType NoteProperty -Name Easy_Tier -Value $row.easy_tier
    $obj | Add-Member -MemberType NoteProperty -Name Easy_Tier_Status -Value $row.easy_tier_status
    $obj | Add-Member -MemberType NoteProperty -Name Compressed_Copy -Value $row.compressed_copy
    $obj | Add-Member -MemberType NoteProperty -Name Parent_MDisk_Grp_ID -Value $row.parent_mdisk_grp_id
    $obj | Add-Member -MemberType NoteProperty -Name Parent_MDisk_Grp_Name -Value $row.parent_mdisk_grp_name
    $obj | Add-Member -MemberType NoteProperty -Name Encrypt -Value $row.encrypt
    $obj | Add-Member -MemberType NoteProperty -Name Deduplicated_Copy -Value $row.deduplicated_copy

    $kyu = $row.vdisk_name.toupper() + " and  Copy ID" + $row.copy_id
    LogWrite -level "INFO" -message "object for $kyu created"
    Write-Host "object for $kyu created" -ForegroundColor White -BackgroundColor Blue
}
catch{
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "WARNING" -message "$message"
    $errors = $errors + 1
}

###############################################################################################
###############################################################################################

    # Create insert statement
try{    
    $properties = $obj.PSObject.Properties
    $i = 0
    $command.CommandText = "INSERT INTO " + $table + " (" + [string]::Join(",", ($properties | ForEach-Object{$_.Name})) + ") VALUES (" + [string]::Join(",", ($properties | ForEach-Object{$i++; "@$i"})) + ")"  
    $command.Parameters.Clear() 
    $i = 0
    $clear = $properties | ForEach-Object{$i++; $command.Parameters.AddWithValue("@$i", $_.Value)}
}
catch{
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1
}
try{
    # Write to database
    $command.ExecuteScalar()
    LogWrite -level "INFO" -message "$kyu write success on DB"
    Write-Host "$kyu write success on DB" -ForegroundColor White -BackgroundColor Blue
}
catch{
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1  
}
}

###############################################################################################
###############################################################################################

# Import third csv
$csvfile3 = Import-Csv $filePath\SVC3_vdisks.csv -Delimiter "$csvdelimiter"
LogWrite -level "INFO" -message "Import Trird SVC CSV"
Write-Host "Import Third SVC CSV" -ForegroundColor White -BackgroundColor Blue

###############################################################################################
###############################################################################################

# Create Insert Array for SVC3
ForEach ($row in $csvfile3){
    #set servername from vdisk-name
    $servername = $row.vdisk_name
    $servername = $servername.split("_")
    $servername = $servername[0]
    LogWrite -level "DEBUG" -message "Detache $($row.vdisk_name) in two"
    LogWrite -level "DEBUG" -message "Server Name $servername"
    
    #if hdh is missing, add it
    if ($servername.startswith("u")){
        $servername = "hdh" + $servername
    }

    #vdisk_disk
    $vdisk = $row.vdisk_name
    $vdisk = $vdisk.split("_")
    $vdisk = $vdisk[1]
    LogWrite -level "DEBUG" -message "$vdisk"

    #MDisk_Group_Name (DC)
    $mdisk_grp_dc = $row.mdisk_grp_name
    $mdisk_grp_dc = $mdisk_grp_dc.split("_")
    $mdisk_grp_dc = $mdisk_grp_dc[0].subString(2)
    LogWrite -level "DEBUG" -message "DC $mdisk_grp_dc"

    $mdisk_grp_str = $row.mdisk_grp_name
    $mdisk_grp_str = $mdisk_grp_str.split("_")
    $mdisk_grp_str = $mdisk_grp_str[1]
    LogWrite -level "DEBUG" -message "Storage $mdisk_grp_str"

    #byte to GiB/GB
    $GBCapacity = $row.capacity /1000/1000/1000
    $GiBCapacity = $row.capacity /1024/1024/1024
    LogWrite -level "DEBUG" -message "byte to GiB/GB"

try{
    $obj = New-Object PSObject    

    #add further information items here
    $obj | Add-Member -MemberType NoteProperty -Name YYYYMM -value $YYYYMM
    $obj | Add-Member -MemberType NoteProperty -Name Creation_Date -Value $CD_date
    $obj | Add-Member -MemberType NoteProperty -Name SVC -Value '3'
    $obj | Add-Member -MemberType NoteProperty -Name VDisk_ID -Value $row.VDisk_ID
    $obj | Add-Member -MemberType NoteProperty -Name VDisk_Name -Value $row.vdisk_name.ToUpper() 
    $obj | Add-Member -MemberType NoteProperty -Name Server_Name -Value $servername.ToUpper()
    $obj | Add-Member -MemberType NoteProperty -Name VDisk_Disk -Value $vdisk
    $obj | Add-Member -MemberType NoteProperty -Name Copy_ID -Value $row.copy_id
    $obj | Add-Member -MemberType NoteProperty -Name Status -Value $row.status
    $obj | Add-Member -MemberType NoteProperty -Name Sync -Value $row.sync
    $obj | Add-Member -MemberType NoteProperty -Name Primary_Volume -Value $row.primary
    $obj | Add-Member -MemberType NoteProperty -Name Mdisk_Grp_ID -Value $row.mdisk_grp_id
    $obj | Add-Member -MemberType NoteProperty -Name Mdisk_Grp_Name -Value $row.mdisk_grp_name
    $obj | Add-Member -MemberType NoteProperty -Name MDisk_Grp_DC -Value $mdisk_grp_dc
    $obj | Add-Member -MemberType NoteProperty -Name MDisk_Grp_Storage_Device -Value $mdisk_grp_str
    $obj | Add-Member -MemberType NoteProperty -Name Capacity -Value $row.capacity
    $obj | Add-Member -MemberType NoteProperty -Name Capacity_GB -Value $GBCapacity
    $obj | Add-Member -MemberType NoteProperty -Name Capacity_GiB -Value $GiBCapacity
    $obj | Add-Member -MemberType NoteProperty -Name Type -Value $row.type
    $obj | Add-Member -MemberType NoteProperty -Name SE_Copy -Value $row.se_copy
    $obj | Add-Member -MemberType NoteProperty -Name Easy_Tier -Value $row.easy_tier
    $obj | Add-Member -MemberType NoteProperty -Name Easy_Tier_Status -Value $row.easy_tier_status
    $obj | Add-Member -MemberType NoteProperty -Name Compressed_Copy -Value $row.compressed_copy
    $obj | Add-Member -MemberType NoteProperty -Name Parent_MDisk_Grp_ID -Value $row.parent_mdisk_grp_id
    $obj | Add-Member -MemberType NoteProperty -Name Parent_MDisk_Grp_Name -Value $row.parent_mdisk_grp_name
    $obj | Add-Member -MemberType NoteProperty -Name Encrypt -Value $row.encrypt
    $obj | Add-Member -MemberType NoteProperty -Name Deduplicated_Copy -Value $row.deduplicated_copy

    $kyu = $row.vdisk_name.toupper() + " and  Copy ID" + $row.copy_id
    LogWrite -level "INFO" -message "object for $kyu created"
    Write-Host "object for $kyu created" -ForegroundColor White -BackgroundColor Blue

}
catch{
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "WARNING" -message "$message"
    $errors = $errors + 1
}

###############################################################################################
###############################################################################################

    # Create insert statement
try{    
    $properties = $obj.PSObject.Properties
    $i = 0
    $command.CommandText = "INSERT INTO " + $table + " (" + [string]::Join(",", ($properties | ForEach-Object{$_.Name})) + ") VALUES (" + [string]::Join(",", ($properties | ForEach-Object{$i++; "@$i"})) + ")"  
    $command.Parameters.Clear() 
    $i = 0
    $clear = $properties | ForEach-Object{$i++; $command.Parameters.AddWithValue("@$i", $_.Value)}
}
catch{
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1
}
try{
    # Write to database
    $command.ExecuteScalar()
    LogWrite -level "INFO" -message "$kyu write success on DB"
    Write-Host "$kyu write success on DB" -ForegroundColor White -BackgroundColor Blue
}
catch{
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1  
}
}

###############################################################################################
###############################################################################################

# Close SQL Connection
$con.Close()

$endDTM = (Get-Date)
$ts = New-TimeSpan -Seconds $(($endDTM-$startDTM).totalseconds)
"Elapsed Time: $ts"

if($errors -gt 0){
    $subject = "Import SCV has failed"
    $body = "Import of SVC Files to Services_idr/dbo.SVC_LUN has failed with $errors Error(s)"
    LogEmail -from $from -to $to -subject $subject -body $body -attachment $global:logFile
    LogWrite -level "INFO" -message "Error-E-Mail to $to sent successfully from $from"
}

# Close Log File
LogFinish -logPath $global:logFile -processingTime $ts -errors $errors -warnings $warnings -NoExit $True