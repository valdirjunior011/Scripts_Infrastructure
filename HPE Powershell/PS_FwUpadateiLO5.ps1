# Get Start Time
$startDTM = (Get-Date)
Clear-Host

# VARIABLES

# Meta Information of script
$author = "Valdir"
$version = "1.2"
$runAs = [Environment]::UserDomainName + "\" + [Environment]::UserName
$workingFile = $MyInvocation.MyCommand.Definition
$creationDate = (Get-ChildItem $workingFile).CreationTime 
$creationDate = Get-Date -Date "$creationDate" -Format "yyyy-MM-dd"
$lastModified = (Get-ChildItem $workingFile).LastWriteTime
$lastModified = Get-Date -Date "$lastModified" -Format "yyyy-MM-dd HH:mm:ss"
$logPath = ""
$csv = ""
$iLO5_Location = "" <# Location of the iLO5 firmware USE .bin file #> 

# Dates
$date = Get-Date -Format dd_MM_yyyy

# Errors and Warnings
$errors = 0
$warnings = 0

############################################################################################################################################

# LOGGING

# Import Logging Functions
Write-Host "Creating LogFile" -ForegroundColor White -BackgroundColor Blue

. "\\Scripts\Logging\Logging_Functions.ps1"
$logName = "$date.log"

$global:logFile = $logPath + $logName

# creating Logging File
LogStart -logPath $logPath -logName $logName -workingFile $workingFile -author $author -version $version -created $creationDate -modified $lastModified -runAs $runAs

##########################################################################################################################################

# MODULES TO INSTALL

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

# HPE iLO PowerShell Cmdlets 
If (-not (Get-Module -Name HPEiLOCmdlets)) {
    Install-Module -Name HPEiLOCmdlets
    Write-Host "Installing Module HPE iLO"
    LogWrite -level "INFO" -message "Installing Module HPE iLO"
}
Import-Module HpeIloCmdlets
Write-Host "Importing Module HPE iLO"
LogWrite -level "INFO" -message "Importing Module HPE iLO"

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

# Disconnect-HPOVMgmt $ConnectedSessions
try {
    $Connection1 = Connect-HPOVMgmt -Hostname Instance1 -AuthLoginDomain euro1 -Credential $credential 
    Write-Host "Connecting OneView Host $($Connection1.name)" -ForegroundColor White -BackgroundColor Blue
    LogWrite -level "INFO" -message "Connecting OneView Host $($Connection1.name)"
 
    $Connection2 = Connect-HPOVMgmt -Hostname Instance2 -AuthLoginDomain euro1 -Credential $credential 
    Write-Host "Connecting OneView Host $($Connection2.name)" -ForegroundColor White -BackgroundColor Blue    
    LogWrite -level "INFO" -message "Connecting OneView Host $($Connection2.name)"
   
    $Connection3 = Connect-HPOVMgmt -Hostname Instance3 -AuthLoginDomain euro1 -Credential $credential
    Write-Host "Connecting OneView Host $($Connection3.name)" -ForegroundColor White -BackgroundColor Blue    
    LogWrite -level "INFO" -message "Connecting OneView Host $($Connection3.name)"
     
    $Connection4 = Connect-HPOVMgmt -Hostname Instance4 -AuthLoginDomain euro1 -Credential $credential
    Write-Host "Connecting OneView Host $($Connection4.name)" -ForegroundColor White -BackgroundColor Blue 
    LogWrite -level "INFO" -message  "Connecting OneView Host $($Connection4.name)"
    
    $Connection5 = Connect-HPOVMgmt -Hostname Instance5 -AuthLoginDomain euro1 -Credential $credential
    Write-Host "Connecting OneView Host $($Connection5.name)" -ForegroundColor White -BackgroundColor Blue 
    LogWrite -level "INFO" -message "Connecting OneView Host $($Connection5.name)"
}
catch {
    $err = $_.Exception
    $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
    LogWrite -level "ERROR" -message "$message"
    $errors = $errors + 1
}

##########################################################################################################################################

# Build CSV File and Exporting
Write-Host "Getting iLO5 Servers and Export to CSV" -ForegroundColor White -BackgroundColor Blue    
LogWrite -level "INFO" -message "Getting iLO5 Servers and Export to CSV"

Get-HPOVServer -ApplianceConnection $ConnectedSessions | Select-Object servername, shortmodel, mpmodel, mpfirmwareVersion | Where-Object {$_.mpmodel -eq "iLO5" -and $_.mpfirmwareVersion -eq "2.72 Sep 04 2022" -and $_.servername -contains "HDH*"} |
ForEach-Object {
    new-object psobject -Property @{
        ServerName      = $_.servername
        Model           = $_.shortmodel
        iLO_version     = $_.mpmodel
        FirmwareVersion = $_.mpfirmwareVersion
    
    }
} | Select-Object ServerName, Model, iLO_version, FirmwareVersion | 
Export-Csv -Delimiter "," -Path $csv\Firmware.csv -NoTypeInformation | Format-Table 

