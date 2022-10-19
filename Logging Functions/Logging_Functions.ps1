Function LogStart {
  <#
    .SYNOPSIS
    Creates log file

    .DESCRIPTION
    Creates log file with path and name that is passed. Checks if log file exists, and if it does deletes it and creates a new one.
    Once created, writes initial logging data

    .PARAMETER logPath
    Mandatory. Path of where log is to be created. Example: C:\Windows\Temp

    .PARAMETER logName
    Mandatory. Name of log file to be created. Example: Test_Script.log
      
    .PARAMETER workingFile


    .PARAMETER runAs


    .PARAMETER author


    .PARAMETER version


    .PARAMETER created


    .PARAMETER modified


    .INPUTS
    Parameters above

    .OUTPUTS
    Log file created

    .EXAMPLE
    Log-Start -LogPath "C:\Windows\Temp" -LogName "Test_Script.log" -ScriptVersion "1.5"
#>
    
  [CmdletBinding()]
  
  Param (
    [Parameter(Mandatory = $true)][string]$logPath, 
    [Parameter(Mandatory = $true)][string]$logName, 
    [Parameter(Mandatory = $true)][string]$workingFile,
    [Parameter(Mandatory = $true)][string]$runAs,
    [Parameter(Mandatory = $true)][string]$author,
    [Parameter(Mandatory = $true)][string]$version,
    [Parameter(Mandatory = $true)][string]$created,
    [Parameter(Mandatory = $true)][string]$modified
  )
  
  Process {
    $sFullPath = $logPath + "\" + $logName
    
    #Check if file exists and delete if it does
    If ((Test-Path -Path $sFullPath)) {
      Remove-Item -Path $sFullPath -Force
    }
    
    #Create file and start logging
    New-Item $sFullPath -type file -force
    
    $date1 = Get-Date -Format d 
    $date2 = Get-Date -Format HH:mm:ss
    $date = $date1 + " " + $date2

    Add-Content -Path $sFullPath -Value "=========================================================================="
    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value "@script:`t $workingFile"
    Add-Content -Path $sFullPath -Value "@runAs:`t`t $runAs"
    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value "@author:`t $author"
    Add-Content -Path $sFullPath -Value "@version:`t $version"
    Add-Content -Path $sFullPath -Value "@created:`t $created"
    Add-Content -Path $sFullPath -Value "@modified:`t $modified"
    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value "Started processing at [$date]."
    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value "=========================================================================="
    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value ""
  }
}

Function LogWrite {
  <#
  .SYNOPSIS
    Writes to a log file

  .DESCRIPTION
    Appends a new line to the end of the specified log file
  
  .PARAMETER LogPath
    Mandatory. Full path of the log file you want to write to. Example: C:\Windows\Temp\Test_Script.log
  
  .PARAMETER LineValue
    Mandatory. The string that you want to write to the log
      
  .INPUTS
    Parameters above

  .OUTPUTS
    None

  .EXAMPLE
    Log-Write -LogPath "C:\Windows\Temp\Test_Script.log" -LineValue "This is a new line which I am appending to the end of the log file."
  #>
  
  [CmdletBinding()]
  
  Param ([Parameter(Mandatory = $true)][string]$level, [Parameter(Mandatory = $true)][string]$message)
  
  Process {
    $date1 = Get-Date -Format d 
    $date2 = Get-Date -Format HH:mm:ss
    $date = $date1 + " " + $date2

    $message = "[$date]`t[$level]`t" + $message
    Add-Content -Path $global:logFile -Value $message
  
    #Write to screen for debug mode
    Write-Debug $message
  }
}

