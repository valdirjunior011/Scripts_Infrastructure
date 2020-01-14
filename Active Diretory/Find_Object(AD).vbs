' Modificado por Jamilton Santan
' Script faz a busca pelo IP e retorna : Ip, Dominio/Usuário e máquina.

strcomputer = inputbox("Enter Computer Name or IP")
if strcomputer = "" then
    wscript.quit
else

' Faz teste com o ping
Set objPing = GetObject("winmgmts:{impersonationLevel=impersonate}").ExecQuery _
    ("select * from Win32_PingStatus where address = '" & strcomputer & "'")
For Each objStatus in objPing
    If IsNull(objStatus.StatusCode) or objStatus.StatusCode<>0 Then
        'request timed out
        msgbox(strcomputer & " did not reply" & vbcrlf & vbcrlf & _
    "Please check the name and try again")
    else
        'Coleta user
        set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & _
    strComputer & "\root\cimv2")
        Set colSettings = objWMIService.ExecQuery("Select * from Win32_ComputerSystem")
        For Each objComputer in colSettings
            msgbox("System Name: " & objComputer.Name & vbcrlf & "User Logged in : " & _
    objcomputer.username  & vbcrlf & "Domain: " & objComputer.Domain)
        Next
    end if
next
end if