#######################################################################################################################

# Added these lines to avoid the error: "The underlying connection was closed: Could not establish trust relationship for the SSL/TLS secure channel."
# due to an invalid Remote Certificate

Write-Host "Certificate Definition for iLO Connection" -ForegroundColor White -BackgroundColor Blue   
LogWrite -level "INFO" -message "Certificate Definition for iLO Connection" 

add-type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#######################################################################################################################
  
# Computes selection  
Write-Host "Building Array List of Servers iLO" -ForegroundColor White -BackgroundColor Blue  
LogWrite -level "INFO" -message "Building Array List of Servers iLO"
$computes = (Get-HPOVServer -ApplianceConnection $ConnectedSessions | Where-Object {$_.mpmodel -eq "iLO5" -and $_.mpfirmwareVersion -eq "2.72 Sep 04 2022" -and $_.servername -contains "HDH*"})
 
#######################################################################################################################

Write-Host "Begin of Updating Process" -ForegroundColor White -BackgroundColor Blue    
LogWrite -level "INFO" -message "Begin of Updating Process"

ForEach ($compute in $computes) {

    $testconnection = Test-Connection $compute -Count 2 -Quiet
        IF ($testconnection -eq "True"){
        Write-Host "Begin of Updating Process" -ForegroundColor White -BackgroundColor Blue    
        LogWrite -level "INFO" -message "Begin of Updating Process"
        # Capture of the SSO Session Key
        try {
            $iloSession = $compute | Get-OVIloSso -IloRestSession
        }
        catch {
            $warn = $_.Exception
            $message = "[] " + $warn.Message + "  " + $_.InvocationInfo.ScriptLineNumber
            Write-Host "Device $($compute.serverName) is unavailable or busy" -ForegroundColor Red -BackgroundColor White
            LogWrite -level "WARNING" -message "Device $($compute.serverName) is unavailable or busy"
            $warnings = $warnings + 1
        }
        $ilosessionkey = $iloSession."X-Auth-Token"
        Write-Host "Capture SSO Key Session of $($compute.serverName) = $ilosessionkey" -ForegroundColor White -BackgroundColor Blue
        LogWrite -level "INFO" -message "Capture SSO Key Session of $($compute.serverName) = $ilosessionkey"
        $iloIP = $compute.mpHostInfo.mpIpAddresses | Where-Object type -ne LinkLocal | ForEach-Object address

        $Ilohostname = $compute  | ForEach-Object { $_.mpHostInfo.mpHostName }
        $iloModel = $compute  | ForEach-Object mpmodel
        $serverName = $compute  | ForEach-Object serverName
        if (! $serverName) { $serverName = "Unnamed" }
        $Model = $compute  | ForEach-Object Model
        
        if ($iloModel -eq "iLO5") {

            $connection = Connect-HPEiLO -Address $iloIP -XAuthToken $ilosessionkey -DisableCertificateAuthentication -Force
            Write-Host "Connectiong on iLO and updating the Firmware" -ForegroundColor White -BackgroundColor Blue
            LogWrite -level "INFO" -message "Connectiong on iLO and updating the Firmware"

            try {
                $task = Update-HPEiLOFirmware -TPMEnabled -Location $iLO5_location -Connection $connection -Confirm:$False -UploadTimeout 900 -Force
                Write-Host "$iloModel $iloIP [$Ilohostname - $serverName - $Model]: $($task.statusinfo.message)" -ForegroundColor White -BackgroundColor Blue
                LogWrite -level "INFO" -message "`n$iloModel $iloIP [$Ilohostname - $serverName - $Model]: $($task.statusinfo.message)"
            }
            catch {
                Write-Host "$iloModel $iloIP [$Ilohostname - $serverName - $Model]: Update Failure !" -ForegroundColor Red -BackgroundColor White
                LogWrite -level "ERROR" -message "`n$iloModel $iloIP [$Ilohostname - $serverName - $Model]: Update Failure !"
                $errors = $errors + 1
            }
            
        }Else{
            Write-Host "$compute is not online" -ForegroundColor White -BackgroundColor Blue   
            LogWrite -level "ERROR" -message "$compute is not online"
        }
    }
}