Function LogFinish {
  <#
  .SYNOPSIS
    Write closing logging data & exit

  .DESCRIPTION
    Writes finishing logging data to specified log and then exits the calling script
  
  .PARAMETER LogPath
    Mandatory. Full path of the log file you want to write finishing data to. Example: C:\Windows\Temp\Test_Script.log

  .PARAMETER NoExit
    Optional. If this is set to True, then the function will not exit the calling script, so that further execution can occur
  
  .INPUTS
    Parameters above

  .OUTPUTS
    None

  .EXAMPLE
    Log-Finish -LogPath "C:\Windows\Temp\Test_Script.log"

.EXAMPLE
    Log-Finish -LogPath "C:\Windows\Temp\Test_Script.log" -NoExit $True
  #>
  
  [CmdletBinding()]
  
  Param (
    [Parameter(Mandatory = $true)][string]$logPath, 
    [Parameter(Mandatory = $true)][string]$processingTime,
    [Parameter(Mandatory = $true)][string]$errors = 0,
    [Parameter(Mandatory = $true)][string]$warnings = 0,   
    [Parameter(Mandatory = $false)][string]$NoExit
  )
  
  Process {
    $date1 = Get-Date -Format d 
    $date2 = Get-Date -Format HH:mm:ss
    $date = $date1 + " " + $date2

    Add-Content -Path $LogPath -Value ""
    Add-Content -Path $LogPath -Value ""
    Add-Content -Path $LogPath -Value "=========================================================================="
    Add-Content -Path $LogPath -Value ""
    Add-Content -Path $LogPath -Value "Finished processing at [$date]."
    Add-Content -Path $LogPath -Value ""
    Add-Content -Path $LogPath -Value "Total Processing Time: $processingTime (HH:MM:SS)"
    Add-Content -Path $LogPath -Value ""
    Add-Content -Path $LogPath -Value "$errors Errors"
    Add-Content -Path $LogPath -Value "$warnings Warnings"
    Add-Content -Path $LogPath -Value ""
    Add-Content -Path $LogPath -Value "=========================================================================="
  
  
    #Exit calling script if NoExit has not been specified or is set to False
    If (!($NoExit) -or ($NoExit -eq $False)) {
      Exit
    }    
  }
}

Function LogEmail {
  <#
  .SYNOPSIS
    Emails log file to list of recipients

  .DESCRIPTION
    Emails the contents of the specified log file to a list of recipients
  
  .PARAMETER LogPath
    Mandatory. Full path of the log file you want to email. Example: C:\Windows\Temp\Test_Script.log
  
  .PARAMETER EmailFrom
    Mandatory. The email addresses of who you want to send the email from. Example: "admin@9to5IT.com"

  .PARAMETER EmailTo
    Mandatory. The email addresses of where to send the email to. Seperate multiple emails by ",". Example: "admin@9to5IT.com, test@test.com"
  
  .PARAMETER EmailSubject
    Mandatory. The subject of the email you want to send. Example: "Cool Script - [" + (Get-Date).ToShortDateString() + "]"

  .INPUTS
    Parameters above

  .OUTPUTS
    Email sent to the list of addresses specified

  .EXAMPLE
    Log-Email -LogPath "C:\Windows\Temp\Test_Script.log" -EmailFrom "admin@9to5IT.com" -EmailTo "admin@9to5IT.com, test@test.com" -EmailSubject "Cool Script - [" + (Get-Date).ToShortDateString() + "]"
  #>
  
  [CmdletBinding()]
  
  Param (
    [Parameter(Mandatory = $true)][string]$from, 
    [Parameter(Mandatory = $true)][string]$to, 
    [Parameter(Mandatory = $true)][string]$subject,
    [Parameter(Mandatory = $true)][string]$body,
    [Parameter(Mandatory = $false)][string]$attachment
  )
  
  Process {
    if ($attachment -ne "") {
      Send-MailMessage -from $from -to $to -Subject $subject -body $body -encoding ([System.Text.Encoding]::UTF8) -SmtpServer "SMTP SERVER" -Attachments $attachment
    }
    else {
      Send-MailMessage -from $from -to $to -Subject $subject -body $body -encoding ([System.Text.Encoding]::UTF8) -SmtpServer "SMTP SERVER"
    }
  }
}