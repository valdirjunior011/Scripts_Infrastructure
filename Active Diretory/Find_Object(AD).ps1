#---------------------------------------------------------[Initialisations]--------------------------------------------------------
# Init PowerShell Gui
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#Load dlls into context of the current console session
Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
 
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
#---------------------------------------------------------[Functions]--------------------------------------------------------
function Start-ShowConsole {
    $PSConsole = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($PSConsole, 5)
}
     
function Start-HideConsole {
    $PSConsole = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($PSConsole, 0)
}
#---------------------------------------------------------[Form and Script]--------------------------------------------------------
Start-HideConsole
$window = New-Object System.Windows.Forms.Form
$window.Text = "Check Device Information"
$window.Width = 450
$window.Height = 298
$window.StartPosition = "CenterScreen"
$window.KeyPreview = $True
$window.MaximumSize = $window.Size
$window.MinimumSize = $window.Size
 

$Label = New-Object System.Windows.Forms.Label
$Label.Location = New-Object System.Drawing.Size(10, 10)
$Label.Text = "Enter Computer Name or IP"
$Label.AutoSize = $True
$window.Controls.Add($Label)

$windowTextBox = New-Object System.Windows.Forms.TextBox
$windowTextBox.Location = New-Object System.Drawing.Size(50, 40)
$windowTextBox.Size = New-Object System.Drawing.Size(350, 50)
$window.Controls.Add($windowTextBox)

$resultsLabel = New-Object System.Windows.Forms.Label
$resultsLabel.Location = New-Object System.Drawing.Size(10, 80)
$resultsLabel.Text = "Results:"
$resultsLabel.AutoSize = $True
$window.Controls.Add($resultsLabel)

$systemLabel = New-Object System.Windows.Forms.Label
$systemLabel.Location = New-Object System.Drawing.Size(10, 110)
$systemLabel.Text = "System Name:"
$systemLabel.AutoSize = $True
$window.Controls.Add($systemLabel)

$windowTextBox1 = New-Object System.Windows.Forms.TextBox
$windowTextBox1.Location = New-Object System.Drawing.Size(120, 110)
$window.Controls.Add($windowTextBox1)

$userLabel = New-Object System.Windows.Forms.Label
$userLabel.Location = New-Object System.Drawing.Size(10, 140)
$userLabel.Text = "User Logged:"
$userLabel.AutoSize = $True
$window.Controls.Add($userLabel)

$windowTextBox2 = New-Object System.Windows.Forms.TextBox
$windowTextBox2.Location = New-Object System.Drawing.Size(120, 140)
$window.Controls.Add($windowTextBox2)

$DomainLabel = New-Object System.Windows.Forms.Label
$DomainLabel.Location = New-Object System.Drawing.Size(10, 170)
$DomainLabel.Text = "Domain:"
$DomainLabel.AutoSize = $True
$window.Controls.Add($DomainLabel)

$windowTextBox3 = New-Object System.Windows.Forms.TextBox
$windowTextBox3.Location = New-Object System.Drawing.Size(120, 170)
$window.Controls.Add($windowTextBox3)

$cleanButton = New-Object System.Windows.Forms.Button
$cleanButton.Location = New-Object System.Drawing.Size(120, 200)
$cleanButton.Size = New-Object System.Drawing.Size(50, 50)
$cleanButton.Text = "Clean"
$cleanButton.Add_Click({
        $windowTextBox.Clear()
        $windowTextBox1.Clear()
        $windowTextBox2.Clear()
        $windowTextBox3.Clear()

    })

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Location = New-Object System.Drawing.Size(200, 200)
$closeButton.Size = New-Object System.Drawing.Size(50, 50)
$closeButton.Text = "Close"
$closeButton.Add_Click({
        $window.dispose()
    })
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Size(30, 200)
$okButton.Size = New-Object System.Drawing.Size(50, 50)
$okButton.Text = "OK"
$okButton.Add_Click({
        $strcomputer = $windowTextBox.Text
        # Ping Verification $true follow if not Write Host
        If ($windowTextBox.Text -eq "") {
            $windowTextBox.Text = "Empty is not allow! Please entry with valid hostname or IP"
        }
        elseif ( Test-Connection -ComputerName $strcomputer -count 1 -Quiet -ErrorAction SilentlyContinue) {
            $Results = (Get-WmiObject -ComputerName $strcomputer -Class Win32_ComputerSystem -ErrorAction SilentlyContinue)
            $windowTextBox1.Text = "$($Results.PSComputerName)"
            $windowTextBox2.Text = "$($Results.UserName)"
            $windowTextBox3.Text = "$($Results.Domain)"
        }
        else {
            $windowTextBox.Text = "Computer $strcomputer is Offiline or not exist"
        }
    
    })
 
$window.Controls.Add($okButton)
$window.Controls.Add($closeButton)
$window.Controls.Add($cleanButton)

[void]$window.ShowDialog()