# Adding Waiting time to refresh information on OV and get new Reports
# time 10 min in seconds 600 seconds
IF ($computes -ne 0){
    $duration = 600
    $step = 1

    for ($i = 1; $i -le $duration; $i += $step) {
        Start-Sleep -Seconds $step
        $percentComplete = [int]($i / $duration * 100)
        Write-Progress -Activity "Waiting 10 min to OneView Refresh new iLO Version" -Status "Time elapsed: $i seconds" -PercentComplete $percentComplete
    }

    Write-Host "Gettiing new Firmware Version After Updated" -ForegroundColor White -BackgroundColor Blue   
    LogWrite -level "INFO" -message "Gettiing new Firmware Version After Updated"

    Get-HPOVServer -ApplianceConnection $ConnectedSessions | Where-Object mpmodel -eq "iLO5" | Select-Object ServerName, mpfirmwareVersion |
    ForEach-Object {
        new-object psobject -Property @{
            ServerName         = $_.servername
            NewFirmwareVersion = $_.mpfirmwareVersion
        }
    } | Select-Object ServerName, NewFirmwareVersion | 
    Export-Csv -Delimiter "," -Path $csv\NewFirware.csv -NoTypeInformation | Format-Table 

    try {
        $CSVFile = Import-CSV $csv\Firmware.csv -Delimiter ","
        $results = Import-CSV $csv\NewFirware.csv -Delimiter ","
    }
    catch {
        $err = $_.Exception
        $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
        LogWrite -level "ERROR" -message "$message"
        $errors = $errors + 1
    }

    Write-Host "Adding Info of New Firmware Version to Exist CSV" -ForegroundColor White -BackgroundColor Blue   
    LogWrite -level "INFO" -message "Adding Info of New Firmware Version to Exist CSV"

    Foreach ($Line in (0..($CSVFile.count - 1))) {
        $NewFirmware = ($results | Where-Object { $_.ServerName -eq $CSVFile[$line].Servername }).NewFirmwareVersion
        $CSVFile[$Line] | Add-Member -Name NewFirmwareVersion -Value $NewFirmware -MemberType NoteProperty -Force
    }

    try {
        $CSVFile | Export-CSV 'Firmware.csv' -NoTypeInformation
    }
    catch {
        $err = $_.Exception
        $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
        LogWrite -level "ERROR" -message "$message"
        $errors = $errors + 1
    }
    Write-Host "Deleting Temp File" -ForegroundColor White -BackgroundColor Blue 
    LogWrite -level "INFO" -message "Deleting Temp File" 

    try {
        Remove-Item '\NewFirware.csv'
    }
    catch {
        $err = $_.Exception
        $message = "[] " + $err.Message + "  " + $_.InvocationInfo.ScriptLineNumber
        LogWrite -level "ERROR" -message "$message"
        $errors = $errors + 1
    }
}Else{

    Write-Host "No Servers to be update was found" -ForegroundColor White -BackgroundColor Blue   
    LogWrite -level "INFO" -message "No Servers to be update was found"
}

Write-Host "Disconnecting of All OneView Servers" -ForegroundColor White -BackgroundColor Blue       
LogWrite -level "INFO" -message "Disconnecting of All OneView Servers" 

#Disconnect from all OneView    
Disconnect-HPOVMgmt $ConnectedSessions

# Get End Time
$endDTM = (Get-Date)
$ts = New-TimeSpan -Seconds $(($endDTM - $startDTM).totalseconds)

# Write Mail if Error
if ($errors -gt 0) {
    try {
        Write-Host "Operation Done with $errors error(s)! Elapsed Time: $ts" -ForegroundColor Red -BackgroundColor White
        LogWrite -level "INFO" -message  "Operation Done with $errors errors! Elapsed Time: $ts"
        LogEmail -from "Email" -to "Email" -subject "Error running Script $workingFile" -body "There have been $errors errors" -attachment $global:logFile
    }
    catch {
        Write-Output "Sending Email failed"
    }
}
elseif ($warnings -gt 0) {
    try {
        Write-Host "Operation Done with $warnings error(s)! Elapsed Time: $ts" -ForegroundColor Red -BackgroundColor White
        LogWrite -level "INFO" -message  "Operation Done with $warnings errors! Elapsed Time: $ts"
        LogEmail -from "Email" -to "Email" -subject "Error running Script $workingFile" -body "There have been $errors errors" -attachment $global:logFile
    }
    catch {
        Write-Output "Sending Email failed"
    }
}
else {
    Write-Host "Operation Done! Elapsed Time: $ts" -ForegroundColor White -BackgroundColor Blue 
    LogWrite -level "INFO" -message  "Operation Done! Elapsed Time: $ts"
}

# Close Log File
LogFinish -logPath "$logPath\$date.log" -processingTime $ts -errors $errors -warnings $warnings -NoExit $True