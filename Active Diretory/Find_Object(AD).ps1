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

$Label1 = New-Object System.Windows.Forms.Label
$Label1.Location = New-Object System.Drawing.Size(10, 80)
$Label1.Text = "Results"
$Label1.AutoSize = $True
$window.Controls.Add($Label1)

$Label2 = New-Object System.Windows.Forms.Label
$Label2.Location = New-Object System.Drawing.Size(10, 110)
$Label2.Text = "System Name:"
$Label2.AutoSize = $True
$window.Controls.Add($Label2)

$windowTextBox1 = New-Object System.Windows.Forms.TextBox
$windowTextBox1.Location = New-Object System.Drawing.Size(120, 110)
#$windowTextBox1.Size = New-Object System.Drawing.Size(350, 250)
$window.Controls.Add($windowTextBox1)

$Label3 = New-Object System.Windows.Forms.Label
$Label3.Location = New-Object System.Drawing.Size(10, 140)
$Label3.Text = "User Logged:"
$Label3.AutoSize = $True
$window.Controls.Add($Label3)

$windowTextBox2 = New-Object System.Windows.Forms.TextBox
$windowTextBox2.Location = New-Object System.Drawing.Size(120, 140)
#$windowTextBox2.Size = New-Object System.Drawing.Size(350, 250)
$window.Controls.Add($windowTextBox2)

$Label4 = New-Object System.Windows.Forms.Label
$Label4.Location = New-Object System.Drawing.Size(10, 170)
$Label4.Text = "Domain:"
$Label4.AutoSize = $True
$window.Controls.Add($Label4)

$windowTextBox3 = New-Object System.Windows.Forms.TextBox
$windowTextBox3.Location = New-Object System.Drawing.Size(120, 170)
#$windowTextBox3.Size = New-Object System.Drawing.Size(350, 250)
$window.Controls.Add($windowTextBox3)

$windowButton2 = New-Object System.Windows.Forms.Button
$windowButton2.Location = New-Object System.Drawing.Size(120, 200)
$windowButton2.Size = New-Object System.Drawing.Size(50, 50)
$windowButton2.Text = "Clean"
$windowButton2.Add_Click({
        # $window.clean()
        $windowTextBox.Clear()
        $windowTextBox1.Clear()
        $windowTextBox2.Clear()
        $windowTextBox3.Clear()

    })

$windowButton1 = New-Object System.Windows.Forms.Button
$windowButton1.Location = New-Object System.Drawing.Size(200, 200)
$windowButton1.Size = New-Object System.Drawing.Size(50, 50)
$windowButton1.Text = "Close"
$windowButton1.Add_Click({
        $window.dispose()
    })
$windowButton = New-Object System.Windows.Forms.Button
$windowButton.Location = New-Object System.Drawing.Size(30, 200)
$windowButton.Size = New-Object System.Drawing.Size(50, 50)
$windowButton.Text = "OK"
$windowButton.Add_Click({
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
 
$window.Controls.Add($windowButton)
$window.Controls.Add($windowButton1)
$window.Controls.Add($windowButton2)

[void]$window.ShowDialog()